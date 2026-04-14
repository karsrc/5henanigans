extends CharacterBody2D

var speed: int = 150

func _physics_process(delta: float):
	move_and_slide()
