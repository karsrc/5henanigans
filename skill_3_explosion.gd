extends AnimatedSprite2D

func _ready():
	set_as_top_level(true)
	
	play("default")
	animation_finished.connect(queue_free)
