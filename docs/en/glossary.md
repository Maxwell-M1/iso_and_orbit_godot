# Glossary

[← Documentation index](index.md)

Terms as this documentation and the code use them.

| Term | Meaning |
|---|---|
| **Agent radius** | How far the navigation mesh keeps from obstacles: 0.5 m, more than the character's 0.35 m capsule, so paths keep a margin from corners |
| **Arm** | `CameraArm`: the node holding the camera at the end of a line from the target. The wheel sets its length; obstacles shorten it |
| **Blend** | `GroundCharacter.get_locomotion_blend()`: the speed as a number for animations, 0 standing, 1 running, 2 sprinting |
| **Bounds** | Physics layer 4: invisible walls at the edge of a level. Characters collide with them, clicks and the camera arm pass through them |
| **Camera-only body** | A body on physics layer 3 (`camera`): it stops the camera arm, but clicks, navigation and characters ignore it |
| **Character state** | What the character is doing: standing, running, sprinting, jumping or falling (`GroundCharacter.get_state()`, the signal `state_changed`) |
| **Click** | A press of the left button released within the hold delay. The character runs along a path to the point where the button was pressed |
| **Coyote time** | A short time after walking off an edge when a jump still works (0.1 s) |
| **Exhausted** | The state after stamina runs out: no sprinting until stamina recovers to `recover_ratio` (30%) |
| **Facing** | Where the character looks, as opposed to where it moves. They differ when sidestepping or backing up. `NavigationMover.get_facing()` |
| **Fall settings** | How the character comes down after the top of a jump or off an edge: the gravity of the fall, the fastest fall and how a faster fall slows down to it (`FallSettings`). The rise of a jump does not depend on them |
| **Floating** | The hero's model hanging above the ground and gliding over stairs while the body walks as usual (`CharacterHover`). A floating character has no steps, and in the demo it comes down more slowly |
| **Follow** | The camera turning behind the running character by itself, and bringing its tilt and its height to set values; each move starts and ends smoothly (`follow_movement`, `follow_pitch`, `follow_zoom`). After an orbit it can wait for a stop or a new run (`follow_wait_after_rotate`, on in the demo) |
| **Gait cycle** | Two steps, the left and the right, as a number from 0 to 1 (`GroundCharacter.get_gait_cycle()`). It follows the distance covered, not time |
| **Heading** | The direction the character moves. `NavigationMover.get_heading()` |
| **Hero look** | One of the ten models the player's character can wear, chosen by number in the settings (`CharacterAppearance`) |
| **Hold** | The left button held longer than the hold delay. The character runs after the cursor |
| **Hold delay** | The time that tells a click from a hold: 0.2 s (`PointClickMoveInput.hold_delay`) |
| **Jump buffer** | A jump pressed shortly before landing is remembered and fires on landing (0.12 s) |
| **Keeping the aim** | Moving the system cursor with the world while the button is held and the camera turns, so the cursor stays over the same spot of ground (`keep_aim_on_camera_turn`) |
| **Ledge guard** | `LedgeGuard`: stops the character at a drop higher than 0.5 m, or slides it along the edge |
| **Level host** | `LevelHost`: the node that holds the current level and changes it behind the loading screen; the hero and the interface are its siblings, not parts of a level |
| **Loading screen** | `LoadingScreen`: the screen over the game while a level changes: the last frame blurred, the name of the place, a progress bar and tips |
| **Look** | See hero look |
| **Looking around** | The right button pressed while a hold runs after the cursor: the mouse turns only the camera, and the run keeps its course (`look_around_while_held`). Pressed first, the right button steers the run where the camera looks |
| **Marker** | `ClickMarker`: the ring on the ground at a clicked point |
| **Mover** | `NavigationMover`: turns commands (`move_to`, `steer`, `stop`) into a horizontal velocity each tick. It never moves the body |
| **Navigation mesh** | The walkable area baked from the level's collisions on layer 1 (on the island also the invisible walls on layer 4), stored in each level's scene. Paths are searched on it |
| **Offer to travel** | `TravelPrompt`: the key and "Teleport to …" on screen while the hero stands on a portal that asks first, such as a teleport pad. E (the `interact` action) or a click on it travels; walking away hides it |
| **Physics interpolation** | Drawing bodies between physics ticks at the display frame rate. On by default; a setting turns it off |
| **Pitch, tilt** | How steeply the camera looks down. Negative angles in code, degrees down in the settings |
| **Pivot** | Turning instantly from a standstill, below `pivot_speed` (1 m/s) |
| **Place** | A `PointOfInterest`: an area that shows "Discovered: …" the first time the player enters it |
| **Playable hero** | `PlayableHero` (`playable_hero.tscn`): the hero the player controls, with its input, camera, click marker and path line, put into the game scene next to the levels |
| **Portal** | `LevelPortal`: an area that leads to another level; the demo's teleport pads are portals |
| **Pull-in** | The camera moving in front of an obstacle that hides the character (`pull_in_on_occlusion`) |
| **Sharp turn** | A turn of the run faster than `OrbitCameraRig.sharp_turn_speed` (360°/s), such as a turnaround: the camera does not follow the passing directions and takes up the new one after the turn |
| **Shell** | The scene that stays while the game runs (`main.tscn` with `main.gd`): the level host, the hero, the interface and the loading screen |
| **Sidestep** | A keys mode with the right button: the character keeps facing where the camera looks while moving sideways or backward |
| **Silhouette** | The character drawn as a flat shape with an outline where something hides it (`OccludedSilhouette`) |
| **Spawn point** | `SpawnPoint`: where a character appears on a level, by name; every level has a `default` one |
| **Sprint** | Running faster (×1.5) while Shift is held or toggled, spending stamina |
| **Stair height** | The highest stair the character steps onto without a jump: 0.3 m (`GroundCharacter.max_step_height`) |
| **Stamina** | The sprint reserve (`Stamina`): spent while sprinting, recovers after a pause |
| **Start level** | The level the game starts on, placed under the level host in the editor: `shared/world/world.tscn`, the fenced glade, also called the meadow. In the game it is named Green Vale (the title of the island's pad) |
| **Steer** | Running in a direction without a path: `NavigationMover.steer()`. Holding the button steers toward the cursor by default |
| **Teleport** | Putting a character elsewhere at once, without a run and without a jerk: `GroundCharacter.teleport()`, `PlayableHero.teleport()` |
| **Tick** | One physics step; 60 per second |
| **Traveller** | A body that can use a portal: one in the portal's group `traveller_group` (`player` by default) |
| **Turn mode** | A keys mode with the right button: the character turns to face the way it goes |
| **Warm-up** | The frames the level host draws of a new level behind the loading screen before it goes, so that shaders compile then and the character settles (`LevelHost.warmup_frames`, 3) |
| **Yaw** | The camera's direction around the vertical axis |
| **Zoom** | A value from 0 (closest) to 1 (farthest) that sets the camera's distance and tilt together |

---

*This page matches Iso & Orbit 1.2.0.*
