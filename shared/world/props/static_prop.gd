@tool
class_name StaticProp
extends StaticBody3D
## A solid object of a level: its visible parts and collision shapes are children of this root. Move it by the root
## and resize it with [member dimensions]: the visible parts and the collision are stretched together, and a resized
## shape is a copy of its own, so the objects that share the shape stay as they are. Edit the parts as usual: saving
## keeps them as they were made, and the stretch is applied again when the scene opens and when the game starts. Do not
## scale the root.

## The object's size along its own axes: its visible parts and its collision are stretched to it together. 0 on an
## axis keeps the size of the parts along it ([method get_natural_size]): the default, (0, 0, 0), is the object as made.
@export_custom(PROPERTY_HINT_RANGE, "0,1000,0.01,or_greater,suffix:m") var dimensions := Vector3.ZERO:
	set(value):
		dimensions = value
		if is_inside_tree() and not _applying:
			if not _initialized:
				_capture_layout()
			elif _layout_changed():
				_refresh_layout(false)
			_apply_dimensions()
			_watch_geometry()
			update_configuration_warnings()
## Optional override for the object's visible surfaces. Empty keeps their authored materials.
@export var surface_material: Material:
	set(value):
		surface_material = value
		if is_inside_tree() and not _applying:
			if not _initialized:
				_capture_layout()
			elif _layout_changed():
				_refresh_layout(true)
			_apply_dimensions()
			_apply_material()
			_watch_geometry()

var _reference_dimensions := Vector3.ZERO
var _visuals: Array[Dictionary] = []
var _collisions: Array[Dictionary] = []
var _materials: Array[Dictionary] = []
var _initialized := false
var _applying := false
var _saving := false
var _changed_geometry := {}
var _resize_ratio := Vector3.ONE
var _layout_nodes: Array[Node] = []
var _watched_geometry: Array[Resource] = []
# In the editor: whether the root is scaled, which a warning reads (_process).
var _scaled := false


func _ready() -> void:
	# In the editor too: the object shows its size and material as in the game. Saving keeps the parts as made.
	_capture_layout()
	_apply_dimensions()
	_apply_material()
	if Engine.is_editor_hint():
		_scaled = _is_scaled()
		_watch_geometry()
		update_configuration_warnings()
		return
	set_process(false)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or _saving:
		return
	if _layout_changed():
		_refresh_layout(true)
		_apply_dimensions()
		_apply_material()
		_watch_geometry()
		update_configuration_warnings()
	# A scale of the root tells the object nothing: the warning about it is checked every frame.
	if _is_scaled() != _scaled:
		_scaled = not _scaled
		update_configuration_warnings()


func _notification(what: int) -> void:
	if not Engine.is_editor_hint() or not _initialized:
		return
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		if _layout_changed():
			_refresh_layout(true)
		_saving = true
		_restore_authored_layout()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_saving = false
		_apply_dimensions()
		_apply_material()
		_watch_geometry()


## The size of the parts as they are made, along the object's own axes: the size on the axes where
## [member dimensions] is 0.
func get_natural_size() -> Vector3:
	return _reference_dimensions if _initialized else _authored_bounds().size


# The bounds of the visible parts and the shapes in this object's coordinates, also outside the tree.
func _authored_bounds() -> AABB:
	var bounds := AABB()
	var found := false
	for node: Node in find_children("*", "", true, false):
		var local_bounds := AABB()
		if node is MeshInstance3D and node.mesh != null:
			local_bounds = node.mesh.get_aabb()
		elif node is CollisionShape3D and node.shape != null:
			local_bounds = node.shape.get_debug_mesh().get_aabb()
		else:
			continue
		local_bounds = _relative_transform(node) * local_bounds
		bounds = bounds.merge(local_bounds) if found else local_bounds
		found = true
	return bounds


func _capture_layout() -> void:
	_visuals.clear()
	_collisions.clear()
	_materials.clear()
	var branches := {}
	_reference_dimensions = _authored_bounds().size.max(Vector3.ONE * 0.01)
	_layout_nodes = find_children("*", "", true, false)
	for node: Node in _layout_nodes:
		if node is MeshInstance3D or node is Label3D or node is Light3D:
			# Keep imported models and their skeletons in the same scaled coordinate system.
			var branch := _visual_branch(node)
			if not branches.has(branch):
				branches[branch] = true
				_visuals.append({"node": branch, "transform": _relative_transform(branch),
					"applied": _relative_transform(branch)})
			if node is MeshInstance3D:
				_materials.append({"node": node, "material": node.material_override,
					"applied": node.material_override, "mesh": node.mesh})
		elif node is CollisionShape3D:
			_collisions.append({"node": node, "transform": _relative_transform(node), "shape": node.shape,
				"applied": _relative_transform(node), "applied_shape": node.shape})
	_initialized = true
	_changed_geometry.clear()


func _layout_changed() -> bool:
	if not _changed_geometry.is_empty() or find_children("*", "", true, false) != _layout_nodes:
		return true
	for entry: Dictionary in _visuals:
		if not is_instance_valid(entry.node) or not _relative_transform(entry.node).is_equal_approx(entry.applied):
			return true
	for entry: Dictionary in _collisions:
		if not is_instance_valid(entry.node) or entry.node.shape != entry.applied_shape \
				or not _relative_transform(entry.node).is_equal_approx(entry.applied):
			return true
	for entry: Dictionary in _materials:
		if not is_instance_valid(entry.node) or entry.node.material_override != entry.applied \
				or entry.node.mesh != entry.mesh:
			return true
	return false


func _refresh_layout(keep_ratio: bool) -> void:
	# Child edits are made against the visible preview. Normalize those edits before capturing a new authoring basis.
	var inverse_resize := Transform3D(Basis.IDENTITY.scaled(_resize_ratio).inverse(), Vector3.ZERO)
	var additions: Array[Dictionary] = []
	var new_branches := {}
	for node: Node in find_children("*", "", true, false):
		if _layout_nodes.has(node):
			continue
		if node is MeshInstance3D or node is Label3D or node is Light3D:
			var branch := _visual_branch(node)
			var known := _visuals.any(func(entry: Dictionary) -> bool: return entry.node == branch)
			if not known and not new_branches.has(branch):
				new_branches[branch] = true
				additions.append({"node": branch, "transform": inverse_resize * _relative_transform(branch)})
		elif node is CollisionShape3D and node.shape != null:
			var current := _relative_transform(node)
			var normalize := current.basis.inverse() * inverse_resize.basis * current.basis
			additions.append({"node": node, "transform": Transform3D(current.basis, current.origin / _resize_ratio),
				"shape": node.shape if normalize.is_equal_approx(Basis.IDENTITY)
					else _resized_shape(node.shape, normalize)})
	for entry: Dictionary in _visuals:
		if is_instance_valid(entry.node):
			var current := _relative_transform(entry.node)
			if not current.is_equal_approx(entry.applied):
				entry.transform = inverse_resize * current
	for entry: Dictionary in _collisions:
		if not is_instance_valid(entry.node):
			continue
		var current := _relative_transform(entry.node)
		if entry.node.shape != entry.applied_shape \
				or (entry.node.shape != entry.shape and _changed_geometry.has(entry.node.shape)) \
				or not current.basis.is_equal_approx(entry.applied.basis):
			if entry.node.shape != null:
				var normalize := current.basis.inverse() * inverse_resize.basis * current.basis
				entry.shape = entry.node.shape if normalize.is_equal_approx(Basis.IDENTITY) \
						else _resized_shape(entry.node.shape, normalize)
		if not current.is_equal_approx(entry.applied):
			entry.transform = Transform3D(current.basis, current.origin / _resize_ratio)
	for entry: Dictionary in _materials:
		if is_instance_valid(entry.node) and entry.node.material_override != entry.applied:
			entry.material = entry.node.material_override
	_restore_authored_layout()
	for entry: Dictionary in additions:
		entry.node.transform = _parent_transform(entry.node).affine_inverse() * entry.transform
		if entry.has("shape"):
			entry.node.shape = entry.shape
	_capture_layout()
	if keep_ratio:
		# The parts were edited: the object keeps its stretch on the axes where dimensions sets a size.
		var kept := _reference_dimensions * _resize_ratio
		for axis in 3:
			if dimensions[axis] <= 0.0:
				kept[axis] = 0.0
		_applying = true
		dimensions = kept
		_applying = false


func _restore_authored_layout() -> void:
	_applying = true
	for entry: Dictionary in _visuals:
		if is_instance_valid(entry.node):
			entry.node.transform = _parent_transform(entry.node).affine_inverse() * entry.transform
	for entry: Dictionary in _collisions:
		if is_instance_valid(entry.node):
			entry.node.shape = entry.shape
			entry.node.transform = _parent_transform(entry.node).affine_inverse() * entry.transform
	for entry: Dictionary in _materials:
		if is_instance_valid(entry.node):
			entry.node.material_override = entry.material
	_applying = false


func _watch_geometry() -> void:
	if not Engine.is_editor_hint():
		return
	for resource: Resource in _watched_geometry:
		var callback := Callable(self, "_on_geometry_changed").bind(resource)
		if resource.changed.is_connected(callback):
			resource.changed.disconnect(callback)
	_watched_geometry.clear()
	for entry: Dictionary in _materials:
		if is_instance_valid(entry.node):
			_watch_geometry_resource(entry.node.mesh)
	for entry: Dictionary in _collisions:
		if is_instance_valid(entry.node):
			_watch_geometry_resource(entry.shape)
			_watch_geometry_resource(entry.node.shape)


func _watch_geometry_resource(resource: Resource) -> void:
	var callback := Callable(self, "_on_geometry_changed").bind(resource)
	if resource != null and not resource.changed.is_connected(callback):
		resource.changed.connect(callback)
		_watched_geometry.append(resource)


func _on_geometry_changed(resource: Resource) -> void:
	if not _applying and not _saving:
		_changed_geometry[resource] = true


func _visual_branch(node: Node3D) -> Node3D:
	var branch := node
	while branch.get_parent() != self and branch.get_parent() is Node3D:
		var parent: Node3D = branch.get_parent()
		if parent is PhysicsBody3D or not parent.find_children("*", "CollisionShape3D", true, false).is_empty():
			break
		branch = parent
	return branch


func _apply_dimensions() -> void:
	if _reference_dimensions == Vector3.ZERO:
		return
	var ratio := _get_size() / _reference_dimensions
	if ratio.is_equal_approx(Vector3.ONE) and _resize_ratio.is_equal_approx(Vector3.ONE):
		return
	var resize := Transform3D(Basis.IDENTITY.scaled(ratio), Vector3.ZERO)
	_applying = true
	for entry: Dictionary in _visuals:
		var node: Node3D = entry.node
		if is_instance_valid(node):
			node.transform = _parent_transform(node).affine_inverse() * resize * entry.transform
			entry.applied = _relative_transform(node)
	for entry: Dictionary in _collisions:
		var node: CollisionShape3D = entry.node
		if not is_instance_valid(node):
			continue
		var original: Transform3D = entry.transform
		var local_resize := original.basis.inverse() * resize.basis * original.basis
		var unchanged: bool = entry.shape == null or local_resize.is_equal_approx(Basis.IDENTITY)
		node.shape = entry.shape if unchanged else _resized_shape(entry.shape, local_resize)
		node.transform = _parent_transform(node).affine_inverse() * Transform3D(original.basis, original.origin * ratio)
		entry.applied_shape = node.shape
		entry.applied = _relative_transform(node)
	_resize_ratio = ratio
	_applying = false


# The size the object is stretched to: dimensions, and the size of the parts on the axes where it is 0.
func _get_size() -> Vector3:
	var size := _reference_dimensions
	for axis in 3:
		if dimensions[axis] > 0.0:
			size[axis] = maxf(dimensions[axis], 0.01)
	return size


static func _resized_shape(original: Shape3D, resize: Basis) -> Shape3D:
	var shape := original.duplicate() as Shape3D
	var ratio := Vector3(resize.x.length(), resize.y.length(), resize.z.length())
	# Non-uniform resizing can shear a rotated primitive, or turn its round ends into ellipsoids.
	# Bake that transform into a convex hull instead of silently leaving a different physical volume.
	var off_diagonal := absf(resize.x.y) + absf(resize.x.z) + absf(resize.y.x) + absf(resize.y.z) \
			+ absf(resize.z.x) + absf(resize.z.y)
	var diagonal := off_diagonal < 0.00001
	var radial := is_equal_approx(ratio.x, ratio.z)
	var uniform := radial and is_equal_approx(ratio.x, ratio.y)
	if (shape is BoxShape3D and not diagonal) or (shape is CylinderShape3D and (not diagonal or not radial)) \
			or ((shape is CapsuleShape3D or shape is SphereShape3D) and (not diagonal or not uniform)):
		var points := PackedVector3Array()
		var debug_mesh := original.get_debug_mesh()
		for surface in debug_mesh.get_surface_count():
			var vertices: PackedVector3Array = debug_mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex: Vector3 in vertices:
				points.append(resize * vertex)
		var convex := ConvexPolygonShape3D.new()
		convex.points = points
		convex.margin = original.margin
		return convex
	if shape is BoxShape3D:
		shape.size = original.size * ratio
	elif shape is CylinderShape3D:
		shape.radius = original.radius * maxf(ratio.x, ratio.z)
		shape.height = original.height * ratio.y
	elif shape is CapsuleShape3D:
		shape.radius = original.radius * maxf(ratio.x, ratio.z)
		shape.height = maxf(original.height * ratio.y, shape.radius * 2.0)
	elif shape is SphereShape3D:
		shape.radius = original.radius * maxf(ratio.x, maxf(ratio.y, ratio.z))
	elif shape is ConvexPolygonShape3D:
		var points: PackedVector3Array = original.points.duplicate()
		for point_index in points.size():
			points[point_index] = resize * points[point_index]
		shape.points = points
	elif shape is ConcavePolygonShape3D:
		var faces: PackedVector3Array = original.get_faces()
		for face_index in faces.size():
			faces[face_index] = resize * faces[face_index]
		shape.set_faces(faces)
	return shape


func _apply_material() -> void:
	_applying = true
	for entry: Dictionary in _materials:
		if is_instance_valid(entry.node):
			entry.node.material_override = surface_material if surface_material != null else entry.material
			entry.applied = entry.node.material_override
	_applying = false


func _relative_transform(node: Node3D) -> Transform3D:
	var result := node.transform
	var parent := node.get_parent()
	while parent != null and parent != self:
		if parent is Node3D:
			result = parent.transform * result
		parent = parent.get_parent()
	return result


func _parent_transform(node: Node3D) -> Transform3D:
	var parent := node.get_parent()
	return _relative_transform(parent) if parent is Node3D and parent != self else Transform3D.IDENTITY


func _is_scaled() -> bool:
	return not transform.basis.get_scale().is_equal_approx(Vector3.ONE)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if dimensions.x < 0.0 or dimensions.y < 0.0 or dimensions.z < 0.0:
		warnings.append("Dimensions must not be negative: 0 keeps the size of the parts.")
	if _is_scaled():
		warnings.append("Resize the object with Dimensions, not with the scale of its root.")
	if find_children("*", "CollisionShape3D", true, false).is_empty():
		warnings.append("Add the object's collision shapes below its physics bodies.")
	return warnings
