extends "res://tests/check_suite.gd"
## Regression checks for scene contracts.


func _checks() -> Array[Callable]:
	return [_check_contracts]


func _check_contracts() -> void:
	print("\n== missing scene requirements produce configuration warnings")
	var mover := NavigationMover.new()
	_expect(not mover._get_configuration_warnings().is_empty(), "an orphan mover warns about its required parent")
	var body := Node3D.new()
	body.add_child(mover)
	_expect(mover._get_configuration_warnings().is_empty(), "a valid mover hierarchy clears the warning")
	body.free()
