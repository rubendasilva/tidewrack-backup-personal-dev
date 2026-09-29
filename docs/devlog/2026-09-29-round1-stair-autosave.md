# Dev-log — 2026-09-29: Round 1 feedback + stair autosave

Round 1 follow-up at Cape Marrow Light: PR1 remains open, and the stair now
saves before entering the lamp room.

- **PR1 is still open.** Yuki closed the final dialogue line with Enter, tapped
  a movement key with no response, then moved on the next press. Yuki and Callum
  both reported keyboard input loss on `v0.1.0-playtest1`. We have not reproduced
  that movement failure or confirmed its cause in this repository. The separate
  keyboard-binding and pause-focus fixes do not resolve the report, and there is
  no demonstrated gap between dialogue closing and movement unlocking. The old
  build is unavailable, so investigation continues here with opt-in
  `-- --trace-input` logging of key events, dialogue state and movement locks.
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
The lamp-room transition is wired, but its player, puzzle and relight ending
are still unfinished. PR1 stays open for tracing, and Dmitri still needs to
verify the save feedback in play.
