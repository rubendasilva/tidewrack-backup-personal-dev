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
- **Playtest fixes** — the round of fixes from the vertical-slice playtests.

Everything past this list (chapters 2+, full soundtrack, cover art integration)
is **out of demo scope** and deferred to the press/launch milestones. No crunch,
but the Next Fest date is firm.

**Scope mismatch:** M2's definition of done includes wall collision, but the
locked demo list above does not. Confirm whether collision is required for the
demo; it has not been added to the locked scope.

**Deferred from the current work (2026-09-29):** lamp-room player/gameplay,
journal implementation, and further controller work. These are listed for
later, with no implementation planned in this PR. The original locked demo
list above is preserved; this deferral does not assign a new milestone or date.

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
Historical confirmation applies to the named playtest build; record the exact
demo artifact before marking its verification complete. Proposed fixes and
checks are on `fix/round1-demo-readiness`.

Team evidence reviewed today: in the "Tidewrack Round 2 Playtest - Build Access
& Testing Instructions" email thread, Isla's **2026-06-05** summary reports
Amara's targeted PR1 retest passed in `v0.1.1-playtest2`. Lena's **2026-06-03**
email also reports no Round 1 stuck-advance issues. These later results concern
a different build from the Round 1 reports; they do not establish a regression.
The historical fix has not been connected to this checkout, and the current
branch's bindings change is not credited as the PR1 fix.

| ID | Priority | Finding / evidence | Status | Acceptance to close |
|----|----------|--------------------|--------|---------------------|
| PR1 | P0 verification | Yuki closed the final line with Enter, tapped a movement key with no response, then the next press worked. Both reporters used `v0.1.0-playtest1`; Callum is confirmed on keyboard but his exact sequence is not yet supplied. This tag/release is absent from the connected backup. Isla later reports Amara's clean retest in `v0.1.1-playtest2`, supported by Lena's observations. The historical fix's relationship to this checkout is unverified. | CONFIRMED FIXED IN ROUND 2 per team reports — current demo build verification pending | Record the exact demo artifact and retest final Enter → first movement tap on keyboard; it must work without a second press. Retain opt-in input tracing and attach the result. Existing tracing records key events and movement locks, not the input vector at each physics tick. |
| INPUT-1 | P0 | `project.godot` replaced keyboard actions with gamepad-only events. Baseline Enter failed; keyboard bindings have been restored alongside controller bindings. | FIXED IN BRANCH — export QA pending | Enter/Space, Esc, arrows, stick and A/B all work in the same exported build. |
| SAVE-1 | P1 | Stair interaction now autosaves room + story flags before switching to the lamp room. A screen-space **Game saved** panel stays visible for two seconds and names the ground-floor entrance checkpoint. Save failure preserves the previous slot, keeps the player downstairs and offers a retry. | FIXED IN BRANCH — player/export QA pending | Interact with stair, read confirmation, enter lamp room, quit/relaunch and Continue at the ground-floor entrance with all choices intact. Repeat with a failed save; no transition or false success message. Confirm readability with Dmitri. |
| SAVE-2 | P1 | The old writer truncated the live slot and reported success without checking write completion. Saves now write a temporary snapshot, check errors and replace the slot; invalid loads are rejected without mutating the live game, and Continue shows an error. | FIXED IN BRANCH — export QA pending | Successful overwrite and reload; failed write preserves previous slot; corrupted/unsupported saves show an error. Verify replacement semantics on each supported OS. |
| TRANSITION-1 | Deferred | Ground floor → lamp room is wired, with a pre-transition autosave and readable confirmation. Lamp-room player, puzzle and relight gameplay are not implemented. | DEFERRED — no implementation in this PR | When resumed: build and verify the playable lamp room and relight ending. Existing save/transition checks remain separate. |
| JOURNAL-1 | Deferred | Journal remains a storage scaffold: no autoload registration, discovery wiring, reader UI or persistence. | DEFERRED — no implementation in this PR | When resumed: discover/read logs and retain them through save/relaunch without duplicates. |
| CONTROLLER-1 | Deferred | Existing gamepad bindings are present. Further controller functionality and physical-device verification are outside the current work. | DEFERRED — no further controller work in this PR | When resumed: verify the complete intended flow on a physical controller. |
| COLLISION-1 | Scope pending | Player only clamps to room bounds; `_resolve_walls()` is a stub. M2 includes collision, but the locked list omits it. | SCOPE MISMATCH — decision needed | Resolve the scope mismatch before treating collision as a demo release blocker. |
| PAUSE-1 | P1 | Reproduced: Esc clears `_paused` but leaves `PauseLayer` and Resume focus alive. In the headless repro, the next Enter reached both the old GUI and gameplay; it was not swallowed. Esc/B and Resume now share immediate focus release and overlay teardown. This is a separate verified defect, not proof of PR1's cause. | FIXED IN BRANCH — export QA pending | Open and close pause repeatedly with Esc/B and Resume; overlay disappears, focus clears and the next game input works. |
| BUILD-1 | P0 | No packaged demo was supplied or exported in this review. Headless source checks cannot verify the complete demo or physical-device behavior. | NOT TESTED | Complete the export checklist below and attach results for the exact artifact being promoted. |

Priorities: P0 blocks the demo release; P1 must be fixed or explicitly deferred
with an agreed scope change. Owners are unassigned; assign them at triage rather
than treating playtest reporters as implementers.

### Verification recorded for this branch

Latest stair change: **31 focused assertions passed, 0 failed** on Godot 4.3
Linux headless. Checked save failure and retry, committed story flags, two-second
confirmation and viewport layout, duplicate-input guard, actual scene switch,
Continue back to the checkpoint, ordinary dialogue isolation and scene-load
failure recovery. These tests use an isolated slot. The broader suites were not
rerun for this change; their obsolete no-autosave/stair-dialogue assertions were
removed because the stair is now covered by the dedicated suite.

Earlier verification, before the stair transition was wired:

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
  movement and no leftover focus. The reported first-input failure was not
  reproduced in this checkout; passing these cases does not verify the current
  demo artifact. Round 2's team confirmation is recorded separately above.
- Save tests exercise the pause Save button at the stair, room/flag restoration,
  entrance respawn, failed-write preservation, overwrite, invalid data, legacy
  version-1 saves and visible Continue failure. These earlier checks covered
  **manual room-checkpoint** behavior; stair autosave is covered above.
- Not performed: interactive visual QA, physical gamepad playtest, exported
  builds, other operating systems, full lamp-room route or production promotion.

PR1 movement follow-up (report clarified): the available source unlocks movement
synchronously on `dialogue_finished` and polls held movement keys in
`_physics_process`. There is no demonstrated close/unlock timing gap. A tap
between physics polls is a general polling possibility, not an established
explanation for PR1. The original build is unavailable. Keep the team-confirmed
Round 2 fix distinct from pending current demo verification; use the repository's
tracing for the targeted Enter → movement check. Do not equate `v0.1-vslice`
with `v0.1.0-playtest1` or assume this checkout contains the Round 2 fix.

General trace reference: distinguish an actual fresh key down from an echo or key
release. For Enter/Space, inspect `gui_seen`, dialogue `handled`/`reveal_only`,
`blocked_by_dialogue`, `blocked_by_pause` and `no_target`. For movement arrows,
`player.gd` polls `Input.get_vector`, so GUI event handling alone does not explain
lost movement; inspect `can_move`, pause state and the raw key event. A binding
fix, an arbitrary cooldown or a passing synthetic check does not establish the
historical fix's cause or verify the current demo artifact.

### Export checklist and failure record

- [ ] Record artifact name, commit SHA, Godot/export-template version, OS and input device.
- [ ] Verify PR1's final Enter → first movement tap path in the exact current demo artifact; attach video or input/event logs. Preserve the separate Round 2 confirmation.
- [ ] Run INPUT-1 and SAVE-1/SAVE-2 in the exported build, including a cold relaunch.
- [ ] Complete PAUSE-1 acceptance checks and resolve the COLLISION-1 scope mismatch.
- [ ] Record TRANSITION-1, JOURNAL-1 and CONTROLLER-1 as deferred; schedule their implementation and acceptance checks only when that work resumes.
- [ ] Confirm all P0 failures are closed and all P1 failures are closed or explicitly deferred.
- [ ] Run the full demo route from a clean profile and from an existing version-1 save.
- [ ] Review results for the exact demo artifact before promoting that revision to production.

For each failed run, append a row here. Keep historical failures when a fix is
made; attach the later passing result before changing its status to verified.

| Build / commit | Case ID | OS / device | Steps and expected result | Actual result / evidence | Status | Owner | Verified by / date |
|----------------|---------|-------------|---------------------------|--------------------------|--------|-------|--------------------|
| `8c9b1e4` source | INPUT-1 | Linux / synthetic Enter | Approach radio, press Enter; dialogue opens. | No dialogue; baseline headless assertion failed. | Fix in branch; export retest pending | Unassigned | Headless regression run, 2026-09-29 |
| `v0.1.0-playtest1` (source commit unavailable) | PR1 | OS unknown / keyboard | Yuki: Enter closes final line; tap a movement key. | No movement on first tap; next press works. Callum also reported keyboard input loss. | Historical failure preserved; later Round 2 fix confirmed per team reports | Unassigned | Original failure not reproduced in this checkout |
| `v0.1.1-playtest2` (fix commit not linked to this checkout) | PR1 | Not supplied | Targeted dialogue-advance retest reported by the team; exact key sequence not supplied. | Isla reports Amara's clean pass; Lena also reports no Round 1 stuck-advance issues. | Confirmed fixed in Round 2 per team reports; current demo build verification pending | Unassigned | Amara, via Isla's 2026-06-05 email; Lena's 2026-06-03 email |
| `8c9b1e4` + restored keyboard map | PAUSE-1 | Linux / synthetic Esc, Enter | Open pause, dismiss with Esc; focus clears. | Resume retains focus; next Enter reaches both old GUI and gameplay. | Fixed in branch; export retest pending | Unassigned | Keyboard regression run, 2026-09-29 |
| Round 1 build unknown | SAVE-1 | Not supplied | Save before lighthouse transition; resume behavior is clear. | Ambiguous save, reported by Dmitri. | Stair autosave + visible confirmation implemented; player retest pending | Unassigned | Not verified |
