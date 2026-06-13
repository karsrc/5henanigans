extends AnimatedSprite2D

func _ready():
	pause()
	if sprite_frames and sprite_frames.has_animation("default"):
		frame = randi() % sprite_frames.get_frame_count("default")
	rotation_degrees = randf_range(0, 360)
	flip_h = randf() > 0.5
	flip_v = randf() > 0.5
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	fade_tween.finished.connect(queue_free)
