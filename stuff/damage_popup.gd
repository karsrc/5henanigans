extends Marker2D

@onready var label = $Label

func setup(amount: int, is_crit: bool = false):
	label.text = str(amount)
	
	if is_crit:
		label.modulate = Color(1, 0.2, 0.2)
		label.scale = Vector2(1.5, 1.5)
		var random_x = randf_range(-30, 30)
		var target_pos = position + Vector2(random_x, -50)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "position", target_pos, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate", 0, 0.4).set_delay(0.2)
		await tween.finished
		queue_free()
