extends CharacterBody2D

var direction: Vector2 = Vector2(1,1)
var speed: int = 300

func _physics_process(_delta: float):
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	update_animation()
	move_and_slide()
	
func update_animation():
	if direction != Vector2.ZERO:
		if direction.y < 0:
			$AnimatedSprite2D.play("up") 
		elif direction.y > 0:
			$AnimatedSprite2D.play("down")
		elif direction.x != 0:
			$AnimatedSprite2D.play("left")
			
			if direction.x > 0:
				$AnimatedSprite2D.flip_h = true
			elif direction.x < 0:
				$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.frame = 0
