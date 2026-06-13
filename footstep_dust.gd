extends AnimatedSprite2D

func _ready():
	pause()
	
	frame = randi() % sprite_frames.get_frame_count("default")
	
	flip_h = randf() > 0.5
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.1)
	fade_tween.finished.connect(queue_free)
