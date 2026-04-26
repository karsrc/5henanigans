extends CharacterBody2D

@onready var crosshair = $Crosshair
@onready var aim_pivot = $AimPivot
@onready var aim_spirte = $AimPivot/AimSprite
@onready var attack_area = $AimPivot/AttackArea
@onready var health_bar = $CanvasLayer/ProgressBar
@onready var awakening_bar = $CanvasLayer/AwakeningBar
@onready var tile_map = get_parent().get_node("board") 


var is_under_overlay: bool = false
var direction: Vector2 = Vector2(1,1)
var walk_speed: float = 180
var run_speed: float = 300
var speed: float = walk_speed
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
var enemies_hit_this_punch: Array = []
var punch_cooldown: float = 0


# Skill 1
var barrage_duration: float = 2.0
var barrage_hits: int = 30
var barrage_damage: int = 8
var is_barraging: bool = false
var barrage_cooldown: float = 9.0
var current_barrage_cooldown: float = 0.0

# Skill 2
var is_in_zone: bool = false
var is_cursed_enhanced: bool = false
var ce_duration: float = 0
var ce_cooldown: float = 0
var ce_tween: Tween

# Skill 3
var leap_speed: int = 400
var leap_duration: float = 1.1
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
	if punch_cooldown > 0: punch_cooldown -= _delta
	if ce_cooldown > 0: ce_cooldown -= _delta
	if ce_duration > 0:
		ce_duration -= _delta
		if ce_duration <= 0:
			deactivate_cursed_energy()
	
	var player_tile_pos = tile_map.local_to_map(tile_map.to_local(global_position))
	var has_tile_above = tile_map.get_cell_source_id(3, player_tile_pos) != -1
	if has_tile_above != is_under_overlay:
		is_under_overlay = has_tile_above
		fade_tilemap_layer(3, 0.3 if is_under_overlay else 1)
	
	if Input.is_key_pressed(KEY_9):
		add_ult_charge(max_ult_charge)
		
	# KING OF CURSES LOGIC
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
			elif Input.is_action_just_pressed("skill_1"):
				fire_sukuna_slash(true)
			elif Input.is_action_just_pressed("skill_3"):
				activate_domain_expansion()
				
		update_animation()
		move_and_slide()
		return 
		
	# VESSEL LOGIC
	if Input.is_action_just_pressed("skill_2") and ce_cooldown <= 0 and not is_cursed_enhanced:
		activate_cursed_energy()
	elif Input.is_action_just_pressed("special_r") and current_manji_cooldown <= 0:
		enter_manji_stance()
			
	if not is_using_skill:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		if Input.is_action_pressed("sprint") and direction != Vector2.ZERO and punch_cooldown <= 0 and not is_attacking:
			speed = run_speed
		else:
			speed = walk_speed
			
		if is_attacking or (punch_cooldown > 0 and Input.is_action_pressed("attack")):
			velocity = direction * (speed * 0.3)
			$AnimatedSprite2D.flip_h = get_global_mouse_position().x < global_position.x
			
		elif Input.is_key_pressed(KEY_F):
			if not is_blocking: 
				$AudioManager.play_random_sound($AudioManager.light_whiffs, 0.8, 0.1, -5.0)
			is_blocking = true
			velocity = direction * (speed * 0.3)
		else:
			is_blocking = false
			velocity = direction * speed
			
		if Input.is_key_pressed(KEY_Q) and current_dash_cooldown <= 0:
			$AudioManager.play_random_sound($AudioManager.dashes)
			perform_dash()
		elif Input.is_action_just_pressed("skill_1") and current_barrage_cooldown <= 0:
			perform_barrage()
		elif Input.is_action_just_pressed("skill_3") and current_leap_cooldown <= 0:
			perform_leap()
		elif Input.is_action_pressed("attack") and not is_attacking and punch_cooldown <= 0:
			perform_punch()
			
		if current_combo > 0 and not is_attacking:
			time_since_last_hit += _delta
			if time_since_last_hit >= 0.8: 
				current_combo = 0
				combo_target = null
				
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
	
func take_damage(damage_amount: int, knockback_force: Vector2 = Vector2.ZERO, attacker_pos: Vector2 = Vector2.ZERO):
	
	if is_countering:
		trigger_manji_kick(attacker_pos)
		
		return 
		
	if is_blocking:
		$AudioManager.play_random_sound($AudioManager.blocks)
		velocity = knockback_force * 0.5 
		move_and_slide()
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
	$AimPivot.look_at(get_global_mouse_position())
	time_since_last_hit = 0
	enemies_hit_this_punch.clear()
	
	current_combo += 1
	if current_combo > 3:
		current_combo = 1
		
	var mouse_pos = get_global_mouse_position()
	var lunge_dir = global_position.direction_to(mouse_pos)
	if current_combo == 2:
		global_position += lunge_dir * 8.0
	elif current_combo == 3:
		global_position += lunge_dir * 18.0
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
	$AudioManager.play_random_sound($AudioManager.light_whiffs)
	$AnimatedSprite2D.flip_h = mouse_pos.x < global_position.x
	
	$AimPivot/AimSprite.show() 
	
	if current_combo == 1 or current_combo == 3:
		$AimPivot/AimSprite.play("swipe1")
		$AimPivot/AimSprite.flip_v = false
	elif current_combo == 2:
		$AimPivot/AimSprite.play("swipe2")
		$AimPivot/AimSprite.flip_v = true

	await get_tree().create_timer(0.15, false, false, true).timeout
	
	if is_attacking: 
		execute_hitbox()

func update_animation():
	if is_attacking or is_leaping or is_barraging or is_countering or is_dashing or (punch_cooldown > 0 and Input.is_action_pressed("attack")):
		return 
	var anim = "" 
	
	if velocity != Vector2.ZERO:
		if speed == run_speed:
			if velocity.y < 0 and abs(velocity.y) > abs(velocity.x):
				anim = "up-run"
			else:
				anim = "right-run"
		else:
			if velocity.y < 0 and abs(velocity.y) > abs(velocity.x):
				anim = "up-walk" 
			else:
				anim = "right-walk" 

		if velocity.x != 0:
			$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
		anim = "right"

	if is_cursed_enhanced:
		anim += "_ce" 

	$AnimatedSprite2D.play(anim)


func _on_frame_changed():
	var current_anim = $AnimatedSprite2D.animation
	var current_frame = $AnimatedSprite2D.frame
	
	if current_anim.begins_with("up-run"):
		if current_frame in [0, 2, 4]: 
			$AudioManager.play_random_sound($AudioManager.footsteps_run, 1.0, 0.1, -8.0)
			
	elif current_anim.contains("run"):
		if current_frame in [2, 6, 7]: 
			$AudioManager.play_random_sound($AudioManager.footsteps_run, 1.0, 0.1, -8.0)
	elif current_anim.begins_with("up-walk"):
		if current_frame in [0, 2, 4]:
			$AudioManager.play_random_sound($AudioManager.footsteps_walk)
			
	elif current_anim.contains("walk"):
		if current_frame in [0, 2, 4, 6]:
			$AudioManager.play_random_sound($AudioManager.footsteps_walk)
	if current_anim.begins_with("m1"):
		
		if current_frame == 1: 
			execute_hitbox()
	if current_anim.begins_with("manji-kick"):
		if current_frame == 0: 
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
				if enemy in enemies_hit_this_punch:
					continue
					
				enemies_hit_this_punch.append(enemy)
				hit_enemy = true
				if is_cursed_enhanced:
					$AudioManager.play_random_sound($AudioManager.heavy_impacts, 0.9, 0.1) # Deeper impact!
				else:
					$AudioManager.play_random_sound($AudioManager.light_impacts)
				var knockback_distance = 6.0
				var base_damage = 10 
				
				if current_combo == 2:
					knockback_distance = 12.0
					base_damage = 12
				elif current_combo >= 3:
					knockback_distance = 22.0
					base_damage = 25
					
				if is_cursed_enhanced:
					knockback_distance += 6.0
					base_damage += 15
					
				var shove_dir = global_position.direction_to(enemy.global_position)
				enemy.global_position += shove_dir * knockback_distance
				
				enemy.take_damage(base_damage)
				add_ult_charge(base_damage)
					
				if enemy.has_method("apply_slow"):
					enemy.apply_slow()
	if hit_enemy:
		Engine.time_scale = 0.2
		await get_tree().create_timer(0.02, true, false, true).timeout
		Engine.time_scale = 1.0

func _on_animation_finished():
	if $AnimatedSprite2D.animation.begins_with("m1"):
			$AimPivot/AimSprite.hide()
			if current_combo == 3:
				punch_cooldown = 0.35 
			else:
				punch_cooldown = 0.1 
				
			is_attacking = false

func trigger_hit_stop():
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.1, true, false, true).timeout
	Engine.time_scale = 1
func perform_barrage():
	is_using_skill = true
	is_barraging = true
	current_barrage_cooldown = barrage_cooldown
	
	$AimPivot/AimSprite.show()
	
	var anim_name = "barrage_ce" if is_cursed_enhanced else "barrage"
	$AnimatedSprite2D.play(anim_name)
	
	for i in range(barrage_hits):
		aim_pivot.look_at(get_global_mouse_position())
		$AnimatedSprite2D.flip_h = get_global_mouse_position().x < global_position.x
		
		var overlapping_bodies = attack_area.get_overlapping_bodies()
		var enemies_present = false
		
		for body in overlapping_bodies:
			if body.is_in_group("enemy"):
				enemies_present = true
				break 
		
		if not enemies_present:
			break 
		
		$AudioManager.play_random_sound($AudioManager.light_whiffs, 1.3, 0.2, -12.0)
		
		for body in overlapping_bodies:
			if body.is_in_group("enemy") and body.has_method("take_damage"):
				$AudioManager.play_random_sound($AudioManager.light_impacts, 1.1, 0.2, -8.0)
				body.take_damage(barrage_damage)
				add_ult_charge(1)
				
				if global_position.distance_to(body.global_position) > 25:
					body.global_position += body.global_position.direction_to(global_position) * 10
		
		if not $AimPivot/AimSprite.is_playing():
			$AimPivot/AimSprite.play()

		await get_tree().create_timer(0.08).timeout

	$AimPivot/AimSprite.hide()
	is_using_skill = false
	is_barraging = false

func enter_manji_stance():
	is_using_skill = true
	velocity = Vector2.ZERO
	current_combo = 0
	current_manji_cooldown = manji_cooldown
	is_countering = true
	
	var suffix = "_ce" if is_cursed_enhanced else ""
	
	$AnimatedSprite2D.flip_h = get_global_mouse_position().x < global_position.x
	$AnimatedSprite2D.play("manji-stance" + suffix)
	
	await get_tree().create_timer(0.4, false, false, true).timeout
	
	if is_countering:
		is_countering = false
		is_using_skill = false

func trigger_manji_kick(attacker_pos: Vector2):
	is_countering = false
	
	$AnimatedSprite2D.flip_h = attacker_pos.x < global_position.x
	
	$AudioManager.play_random_sound($AudioManager.heavy_whiffs, 0.8, 0.1)
	
	var suffix = "_ce" if is_cursed_enhanced else ""
	$AnimatedSprite2D.play("manji-kick" + suffix)
	
	await $AnimatedSprite2D.animation_finished
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

func activate_cursed_energy():
	is_cursed_enhanced = true
	ce_duration = 12
	if ce_tween: ce_tween.kill()
	ce_tween = create_tween().set_loops()
	ce_tween.tween_property($AnimatedSprite2D, "modulate", Color(1.2, 1.5, 2), 0.5)
	ce_tween.tween_property($AnimatedSprite2D, "modulate", Color(1, 1, 1), 0.5)
	
func deactivate_cursed_energy():
	is_cursed_enhanced = false
	ce_cooldown = 15
	if ce_tween: ce_tween.kill()
	$AnimatedSprite2D.modulate = Color(1,1,1)

func fade_tilemap_layer(layer_index: int, target_alpha: float):
	var tween = create_tween()
	var current_color = tile_map.get_layer_modulate(layer_index)
	var target_color = Color(current_color.r, current_color.g, current_color.b, target_alpha)
	tween.tween_method(
		func(c): tile_map.set_layer_modulate(layer_index, c),
		current_color,
		target_color,
		0.25
	)
