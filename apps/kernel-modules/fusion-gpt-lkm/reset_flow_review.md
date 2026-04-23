# Reset Flow Review For `fusion_gpt_dr.c`

This review inventories every reset-like command path in
`apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c` and categorizes each path
by trigger surface, implementation, state effects, and intended use. The driver
source is the primary source of truth. `fusion_connect_manager.c` and
`disciplining_state_machine.md` are used only to confirm the intended contract
of the exported reset APIs.

## Findings

### Medium: `fusion_gpt_reset_timing_session()` does not clear discipline model state

`fusion_gpt_reset_timing_session()` funnels through
`fusion_gpt_reset_timing_state_internal(false, false)` and resets timing state
plus discipline control state, but it does not call
`gpt_reset_discipline_model_locked()`.

Relevant code:

- `fusion_gpt_reset_timing_session()`:
  [fusion_gpt_dr.c:757](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:757)
- shared runtime reset path:
  [fusion_gpt_dr.c:679](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:679)
- model reset helper that is not used there:
  [fusion_gpt_dr.c:381](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:381)
- cold start path that does reset model state:
  [fusion_gpt_dr.c:1501](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:1501)

Impact:

- Session reset is documented as the boundary for GM/PTP loss or restart:
  [disciplining_state_machine.md:104](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/disciplining_state_machine.md:104)
- After that reset, old DAC/error samples still remain in the linear-fit window.
- The immediate post-reset reacquire jump is disabled because
  `discipline_reacquire_jump_pending` becomes false, but later model fitting can
  still blend pre-session and post-session samples until the rolling window is
  overwritten.

Assessment:

- This is a real boundary mismatch risk. `gpt_start()` treats model state as
  cold-start state, while runtime session reset leaves it intact.
- If the intended contract is "new timing session, but same oscillator
  calibration," this is intentional and should be documented explicitly.
- If the intended contract is "new timing session with no cross-session
  discipline history," the session reset path is incomplete.

### Low: `fusion_gpt_reset_timing_session()` is not a full discipline reset

Session reset clears continuity and reacquire state, but it still preserves DAC
baseline through `gpt_reset_discipline_control_locked(g, true, false, ...)`.

Relevant code:

- helper behavior:
  [fusion_gpt_dr.c:396](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:396)
- session reset call:
  [fusion_gpt_dr.c:757](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:757)
- DAC restore work:
  [fusion_gpt_dr.c:1441](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:1441)

Impact:

- A caller might infer from the name that session reset returns the whole
  discipline loop to a cold-start baseline.
- It does not. It preserves the current DAC target, queues DAC restore work, and
  only resets timing plus lock/continuity state.

Assessment:

- This looks intentional, not a code bug.
- It is still a contract hazard and should be documented as "session-boundary
  timing reset" rather than "full servo reset."

## Public Interfaces Under Review

### Exported APIs

- `fusion_gpt_reset_timing_state()` in
  [fusion_gpt_client.h:24](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_client.h:24)
  and [fusion_gpt_dr.c:751](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:751)
  is the public operational timing reset.
- `fusion_gpt_reset_timing_session()` in
  [fusion_gpt_client.h:25](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_client.h:25)
  and [fusion_gpt_dr.c:757](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:757)
  is the public session-boundary timing reset.

External caller confirmed:

- `fusion_connect_manager.c` dispatches control messages to either API at
  [fusion_connect_manager.c:1199](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-connect-lkm/fusion_connect_manager.c:1199).

### Writable module params

- `timing_reset_trigger` at
  [fusion_gpt_dr.c:135](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:135)
  is a module-param alias for `fusion_gpt_reset_timing_state()`.
- `timing_reset_sim_trigger` at
  [fusion_gpt_dr.c:175](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:175)
  is a simulated timing reset that also suppresses PPS handling for
  `timing_reset_sim_duration_ms`.
- `timing_pps_gap_sim_trigger` at
  [fusion_gpt_dr.c:220](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:220)
  is not a reset. It is only a PPS suppression hook.
- `timing_reset_sim_duration_ms` at
  [fusion_gpt_dr.c:215](/home/nate/fusion-mini/dev/fusion_monorepo/apps/kernel-modules/fusion-gpt-lkm/fusion_gpt_dr.c:215)
  is a duration control shared by the two simulation hooks.

## Categorized Reset And Reset-Like Flows

### 1. Public Operational Resets

#### `fusion_gpt_reset_timing_state()`

- Trigger surface: exported API and `timing_reset_trigger`
- Shared implementation: `fusion_gpt_reset_timing_state_internal(true, false)`
- Intended use: clear live timing state while preserving continuity when the
  previous PPS anchor is still usable
- State cleared:
  - live timing state via `gpt_reset_timing_state_locked()`
  - servo error accumulator fields, lock streak, GM lock via
    `gpt_reset_discipline_control_locked()`
- State preserved:
  - continuity/reacquire state when `discipline_continuity_ready` and
    `pps_valid` were both true, or a reacquire was already pending
  - preserved PPS capture for continuity validation
  - `last_pps_jiffies` when continuity/reacquire survives
  - DAC target/baseline through `preserve_dac = true`
  - discipline model samples and validity
- Side effects:
  - logs prior state if anything material changed
  - queues DAC restore work with `schedule_work(&g->dac_work)`
  - does not suppress PPS
- Risk/ambiguity:
  - preserves discipline model state even though timing state is cleared

#### `fusion_gpt_reset_timing_session()`

- Trigger surface: exported API
- Shared implementation: `fusion_gpt_reset_timing_state_internal(false, false)`
- Intended use: session-boundary reset for GM/PTP loss or restart
- State cleared:
  - live timing state
  - continuity/reacquire state
  - servo integrator, error stats, lock streak, GM lock
- State preserved:
  - DAC target/baseline
  - discipline model samples and validity
- State not preserved:
  - `discipline_continuity_ready`
  - `discipline_reacquire_pending`
  - preserved PPS capture for continuity validation
  - `last_pps_jiffies`
- Side effects:
  - logs as `timing session reset`
  - queues DAC restore work
  - no PPS suppression
- Risk/ambiguity:
  - not a full servo/model reset despite its boundary semantics

#### `timing_reset_trigger`

- Trigger surface: writable module param
- Shared implementation: exact alias for `fusion_gpt_reset_timing_state()`
- Intended use: operator-triggered one-shot timing reset without a separate
  caller
- Classification: public operational reset alias, not a distinct behavior

### 2. Simulation And Fault-Injection Hooks

#### `timing_reset_sim_trigger`

- Trigger surface: writable module param
- Shared implementation: `fusion_gpt_reset_timing_state_internal(true, true)`
- Intended use: exercise timing reset plus temporary PPS loss handling
- State cleared:
  - same timing and discipline-control state as `fusion_gpt_reset_timing_state()`
- State preserved:
  - same preserved continuity, DAC baseline, and model state as normal timing
    reset
- Additional effect:
  - sets `pps_suppress_until_jiffies` using `timing_reset_sim_duration_ms`
- Side effects:
  - timing reset logging
  - explicit PPS-gap simulation logging
  - queues DAC restore work
- Classification: simulation hook, not a distinct production reset contract

#### `timing_pps_gap_sim_trigger`

- Trigger surface: writable module param
- Shared implementation: `fusion_gpt_simulate_pps_gap_only()`
- Intended use: suppress PPS handling without touching timing state
- State cleared: none
- State preserved:
  - live timing state
  - continuity/reacquire state
  - DAC target
  - servo integrator
  - model-fit state
- Additional effect:
  - only updates `pps_suppress_until_jiffies`
- Side effects:
  - logs PPS-gap simulation
  - does not queue DAC work
- Classification: fault-injection helper, not a reset

### 3. Internal Reset Helpers

#### `gpt_reset_timing_state_locked()`

- Scope: low-level timing-state wipe under `pps_lock`
- Clears:
  - PPS sequence/capture history
  - IF2 validity/capture state
  - PHC epoch and alignment state
  - pending future anchor
  - `last_pps_jiffies`
  - PPS suppression window
- Preserves:
  - servo and model state
  - DAC state
- Used by:
  - runtime reset engine
  - cold start in `gpt_start()`

#### `gpt_reset_discipline_control_locked()`

- Scope: low-level servo/control reset under `ctrl_lock`
- Clears:
  - latest frequency error
  - integrator
  - jitter accumulators
  - GM lock
  - lock streak
  - model-jump ready/consumed flags
- Conditionally preserves:
  - continuity/reacquire state and preserved capture when
    `preserve_continuity_for_reacquire` is true and a valid anchor exists
  - DAC target when `preserve_dac` is true
- Side effects:
  - may set `baseline_restore_pending`
  - may tag restore reason as timing reset vs session reset
- Does not clear:
  - model sample window or model validity

#### `gpt_reset_discipline_model_locked()`

- Scope: low-level model-state reset
- Clears:
  - model sample window
  - slope/intercept fit
  - residual/span metrics
  - predicted DAC
  - model-valid and model-jump flags
- Used by:
  - `gpt_start()` cold start only
- Not used by:
  - runtime reset APIs

### 4. Lifecycle Initialization / Shutdown

#### Cold start in `gpt_start()`

- Trigger surface: driver probe path
- Shared implementation:
  - `gpt_reset_timing_state_locked()`
  - `gpt_reset_discipline_model_locked()`
  - `gpt_reset_discipline_control_locked(g, false, false, false, 0)`
- Intended use: full in-memory start-of-day initialization
- State cleared:
  - timing state
  - model state
  - control/servo state
- State preserved:
  - nothing from a prior timing session
- Side effects:
  - initializes baseline DAC to midpoint rather than preserving prior target
- Classification: full cold-start reset

#### Driver teardown in `gpt_remove()`

- Trigger surface: platform driver removal
- Shared implementation: none of the runtime reset helpers
- Intended use: stop interrupts/work and release resources
- Effects:
  - unpublishes singleton
  - masks interrupts
  - clears latched status
  - stops GPT
  - cancels DAC work
  - disables clocks and unregisters DAC client
- Classification: shutdown flow, not a reset command

## Scenario Reasoning

### Normal timing reset while continuity is valid

- `fusion_gpt_reset_timing_state()` clears live timing/epoch/alignment state.
- If the driver had a valid pre-reset PPS anchor, continuity survives as
  `discipline_reacquire_pending`.
- `last_pps_jiffies` is restored so holdover still measures from the last real
  PPS.
- The first PPS after reset is checked against the preserved capture; an invalid
  interval or one above `error_thresh` drops continuity immediately.

### Session reset after GM/PTP loss

- `fusion_gpt_reset_timing_session()` clears timing state and continuity state.
- No pre-reset PPS edge can validate continuity afterward.
- `last_pps_jiffies` is not restored, so holdover timing restarts from PPS edges
  seen in the new session.
- DAC baseline remains preserved.

### Timing reset with simulated PPS gap

- Same state effects as normal timing reset.
- PPS interrupts are then ignored until `pps_suppress_until_jiffies`.
- This is useful for validating reacquire logic under reset-plus-gap conditions.

### PPS-gap-only simulation with no state reset

- No reset helpers run.
- Only `pps_suppress_until_jiffies` changes.
- Existing timing state, continuity, and servo state remain live.

### Cold start from `gpt_start()`

- Full reset of timing, model, and discipline control state.
- DAC target returns to midpoint baseline rather than preserving prior state.

### First PPS after preserved-continuity reset

- `gpt_update_discipline_state_locked()` treats the saved pre-reset capture as
  the continuity validation reference.
- If the reacquire interval is valid and below threshold, continuity is
  preserved and lock streak restarts at 1.
- Otherwise continuity is dropped immediately.

### First PPS after session reset

- No continuity validation against old PPS state occurs.
- Fresh acquisition starts from post-reset PPS edges only.

### Holdover timeout behavior

- Normal timing reset preserves `last_pps_jiffies` when continuity survives, so
  holdover expiration still measures from the pre-reset physical PPS event.
- Session reset clears that timestamp, so the holdover timer does not bridge the
  session boundary.

## Conclusions

- There are two real runtime reset contracts:
  `fusion_gpt_reset_timing_state()` and `fusion_gpt_reset_timing_session()`.
- `timing_reset_trigger` is just an alias for the first contract.
- `timing_reset_sim_trigger` is a simulation variant of the first contract.
- `timing_pps_gap_sim_trigger` is not a reset at all.
- `gpt_start()` is the only full cold-start reset path that clears timing,
  discipline control, and discipline model state together.
- The main unresolved design point is whether session reset should retain
  model-fit history and DAC baseline. The current code says yes for DAC, and
  implicitly yes for model history.
