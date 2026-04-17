extends CharacterBody2D

@onready var crosshair = $Crosshair
@onready var aim_pivot = $AimPivot
@onready var aim_spirte = $AimPivot/AimSprite
@onready var attack_area = $AimPivot/AttackArea

var direction: Vector2 = Vector2(1,1)
var speed: int = 280
var max_hp: int = 100
var current_hp: int = 100

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	crosshair.z_index = 1000
	current_hp = max_hp

func _physics_process(_delta: float):
	crosshair.global_position = get_global_mouse_position()
	var mouse_pos = get_global_mouse_position()
	aim_pivot.look_at(mouse_pos)
	if Input.is_action_just_pressed("attack"):
		perform_punch()
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	update_animation()
	move_and_slide()
	
func die():
	print("GG Game over!")
	get_tree().reload_current_scene()
	
func take_damage(damage_amount: int):
		current_hp -= damage_amount
		print("Player got hit, current hp:", current_hp)
		if current_hp <= 0:
			die()

func perform_punch():
	var overlapping_bodies = attack_area.get_overlapping_bodies()
	print("sektor: ", overlapping_bodies.size(), " things.")
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
