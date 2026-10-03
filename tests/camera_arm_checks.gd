extends "res://tests/check_suite.gd"
## Camera arm: it rests against what is behind the camera and returns smoothly; it comes closer than a fence that
## hides the character only when this is enabled; a thin pole and bodies in the camera_ignore group do not get in the
## arm's way; up close the character is semi-transparent; the settings reach the arm. The check places the obstacles
## itself, on open ground.

## Where the character stands; the camera looks north, that is, it hangs to the south, over open ground.
const SPOT := Vector3(-8, 0, 0)

var _arm: CameraArm


func setup(tree: SceneTree, main: Node3D) -> void:
	super(tree, main)
	_arm = main.get_node("CameraRig/CameraArm")


func _checks() -> Array[Callable]:
	return [
		_check_open_ground,
		_check_keep_out,
		_check_occlusion,
		_check_ignored_groups,
		_check_fade,
		_check_arm_settings,
	]


func _check_open_ground() -> void:
	print("\n== camera arm on open ground")
	await _stand()
	print("arm length %.2f, wanted %.2f, camera at %.2f" % [_arm.get_current_length(), _arm.length, _camera.position.z])
	_expect(absf(_arm.get_current_length() - _arm.length) < 0.001
			and absf(_camera.position.z - _arm.get_current_length()) < 0.001,
			"nothing around: the arm keeps the length the rig asks for")


## A cliff behind the camera: its front face is at 0.6 of the arm length, so the camera would be inside it.
func _check_keep_out() -> void:
	print("\n== camera arm keeps out of a cliff behind the camera")
	await _stand()
	var full := _arm.length
	var face := _arm_point(full * 0.6).z
	var cliff := await _add_box(Vector3(SPOT.x, 10.0, face + 4.0), Vector3(30, 20, 8))
	await _frames(2)
	var expected := _length_to_plane(face - _arm.probe_radius)
	var instant := _arm.get_current_length()
	print("cliff face at z %.2f: arm %.2f -> %.2f (expected %.2f), camera z %.2f" % [face, full, instant, expected,
		_camera.global_position.z])
	_expect(absf(instant - expected) < 0.03, "the arm shortens at once: the camera rests against the cliff")
	_expect(_camera.global_position.z <= face - _arm.probe_radius + 0.02, "the camera is not inside the cliff")

	# The character walks up to the cliff: the camera moves even closer to the character but does not go into the cliff.
	await _teleport(SPOT + Vector3(0, 0, 1.5))
	await _frames(5)
	var closer := _arm.get_current_length()
	print("player 1.5 m closer to the cliff: arm %.2f, camera z %.2f" % [closer, _camera.global_position.z])
	_expect(closer < instant - 1.0 and _camera.global_position.z <= face - _arm.probe_radius + 0.02,
			"the player walks to the cliff: the camera slides closer and stays out")
	await _teleport(SPOT)
	_arm.snap()
	await _frames(5)

	_free(cliff)
	await _ticks(1)
	var lengths := PackedFloat32Array()
	for i in 150:
		await _tree.process_frame
		lengths.append(_arm.get_current_length())
	var held := lengths[int(_arm.return_delay / DT) - 3]
	var largest_step := 0.0
	for i in range(1, lengths.size()):
		largest_step = maxf(largest_step, lengths[i] - lengths[i - 1])
	print("cliff gone: arm %.2f until the return delay, then (every 15th frame) %s; largest step %.3f m" % [
		held, _fmt(_every(lengths, 15)), largest_step])
	_expect(absf(held - instant) < 0.01, "the arm waits for the return delay before it lengthens")
	_expect(absf(lengths[-1] - full) < 0.01, "then it returns to the full length")
	_expect(largest_step < 0.1 * (full - instant), "the return is smooth")

	_arm.keep_out_of_geometry = false
	cliff = await _add_box(Vector3(SPOT.x, 10.0, face + 4.0), Vector3(30, 20, 8))
	await _frames(5)
	print("keep out off: arm %.2f" % _arm.get_current_length())
	_expect(absf(_arm.get_current_length() - full) < 0.001, "keep out off: the camera goes into the cliff")
	_arm.keep_out_of_geometry = true
	_free(cliff)
	await _settle_arm()

	# A fence with a cliff right behind it: there is no room between them, so the camera stops in front of the fence.
	var fence_face := _arm_point(full * 0.35).z
	var fence := await _add_box(Vector3(SPOT.x, 4.0, fence_face + 0.15), Vector3(12, 8, 0.3))
	cliff = await _add_box(Vector3(SPOT.x, 10.0, fence_face + 0.3 + 6.0), Vector3(30, 20, 12))
	await _frames(3)
	var before_fence := _length_to_plane(fence_face - _arm.probe_radius)
	print("cliff right behind a fence at z %.2f: arm %.2f (expected %.2f)" % [fence_face, _arm.get_current_length(),
		before_fence])
	_expect(absf(_arm.get_current_length() - before_fence) < 0.03,
			"no room between a fence and a cliff behind it: the camera stops in front of the fence")
	_free(fence)
	_free(cliff)
	await _settle_arm()

	# The "camera" layer (3) is for the camera only: a body on it stops the camera, while the character layer (2)
	# does not.
	cliff = await _add_box(Vector3(SPOT.x, 10.0, face + 4.0), Vector3(30, 20, 8), null, &"", 0b100)
	await _frames(3)
	var camera_layer := _arm.get_current_length()
	_free(cliff)
	await _settle_arm()
	cliff = await _add_box(Vector3(SPOT.x, 10.0, face + 4.0), Vector3(30, 20, 8), null, &"", 0b10)
	var character_layer := await _shortest_length(10)
	_free(cliff)
	print("cliff on the camera layer: arm %.2f; on the characters layer: shortest %.2f" % [camera_layer,
		character_layer])
	_expect(absf(camera_layer - expected) < 0.03, "a body on the camera layer stops the camera")
	_expect(absf(character_layer - full) < 0.001, "a body on the characters layer does not")
	await _frames(3)


## A tall fence halfway between the camera and the character, with enough room for the camera behind the fence; then
## a fence right at the character, a thin pole and a pole right next to the arm.
func _check_occlusion() -> void:
	print("
== camera arm and a fence that hides the player")
	await _stand()
	var full := _arm.length
	var near_face := _arm_point(full * 0.5).z
	var fence := await _add_box(Vector3(SPOT.x, 5.0, near_face + 0.15), Vector3(12, 10, 0.3))
	await _frames(30)
	print("pull in off: arm %.2f of %.2f" % [_arm.get_current_length(), full])
	_expect(absf(_arm.get_current_length() - full) < 0.001,
			"by default the camera stays behind the fence: there is room for it there")

	_arm.pull_in_on_occlusion = true
	var lengths := PackedFloat32Array()
	for i in 90:
		await _tree.process_frame
		lengths.append(_arm.get_current_length())
	var waiting := lengths[int(_arm.occlusion_delay / DT) - 3]
	var largest_step := 0.0
	for i in range(1, lengths.size()):
		largest_step = maxf(largest_step, lengths[i - 1] - lengths[i])
	var expected := _length_to_plane(near_face - _arm.probe_radius)
	print(("pull in on: arm %.2f before the occlusion delay, %.2f after 1.5 s (expected %.2f), largest step %.2f m; " +
			"camera z %.2f, fence at %.2f") % [waiting, lengths[-1], expected, largest_step, _camera.global_position.z,
			near_face])
	_expect(absf(waiting - full) < 0.001, "a short occlusion does not move the camera")
	_expect(absf(lengths[-1] - expected) < 0.03, "with pull in on the camera comes in front of the fence")
	_expect(largest_step < 0.3 * (full - expected), "it comes there smoothly, not in one jump")
	_free(fence)
	await _settle_arm()
	print("fence gone: arm %.2f" % _arm.get_current_length())
	_expect(absf(_arm.get_current_length() - full) < 0.01, "the fence is gone: the camera goes back")

	# A fence right at the character: the room in front of it is less than min_pull_in_length, so the camera does not
	# jump to the character's back.
	fence = await _add_box(Vector3(SPOT.x, 5.0, _arm_point(1.2).z + 0.15), Vector3(12, 10, 0.3))
	var at_fence := await _shortest_length(60)
	print("fence 1.2 m from the player: shortest arm %.2f of %.2f, pulled in %s" % [at_fence, full,
		_arm.is_pulled_in_by_occlusion()])
	_expect(absf(at_fence - full) < 0.001 and not _arm.is_pulled_in_by_occlusion(),
			"a fence right at the player: the camera does not jump to the player's back")
	_free(fence)
	await _settle_arm()

	var pole := await _add_box(Vector3(SPOT.x, 5.0, near_face + 0.125), Vector3(0.25, 10, 0.25))
	var at_pole := await _shortest_length(40)
	print("thin pole: shortest arm %.2f, pulled in %s" % [at_pole, _arm.is_pulled_in_by_occlusion()])
	_expect(absf(at_pole - full) < 0.001 and not _arm.is_pulled_in_by_occlusion(),
			"a thin pole hides only part of the player: the camera stays")
	_free(pole)
	_arm.pull_in_on_occlusion = false
	await _settle_arm()

	# A column right next to the arm: the ray misses it, but the camera sphere would touch it. It is not behind the
	# camera, so the keep out does not react.
	var column := await _add_box(Vector3(SPOT.x + 0.3, 5.0, near_face), Vector3(0.3, 10, 0.3))
	var grazed := await _shortest_length(30)
	print("column 0.15 m beside the arm: shortest arm %.2f of %.2f" % [grazed, full])
	_expect(absf(grazed - full) < 0.001, "the arm passes close by a column: the camera stays where it is")
	_free(column)
	await _frames(3)


## Bodies in the camera_ignore group (themselves or under a folder node in that group) do not get in the arm's way.
func _check_ignored_groups() -> void:
	print("\n== camera arm ignores bodies in camera_ignore")
	await _stand()
	var full := _arm.length
	var face := _arm_point(full * 0.6).z
	var cliff := await _add_box(Vector3(SPOT.x, 10.0, face + 4.0), Vector3(30, 20, 8), null, &"camera_ignore")
	var body_in_group := await _shortest_length(40)
	_free(cliff)
	var folder := Node3D.new()
	folder.add_to_group(&"camera_ignore")
	_main.add_child(folder)
	await _add_box(Vector3(SPOT.x, 10.0, face + 4.0), Vector3(30, 20, 8), folder)
	_arm.pull_in_on_occlusion = true
	await _add_box(Vector3(SPOT.x, 4.0, _arm_point(full * 0.35).z + 0.15), Vector3(12, 8, 0.3), folder)
	var under_folder := await _shortest_length(40)
	print(("shortest arm %.2f of %.2f with the cliff in the group; %.2f with a cliff and a fence (pull in on) " +
			"under a folder in the group") % [body_in_group, full, under_folder])
	_expect(absf(body_in_group - full) < 0.001, "a body in camera_ignore does not stop the camera")
	_expect(absf(under_folder - full) < 0.001, "bodies under a node in camera_ignore stop and hide nothing")
	_arm.pull_in_on_occlusion = false
	_free(folder)
	await _settle_arm()


## A cliff very close behind the camera: the arm is shorter than fade_end_length and the character is
## semi-transparent; with the cliff gone, the character is visible again.
func _check_fade() -> void:
	print("\n== camera arm fades the player when the camera is very close")
	await _stand()
	var face := _arm_point(0.9).z
	var cliff := await _add_box(Vector3(SPOT.x, 10.0, face + 10.0), Vector3(30, 20, 20))
	await _frames(3)
	var close_up := _arm.get_current_length()
	var faded := _player_transparency()
	_free(cliff)
	await _settle_arm()
	var back := _player_transparency()
	print("arm %.2f: player transparency %.2f..%.2f; cliff gone: arm %.2f, transparency %.2f..%.2f" % [close_up,
		faded.x, faded.y, _arm.get_current_length(), back.x, back.y])
	_expect(close_up < _arm.fade_end_length and absf(faded.x - _arm.fade_transparency) < 0.001
			and absf(faded.y - _arm.fade_transparency) < 0.001, "the camera at the player's back: the player is see-through")
	_expect(back == Vector2.ZERO, "the camera is back: the player is solid again")


func _check_arm_settings() -> void:
	print("\n== camera arm settings")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	var defaults := [_arm.keep_out_of_geometry, _arm.pull_in_on_occlusion]
	settings.set_value(GameSettings.CAMERA_KEEP_OUT, false)
	settings.set_value(GameSettings.CAMERA_PULL_IN, true)
	var changed := [_arm.keep_out_of_geometry, _arm.pull_in_on_occlusion]
	settings.set_value(GameSettings.CAMERA_KEEP_OUT, true)
	settings.set_value(GameSettings.CAMERA_PULL_IN, false)
	print("keep out, pull in: default %s, after the settings %s" % [defaults, changed])
	_expect(defaults == [true, false], "by default the camera keeps out of what is behind it and does not pull in")
	_expect(changed == [false, true], "both settings reach the arm")


## The character stands at SPOT; the camera looks north and stands still.
func _stand() -> void:
	await _teleport(SPOT)
	_rig.look_along(Vector3.FORWARD)
	_rig.snap()
	await _settle_camera()


## The point on the arm at [param distance] from its start.
func _arm_point(distance: float) -> Vector3:
	return _arm.global_position + _arm.global_basis.z.normalized() * distance


## At what distance from its start the arm crosses the plane z = [param z].
func _length_to_plane(z: float) -> float:
	return (z - _arm.global_position.z) / _arm.global_basis.z.normalized().z


func _add_box(center: Vector3, size: Vector3, parent: Node = null, group := &"", layer := 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	if group != &"":
		body.add_to_group(group)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	# The position is set before the body is added to the tree: otherwise the body appears at the origin for a moment
	# and pushes the character out.
	body.position = center
	(_main if parent == null else parent).add_child(body)
	await _ticks(1)
	return body


func _free(node: Node) -> void:
	node.queue_free()


## The shortest arm length over [param frames] frames.
func _shortest_length(frames: int) -> float:
	var shortest := INF
	for i in frames:
		await _tree.process_frame
		shortest = minf(shortest, _arm.get_current_length())
	return shortest


## Waits until the arm returns after an obstacle (the delay and the smooth return).
func _settle_arm() -> void:
	await _frames(180)


## The lowest and the highest transparency of the player model's meshes.
func _player_transparency() -> Vector2:
	var result := Vector2(INF, -INF)
	for mesh: Node in _player.visual.find_children("*", "GeometryInstance3D", true, false):
		var transparency := (mesh as GeometryInstance3D).transparency
		result = Vector2(minf(result.x, transparency), maxf(result.y, transparency))
	return result
