# Fusion GPT Disciplining Algorithm Demo Notes

This note is based on the current implementation in `fusion_gpt_dr.c`. It is written as a presentation-prep document first and a code review note second, so it explains the algorithm in plain language but stays faithful to what the driver actually does.

## Executive Summary

The disciplining loop uses a 10 MHz external reference as the timer clock and measures each 1PPS event against that 10 MHz counter. In the ideal case, consecutive PPS captures are exactly 10,000,000 timer ticks apart. Any deviation from 10,000,000 ticks is treated as frequency error.

The driver has two hardware control knobs for correcting that error:

- An 8-bit DAC value, which sets the control voltage into the Si5351B frequency-correction input.
- A Si5351B gain register, which changes how strongly that correction input responds.

At startup, the driver tries to use a saved calibration model. If that model still matches the current operating point, it performs a one-shot jump directly to a predicted near-zero-error `(gain, DAC)` pair. If not, it runs a live 5-point probe sweep, fits a local model of frequency error vs. gain and DAC, saves that model to disk, jumps to the predicted best point, and then lets a PI loop do the final trim.

## What Signals We Use

### 10 MHz

This is the core measurement clock. GPT1 is configured to run from the external 10 MHz clock source, so:

- 1 tick = 100 ns
- 1 second = 10,000,000 ticks

That means the disciplining algorithm does not estimate frequency indirectly. It directly counts how many 10 MHz ticks elapsed between two PPS events.

### 1PPS

This is the primary discipline reference. Each PPS edge is captured into `GPT_ICR1`, extended to a 64-bit timestamp, and compared to the previous PPS capture.

The main measured quantity is:

```text
diff = current_pps_capture - previous_pps_capture
freq_error = diff - 10,000,000
```

Interpretation:

- `freq_error = 0`: the local 10 MHz-derived timing matches the PPS spacing exactly
- `freq_error > 0`: the measured interval was too long in ticks
- `freq_error < 0`: the measured interval was too short in ticks

### 48 kHz

The 48 kHz input is captured on `GPT_ICR2`. In this driver it is not part of the correction law. It is only tracked as auxiliary timing information and logged as `48k_off` in the PPS diagnostics path.

For your presentation, the right framing is:

- 1PPS is the absolute long-period reference used for disciplining.
- 10 MHz is the counter basis used to measure error.
- 48 kHz is secondary observability, not a primary control input.

## How We Capture 1PPS and Compare It to the 10 MHz Counter

### Hardware view

GPT1 is configured so that:

- the free-running counter advances on the external 10 MHz clock
- `ICR1` latches on the PPS input
- `ICR2` latches on the 48 kHz input

The driver keeps a software-extended 64-bit version of the 32-bit GPT counter so counter wrap does not break interval measurements.

### ISR flow

On each PPS interrupt:

1. Read the latched `ICR1` capture value.
2. Extend it from 32 bits to 64 bits using the current free-running count.
3. Save it as the latest PPS timestamp.
4. If a previous PPS exists, compute the delta in ticks.
5. Convert that delta into a frequency error by subtracting `10,000,000`.

That is the key measurement in the whole algorithm.

### Why this works

If the local disciplined oscillator were perfect, the timer would count exactly 10,000,000 ticks between PPS edges. So the PPS path turns a timing problem into a simple count-error problem.

This gives a clean signal for control:

- too many ticks between PPS edges means the tuned clock is effectively off in one direction
- too few ticks means it is off in the other direction

### Important architectural point

The ISR is intentionally split in two phases:

- A timing phase under `pps_lock`, which only captures timestamps and maintains epoch/alignment state.
- A control phase under `ctrl_lock`, which updates calibration and PI targets.

Actual I2C writes are deferred to a workqueue. That keeps the interrupt path deterministic and prevents DAC or Si5351B transactions from blocking inside the ISR.

## The Two Control Knobs

## 1. DAC value

The DAC is an 8-bit control, clamped to `0..255`.

Conceptually:

- the DAC sets the correction voltage applied to the Si5351B frequency-correction input
- that voltage nudges the output frequency
- the PI loop mainly works by moving this DAC target

This is the fine-resolution actuator.

## 2. Gain register

The driver also programs a Si5351B gain register over I2C. In the current implementation the allowed range is:

- minimum gain: `40000`
- maximum gain: `250000`

Conceptually:

- gain changes the sensitivity of the frequency-correction input
- a higher gain means the same DAC step produces a larger frequency correction
- a lower gain means the DAC acts more gently

This is the coarse shaping actuator.

### Why both knobs matter

The DAC alone can hit rail limits. If the required correction is too large, the DAC may saturate at `0` or `255`. The gain control gives the algorithm another degree of freedom:

- gain chooses how steep the tuning response is
- DAC chooses where to sit on that response

That is why the startup calibration solves for both together, not just DAC alone.

## Startup Calibration Strategy

The startup logic tries to get close to the correct operating point quickly, before handing off to the steady-state PI loop.

There are three main modes:

1. Prebaked-model verification and jump
2. Live calibration sweep and model fit
3. Fallback directly to PI if calibration cannot complete

## Prebaked model path

The driver stores calibration data in:

`/var/lib/fusion/fusion-gpt-calibration.conf`

That file contains:

- fitted coefficients `k1`, `k2`, `k3`
- the center gain and center DAC where the model was learned
- the saved center error `e0`
- configuration parameters for probing and verification

At startup, if saved coefficients exist, the driver does not trust them blindly. It first re-checks that the current operating point still resembles the saved one.

### Verification process

The driver:

1. Uses the current gain and DAC as the center point.
2. Waits through a bounded verification window.
3. Collects a few low-error PPS samples.
4. Computes the current mean center error `e0`.
5. Compares current gain, DAC, and `e0` against the saved fingerprint.

If the fingerprint matches within configured tolerances, the saved model is accepted. Otherwise, the driver reruns live calibration.

This is a good story for a demo: the system learns once, reuses later, but still protects itself against stale calibration.

## Live calibration sweep

If no valid saved model exists, the driver performs a 5-point local sweep around the current operating point.

### Center point

The center is:

- `center_gain = current gain`
- `center_dac = current dac_target`

### Probe points

The sweep measures five operating points:

1. `(g0, d0)` center
2. `(g1, d0)` gain perturbation
3. `(g2, d0)` opposite gain perturbation
4. `(g0, d0 + dd)` DAC perturbation
5. `(g4, d0 + dd)` combined gain and DAC perturbation

The gain stencil is boundary-aware:

- near minimum gain, it probes upward
- near maximum gain, it probes downward
- otherwise it uses approximately symmetric gain offsets around center

### Per-point measurement process

For each probe point, the worker:

1. Writes the probe gain if needed.
2. Writes the probe DAC if needed.
3. Waits `cal_settle_pps` PPS intervals.
4. Measures mean PPS error over `cal_measure_pps` PPS intervals.

So each probe point produces one average frequency error value. Those five average errors are the data used for model fitting.

## The fitted model

The code fits a local bilinear model of frequency error around the center point:

```text
error(dg, dd) = e0 + k1*dg + k2*dd + k3*dg*dd
```

Where:

- `dg = gain - center_gain`
- `dd = dac - center_dac`
- `e0` is the measured center error
- `k1` is the local sensitivity to gain
- `k2` is the local sensitivity to DAC
- `k3` is the gain-DAC interaction term

Interpretation:

- `k1` says how error changes when gain moves
- `k2` says how error changes when DAC moves
- `k3` captures the fact that DAC sensitivity itself can depend on gain

That interaction term is the important reason this is more than a simple 1D calibration.

### Fit quality check

After fitting, the driver computes the mean absolute residual across the five probe points. If the residual is too high, the fit is rejected and the system falls back to the PI loop instead of trusting a poor model.

That is another good demo point: it has a built-in trust metric.

## Inverse solve and one-shot jump

Once the model is fitted or a prebaked model is accepted, the driver solves the inverse problem:

> Find a `(gain, DAC)` pair where predicted frequency error is zero.

The implementation does this by:

1. Scanning candidate gain values in steps.
2. For each gain, solving algebraically for the DAC offset `dd` that makes the model predict zero error.
3. Rejecting any solution whose DAC lands outside an allowed jump window.
4. Taking the first acceptable solution.

So the algorithm is not searching the entire 2D surface exhaustively. It scans gain and solves DAC from the model at each step.

Once a valid target is found, the worker applies:

- jump gain
- jump DAC

Then startup calibration is marked done.

### Why the jump matters

The jump gets the system close to the final operating point in one move, instead of asking the PI loop to crawl all the way there from an arbitrary startup value.

That improves startup convergence and makes the demo easier to explain:

- model-based coarse correction first
- PI fine correction second

## PI Loop for Final Trim

After calibration completes, or if calibration is skipped or fails, the steady-state PI logic runs on every PPS interval.

### Error signal

The PI loop uses the same measured PPS interval error:

```text
freq_error = measured_ticks_between_pps - 10,000,000
```

### Proportional part

If the absolute error is larger than a threshold, the driver applies a proportional DAC step:

- threshold: `20` ticks
- step size: `abs(error) / 10`
- step clamp: `1..10`

So large errors generate larger DAC moves, but only up to a capped step size.

### Integral part

The driver also accumulates error in `error_integrator`.

When the accumulated error exceeds a small limit:

- positive integrator -> decrement DAC by 1
- negative integrator -> increment DAC by 1

Then the integrator is reset.

This gives the controller a way to clean up small residual bias that the proportional term alone would not eliminate.

### Saturation behavior

If the DAC target runs outside `0..255`, the driver clamps it and then tries to increase the Si5351B gain in steps of `10000`.

That means:

- DAC is the first-choice actuator
- gain only gets bumped when DAC authority is exhausted

This is effectively a coarse/fine hierarchy.

## Recommended 4-Slide Story

## Slide 1: Problem and Signals

Title idea: `How We Measure Frequency Error`

Main points:

- GPT runs from external 10 MHz, so every tick is 100 ns.
- 1PPS is captured once per second and compared against the 10 MHz count.
- Ideal PPS spacing is exactly 10,000,000 ticks.
- Frequency error is `measured_ticks - 10,000,000`.
- 48 kHz is auxiliary timing visibility, not the main control reference.

## Slide 2: Control Knobs

Title idea: `What We Can Tune`

Main points:

- DAC value sets the correction voltage into the Si5351B control input.
- Gain register sets how responsive that input is.
- DAC is the fine control knob.
- Gain is the sensitivity/coarse control knob.
- Using both prevents the loop from relying on a single saturated actuator.

## Slide 3: Model-Based Calibration

Title idea: `Fast Startup With a Learned Local Model`

Main points:

- Probe 5 nearby `(gain, DAC)` points.
- Measure average PPS tick error at each point.
- Fit `error = e0 + k1*dg + k2*dd + k3*dg*dd`.
- Invert that model to find a predicted zero-error target.
- Save coefficients so future runs can skip the full sweep.

## Slide 4: PI Cleanup and Runtime Operation

Title idea: `Final Lock With PI Control`

Main points:

- After the one-shot jump, PI takes over for final trim.
- P term responds quickly to larger PPS interval errors.
- I term removes small steady residual bias.
- If DAC saturates, gain is stepped upward to restore control authority.
- `discipline_ready` is asserted after repeated low-error PPS samples.

## General Explanation You Can Say Out Loud

The simplest way to describe the algorithm is:

> We use the PPS signal as a once-per-second truth marker, and we measure it with a timer clocked from our local 10 MHz source. If the timer counts exactly 10 million ticks between PPS edges, we are perfect. If not, that tick-count difference is our frequency error.

Then:

> We correct that error with two knobs: DAC voltage and correction gain. At startup, we try to model how error changes as those two knobs move, then we solve that model backward to jump near the right operating point immediately. After that, a PI loop keeps trimming the remaining small error.

And finally:

> The result is a hybrid controller: model-based coarse acquisition plus feedback-based fine lock.

## Code-Review Observations Worth Knowing Before the Demo

These are not necessarily presentation topics, but they are worth being prepared for if someone asks implementation questions.

### 1. The 48 kHz capture path appears configured but not interrupt-enabled

In `gpt_start()`, the driver clears `SR_IF2` and sets `CR_IM2_RISING`, but `GPT_IR` is programmed with `IR_OF1IE | IR_IF1IE` and does not include `IR_IF2IE`.

That means the code can process `SR_IF2` when some other interrupt brings the ISR in, but it will not receive dedicated interrupts for every 48 kHz capture. So the current 48 kHz path looks more like best-effort observability than a guaranteed per-edge service path.

If asked about 48 kHz, the safe answer is that it is secondary telemetry in the current disciplining design, not a primary control input.

### 2. PPS capture is configured as `CR_IM1_BOTH`

The code comments say PPS is captured on both edges. The control law, however, assumes one PPS interval corresponds to `10,000,000` ticks.

If the hardware really produces two capture events per second on that input, the measured interval would not match the control law. So this deserves a quick sanity check before the demo:

- confirm whether the PPS source produces only one effective capture event
- or confirm whether the hardware mode behaves differently than the comment suggests

If it is working in the lab, there is probably a board- or signal-level explanation, but this is the first thing I would verify if someone asks deep implementation questions.

### 3. The inverse solve scans gain from startup gain upward

The inverse solver does not do a global 2D optimization. It scans candidate gains from the configured startup gain up to the max and solves DAC for each one.

That is a pragmatic design, not a flaw. But if someone asks whether it finds the mathematically best point on the whole surface, the precise answer is: no, it finds the first in-range zero-crossing candidate along that gain scan.

### 4. Runtime gain adaptation is asymmetric

In the PI path, gain is stepped upward when DAC saturates. There is no corresponding automatic gain decrease path in the steady-state controller.

Again, that may be intentional. But it means gain adaptation is currently framed as “recover authority when DAC rails,” not “continuously optimize gain in both directions.”

## Suggested Short Demo Closing

If you want one closing sentence for the deck:

> The disciplining algorithm treats PPS as truth, measures local oscillator error in 10 MHz timer ticks, uses a learned gain/DAC model to get close quickly, and then uses a lightweight PI loop to finish the lock.
