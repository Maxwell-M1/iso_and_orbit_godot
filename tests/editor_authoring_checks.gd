extends "res://tests/check_suite.gd"
## Regression checks for scene contracts and the start level.


func _checks() -> Array[Callable]:
	return [_check_contracts, _check_initial_level]


func _check_contracts() -> void:
	print("\n== missing scene requirements produce configuration warnings")
	var mover := NavigationMover.new()
	_expect(not mover._get_configuration_warnings().is_empty(), "an orphan mover warns about its required parent")
	var body := Node3D.new()
	body.add_child(mover)
	_expect(mover._get_configuration_warnings().is_empty(), "a valid mover hierarchy clears the warning")
	body.free()


func _check_initial_level() -> void:
	print("\n== the start level: Initial Level, or else the first 3D child")
	var host := LevelHost.new()
	var marker := Marker3D.new()
	var level := Node3D.new()
	host.add_child(marker)
	host.add_child(level)
	host.initial_level = level
	_tree.root.add_child(host)
	_expect(host.get_current_level() == level, "a helper placed before the level cannot become the initial level")
	host.free()
	host = LevelHost.new()
	level = Node3D.new()
	host.add_child(level)
	_tree.root.add_child(host)
	_expect(host.get_current_level() == level, "without Initial Level the host's only 3D child is the start level")
	host.free()
	host = LevelHost.new()
	level = Node3D.new()
	host.add_child(level)
	_expect(host._get_configuration_warnings().is_empty(), "a host with one 3D child needs no Initial Level")
	host.add_child(Marker3D.new())
	_expect(not host._get_configuration_warnings().is_empty(),
		"with several 3D children the host asks for Initial Level")
	host.initial_level = level
	_expect(host._get_configuration_warnings().is_empty(), "assigning the direct child clears the warning")
	host.free()
