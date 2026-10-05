extends SceneTree
## Windowless checks of the demo: running and navigation, the world and the characters in it, the hero look, sprint and
## jump, what the character reports, stairs and slopes, mouse and keys, the camera and its arm, the settings window,
## interface languages, levels and the teleport. The check suites are [code]tests/*_checks.gd[/code] (the base is
## [code]tests/check_suite.gd[/code]); they run in the order of [constant SUITES] on the same main scene.
##
## Run from the project folder (saves nothing, exit code 1 on failure):
##   godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
## Only some suites: parts of their names after "--":
##   godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd -- camera input
##
## Any engine or script error during a check also counts as a failure: a crashed check is interrupted, but the
## others go on, and without this it would pass unnoticed. Only an error a check provokes on purpose and announces
## beforehand ([method expect_error]) does not count.

## The check suites in the order they run.
const SUITES := [
	preload("res://tests/movement_checks.gd"),
	preload("res://tests/world_checks.gd"),
	preload("res://tests/hero_look_checks.gd"),
	preload("res://tests/character_actions_checks.gd"),
	preload("res://tests/character_state_checks.gd"),
	preload("res://tests/input_checks.gd"),
	preload("res://tests/camera_checks.gd"),
	preload("res://tests/camera_arm_checks.gd"),
	preload("res://tests/settings_window_checks.gd"),
	preload("res://tests/localization_checks.gd"),
	preload("res://tests/level_checks.gd"),
]
const CheckSuite := preload("res://tests/check_suite.gd")
## If a check hangs (the script crashed before quit()), it ends in failure after this many seconds of game time. While a
## level loads in the background, the frames without a window run much faster than on a screen, and game time with them.
const TIMEOUT := 1200.0


## Counts engine and script errors, except the expected ones.
class ErrorCounter extends Logger:
	var errors := 0
	## Parts of the messages of the errors the checks expect: each one excuses one error.
	var expected: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		for part in expected:
			if part in code or part in rationale:
				expected.erase(part)
				return
		errors += 1

var _main: Node3D
var _failures := 0
var _summary := PackedStringArray()
var _errors := ErrorCounter.new()


func _initialize() -> void:
	OS.add_logger(_errors)
	create_timer(TIMEOUT).timeout.connect(_on_timeout)
	_run.call_deferred()


func _run() -> void:
	# Ignore the player's settings and never save them: the check runs on the default values.
	# The check script is compiled before the autoload names appear, so take the node from the tree.
	var settings: GameSettings = root.get_node(^"Settings")
	settings.persistent = false
	settings.reset_to_defaults()
	_main = load("res://gdscript/main.tscn").instantiate()
	root.add_child(_main)
	print("viewport: ", root.get_visible_rect().size, " interpolation: ", physics_interpolation)
	for i in 10:
		await physics_frame

	var filters := OS.get_cmdline_user_args()
	for script: GDScript in SUITES:
		var suite_name := script.resource_path.get_file().get_basename()
		if not filters.is_empty() and not Array(filters).any(func(part: String) -> bool: return part in suite_name):
			continue
		print("\n######## %s" % suite_name)
		var suite: CheckSuite = script.new()
		suite.setup(self, _main)
		await suite.run_checks()
		_failures += suite.failures
		_summary.append("%-28s ok %3d, failed %d" % [suite_name, suite.passed, suite.failures])

	await _finish()


func _finish() -> void:
	OS.remove_logger(_errors)
	print("\n" + "\n".join(_summary))
	print("engine and script errors: %d" % _errors.errors)
	_failures += _errors.errors
	print("FAILURES: %d" % _failures)
	# Sounds that are still playing hold playbacks in the audio server. If we quit at once, the engine reports
	# "leaked" AudioStreamPlayback objects on exit (whether there are any depends on the audio thread). So first remove
	# the scene: the players stop, and the audio thread has time to release them.
	if _main != null:
		_main.queue_free()
		await process_frame
		OS.delay_msec(100)
		await process_frame
	quit(1 if _failures > 0 else 0)


## A check is about to provoke an error whose message contains [param part]: it does not count as a failure. The
## check reads [method take_expected_errors] afterwards to see that it came.
func expect_error(part: String) -> void:
	_errors.expected.append(part)


## The expected errors that have not come; from now on they are not expected.
func take_expected_errors() -> Array[String]:
	var left := _errors.expected.duplicate()
	_errors.expected.clear()
	return left


## How many engine and script errors have come so far, except the expected ones: a check compares the count before and
## after what it does.
func get_error_count() -> int:
	return _errors.errors


func _on_timeout() -> void:
	print("\nTIMEOUT: the check did not finish in %d s of game time" % TIMEOUT)
	_failures += 1
	await _finish()
