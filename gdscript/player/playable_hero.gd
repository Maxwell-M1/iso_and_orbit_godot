class_name PlayableHero
extends Node3D
## The hero the player controls, assembled and ready: the character (the base scene, which an AI can drive just as
## well), the mouse and the keys that drive it, the camera that follows it, the marker of the clicked point and the line
## of the path. Put it into the game scene once, next to the levels and not into one of them: the levels change, the
## hero stays and moves between them ([method place_at]).
##
## The root stays where it is, no code moves it: the character moves inside it, and the camera follows the character by
## itself.

@export_group("Parts")
## The character: the base scene, which an AI can drive just as well.
@export var character: GroundCharacter
## The mouse and the keys with the camera button.
@export var input: PointClickMoveInput
## Sprint and jump.
@export var actions: CharacterActionInput
## The camera that follows the character; the mouse and the wheel turn and raise it.
@export var camera_rig: OrbitCameraRig
## The arm that holds the camera away from walls.
@export var camera_arm: CameraArm
## The camera itself.
@export var camera: Camera3D
## The marker of the clicked point.
@export var click_marker: ClickMarker
## The line of the path (hidden unless the settings show it).
@export var path_view: NavigationPathView

@export_group("Character parts")
## The steps and the other sounds of the character.
@export var sounds: CharacterSounds
## The looks the character can take.
@export var appearance: CharacterAppearance
## Floating above the ground.
@export var hover: CharacterHover
## The outline of the character behind obstacles.
@export var silhouette: OccludedSilhouette

## The player controls the hero: the mouse and the keys move it, sprint and jump work. Off, for a cutscene, a dialog or
## a level change: the press under way is forgotten ([method PointClickMoveInput.cancel]), and the hero takes no input;
## a run to a clicked point goes on, unless the hero is stopped or put elsewhere. The camera stays the player's.
var controls_enabled := true:
	set = set_controls_enabled

# How the input nodes processed before the controls were taken away: given back as they were.
var _input_mode := Node.PROCESS_MODE_INHERIT
var _actions_mode := Node.PROCESS_MODE_INHERIT


func _ready() -> void:
	assert(character != null and input != null and camera_rig != null,
			"PlayableHero needs the character, input and camera_rig properties set.")
	for warning in get_setup_warnings():
		push_warning("%s: %s" % [name, warning])


## Problems in how the parts of the hero work together, one line each; empty if there are none. The same lines are
## printed as warnings when the hero enters the tree.
func get_setup_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if character == null or character.mover == null or camera_rig == null:
		return warnings
	var locomotion := character.mover.settings
	if locomotion != null and camera_rig.follow_toward_camera_angle > 0.0 and camera_rig.sharp_turn_speed > 0.0 \
			and camera_rig.sharp_turn_speed >= locomotion.turn_speed:
		warnings.append(("%s.sharp_turn_speed (%.0f°/s) is not below the character's turn speed (%.0f°/s): the "
				+ "character's turns are no longer reliably sharp, and a turnaround toward the camera turns the camera. "
				+ "Keep it at half the turn speed or lower.") % [camera_rig.name, rad_to_deg(camera_rig.sharp_turn_speed),
				rad_to_deg(locomotion.turn_speed)])
	return warnings


func set_controls_enabled(enabled: bool) -> void:
	if enabled == controls_enabled:
		return
	controls_enabled = enabled
	if enabled:
		input.process_mode = _input_mode
		if actions != null:
			actions.process_mode = _actions_mode
		return
	input.cancel()
	# The actions stop updating it: a sprint key held now must not keep the hero sprinting.
	character.sprint_requested = false
	_input_mode = input.process_mode
	input.process_mode = Node.PROCESS_MODE_DISABLED
	if actions != null:
		_actions_mode = actions.process_mode
		actions.process_mode = Node.PROCESS_MODE_DISABLED


## Put the hero at [param position] at once and turn it to [param facing], if given ([method GroundCharacter.teleport]),
## with the camera looking the same way if [param turn_camera]. The press under way is forgotten, and the camera snaps
## into place and follows the hero from scratch.
func teleport(position: Vector3, facing := Vector3.ZERO, turn_camera := true) -> void:
	input.cancel()
	character.teleport(position, facing)
	if turn_camera:
		camera_rig.look_along(facing)
	camera_rig.end_follow_wait()
	camera_rig.snap()


## Put the hero at [param marker] (a [SpawnPoint], for example), facing along its −Z, the camera behind it if
## [param turn_camera].
func place_at(marker: Node3D, turn_camera := true) -> void:
	teleport(marker.global_position, -marker.global_basis.z, turn_camera)
