extends CharacterBody2D

@onready var aim_pivot = $AimPivot
@onready var aim_spirte = $AimPivot/AimSprite
@onready var attack_area = $AimPivot/AttackArea


var direction: Vector2 = Vector2(1,1)
var speed: int = 280

func _physics_process(_delta: float):
	
	var mouse_pos = get_global_mouse_position()
	aim_pivot.look_at(mouse_pos)
	
	if Input.is_action_just_pressed("attack"):
		perform_punch()
		
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	update_animation()
	move_and_slide()
	
func perform_punch():
	var overlapping_bodies = attack_area.get_overlapping_bodies()
	
	for body in overlapping_bodies:
		if body.is_in_group("enemy"):
			if body.has_method("take_damage"):
				body.take_damage(10)
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
