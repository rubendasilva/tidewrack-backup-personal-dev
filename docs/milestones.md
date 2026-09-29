# Tidewrack — Milestones

A nine-month schedule from kickoff to Steam launch. Dates are targets; the
GitHub Milestones mirror these and the issue tracker is grouped under them.

| # | Milestone       | Target date  | Definition of done |
|---|-----------------|--------------|--------------------|
| 0 | Kickoff         | 2026-03-02   | Repo, engine, dialogue system spike, GDD v0. |
| 1 | **Vertical slice** | 2026-05-15 | One explorable scene, working branching dialogue, save/load, menus. *(playtest regressions tracked below)* |
| 2 | **Public demo**    | 2026-08-15 | Second scene (the lamp room), journal, wall collision, controller support. Ships for Steam Next Fest. |
| 3 | **Press build**    | 2026-10-15 | Full act one, localization-ready strings, accessibility pass, review keys out. |
| 4 | **Full launch**    | 2026-11-20 | Complete game, Steam achievements, store page live, launch trailer. |

## Where things stand (2026-07)

Vertical slice is complete and in players' hands. Work now targets the **Public
Demo** for Next Fest: the lamp-room scene, a journal to track discovered logs,
and the collision/controller gaps left open in the slice.

## Notes on scope

- **One location per milestone.** Each milestone adds exactly one new explorable
  space to keep the solo workload honest.
- **Narrative is the long pole.** Writing and iterating dialogue is the critical
  path; systems work is scheduled around leaving writing time.
- **Marketing beats are milestones too.** Store page, trailer, and Next Fest
  are tracked as first-class deliverables, not afterthoughts.

## Demo scope locked (Steam Next Fest)

For the public demo we ship the vertical slice **plus**:

- **Lamp-room chapter** — the stair from the ground floor opens into the lamp
  room; relighting the lamp is the demo's closing beat.
- **Journal** — discovered logs collect into a readable in-game journal.
- **Controller support** — gamepad input map layered on the built-in actions.
- **Wall collision** — ground-floor collision required by the M2 definition of done.
- **Playtest fixes** — the round of fixes from the vertical-slice playtests.

Everything past this list (chapters 2+, full soundtrack, cover art integration)
is **out of demo scope** and deferred to the press/launch milestones. No crunch,
but the Next Fest date is firm.

## Round 1 triage and demo release gate (2026-09-29)

**Release status: BLOCKED.** A candidate tag or passing dialogue-JSON validation
does not establish that the demo can ship. Keep the failures below open until
the relevant exported build passes its acceptance checks.

Schedule discrepancy: M2 targets **2026-08-15**, which precedes this review.
Confirm the intended Next Fest submission date/year before rescheduling the
milestones; the original targets above have not been changed.

Source inspected: `rubendasilva/tidewrack-backup-personal-dev`, baseline
`8c9b1e4` (`v0.2-demo-rc`). At the start of review, this connected backup had no
existing pull request #1.
**PR1 below is the playtest report label, not a verified GitHub PR number.**
If the playtest used another branch or build, record that exact revision before
closing the report. Proposed fixes and checks are on `fix/round1-demo-readiness`.

| ID | Priority | Finding / evidence | Status | Acceptance to close |
|----|----------|--------------------|--------|---------------------|
| PR1 | P0 | Yuki closed the final line with Enter, tapped a movement key with no response, then the next press worked. Both reporters used `v0.1.0-playtest1`; Callum is confirmed on keyboard but his exact sequence is not yet supplied. This tag/release is absent from the connected backup. Binding and focus fixes do not establish the cause. | OPEN — locate playtest source | Resolve `v0.1.0-playtest1` to a commit/build. Trace final Enter → movement key down/up → first physics tick, including `can_move`, pause state and input vector. The first movement tap must work without a second press. |
| INPUT-1 | P0 | `project.godot` replaced keyboard actions with gamepad-only events. Baseline Enter failed; keyboard bindings have been restored alongside controller bindings. | FIXED IN BRANCH — export QA pending | Enter/Space, Esc, arrows, stick and A/B all work in the same exported build. |
| SAVE-1 | P1 | Dmitri reports ambiguity before the lighthouse transition. Existing saves contain room + story flags, not player position; Continue respawns at the ground-floor entrance. Pause text now explains this manual-save contract and names the saved room. | FIXED IN BRANCH — player QA pending | Save at the stair, quit/relaunch, Continue and verify all branch flags, including false values. The room/entrance behavior must match the displayed text. Confirm the explanation is clear to Dmitri. |
| SAVE-2 | P1 | The old writer truncated the live slot and reported success without checking write completion. Saves now write a temporary snapshot, check errors and replace the slot; invalid loads are rejected without mutating the live game, and Continue shows an error. | FIXED IN BRANCH — export QA pending | Successful overwrite and reload; failed write preserves previous slot; corrupted/unsupported saves show an error. Verify replacement semantics on each supported OS. |
| TRANSITION-1 | P0 | `keeper_intro.json:door` still ends with placeholder text. `game.gd` has no lamp-room scene-change path; `lamp_room.gd` has no player, puzzle or wired relight dialogue. There is no transition autosave to inspect yet. | FAIL — implementation missing | Walk ground floor → lamp room → relight ending. Define the checkpoint/autosave timing before wiring the transition; test save/reload immediately before and after it and after a save failure. |
| JOURNAL-1 | P1 | Journal remains a storage scaffold: no autoload registration, discovery wiring, reader UI or persistence. | FAIL — implementation missing | Discover a log, read it in the journal, save/relaunch and retain it without duplicates. |
| COLLISION-1 | P1 | Player only clamps to room bounds; `_resolve_walls()` is a stub and movement does not call it. | FAIL — implementation missing | Ground-floor walls block movement with keyboard and stick, including diagonal approaches. |
| PAUSE-1 | P1 | Reproduced: Esc clears `_paused` but leaves `PauseLayer` and Resume focus alive. In the headless repro, the next Enter reached both the old GUI and gameplay; it was not swallowed. Esc/B and Resume now share immediate focus release and overlay teardown. This is a separate verified defect, not proof of PR1's cause. | FIXED IN BRANCH — export QA pending | Open and close pause repeatedly with Esc/B and Resume; overlay disappears, focus clears and the next game input works. |
| BUILD-1 | P0 | No packaged demo was supplied or exported in this review. Headless source checks cannot verify the complete demo or physical-device behavior. | NOT TESTED | Complete the export checklist below and attach results for the exact artifact being promoted. |

Priorities: P0 blocks the demo release; P1 must be fixed or explicitly deferred
with an agreed scope change. Owners are unassigned; assign them at triage rather
than treating playtest reporters as implementers.

### Verification recorded for this branch

- Godot **4.3 stable**, Linux x86_64, headless: resource import and script loading
  succeeded; **82 regression assertions passed, 0 failed**.
- Additional keyboard suite: **50 assertions passed, 0 failed**. Covers all four
  logbook branch combinations, both radio branches and the stair with Enter and
  Space, key down/up on separate frames, held-key echo and pause focus teardown.
  Baseline with only keyboard bindings restored: **49 passed, 1 failed**; the
  failure was leftover pause focus, not a lost post-dialogue press.
- `python3 tests/validate_dialogue.py`: both production dialogue graphs valid,
  zero warnings. This validates graph structure, not scene wiring.
- Input tests dispatch Enter, Space and synthetic gamepad A through the
  viewport: linear/choice dialogue, terminal choices, close/reopen, restored
  movement and no leftover focus. The baseline first-input report remains
  unconfirmed; passing these cases does not close PR1.
- Save tests exercise the pause Save button at the stair, room/flag restoration,
  entrance respawn, failed-write preservation, overwrite, invalid data, legacy
  version-1 saves and visible Continue failure. They confirm the current
  **manual room-checkpoint** behavior, not a working lighthouse transition.
- Not performed: interactive visual QA, physical gamepad playtest, exported
  builds, other operating systems, full lamp-room route or production promotion.

PR1 movement follow-up (report clarified): the available source unlocks movement
synchronously on `dialogue_finished` and polls held movement keys in
`_physics_process`. Investigate the playtest build's unlock timing and whether the
first down/up pair falls entirely between physics polls; these are hypotheses,
not confirmed causes. Do not equate `v0.1-vslice` with `v0.1.0-playtest1`.
No suites were rerun for this clarification.

General trace reference: distinguish an actual fresh key down from an echo or key
release. For Enter/Space, inspect `gui_seen`, dialogue `handled`/`reveal_only`,
`blocked_by_dialogue`, `blocked_by_pause` and `no_target`. For movement arrows,
`player.gd` polls `Input.get_vector`, so GUI event handling alone does not explain
lost movement; inspect `can_move`, pause state and the raw key event. A binding
fix, an arbitrary cooldown or a passing synthetic check is not grounds to close PR1.

### Export checklist and failure record

- [ ] Record artifact name, commit SHA, Godot/export-template version, OS and input device.
- [ ] Retest PR1 on the original reproduction paths; attach video or input/event logs.
- [ ] Run INPUT-1 and SAVE-1/SAVE-2 in the exported build, including a cold relaunch.
- [ ] Complete TRANSITION-1, JOURNAL-1, COLLISION-1 and PAUSE-1 acceptance checks.
- [ ] Confirm all P0 failures are closed and all P1 failures are closed or explicitly deferred.
- [ ] Run the full demo route from a clean profile and from an existing version-1 save.
- [ ] Review results for the exact demo artifact before promoting that revision to production.

For each failed run, append a row here. Keep historical failures when a fix is
made; attach the later passing result before changing its status to verified.

| Build / commit | Case ID | OS / device | Steps and expected result | Actual result / evidence | Status | Owner | Verified by / date |
|----------------|---------|-------------|---------------------------|--------------------------|--------|-------|--------------------|
| `8c9b1e4` source | INPUT-1 | Linux / synthetic Enter | Approach radio, press Enter; dialogue opens. | No dialogue; baseline headless assertion failed. | Fix in branch; export retest pending | Unassigned | Headless regression run, 2026-09-29 |
| `v0.1.0-playtest1` (source commit unavailable) | PR1 | OS unknown / keyboard | Yuki: Enter closes final line; tap a movement key. | No movement on first tap; next press works. Callum also reported keyboard input loss. | Open; exact source tag/release absent from connected backup | Unassigned | Not verified |
| `8c9b1e4` + restored keyboard map | PAUSE-1 | Linux / synthetic Esc, Enter | Open pause, dismiss with Esc; focus clears. | Resume retains focus; next Enter reaches both old GUI and gameplay. | Fixed in branch; export retest pending | Unassigned | Keyboard regression run, 2026-09-29 |
| Round 1 build unknown | SAVE-1 | Not supplied | Save before lighthouse transition; resume behavior is clear. | Ambiguous save, reported by Dmitri. | Copy clarified; player retest pending | Unassigned | Not verified |
