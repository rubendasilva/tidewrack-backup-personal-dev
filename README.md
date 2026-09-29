# Tidewrack

A narrative adventure set on a fog-bound island off the Washington coast. You
are the new keeper of **Cape Marrow Light**. The keeper before you, Edith Vane,
rowed out into the fog eleven days ago and did not come back.

Built solo by **Fogline Games** (Seattle) in **Godot 4**, shipping to Steam.

> **Status:** Public-demo work in progress. The tagged candidate still has
> unfinished demo systems and open playtest blockers. See
> [`docs/milestones.md`](docs/milestones.md) for failures and release gates.

## Controls

| Action        | Key                     |
|---------------|-------------------------|
| Move          | Arrow keys              |
| Interact      | Enter / Space           |
| Advance / skip line | Enter / Space     |
| Pause / back  | Esc                     |

The game uses only Godot's built-in input actions, so it works with no input
remapping (controller support and remappable keys are a Public Demo milestone).

## Running it

Requires **Godot 4.3+** (standard, non-.NET build).

```bash
# Open in the editor
godot -e --path .

# Or run directly
godot --path .
```

The main scene is `scenes/main_menu.tscn`. Saves are written to Godot's
`user://save.json` (per-OS user data dir).

Saving is manual, through the pause menu. It stores story choices and the
current room; **Continue starts at that room's entrance**, not the saved player
position. The lamp-room stair currently shows placeholder dialogue and does
not change rooms or autosave. A failed save leaves the previous slot intact;
failed loads show a message and keep the save file.

## Project layout

```
tidewrack/
├── project.godot            # engine config; registers the two autoloads
├── scenes/                  # thin .tscn wrappers (root node + script)
│   ├── main_menu.tscn
│   ├── game.tscn            # the vertical-slice level
│   └── ui/{dialogue_box,settings}.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_state.gd     # story flags + save/load  (autoload: GameState)
│   │   └── dialogue_manager.gd  # branching graph player (autoload: DialogueManager)
│   ├── main_menu.gd, settings.gd
│   ├── game.gd               # builds the level + HUD + pause menu
│   ├── player.gd             # top-down movement (Player)
│   ├── interactable.gd       # examinable world object (Interactable)
│   └── dialogue_box.gd       # dialogue UI, listens to DialogueManager
├── data/dialogue/
│   └── keeper_intro.json     # the keeper's-log conversation
├── assets/{sprites,audio,fonts}/   # placeholder art for now
├── tests/validate_dialogue.py      # engine-free dialogue-graph checker
└── docs/                     # GDD, narrative bible, milestones, credits
```

**Design note:** UI and levels are constructed in GDScript rather than authored
as large scene files. This keeps `.tscn` files small and reviewable in diffs and
avoids merge pain — a deliberate choice for a one-person studio.

## The dialogue system

Conversations are plain JSON graphs in `data/dialogue/`. Each node is either a
linear line (`"next": "<id>"`, or `null` to end) or a choice node (`"choices"`).
Any node can set story flags via `"set_flag"`, which `GameState` persists.

```json
{
  "start": { "speaker": "Edith", "text": "…", "next": "choice1" },
  "choice1": {
    "text": "…",
    "choices": [
      { "text": "Trust her", "next": "end", "set_flag": { "trusted_edith": true } }
    ]
  },
  "end": { "speaker": "", "text": "…", "next": null }
}
```

## Verifying changes

```bash
# Validate every dialogue graph (targets resolve, has an ending, no orphans)
python3 tests/validate_dialogue.py

# Import resources and register script classes (requires Godot 4.3+ on PATH)
godot --headless --editor --path . --quit

# Input, focus, manual-save and load-failure regressions
godot --headless --path . tests/test_demo.tscn
```

The regression suite uses real viewport event dispatch for Enter, Space and
synthetic gamepad events. Save tests use a unique test slot and never modify
`user://save.json`. Deliberately invalid saves emit expected error messages;
the final `Demo checks` result must report zero failures. A missing final result,
a script error or a nonzero exit is a failed run. These headless checks do not
replace exported-build testing with a physical controller; see the milestone
checklist for the remaining gates.

## Steam Next Fest demo

The public demo (target: **Steam Next Fest**) extends the vertical slice with
the lamp-room chapter, a discovered-logs journal, and controller support. Demo
scope is locked in [`docs/milestones.md`](docs/milestones.md). The historical
`v0.2-demo-rc` tag does not imply that the demo release gates have passed.

Demo controls add a gamepad (analog stick + A/B) on top of the keyboard bindings.
