class_name CharacterSounds
extends Node3D
## Character sounds: footsteps, jump and landing, the sprint burst and the sprint. Plays them on [GroundCharacter]
## signals: it computes nothing itself, and the character works the same without this node.
##
## The node is added as a child of the character, and its children are [AudioStreamPlayer3D] nodes (the sound comes
## from the character, so NPCs are heard where they are, too). Sound groups are turned on and off separately
## ([member footsteps_enabled], [member jump_enabled], [member sprint_enabled]).

## Whose sounds these are. If not set, the parent.
@export var character: GroundCharacter

@export_group("Players")
## Footsteps: a stream with several variants ([AudioStreamRandomizer]) so that the steps do not all sound the same.
@export var footsteps: AudioStreamPlayer3D
## The push-off of a jump.
@export var jump: AudioStreamPlayer3D
## Landing. The volume depends on the fall speed.
@export var land: AudioStreamPlayer3D
## Burst: the start of a sprint.
@export var sprint_start: AudioStreamPlayer3D
## A loop that plays while the character sprints (breathing, rushing air).
@export var sprint_loop: AudioStreamPlayer3D

@export_group("Switches")
@export var footsteps_enabled := true:
	set(value):
		footsteps_enabled = value
		if not value and footsteps != null:
			footsteps.stop()
## Jump and landing.
@export var jump_enabled := true:
	set(value):
		jump_enabled = value
		if not value:
			for player: AudioStreamPlayer3D in [jump, land]:
				if player != null:
					player.stop()
## The burst and the sprint loop.
@export var sprint_enabled := true:
	set(value):
		sprint_enabled = value
		if not value:
			if sprint_start != null:
				sprint_start.stop()
			_fade_sprint_loop(false)
		elif character != null and character.is_sprinting():
			_fade_sprint_loop(true)

@export_group("Tuning")
## Steps while sprinting sound slightly higher and louder (they are more frequent anyway: steps follow the distance
## traveled).
@export_range(0.5, 2.0, 0.01) var sprint_step_pitch := 1.08
@export_range(-12.0, 12.0, 0.5, "suffix:dB") var sprint_step_volume_db := 2.0
## At this fall speed the landing sounds at full volume; slower falls sound quieter, but no quieter than
## [member min_land_volume].
@export_range(1.0, 30.0, 0.5, "suffix:m/s") var land_full_speed := 10.0
@export_range(0.0, 1.0, 0.01) var min_land_volume := 0.3
## How long the sprint loop takes to fade in and to fade out.
@export_range(0.0, 2.0, 0.01, "suffix:s") var sprint_loop_fade := 0.25

var _footsteps_volume_db := 0.0
var _sprint_loop_volume_db := 0.0
var _sprint_tween: Tween


func _ready() -> void:
	if character == null:
		character = get_parent() as GroundCharacter
	assert(character != null,
			"CharacterSounds needs a GroundCharacter: set the character property or make it the parent.")
	if footsteps != null:
		_footsteps_volume_db = footsteps.volume_db
	if sprint_loop != null:
		_sprint_loop_volume_db = sprint_loop.volume_db
	character.stepped.connect(_on_stepped)
	character.jumped.connect(_on_jumped)
	character.landed.connect(_on_landed)
	character.sprint_changed.connect(_on_sprint_changed)


func _on_stepped(sprinting: bool) -> void:
	if not footsteps_enabled or footsteps == null:
		return
	footsteps.pitch_scale = sprint_step_pitch if sprinting else 1.0
	footsteps.volume_db = _footsteps_volume_db + (sprint_step_volume_db if sprinting else 0.0)
	footsteps.play()


func _on_jumped() -> void:
	if jump_enabled and jump != null:
		jump.play()


func _on_landed(impact_speed: float) -> void:
	if not jump_enabled or land == null:
		return
	var loudness := clampf(impact_speed / land_full_speed, min_land_volume, 1.0)
	land.volume_db = linear_to_db(loudness)
	land.play()


func _on_sprint_changed(sprinting: bool) -> void:
	if not sprint_enabled:
		return
	if sprinting and sprint_start != null:
		sprint_start.play()
	_fade_sprint_loop(sprinting)


## The sprint loop fades in and out smoothly: an abrupt start or cutoff of the noise is heard as a click.
func _fade_sprint_loop(on: bool) -> void:
	if sprint_loop == null:
		return
	if _sprint_tween != null:
		_sprint_tween.kill()
	if on:
		if not sprint_loop.playing:
			sprint_loop.volume_db = -60.0
			sprint_loop.play()
		_sprint_tween = create_tween()
		_sprint_tween.tween_property(sprint_loop, "volume_db", _sprint_loop_volume_db, sprint_loop_fade)
	elif sprint_loop.playing:
		_sprint_tween = create_tween()
		_sprint_tween.tween_property(sprint_loop, "volume_db", -60.0, sprint_loop_fade)
		_sprint_tween.tween_callback(sprint_loop.stop)


## The sprint loop is playing now (or fading out).
func is_sprint_loop_playing() -> bool:
	return sprint_loop != null and sprint_loop.playing
