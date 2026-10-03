# Glossary

Terms as this documentation and the code use them.

| Term | Meaning |
|---|---|
| **Agent radius** | How far the navigation mesh keeps from obstacles: 0.5 m, more than the character's 0.35 m capsule, so paths keep a margin from corners |
| **Arm** | `CameraArm`: the node holding the camera at the end of a line from the target. The wheel sets its length; obstacles shorten it |
| **Camera-only body** | A body on physics layer 3 (`camera`): it stops the camera arm, but clicks, navigation and characters ignore it |
| **Click** | A press of the left button released within the hold delay. The character runs along a path to the point where the button was pressed |
| **Coyote time** | A short time after walking off an edge when a jump still works (0.1 s) |
| **Exhausted** | The state after stamina runs out: no sprinting until stamina recovers to `recover_ratio` (30%) |
| **Facing** | Where the character looks, as opposed to where it moves. They differ when sidestepping or backing up. `NavigationMover.get_facing()` |
| **Follow** | The camera turning behind the running character by itself, and optionally easing its tilt (`follow_movement`, `follow_pitch`) |
| **Heading** | The direction the character moves. `NavigationMover.get_heading()` |
| **Hero look** | One of the ten models the player's character can wear, chosen by number in the settings (`CharacterAppearance`) |
| **Hold** | The left button held longer than the hold delay. The character runs after the cursor |
| **Hold delay** | The time that tells a click from a hold: 0.2 s (`PointClickMoveInput.hold_delay`) |
| **Jump buffer** | A jump pressed shortly before landing is remembered and fires on landing (0.12 s) |
| **Keeping the aim** | Moving the system cursor with the world while the button is held and the camera turns, so the cursor stays over the same spot of ground (`keep_aim_on_camera_turn`) |
| **Ledge guard** | `LedgeGuard`: stops the character at a drop higher than 0.5 m, or slides it along the edge |
| **Look** | See hero look |
| **Marker** | `ClickMarker`: the ring on the ground at a clicked point |
| **Mover** | `NavigationMover`: turns commands (`move_to`, `steer`, `stop`) into a horizontal velocity each tick. It never moves the body |
| **Navigation mesh** | The walkable area baked from the level's collisions on layer 1, stored in `world.tscn`. Paths are searched on it |
| **Physics interpolation** | Drawing bodies between physics ticks at the display frame rate. Off by default; a setting turns it on |
| **Pitch, tilt** | How steeply the camera looks down. Negative angles in code, degrees down in the settings |
| **Pivot** | Turning instantly from a standstill, below `pivot_speed` (1 m/s) |
| **Place** | A `PointOfInterest`: an area that shows "Discovered: …" the first time the player enters it |
| **Pull-in** | The camera moving in front of an obstacle that hides the character (`pull_in_on_occlusion`) |
| **Sidestep** | A keys mode with the right button: the character keeps facing where the camera looks while moving sideways or backward |
| **Silhouette** | The character drawn as a flat shape with an outline where something hides it (`OccludedSilhouette`) |
| **Sprint** | Running faster (×1.5) while Shift is held or toggled, spending stamina |
| **Stamina** | The sprint reserve (`Stamina`): spent while sprinting, recovers after a pause |
| **Steer** | Running in a direction without a path: `NavigationMover.steer()`. Holding the button steers toward the cursor by default |
| **Tick** | One physics step; 60 per second |
| **Turn mode** | A keys mode with the right button: the character turns to face the way it goes |
| **Yaw** | The camera's direction around the vertical axis |
| **Zoom** | A value from 0 (closest) to 1 (farthest) that sets the camera's distance and tilt together |

---

*This page matches Iso & Orbit 1.0.0.*
