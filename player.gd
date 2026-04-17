extends CharacterBody2D

@onready var crosshair = $Crosshair
@onready var aim_pivot = $AimPivot
@onready var aim_spirte = $AimPivot/AimSprite
@onready var attack_area = $AimPivot/AttackArea

var direction: Vector2 = Vector2(1,1)
var speed: int = 280
var max_hp: int = 100
var current_hp: int = 100

var is_attacking: bool = false
var current_combo: int = 0
var combo_target: Node2D = null
var time_since_last_hit: float = 0
var combo_drop_time: float = 1

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	crosshair.z_index = 1000
	current_hp = max_hp

func _physics_process(_delta: float):
	crosshair.global_position = get_global_mouse_position()
	var mouse_pos = get_global_mouse_position()
	aim_pivot.look_at(mouse_pos)
	if current_combo > 0 and not is_attacking:
		time_since_last_hit += _delta
		if time_since_last_hit >= combo_drop_time:
			current_combo = 0
			combo_target = null
			print("Combo Failed. Back to 0")
	if Input.is_action_just_pressed("attack") and not is_attacking:
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
	is_attacking = true
	time_since_last_hit = 0
	var hit_enemy = false
	var overlapping_bodies = attack_area.get_overlapping_bodies()
	print("sektor: ", overlapping_bodies.size(), " things.")
	for body in overlapping_bodies:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			hit_enemy = true
			if combo_target == body:
				current_combo += 1
			else:
				combo_target = body
				current_combo = 1
			print("Target hit. Combo is now: ", current_combo)
			body.take_damage(10)
			break 
	if not hit_enemy:
		current_combo = 0
		combo_target = null
	await get_tree().create_timer(0.3, false, false, true).timeout
	is_attacking = false 
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
func trigger_hit_stop():
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.1, true, false, true).timeout
	Engine.time_scale = 1
