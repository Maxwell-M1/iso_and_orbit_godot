extends "res://tests/check_suite.gd"
## Hero look: the staff in the right hand, the silhouette through obstacles (body, gear, outline), the staff swaying in
## step with the strides, the look from the settings changing on the fly.


func _checks() -> Array[Callable]:
	return [
		_check_player_model,
		_check_hand_sway,
		_check_appearance,
	]


## The staff in the right hand of the player model: it is to the right of the character and turns with it.
## The silhouette through obstacles ([OccludedSilhouette]) sits on top of all meshes of the model: the body has one
## chain of passes, the gear in the hands has its own, including gear added later. The outline turns on and off with a
## property and a setting.
func _check_player_model() -> void:
	print("\n== player model: the staff in the right hand, one silhouette for the body, one for the gear, the outline")
	var staff: Node3D = _player.get_node("Visual/Hover/Model/RightHand/Staff")
	var silhouette: OccludedSilhouette = _player.get_node("Silhouette")
	var sides := PackedFloat32Array()
	for direction: Vector3 in [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, -1)]:
		await _teleport(Vector3.ZERO)
		_mover.steer(direction)
		await _ticks(40)
		_mover.stop()
		await _ticks_until_stopped(60)
		var offset := staff.global_position - _player.global_position
		var right := _visual_forward().cross(Vector3.UP)
		sides.append(offset.dot(right))
	var meshes := _player.get_node("Visual").find_children("*", "GeometryInstance3D", true, false)
	var body := silhouette.get_overlay(false)
	var gear := silhouette.get_overlay(true)
	var body_count := 0
	var gear_count := 0
	for mesh: GeometryInstance3D in meshes:
		if mesh.material_overlay == body and not staff.is_ancestor_of(mesh):
			body_count += 1
		elif mesh.material_overlay == gear and staff.is_ancestor_of(mesh):
			gear_count += 1
	var new_gear := MeshInstance3D.new()
	new_gear.mesh = BoxMesh.new()
	_player.get_node("Visual/Hover/Model/RightHand").add_child(new_gear)
	var new_body := MeshInstance3D.new()
	new_body.mesh = BoxMesh.new()
	_player.get_node("Visual/Hover/Model").add_child(new_body)
	var added_right := new_gear.material_overlay == gear and new_body.material_overlay == body
	new_gear.free()
	new_body.free()
	var outline: Material = silhouette.outline
	var with_outline := body.next_pass.next_pass == outline and gear.next_pass.next_pass == outline
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	settings.set_value(GameSettings.SILHOUETTE_OUTLINE, false)
	var outline_off := not silhouette.outline_enabled and body.next_pass.next_pass == null \
			and gear.next_pass.next_pass == null
	settings.set_value(GameSettings.SILHOUETTE_OUTLINE, true)
	var outline_on := silhouette.outline_enabled and body.next_pass.next_pass == outline
	print(("staff to the right of the character after three turns: %s m; body silhouette on %d meshes, gear on %d " +
			"(of %d); new meshes in the hand and in the body %s; outline %s, off %s, back on %s") % [
		sides, body_count, gear_count, meshes.size(), added_right, with_outline, outline_off, outline_on])
	_expect(_min(sides) > 0.35, "the staff stays in the right hand when the character turns")
	_expect(body != gear and body_count + gear_count == meshes.size() and gear_count > 3 and added_right,
			"the body and the gear in the hands get their own silhouettes, meshes added later too")
	_expect(with_outline and outline_off and outline_on, "the outline goes off and on from the setting")
	await _teleport(Vector3.ZERO)


## The staff in the hand sways in step with the strides: standing, the hand stays in place; running, it swings back
## and forth, with its far points on the steps, forward and back in turn; on a start it lags back; after a stop it
## returns; on landing the hand dips.
func _check_hand_sway() -> void:
	print("\n== the staff sways in the hand: in step with the stride, lags on start, settles on stop, dips on landing")
	var hand: Node3D = _player.get_node("Visual/Hover/Model/RightHand")
	# Compare with where the hand is in the model itself (right now the hand may still be swaying after the previous
	# checks).
	var model: Node3D = (load(_player.get_node("Visual/Hover/Model").scene_file_path) as PackedScene).instantiate()
	var rest := (model.get_node("RightHand") as Node3D).transform
	model.free()
	await _teleport(Vector3(-30, 0, 34))
	for i in 30:
		await _tree.physics_frame
	var still := hand.transform.origin.distance_to(rest.origin) < 0.001
	var step_offsets: Array[float] = []
	var on_step := func(_sprinting: bool) -> void: step_offsets.append(hand.transform.origin.z - rest.origin.z)
	_player.stepped.connect(on_step)
	var start_tilt := 0.0
	var forward := 0.0
	var back := 0.0
	var lowest := 0.0
	_mover.steer(Vector3.RIGHT)
	for i in 150:
		await _tree.physics_frame
		var offset := hand.transform.origin - rest.origin
		if i < 20:
			# The backward lean from the start: the top of the item (the hand's Y axis) moves toward +Z.
			start_tilt = maxf(start_tilt, hand.transform.basis.y.z)
		elif i > 60:
			forward = minf(forward, offset.z)
			back = maxf(back, offset.z)
			lowest = minf(lowest, offset.y)
	_player.stepped.disconnect(on_step)
	_mover.stop()
	var settle := -1.0
	for i in 120:
		await _tree.physics_frame
		var offset := hand.transform.origin - rest.origin
		if offset.length() < 0.003 and hand.transform.basis.y.angle_to(rest.basis.y) < deg_to_rad(0.5):
			settle = i * DT
			break
	var alternating := step_offsets.size() >= 4
	for i in range(2, step_offsets.size()):
		alternating = alternating and step_offsets[i] * step_offsets[i - 1] < 0.0 and absf(step_offsets[i]) > 0.05
	await _teleport(Vector3(-30, 0, 34))
	for i in 30:
		await _tree.physics_frame
	_player.jump()
	var dip := 0.0
	for i in 90:
		await _tree.physics_frame
		if _player.is_on_floor() and i > 10:
			dip = minf(dip, hand.transform.origin.y - rest.origin.y)
	print(("standing: hand at rest %s; start: staff top leans back %.3f; running: hand %.3f..%.3f m along, " +
			"lowest %.3f m; at steps %s; back at rest %.2f s after the stop; after a jump the hand dips %.3f m") % [
		still, start_tilt, forward, back, lowest, step_offsets, settle, dip])
	_expect(still, "standing: the hand stays where the model puts it")
	_expect(start_tilt > 0.04, "starting to run: the staff top lags back")
	_expect(forward < -0.05 and back > 0.05 and lowest < -0.015,
			"running: the hand swings forward and back and dips on steps")
	_expect(alternating, "the swing is in step: at each step the hand is at its far point, forward and back in turn")
	_expect(settle >= 0.0 and settle < 1.5, "after the stop the hand comes back to rest")
	_expect(dip < -0.01, "landing: the hand dips")
	await _teleport(Vector3.ZERO)


## Hero look from the settings: the necromancer (8) by default; any of the ten options goes on on the fly: the old
## model is removed, the staff in the new model's hand sways in step with the strides, the silhouette sits on its
## meshes.
func _check_appearance() -> void:
	print("\n== hero look from the settings: the default one at start, any of the ten on the fly")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	var appearance: CharacterAppearance = _player.get_node("Appearance")
	var sway: HandSway = _player.get_node("RightHandSway")
	var silhouette: OccludedSilhouette = _player.get_node("Silhouette")
	var slot := appearance.slot
	var default_look := appearance.get_look()
	var default_scene := appearance.get_model().scene_file_path
	var report := PackedStringArray()
	var ok := appearance.models.size() == 10
	for number in range(1, appearance.models.size() + 1):
		await _teleport(Vector3(-30, 0, 34))
		settings.set_value(GameSettings.CHARACTER_LOOK, number)
		await _ticks(2)
		var model := appearance.get_model()
		var hand := model.get_node("RightHand") as Node3D
		var rest := hand.transform
		var meshes := model.find_children("*", "GeometryInstance3D", true, false)
		var covered := 0
		for mesh: GeometryInstance3D in meshes:
			if mesh.material_overlay == silhouette.get_overlay(silhouette.is_gear(mesh)):
				covered += 1
		_mover.steer(Vector3.RIGHT)
		await _ticks(40)
		var swing := hand.transform.origin.distance_to(rest.origin)
		_mover.stop()
		await _ticks_until_stopped(60)
		var right := appearance.get_look() == number and slot.get_child_count() == 1 and sway.hand == hand \
				and covered == meshes.size() and swing > 0.02
		report.append("%d %s%s" % [
			number, model.scene_file_path.get_file().get_basename().trim_prefix("option_"), "" if right else " (!)"])
		ok = ok and right
	settings.set_value(GameSettings.CHARACTER_LOOK, GameSettings.DEFAULTS[GameSettings.CHARACTER_LOOK])
	await _ticks(2)
	print("default look %d (%s); %s; back to %d" % [
		default_look, default_scene.get_file(), ", ".join(report), appearance.get_look()])
	var expected_look: int = GameSettings.DEFAULTS[GameSettings.CHARACTER_LOOK]
	_expect(default_look == expected_look and default_scene.get_file().begins_with("option_%02d_" % expected_look),
			"the hero wears the default look of the settings")
	_expect(ok,
			"each of the ten looks goes on at once: one model, the staff sways in its hand, the silhouette covers it")
	_expect(appearance.get_look() == expected_look, "the default look comes back")
	await _teleport(Vector3.ZERO)
