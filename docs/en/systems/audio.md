# Audio

`GroundCharacter` reports what happens to it with signals: `stepped(sprinting)`, `jumped`, `landed(impact_speed)`,
`sprint_changed(sprinting)` (see [Locomotion](locomotion.md#signals)). Sounds, dust under the feet or animations
connect to them; the character itself knows nothing about them. The demo connects sounds.

## CharacterSounds

`CharacterSounds` (`Player/Sounds`) is a `Node3D` child of the character. Its children are `AudioStreamPlayer3D`
nodes, so the sound comes from the character and works the same for an NPC. Without this node the character works
exactly the same, only silently.

| Sound | Player | What plays |
|---|---|---|
| Footsteps | `Footsteps` | An `AudioStreamRandomizer` of four variants with random pitch (±8%) and volume, up to three at once. Sprinting, a little higher (`sprint_step_pitch` 1.08) and louder (+2 dB); faster by themselves, since steps follow the distance |
| Jump | `Jump` | A foot push and the whoosh of clothes |
| Landing | `Land` | A heavy thud, louder the faster the fall: full volume from `land_full_speed` (10 m/s), never quieter than `min_land_volume` (30%) |
| Sprint start | `SprintStart` | A push and a rising rush of air at the start of a sprint |
| Sprinting | `SprintLoop` | A 2 s loop of quick breathing and air, faded in and out over `sprint_loop_fade` (0.25 s) |

| Property | Default | Meaning |
|---|---|---|
| `character` | parent | Whose signals to play |
| `footsteps`, `jump`, `land`, `sprint_start`, `sprint_loop` | — | The players |
| `footsteps_enabled`, `jump_enabled`, `sprint_enabled` | on | Groups of sounds; jump covers jump and landing, sprint covers the start and the loop |
| `sprint_step_pitch`, `sprint_step_volume_db` | 1.08, +2 dB | Footsteps while sprinting |
| `land_full_speed`, `min_land_volume` | 10 m/s, 0.3 | Landing volume curve |
| `sprint_loop_fade` | 0.25 s | Fade of the sprint loop |

The volumes are set on the players in `gdscript/player/player.tscn`; tune them in the running game through the
Remote tree. The exception is `Land`: its volume is set before every landing from the fall speed
(`land_full_speed`, `min_land_volume`). The groups are switched in Settings → Sound; the demo turns the sprint
sounds off by default. The overall volume there is the `Master` bus: percent is a share of the amplitude (50% is
6 dB quieter), 0 mutes the bus.

## The sounds themselves

The files in `shared/audio/character/` were synthesized by a script: thuds are sines with a falling pitch, crunches
and air are noise through band-pass filters. The sprint loop carries a `smpl` chunk in the WAV, and the default import
loop mode, "Detect From WAV", makes it loop without touching the import settings. The loop seam is crossfaded end into
start, so it does not click.

Real recorded sounds can replace these: put files with the same names in the folder.

---

*This page matches Iso & Orbit 1.1.0.*
