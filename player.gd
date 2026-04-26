extends CharacterBody2D

@onready var crosshair = $Crosshair
@onready var aim_pivot = $AimPivot
@onready var aim_spirte = $AimPivot/AimSprite
@onready var attack_area = $AimPivot/AttackArea
@onready var health_bar = $CanvasLayer/ProgressBar
@onready var awakening_bar = $CanvasLayer/AwakeningBar

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
var is_blocking: bool = false
var is_dashing: bool = false
var dash_speed: int = 700
var dash_cooldown: float = 1.2
var current_dash_cooldown: float = 0
var has_hit_this_punch: bool = false

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
var leap_speed: int = 400
var leap_duration: float = 1
var leap_damage: int = 30
var leap_cooldown: float = 10.0
var current_leap_cooldown: float = 0.0
var is_leaping: bool = false

# Special
var manji_cooldown: float = 5
var current_manji_cooldown: float = 0
var is_countering: bool = false
var manji_damage: int = 25



# Ultimate
var is_sukuna: bool = false
var is_domain_active: bool = false
var domain_tick_timer: float = 0
var ult_duration: float = 15
var dismantle_cooldown: float = 0
var base_speed: int = 300
var max_ult_charge: int = 2000
var current_ult_charge: int = 0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	crosshair.z_index = 1000
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	awakening_bar.max_value = max_ult_charge
	awakening_bar.value = current_ult_charge
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	$AimPivot/AimSprite.hide()

func _physics_process(_delta: float):
	crosshair.global_position = get_global_mouse_position()
	if not is_attacking and not is_barraging and not is_leaping:
		aim_pivot.look_at(get_global_mouse_position())
	
	# --- TICK COOLDOWNS ---
	if dismantle_cooldown > 0: dismantle_cooldown -= _delta
	if current_leap_cooldown > 0: current_leap_cooldown -= _delta
	if current_barrage_cooldown > 0: current_barrage_cooldown -= _delta
	if current_dash_cooldown > 0: current_dash_cooldown -= _delta
	if current_manji_cooldown > 0: current_manji_cooldown -= _delta
	
	if Input.is_key_pressed(KEY_9):
		add_ult_charge(max_ult_charge)
		
	# SUKUNA LOGIC
	if is_sukuna:
		if is_domain_active:
			domain_tick_timer += _delta
			if domain_tick_timer >= 1.0:
				domain_tick_timer = 0.0
				shake_camera(5)
				var all_enemies = get_tree().get_nodes_in_group("enemy")
				for enemy in all_enemies:
					if is_instance_valid(enemy) and enemy.has_method("take_damage"):
						enemy.take_damage(15)
						
			if Input.is_action_just_pressed("skill_2"):
				fire_fuga()
				return
				
		else:
			direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			velocity = direction * speed
			
			if Input.is_action_pressed("attack") and dismantle_cooldown <= 0:
				dismantle_cooldown = 0.15
				fire_sukuna_slash(false)
				
			if Input.is_action_just_pressed("skill_1"):
				fire_sukuna_slash(true)
				
			if Input.is_action_just_pressed("skill_3"):
				activate_domain_expansion()
				
		update_animation()
		move_and_slide()
		return
		
	# NORMAL YUJI LOGIC

	if Input.is_action_just_pressed("skill_2"):
		toggle_cursed_stance()
		return
		
	if Input.is_key_pressed(KEY_R):
		if current_manji_cooldown <= 0:
			enter_manji_stance()
			return
			
	if not is_using_skill:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		if is_attacking:
			velocity = direction * (speed * 0.3)
			$AnimatedSprite2D.flip_h =  get_global_mouse_position().x < global_position.x
		elif Input.is_key_pressed(KEY_F):
			is_blocking = true
			velocity = direction * (speed * 0.3)
		else:
			is_blocking = false
			velocity = direction * speed
		if Input.is_key_pressed(KEY_SPACE) and current_dash_cooldown <= 0:
			perform_dash()
			return 
			
		if Input.is_action_just_pressed("skill_1") and current_barrage_cooldown <= 0:
			perform_barrage()
			return
			
		if Input.is_action_just_pressed("skill_3") and current_leap_cooldown <= 0:
			perform_leap()
			return
			
		if Input.is_action_just_pressed("skill_4") and current_ult_charge >= max_ult_charge:
			transform_sukuna()
			return
			
		if current_combo > 0 and not is_attacking:
			time_since_last_hit += _delta
			if time_since_last_hit >= 0.3: 
				current_combo = 0
				combo_target = null
				
		if Input.is_action_pressed("attack") and not is_attacking:
			perform_punch()
			
	if is_barraging:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = direction * (speed * 0.6) 
	if is_leaping and ($AnimatedSprite2D.animation == "knife-stance" or $AnimatedSprite2D.animation == "knife-leap-land"):
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = direction * (speed * 0.2)
		$AnimatedSprite2D.flip_h = get_global_mouse_position().x < global_position.x
		
	update_animation()
	move_and_slide()
func die():
	get_tree().reload_current_scene()
	
func take_damage(damage_amount: int) -> void:
	if is_countering:
		is_countering = false
		trigger_manji_counter()
		return
	
	if is_using_skill or is_invincible:
		return
	if is_blocking:
		damage_amount = int(damage_amount * 0.2)
		shake_camera(3)
		
	current_hp -= damage_amount
	health_bar.value = current_hp
	
	if current_hp <= 0:
		die()
	else:
		var flash_tween = get_tree().create_tween()
		flash_tween.set_loops(5)
		flash_tween.tween_property($AnimatedSprite2D, "modulate", Color(5, 5, 5, 0.4), 0.05)
		flash_tween.tween_property($AnimatedSprite2D, "modulate", Color(1,1,1,1), 0.05)
		await get_tree().create_timer(0.5, false, false, true).timeout
		flash_tween.kill()
		$AnimatedSprite2D.modulate = Color(1,1,1,1)
		is_invincible = false

func perform_dash():
	is_using_skill = true 
	is_dashing = true 
	is_invincible = true
	current_dash_cooldown = dash_cooldown
	
	var dash_dir = direction
	if dash_dir == Vector2.ZERO:
		dash_dir = global_position.direction_to(get_global_mouse_position())
		
	velocity = dash_dir.normalized() * dash_speed
	
	var anim_name = "dash-up" if dash_dir.y < 0 else "dash"
	if is_cursed_enhanced:
		anim_name += "_ce"
		
	$AnimatedSprite2D.play(anim_name)
	$AnimatedSprite2D.flip_h = dash_dir.x < 0
	
	await $AnimatedSprite2D.animation_finished 
	
	velocity = Vector2.ZERO 
	is_using_skill = false
	is_dashing = false 
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
	has_hit_this_punch = false
	
	current_combo += 1
	if current_combo > 3:
		current_combo = 1
		
	var mouse_pos = get_global_mouse_position()
	var facing_front = mouse_pos.y > global_position.y
	var suffix = "-front" if facing_front else ""
	
	var anim_to_play = "m1"
	if current_combo == 1:
		anim_to_play = "m1-1-front" if facing_front else "m1"
	elif current_combo == 2:
		anim_to_play = "m1-2" + suffix
	elif current_combo == 3:
		anim_to_play = "m1-3" + suffix
		
	if is_cursed_enhanced:
		anim_to_play += "_ce"
		
	$AnimatedSprite2D.play(anim_to_play)
	$AnimatedSprite2D.flip_h = mouse_pos.x < global_position.x
	
	$AimPivot/AimSprite.show() 
	
	if current_combo == 1 or current_combo == 3:
		$AimPivot/AimSprite.play("swipe1")
		$AimPivot/AimSprite.flip_v = false
	elif current_combo == 2:
		$AimPivot/AimSprite.play("swipe2")
		$AimPivot/AimSprite.flip_v = true

func update_animation():
	if is_attacking or is_leaping or is_barraging or is_dashing:
		return
		
	var anim_name = "idle"
	var flip = false
	var mouse_pos = get_global_mouse_position()
	
	if is_blocking:
		anim_name = "block" 
		flip = mouse_pos.x < global_position.x
	elif is_countering:
		anim_name = "manji-stance"
		flip = mouse_pos.x < global_position.x
		
	elif direction != Vector2.ZERO:
		if direction.y < 0:
			anim_name = "up-run"
		else:
			anim_name = "right-run" 
			flip = direction.x < 0 if direction.x != 0 else false
			
	else:
		if direction.y < 0: anim_name = "up" 
		else: anim_name = "right" 
		
	if $AnimatedSprite2D.animation != anim_name:
		$AnimatedSprite2D.play(anim_name)
		
	$AnimatedSprite2D.flip_h = flip

func _on_frame_changed():
	if not is_attacking: return
	var anim = $AnimatedSprite2D.animation
	var frame = $AnimatedSprite2D.frame
	if (anim == "m1" or anim == "m1-1-front" or anim == "m1-2" or anim == "m1-2-front") and frame == 2:
		execute_hitbox()
		
func execute_hitbox():
	var hit_enemy = false
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	
	var locked_aim_direction = Vector2.RIGHT.rotated(aim_pivot.rotation)
	
	for enemy in all_enemies:
		if not is_instance_valid(enemy): continue
		
		var distance = global_position.distance_to(enemy.global_position)
		var dir_to_enemy = global_position.direction_to(enemy.global_position)
		
		var is_in_front = locked_aim_direction.dot(dir_to_enemy) > 0.3 
		
		if attack_area.overlaps_body(enemy) or (distance <= 45 and is_in_front):
			
			if enemy.has_method("take_damage"):
				hit_enemy = true
				var knockback_distance = 6
				if current_combo == 2:
					knockback_distance = 12
				elif current_combo >= 3:
					knockback_distance = 22
				if is_cursed_enhanced:
					knockback_distance += 6
				
				var shove_dir = global_position.direction_to(enemy.global_position)
				enemy.global_position += shove_dir * knockback_distance
				
				if is_cursed_enhanced:
					enemy.take_damage(25) 
					add_ult_charge(25)
				else:
					enemy.take_damage(10)
					add_ult_charge(10)
				if enemy.has_method("apply_slow"):
					enemy.apply_slow()
					
	if hit_enemy:
		Engine.time_scale = 0.2
		await get_tree().create_timer(0.02, true, false, true).timeout
		Engine.time_scale = 1.0

func _on_animation_finished():
	var anim = $AnimatedSprite2D.animation
	if anim.begins_with("m1"):
		is_attacking = false
		$AimPivot/AimSprite.hide()

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
				add_ult_charge(barrage_damage)
				
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

func enter_manji_stance():
	is_using_skill = true
	velocity = Vector2.ZERO
	current_combo = 0
	current_manji_cooldown = manji_cooldown
	is_countering = true
	$AnimatedSprite2D.modulate = Color(0.6, 0.8, 1)
	await get_tree().create_timer(0.4, false, false, true).timeout
	
	if is_countering:
		is_countering = false
		is_using_skill = false
		$AnimatedSprite2D.modulate = Color(1,1,1,1)

func trigger_manji_counter():
	is_invincible = true
	$AnimatedSprite2D.modulate = Color(1,1,11)
	trigger_hit_stop()
	shake_camera(15)
	var final_damage = manji_damage
	if is_cursed_enhanced: final_damage = manji_damage * 2
	
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			if global_position.distance_to(enemy.global_position) <= 85:
				if enemy.has_method("take_damage"):
					enemy.take_damage(final_damage)
					add_ult_charge(final_damage *2)
				if enemy.has_method("stun"): enemy.stun(1)
				
				var shove_dir = global_position.direction_to(enemy.global_position)
				if shove_dir == Vector2.ZERO: shove_dir = Vector2.RIGHT
				enemy.global_position += shove_dir * 50
	await get_tree().create_timer(0.3, false, false, true).timeout
	is_invincible = false
	is_using_skill = false

func perform_leap() -> void:
	is_using_skill = true
	is_attacking = false
	current_combo = 0
	combo_target = null
	is_leaping = true
	
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("knife-stance")
	await $AnimatedSprite2D.animation_finished 
	
	$AnimatedSprite2D.play("knife-leap")
	
	
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
					add_ult_charge(leap_damage)
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
				add_ult_charge(25)
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
		
	$AnimatedSprite2D.play("knife-leap-land")
	await $AnimatedSprite2D.animation_finished 
		
	is_leaping = false
	is_using_skill = false

func toggle_cursed_stance():
	is_using_skill = true
	velocity = Vector2.ZERO
	current_combo = 0
	is_cursed_enhanced = !is_cursed_enhanced

	await get_tree().create_timer(0.4, false, false, true).timeout
	is_using_skill = false

func transform_sukuna():
	is_using_skill = true
	velocity = Vector2.ZERO
	current_ult_charge = 0
	awakening_bar.value = 0
	is_sukuna = true
	Engine.time_scale = 0.05
	shake_camera(25)
	current_hp = max_hp
	health_bar.value = current_hp
	await get_tree().create_timer(0.05, true, false, true).timeout
	Engine.time_scale = 1
	is_using_skill = false
	await get_tree().create_timer(ult_duration, false, false, true).timeout
	end_sukuna()
	
func end_sukuna():
	if not is_sukuna: return
	is_sukuna = false
	is_domain_active = false
	speed = base_speed
	var shrine = get_node_or_null("MalevolentShrineVisual")
	if shrine:
		shrine.queue_free()

func fire_sukuna_slash(is_heavy: bool):
	is_attacking = true
	
	var proj = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	shape.size = Vector2(100, 100) if is_heavy else Vector2(20, 60)
	collision.shape = shape
	proj.add_child(collision)
	
	#TEXTURE NEEDED here
	var sprite = Sprite2D.new()
	sprite.name = "Texture"
	proj.add_child(sprite)
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	var dir = global_position.direction_to(get_global_mouse_position())
	proj.rotation = dir.angle()
	
	proj.body_entered.connect(func(body):
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(100 if is_heavy else 15)
			var shove = dir * (150 if is_heavy else 20)
			body.global_position += shove
	) 
	var travel_distance = dir * (800 if is_heavy else 400)
	var tween = get_tree().create_tween()
	tween.tween_property(proj, "global_position", proj.global_position + travel_distance, 0.2)
	tween.tween_callback(proj.queue_free)

func activate_domain_expansion():
	if is_domain_active: return
	is_domain_active = true
	is_using_skill = true
	velocity = Vector2.ZERO
	domain_tick_timer = 0
	Engine.time_scale = 0.05
	shake_camera(20)
	
	var shrine = Sprite2D.new()
	shrine.texture = load("res://icon.svg")
	shrine.scale = Vector2(3, 8)
	shrine.modulate = Color(0,0 ,0, 0.8)
	shrine.position = Vector2(0, -100)
	shrine.z_index = -1
	shrine.name = "MalevolentShrineVisual"
	add_child(shrine)
	await get_tree().create_timer(0.05, true, false, true).timeout
	Engine.time_scale = 1
	is_using_skill = false
	
func fire_fuga():
	is_using_skill = true
	velocity = Vector2.ZERO
	Engine.time_scale = 0.05
	$AnimatedSprite2D.modulate = Color(1, 0.5, 0)
	var blast = ColorRect.new()
	blast.color = Color(1, 0.2, 0, 0)
	blast.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$CanvasLayer.add_child(blast)
	
	await get_tree().create_timer(0.05, true, false, true).timeout
	
	Engine.time_scale = 1
	shake_camera(20)
	blast.color = Color(1, 0.8, 0, 1)
	
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in all_enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(9999)
			
	var tween = get_tree().create_tween()
	tween.tween_property(blast, "color", Color(1, 0.2, 0, 0), 1)
	tween.tween_callback(blast.queue_free)
	await get_tree().create_timer(1, false, false, true).timeout
	is_using_skill = false
	
	end_sukuna()

func add_ult_charge(amount: int):
	if is_sukuna or current_ult_charge >= max_ult_charge:
		return
		
	current_ult_charge += amount
	awakening_bar.value = current_ult_charge
	
	if current_ult_charge >= max_ult_charge:
		current_ult_charge = max_ult_charge
		awakening_bar.value = current_ult_charge
