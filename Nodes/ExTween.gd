extends Tween
class_name ExTween

signal tween_all_stopped()
signal tween_all_completed_or_stopped()

func _init() -> void:
	connect("tween_all_completed", self, "emit_signal", ["tween_all_completed_or_stopped"])

func stop_all():
	if is_active():
		.stop_all()
		emit_signal("tween_all_stopped")
		emit_signal("tween_all_completed_or_stopped")
