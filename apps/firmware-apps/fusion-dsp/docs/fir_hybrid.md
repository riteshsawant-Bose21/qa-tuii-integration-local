# FIR Hybrid Overview

Goal: Zero-latency, long-tap FIR filtering by blending a direct-form lead partition with FFT-based partitions. The hybrid layout targets high tap counts while keeping CPU burstiness bounded.

## Summary
- The first partition is strictly direct-form (2 x base partition taps) so the algorithm maintains zero additional latency.
- All following partitions operate in FFT land and are instantiated in doubling pairs (N, N, 2N, 2N, 4N, 4N, …) to keep the work evenly spread.

## Partition Topology
- `base_partition_size` is derived from the `direct_taps` property (default 128) and clamped so each FFT block spans at least two audio frames; the direct partition then spans `min(2xbase_partition_size, num_taps)` samples.
- Each FFT partition is capped at 65,536 taps, but the overall filter can exceed that because partitions keep doubling and executing less often, so the "three partitions per frame" budget is still sufficient.
- Odd-indexed FFT partitions own the full FFT pipeline (input buffer, impulse spectrum, caches, temporary workspaces, and the optional half-size FFT accelerator). Even-indexed partitions reuse their odd partner’s cached spectra.
- Delay compensation is pre-computed per partition so all FFT outputs line up with the zero-latency direct path.

## Memory and State Management
- Each FFT partition keeps its overlap-save buffers, impulse spectra, accumulator scratch, and delay FIFO in `DspStateMemory`, ensuring the DSP owns the lifetime and avoids heap churn.
- Scheduling scratch (ready/process lists, pair bookkeeping, selection flags) uses `DspTempMemory`, so the same fixed buffers are re-used per frame.
- Coefficient initialization, half-FFT workspaces, and FFT temporaries are also pulled from DSP-managed pools. This change alone dropped average load from roughly 6% MIPS to ~1% MIPS for a 65k-tap, single-channel case.
- The direct-form partition still stores its `std::vector<std::unique_ptr<FirFilter>>` on the heap; profiling showed that moving these objects into `DspStateMemory` added measurable overhead, so the heap-backed vector remains for now.

## Spectral Reuse and Scheduler
- Odd partitions compute new spectra and cache the results; their even partners copy the cache, cutting the FFT cost roughly in half for each odd/even pair.
- A per-frame scheduler can execute up to three FFT partitions:
	1. Build `pair_indices` by walking the ready set, pairing each odd partition with its even partner when both have accumulated enough samples. Sort pairs by the odd partition length so that shorter FFT blocks refresh first.
	2. Consume as many complete pairs as possible (typically one pair and maybe one single) within the three-partition budget, guaranteeing the cached spectra stay fresh.
	3. Remaining ready partitions are copied into `remaining_indices`, re-sorted by length, and pulled in until the per-frame budget is exhausted. Using two queues prevents singletons from starving the reuse pairs.

## Coefficient Lifecycle
- `parameter_coefficients` are wired through `POST_FUNCTION_VECTOR(on_coefficients_updated)`. Dirty rows are copied into the working coefficient buffer and mark the partitions for a rebuild.
- During initialization or whenever taps change, each FFT partition rehydrates its impulse spectrum. For long FFTs, odd partitions use the half-size combination trick: split taps into even/odd sequences, run two half-sized FFTs, and recombine via cached twiddle factors.

## Verification and Profiling
- Primary regression: `./build/test_dsp --test-suite "FIR Hybrid POC"` (includes direct vs. hybrid tests).
- Profiling helpers: `firh_check_profiling.py` (hybrid) and `fird_check_profiling.py` (direct) report the MIPS deltas after running the FIR profile_block scripts.
- `fir_direct.cpp` was added alongside the hybrid implementation for unit tests, profiling baselines, and direct-form math validation.

## Future Improvements
- Additional memory sharing between partitions is possible, but currently the savings are marginal compared to the hybrid gains. Revisit alongside larger architectural efforts (e.g., multi-threaded partition processing or convolution-reverb-length filters).