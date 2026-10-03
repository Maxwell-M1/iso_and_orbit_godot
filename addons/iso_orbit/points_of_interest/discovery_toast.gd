class_name DiscoveryToast
extends Label
## A "Discovered: …" caption for a few seconds when the player finds a [PointOfInterest]. It finds the places
## at startup by the group [constant PointOfInterest.GROUP].

## How to write it: a format string with the place name. Both the string and the name are translated.
@export var text_format := "Discovered: %s"

## How long the caption stays, not counting fading in and out.
@export_range(0.5, 10.0, 0.1, "suffix:s") var show_time := 3.5

## How long it takes to fade in and to fade out.
@export_range(0.0, 2.0, 0.05, "suffix:s") var fade_time := 0.6

var _tween: Tween
var _title := ""


func _ready() -> void:
	# The text is composed of two translations; it cannot be translated as a whole.
	auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	modulate.a = 0.0
	for place: Node in get_tree().get_nodes_in_group(PointOfInterest.GROUP):
		(place as PointOfInterest).discovered.connect(show_discovery)


## Show the caption about the place [param title].
func show_discovery(title: String) -> void:
	_title = title
	_update_text()
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, fade_time)
	_tween.tween_interval(show_time)
	_tween.tween_property(self, "modulate:a", 0.0, fade_time)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and not _title.is_empty():
		_update_text()


func _update_text() -> void:
	text = tr(text_format) % tr(_title)
