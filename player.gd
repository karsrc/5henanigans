extends CharacterBody2D

@onready var crosshair = $Crosshair
@onready var aim_pivot = $AimPivot
@onready var aim_spirte = $AimPivot/AimSprite
@onready var attack_area = $AimPivot/AttackArea
@onready var health_bar = $CanvasLayer/ProgressBar

var direction: Vector2 = Vector2(1,1)
var speed: int = 280
var max_hp: int = 160
var current_hp: int = 160
var is_attacking: bool = false
var current_combo: int = 0
var combo_target: Node2D = null
var time_since_last_hit: float = 0
var combo_drop_time: float = 1
var is_invincible: bool = false
var is_using_skill: bool = false

# Skill 1
var barrage_duration: float = 2.0
var barrage_hits: int = 30
var barrage_damage: int = 8
var is_barraging: bool = false
var barrage_cooldown: float = 9.0
var current_barrage_cooldown: float = 0.0

# Skill 2
var divergent_cooldown: float = 8.0
var current_divergent_cooldown: float = 0.0
var is_sprinting: bool = false
var qte_in_progress: bool = false
var black_flash_triggered: bool = false
var is_in_zone: bool = false
var is_cursed_enhanced: bool = false

# Skill 3
var leap_speed: int = 1050
var leap_duration: float = 0.4
var leap_damage: int = 30
var leap_cooldown: float = 10.0
var current_leap_cooldown: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	crosshair.z_index = 1000
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp

func _physics_process(_delta: float):
	crosshair.global_position = get_global_mouse_position()
	aim_pivot.look_at(get_global_mouse_position())
	
	# Tick cooldowns
	if current_leap_cooldown > 0: current_leap_cooldown -= _delta
	if current_barrage_cooldown > 0: current_barrage_cooldown -= _delta
	if current_divergent_cooldown > 0: current_divergent_cooldown -= _delta
	
	# Skill 2 inoput
	if Input.is_action_just_pressed("skill_2"):
			toggle_cursed_stance()
			return
	
	if not is_using_skill:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = direction * speed
		
		if Input.is_action_just_pressed("skill_1"):
			if current_barrage_cooldown <= 0:
				perform_barrage()
				return
				
		if Input.is_action_just_pressed("skill_2"):
			toggle_cursed_stance()
			return
		
		if Input.is_action_just_pressed("skill_3"):
			if current_leap_cooldown <= 0:
				perform_leap()
				return
		
		# Combo Drop Timer
		if current_combo > 0 and not is_attacking:
			time_since_last_hit += _delta
			if time_since_last_hit >= combo_drop_time:
				current_combo = 0
				combo_target = null
		if Input.is_action_pressed("attack") and not is_attacking:
			perform_punch()
			
	if is_barraging:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = direction * (speed * 0.6) 
	
	update_animation()
	move_and_slide()

func die():
	get_tree().reload_current_scene()
	
func take_damage(damage_amount: int) -> void:
	if is_using_skill or is_invincible:
		return
		
	current_hp -= damage_amount
	health_bar.value = current_hp
	
	if current_hp <= 0:
		die()
	else:
		is_invincible = true
		$AnimatedSprite2D.modulate = Color(1, 0, 0, 0.5) 
		await get_tree().create_timer(0.5, false, false, true).timeout
		$AnimatedSprite2D.modulate = Color(1, 1, 1, 1) if not is_in_zone else Color(0.8, 0.2, 0.2)
		is_invincible = false

func shake_camera(intensity: float):
	var camera = $Camera2D
	if camera:
		camera.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		var tween = get_tree().create_tween()
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

func perform_punch():
	is_attacking = true
	time_since_last_hit = 0
	var hit_enemy = false
	var overlapping_bodies = attack_area.get_overlapping_bodies()
	
	var attack_recovery = 0.45 if is_cursed_enhanced else 0.3
	
	for body in overlapping_bodies:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			hit_enemy = true
			if combo_target == body: current_combo += 1
			else:
				combo_target = body
				current_combo = 1
			
			if is_cursed_enhanced:
				body.take_damage(25) 
				var shove_dir = global_position.direction_to(body.global_position)
				body.global_position += shove_dir * 18 
			else:
				body.take_damage(10)
			break 
			
	if not hit_enemy:
		current_combo = 0
		combo_target = null
	await get_tree().create_timer(attack_recovery, false, false, true).timeout
	is_attacking = false 

func update_animation():
	if is_barraging:
		$AnimatedSprite2D.play("left") 
		if get_global_mouse_position().x > global_position.x: $AnimatedSprite2D.flip_h = true
		else: $AnimatedSprite2D.flip_h = false
	else:
		if direction != Vector2.ZERO:
			if direction.y < 0: $AnimatedSprite2D.play("up") 
			elif direction.y > 0: $AnimatedSprite2D.play("down")
			elif direction.x != 0:
				$AnimatedSprite2D.play("left")
				if direction.x > 0: $AnimatedSprite2D.flip_h = true
				elif direction.x < 0: $AnimatedSprite2D.flip_h = false
		else:
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.frame = 0

func trigger_hit_stop():
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.1, true, false, true).timeout
	Engine.time_scale = 1
func perform_barrage():
	is_using_skill = true
	is_barraging = true
	is_attacking = false
	current_combo = 0
	combo_target = null
	current_barrage_cooldown = barrage_cooldown
	
	var punch_delay = barrage_duration / float(barrage_hits)
	
	for i in range(barrage_hits):
		aim_spirte.modulate = Color(1.0, 0.0, 0.0, 0.8) 
		await get_tree().physics_frame
		
		var overlapping_bodies = attack_area.get_overlapping_bodies()
		var enemies_in_range = 0 
		
		for body in overlapping_bodies:
			if body.is_in_group("enemy") and body.has_method("take_damage"):
				enemies_in_range += 1
				body.take_damage(barrage_damage)
				
				if body.has_method("stun"): body.stun(0.4) 
				
				if i == barrage_hits - 1:
					trigger_hit_stop()
					shake_camera(15)
					var shove_direction = global_position.direction_to(body.global_position)
					var target_position = body.global_position + (shove_direction * 150)
					var knockback_tween = get_tree().create_tween()
					knockback_tween.tween_property(body, "global_position", target_position, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
				else:
					if global_position.distance_to(body.global_position) > 40: 
						var pull_direction = body.global_position.direction_to(global_position)
						body.global_position += pull_direction * 6
						
		if enemies_in_range == 0: break 
			
		var tween = get_tree().create_tween()
		tween.tween_property(aim_spirte, "modulate", Color(1.0, 1.0, 1.0, 0.1), punch_delay - 0.05)
		await get_tree().create_timer(punch_delay).timeout
		
	aim_spirte.modulate = Color(1.0, 1.0, 1.0, 1.0) 
	is_using_skill = false
	is_barraging = false
func perform_divergent_sprint():
	is_using_skill = true
	is_sprinting = true
	qte_in_progress = false
	black_flash_triggered = false
	current_divergent_cooldown = divergent_cooldown
	
	var dash_dir = global_position.direction_to(get_global_mouse_position())
	velocity = dash_dir * (speed * 2.5) 
	
	var time_passed = 0.0
	while time_passed < 0.4 and is_sprinting:
		await get_tree().physics_frame
		time_passed += get_physics_process_delta_time()
		
		for body in attack_area.get_overlapping_bodies():
			if body.is_in_group("enemy") and body.has_method("take_damage"):
				# --- 1. THE KINETIC IMPACT ---
				is_sprinting = false
				velocity = Vector2.ZERO 
				
				qte_in_progress = true # Open the recast window
				
				# --- 2. THE HIT-STOP CUE ---
				Engine.time_scale = 0.05 
				$AnimatedSprite2D.modulate = Color(10, 10, 10) 
				shake_camera(8.0) 
				
				# --- 3. THE SWEET SPOT (0.2s Window) ---
				await get_tree().create_timer(0.2, true, false, true).timeout 
				
				# --- 4. RESUME TIME ---
				qte_in_progress = false
				Engine.time_scale = 1.0
				$AnimatedSprite2D.modulate = Color(1, 1, 1) if not is_in_zone else Color(0.8, 0.2, 0.2)
				
				# --- 5. THE OUTCOME ---
				if black_flash_triggered: execute_black_flash(body)
				else: execute_divergent_fist(body)
				return 
				
	velocity = Vector2.ZERO
	is_using_skill = false
	is_sprinting = false
func execute_divergent_fist(target: Node2D):
	target.take_damage(10) 
	is_using_skill = false 
	
	await get_tree().create_timer(0.5, false, false, true).timeout
	
	if is_instance_valid(target):
		trigger_hit_stop()
		shake_camera(10.0)
		target.take_damage(20) 
		
		var all_enemies = get_tree().get_nodes_in_group("enemy")
		for enemy in all_enemies:
			if is_instance_valid(enemy) and enemy != target:
				if target.global_position.distance_to(enemy.global_position) < 65:
					var shove_dir = target.global_position.direction_to(enemy.global_position)
					if shove_dir == Vector2.ZERO: shove_dir = Vector2.RIGHT
					enemy.global_position += shove_dir * 50

func execute_black_flash(target: Node2D):
	is_using_skill = false
	$AnimatedSprite2D.modulate = Color(-1, -0.5, -0.5) 
	trigger_hit_stop() 
	shake_camera(25.0)
	
	target.take_damage(60) 
	current_divergent_cooldown = 0.0 
	
	if not is_in_zone: enter_the_zone()

func enter_the_zone():
	is_in_zone = true
	$AnimatedSprite2D.modulate = Color(0.8, 0.2, 0.2) 
	await get_tree().create_timer(7.0, false, false, true).timeout
	is_in_zone = false
	$AnimatedSprite2D.modulate = Color(1, 1, 1) 

func perform_leap() -> void:
	is_using_skill = true
	is_attacking = false
	current_combo = 0
	combo_target = null
	
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.2, false, false, true).timeout 
	
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in all_enemies:
		add_collision_exception_with(enemy)
	
	var dash_direction = global_position.direction_to(get_global_mouse_position())
	velocity = dash_direction * leap_speed
	current_leap_cooldown = leap_cooldown
	
	var dash_time_passed = 0.0
	var enemies_hit = []
	var hit_someone = false
	
	while dash_time_passed < leap_duration:
		await get_tree().physics_frame
		dash_time_passed += get_physics_process_delta_time()
		
		for body in attack_area.get_overlapping_bodies():
			if body.is_in_group("enemy") and body.has_method("take_damage"):
				if not enemies_hit.has(body):
					body.take_damage(leap_damage)
					if body.has_method("stun"): body.stun(1.5)
					enemies_hit.append(body)
					hit_someone = true 
					
	velocity = Vector2.ZERO
	
	all_enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in all_enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < 80:
			if enemy.has_method("take_damage") and not enemies_hit.has(enemy):
				enemy.take_damage(25) 
			if enemy.has_method("stun"): enemy.stun(1.5)
			hit_someone = true
			
		if distance < 40:
			var shove_direction = global_position.direction_to(enemy.global_position)
			if shove_direction == Vector2.ZERO: shove_direction = Vector2(1, 0)
			enemy.global_position += shove_direction * 45
	
	if hit_someone:
		trigger_hit_stop()
		shake_camera(20.0) 
		
	for enemy in all_enemies:
		remove_collision_exception_with(enemy)
	
	is_using_skill = false

func toggle_cursed_stance():
	is_using_skill = true
	velocity = Vector2.ZERO
	current_combo = 0
	is_cursed_enhanced = !is_cursed_enhanced

	await get_tree().create_timer(0.4, false, false, true).timeout
	is_using_skill = false
