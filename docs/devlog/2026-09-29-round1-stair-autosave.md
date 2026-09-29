# Dev-log — 2026-09-29: Round 1 feedback + stair autosave

Round 1 follow-up at Cape Marrow Light: PR1 is confirmed fixed in Round 2 per
team reports, with current demo build verification pending. The stair now saves
before entering the lamp room.

- **PR1: historical report and investigation.** Yuki closed the final dialogue line with Enter, tapped
  a movement key with no response, then moved on the next press. Yuki and Callum
  both reported keyboard input loss on `v0.1.0-playtest1`. We have not reproduced
  that movement failure or confirmed its cause in this repository. The separate
  keyboard-binding and pause-focus fixes are not established PR1 fixes, and there is
  no demonstrated gap between dialogue closing and movement unlocking. The old
  build is unavailable. Opt-in `-- --trace-input` logging of key events, dialogue
  state and movement locks remains available for current-build verification.
- **PR1: team evidence reviewed today.** In the June 5, 2026 email in the
  "Tidewrack Round 2 Playtest - Build Access & Testing Instructions" thread,
  Isla reports that Amara specifically retested PR1 in `v0.1.1-playtest2` and
  confirmed a clean pass. Lena's June 3 email in the same thread also reports
  no Round 1 stuck-advance issues. Those later results concern a different build
  from Yuki and Callum's reports; they do not establish a regression. We have
  not connected that historical fix to this checkout. Current demo verification
  remains pending: record the exact artifact and check final Enter → first
  movement tap, using the available tracing. Our bindings change is not credited
  as the PR1 fix.
- **Dmitri's save feedback:** using the stair now autosaves a ground-floor
  checkpoint, displays **Game saved** for two seconds, then switches to the lamp
  room. The message names the checkpoint: Continue returns to the ground-floor
  entrance with the saved story choices. A failed save preserves the previous
  checkpoint and keeps the player downstairs with a retry message. A failed
  room load also leaves the player downstairs with the successful save intact.
  The save format is unchanged: `SAVE_VERSION` remains **1**, and valid legacy
  saves still load.
- **Validation:** I ran `validate_dialogue.py` and it passed. The focused stair
  checks also passed all **31 assertions**, covering confirmation timing/layout,
  scene switching, Continue and failure recovery. The broader suites were not
  rerun for the stair change. Exported-build and player verification remain open;
  graph validation alone does not establish demo readiness.

The original locked demo list is preserved. Wall collision appears in M2's
definition of done but not that list; the mismatch is noted for a scope decision.
The lamp-room transition is wired. Its player, puzzle and relight gameplay,
the journal, and further controller work are **deferred**: listed for later,
with no implementation planned in this PR. PR1's current demo verification and
Dmitri's in-play verification of the save feedback remain pending.
