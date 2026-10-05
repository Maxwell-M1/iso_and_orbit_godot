extends RefCounted
## The base of a check suite for [code]tests/run_checks.gd[/code]: the main scene nodes, waiting for ticks, mouse
## and keyboard events, verifying expectations and simple statistics over measurements.
##
## A suite is a [code]tests/*_checks.gd[/code] file that extends this script: it lists its checks in [method _checks]
## in the order they run. A check is a function without parameters (or with parameters bound with
## [method Callable.bind]): it puts the character where needed ([method _teleport]), acts, prints measurements and
## verifies them with [method _expect]. Whatever a check has changed (node properties, settings), it restores
## itself: the suites run one after another on the same main scene, and when only some of the suites run, on a
## fresh one.
##
## Do not use as types, here or in the suites, the classes that access the Settings autoload (the settings window
## controls): the check scripts are compiled before the autoload names appear, and such a class will not compile.
## The settings node itself is [code]_tree.root.get_node(^"Settings")[/code].

## The physics tick when run with [code]--fixed-fps 60[/code].
const DT := 1.0 / 60.0

## How many expectations passed.
var passed := 0
## How many expectations failed.
var failures := 0

var _tree: SceneTree
var _main: Node3D
var _hero: PlayableHero
var _levels: LevelHost
var _player: GroundCharacter
var _mover: NavigationMover
var _rig: OrbitCameraRig
var _camera: Camera3D
var _marker: Node3D
var _input: PointClickMoveInput
var _actions: CharacterActionInput
# The character has reached the destination (NavigationMover.arrived): for _run_until_arrived().
var _arrived := false


## Take the nodes of the main scene [param main], which is already in the tree [param tree].
func setup(tree: SceneTree, main: Node3D) -> void:
	_tree = tree
	_main = main
	_hero = main.get_node("Hero")
	_levels = main.get_node("Levels")
	_player = _hero.character
	_mover = _player.mover
	_rig = _hero.camera_rig
	_camera = _hero.camera
	_marker = _hero.click_marker
	_input = _hero.input
	_actions = _hero.actions


## Run the suite's checks in order.
func run_checks() -> void:
	_mover.arrived.connect(_on_arrived)
	for check: Callable in _checks():
		await check.call()
	_mover.arrived.disconnect(_on_arrived)


## The suite's checks in the order they run. Every suite overrides this.
func _checks() -> Array[Callable]:
	return []


func _on_arrived() -> void:
	_arrived = true


## A route by click from [param from] to [param to]: whether the character arrived within [param max_time] seconds
## without getting stuck; with [param reachable], also exactly at the point and on the right floor (toward an
## unreachable point, the character goes to the nearest reachable one).
func _check_route(title: String, from: Vector3, to: Vector3, max_time: float, reachable := true) -> void:
	print("\n== route: %s" % title)
	await _teleport(from)
	var run := await _run_until_arrived(to, max_time)
	var straight := Vector2(to.x - from.x, to.z - from.z).length()
	print("arrived %s in %.2f s, walked %.2f m (straight %.2f m), end %s, error %.3f m, stuck ticks %d" % [
		run.arrived, run.time, run.walked, straight, _player.global_position.snapped(Vector3.ONE * 0.01), run.error,
		run.stuck])
	_expect(run.arrived, "%s: arrived" % title)
	if reachable:
		_expect(run.error < 0.05, "%s: at the target" % title)
		_expect(absf(_player.global_position.y - to.y) < 0.1, "%s: on the right floor" % title)
	_expect(run.stuck < 6, "%s: not stuck" % title)


func _teleport(position: Vector3) -> void:
	_player.teleport(position)
	for i in 3:
		await _tree.physics_frame


## Runs to [param target] until it arrives or the time runs out. Returns the measurements.
func _run_until_arrived(target: Vector3, max_time: float, issue_command := true) -> Dictionary:
	_arrived = false
	if issue_command:
		_mover.move_to(target)
	var speeds := PackedFloat32Array()
	var distances := PackedFloat32Array()
	var walked := 0.0
	var stuck := 0
	var previous := _player.global_position
	var time := 0.0
	while not _arrived and time < max_time:
		await _tree.physics_frame
		time += DT
		var position := _player.global_position
		var step := _flat_distance(previous, position)
		walked += step
		if _mover.get_speed() > 1.0 and step < _mover.get_speed() * DT * 0.2:
			stuck += 1
		previous = position
		speeds.append(_mover.get_speed())
		distances.append(_flat_distance(position, _mover.get_destination()))
	# A few more ticks: the character must not move on.
	for i in 10:
		await _tree.physics_frame
	var backtrack := 0.0
	for i in range(1, distances.size()):
		if distances[i] < 1.0:
			backtrack = maxf(backtrack, distances[i] - distances[i - 1])
	return {
		arrived = _arrived,
		time = time,
		speeds = speeds,
		walked = walked,
		stuck = stuck,
		backtrack = backtrack,
		error = _flat_distance(_player.global_position, target),
	}


func _settle_camera() -> void:
	for i in 60:
		await _tree.process_frame


func _ticks(count: int) -> void:
	for i in count:
		await _tree.physics_frame


func _frames(count: int) -> void:
	for i in count:
		await _tree.process_frame


## Waits for physics ticks until [param condition] becomes true, but no more than [param max_ticks].
func _wait_until(condition: Callable, max_ticks: int) -> void:
	for i in max_ticks:
		if condition.call():
			return
		await _tree.physics_frame


## A jump in place at [param at]: the vertical speed after every tick in the air, from the take-off to the landing.
func _record_jump(at: Vector3) -> PackedFloat32Array:
	await _teleport(at)
	_player.jump()
	var speeds := PackedFloat32Array()
	for i in 600:
		await _tree.physics_frame
		if not _player.is_on_floor():
			speeds.append(_player.velocity.y)
		elif not speeds.is_empty():
			break
	return speeds


## Waits until the character stops (no more than [param max_ticks]). Returns the time in seconds or −1.
func _ticks_until_stopped(max_ticks: int) -> float:
	for i in max_ticks:
		if not _mover.is_moving() and _mover.get_speed() == 0.0:
			return i * DT
		await _tree.physics_frame
	return -1.0


## Press and release a key. [param shift] is whether Shift is held meanwhile (this is how the event carries
## modifiers).
func _send_key(keycode: Key, shift := false) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.pressed = pressed
		event.shift_pressed = shift
		Input.parse_input_event(event)


## [param position] is in viewport coordinates. The engine receives events in window coordinates, and the headless
## window is 64 × 64 with a base size of 1152 × 648, so convert back through the final transform of the root.
func _send_button(button: MouseButton, pressed: bool, position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = _tree.root.get_final_transform() * position
	event.global_position = event.position
	event.factor = 1.0
	Input.parse_input_event(event)


func _send_motion(position: Vector2, relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = _tree.root.get_final_transform() * position
	event.global_position = event.position
	event.relative = relative
	event.screen_relative = relative
	Input.parse_input_event(event)


## Where the character model faces, horizontally.
func _visual_forward() -> Vector3:
	var look := -_player.visual.global_basis.z
	return Vector3(look.x, 0.0, look.z).normalized()


func _camera_forward() -> Vector3:
	return -_camera.global_basis.z


## The horizontal angle between directions, in degrees.
static func _flat_angle(a: Vector3, b: Vector3) -> float:
	return rad_to_deg(absf(Vector2(a.x, a.z).angle_to(Vector2(b.x, b.z))))


func _expect(condition: bool, what: String) -> void:
	if condition:
		passed += 1
		print("  ok: ", what)
	else:
		failures += 1
		print("  FAIL: ", what)


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _flat_speed(velocity: Vector3) -> float:
	return Vector2(velocity.x, velocity.z).length()


static func _median(values: PackedFloat32Array) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[int(sorted.size() / 2.0)]


static func _max(values: PackedFloat32Array) -> float:
	var result := -INF
	for value: float in values:
		result = maxf(result, value)
	return result


static func _min(values: PackedFloat32Array) -> float:
	var result := INF
	for value: float in values:
		result = minf(result, value)
	return result


## The largest difference between two series, value by value; INF if their lengths differ.
static func _largest_difference(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	if a.size() != b.size():
		return INF
	var largest := 0.0
	for i in a.size():
		largest = maxf(largest, absf(a[i] - b[i]))
	return largest


## After how many seconds the value first dropped to [param limit]; -1 if it never did.
static func _first_time_at_most(values: PackedFloat32Array, limit: float) -> float:
	for i in values.size():
		if values[i] <= limit:
			return (i + 1) * DT
	return -1.0


static func _every(values: PackedFloat32Array, step: int) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	for i in range(0, values.size(), step):
		result.append(values[i])
	return result


static func _fmt(values: PackedFloat32Array) -> String:
	var parts := PackedStringArray()
	for value: float in values:
		parts.append("%.2f" % value)
	return " ".join(parts)
