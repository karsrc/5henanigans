extends CPUParticles2D

@onready var audio = $AudioStreamPlayer2D

func _ready():
	emitting = true
	audio.play()
	await get_tree().create_timer(lifetime, false, false, true).timeout
	queue_free()
