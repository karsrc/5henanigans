extends CharacterBody2D

var direction: Vector2 = Vector2(1,1)
var speed: int = 100

func _physics_process(_delta: float):
	direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	animation()
	move_and_slide()
	
	if Input.is_action_just_pressed("confirm"):
		print ('something')
	
func animation():
	if direction:
		if direction.x > 0:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.frame = 0
