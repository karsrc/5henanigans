extends BaseFighter

@onready var aim_spirte = $AimPivot/AimSprite
@onready var black_flash_scene = preload("res://black_flash_sparks.tscn")

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
var max_ult_charge: int = 2000
var current_ult_charge: int = 0
var is_in_the_zone: bool = false
var zone_duration: float = 12.0
var zone_timer: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	crosshair.z_index = 1000
	current_hp = max_hp
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	$AimPivot/AimSprite.hide()
	

func _physics_process(delta: float):
	if current_leap_cooldown > 0: current_leap_cooldown -= delta
	if current_barrage_cooldown > 0: current_barrage_cooldown -= delta
	if current_manji_cooldown > 0: current_manji_cooldown -= delta
	if ce_cooldown > 0: ce_cooldown -= delta
	if ce_duration > 0:
		ce_duration -= delta
		if ce_duration <= 0: deactivate_cursed_energy()
	if zone_timer > 0:
		zone_timer -= delta
		if zone_timer <= 0 and is_in_the_zone: exit_the_zone()
		
	if Input.is_action_just_pressed("skill_2") and ce_cooldown <= 0 and not is_cursed_enhanced:
		activate_cursed_energy()
	elif Input.is_action_just_pressed("special_r") and current_manji_cooldown <= 0:
		enter_manji_stance()
	elif Input.is_action_just_pressed("skill_4") and not is_using_skill:
		if current_ult_charge >= max_ult_charge and not is_in_the_zone: enter_the_zone()
	elif Input.is_action_just_pressed("skill_1") and current_barrage_cooldown <= 0 and not is_using_skill:
		perform_barrage()
	elif Input.is_action_just_pressed("skill_3") and current_leap_cooldown <= 0 and not is_using_skill:
		perform_leap()
		
	super._physics_process(delta)

func take_damage(damage_amount: int, knockback_force: Vector2 = Vector2.ZERO, attacker_pos: Vector2 = Vector2.ZERO):
	if is_countering:
		trigger_manji_kick(attacker_pos)
		return 
		
	super.take_damage(damage_amount, knockback_force, attacker_pos)

func shake_camera(intensity: float):
	var camera = $Camera2D
	if not camera: return
	var shake_tween = create_tween()
	for i in range(4):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		shake_tween.tween_property(camera, "offset", offset, 0.04)
		intensity *= 0.5
	shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)

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
	var last_hit_pos = Vector2.ZERO
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
				last_hit_pos = enemy.global_position
				
				# --- SCORE SYSTEM START ---
				score_combo += 1
				var points_earned = 50 + ((score_combo - 1) * 25)
				Global.total_score += points_earned
				get_tree().call_group("hud", "update_score_display")
				# --- SCORE SYSTEM END ---
				
				if is_cursed_enhanced:
					$AudioManager.play_random_sound($AudioManager.heavy_impacts, 0.9, 0.1) 
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
					base_damage += 18
					
				var shove_dir = global_position.direction_to(enemy.global_position)
				enemy.global_position += shove_dir * knockback_distance
				
				enemy.take_damage(base_damage)
				add_ult_charge(base_damage)
					
				if enemy.has_method("apply_slow"):
					enemy.apply_slow()
	if hit_enemy:
		var shake_intensity = 5.0
		if current_combo >= 3: shake_intensity = 14.0
		if is_cursed_enhanced: shake_intensity += 10.0
		if is_in_the_zone: shake_intensity += 20.0 
		shake_camera(shake_intensity)
		if (is_cursed_enhanced or is_in_the_zone) and last_hit_pos != Vector2.ZERO:
			var recoil_dir = -global_position.direction_to(last_hit_pos)
			var recoil_force = 200.0 if is_in_the_zone else 150.0
			velocity += recoil_dir * recoil_force
		if is_in_the_zone:
			$AudioManager.play_random_sound($AudioManager.heavy_impacts, 1.5, 0.1, -2.0)
			
			if last_hit_pos != Vector2.ZERO:
				var sparks = black_flash_scene.instantiate()
				sparks.global_position = last_hit_pos
				get_tree().current_scene.add_child(sparks) 
			
			for hit_target in enemies_hit_this_punch:
				if is_instance_valid(hit_target) and hit_target.has_node("AnimatedSprite2D"):
					var sprite = hit_target.get_node("AnimatedSprite2D")
					var flash_tween = create_tween()
					sprite.self_modulate = Color(0, 0, 0, 1) 
					flash_tween.tween_property(sprite, "self_modulate", Color(5, 0.5, 0.5, 1), 0.1) 
					flash_tween.tween_property(sprite, "self_modulate", Color(1, 1, 1, 1), 0.1)
		var stop_duration = 0.03
		if is_cursed_enhanced: stop_duration = 0.08
		if is_in_the_zone: stop_duration = 0.18 
		
		Engine.time_scale = 0.1
		await get_tree().create_timer(stop_duration, true, false, true).timeout
		Engine.time_scale = 1.0
func _on_animation_finished():
	if $AnimatedSprite2D.animation.begins_with("m1"):
			$AimPivot/AimSprite.hide()
			if current_combo == 3:
				punch_cooldown = 0.35 
			else:
				punch_cooldown = 0.1 
				
			is_attacking = false

func enter_the_zone():
	is_using_skill = true
	is_in_the_zone = true
	zone_timer = zone_duration
	current_ult_charge = 0
	velocity = Vector2.ZERO

	var flash = ColorRect.new()
	flash.color = Color(0, 0, 0, 1) 
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 100
	$CanvasLayer.add_child(flash)

	Engine.time_scale = 0.05
	shake_camera(25.0)

	await get_tree().create_timer(0.05, true, false, true).timeout
	
	flash.queue_free()
	Engine.time_scale = 1.0
	
	$AnimatedSprite2D.speed_scale = 1.5
	$AnimatedSprite2D.modulate = Color(1.8, 0.6, 0.6)
	is_using_skill = false

func exit_the_zone():
	is_in_the_zone = false
	$AnimatedSprite2D.speed_scale = 1.0
	
	if is_cursed_enhanced:
		$AnimatedSprite2D.modulate = Color(1.2, 1.5, 2)
	else:
		$AnimatedSprite2D.modulate = Color(1, 1, 1)

func trigger_hit_stop():
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.1, true, false, true).timeout
	Engine.time_scale = 1
func perform_barrage():
	is_using_skill = true
	is_barraging = true
	current_barrage_cooldown = barrage_cooldown
	
	$AimPivot/AimSprite.show()
	
	$AnimatedSprite2D.play("barrage" + anim_suffix)
	
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

func update_animation():
	if is_leaping or is_barraging or is_countering:
		return 
		
	super.update_animation()

func enter_manji_stance():
	is_using_skill = true
	velocity = Vector2.ZERO
	current_combo = 0
	current_manji_cooldown = manji_cooldown
	is_countering = true
	
	$AnimatedSprite2D.play("manji-stance" + anim_suffix)
	
	await get_tree().create_timer(0.4, false, false, true).timeout
	
	if is_countering:
		is_countering = false
		is_using_skill = false

func trigger_manji_kick(attacker_pos: Vector2):
	is_countering = false
	
	$AnimatedSprite2D.flip_h = attacker_pos.x < global_position.x
	
	$AudioManager.play_random_sound($AudioManager.heavy_whiffs, 0.8, 0.1)
	
	$AnimatedSprite2D.play("manji-kick" + anim_suffix)
	
	await $AnimatedSprite2D.animation_finished
	is_using_skill = false

func perform_leap() -> void:
	is_using_skill = true
	is_attacking = false
	current_combo = 0
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

func add_ult_charge(amount: int):
	if current_ult_charge >= max_ult_charge:
		return
		
	current_ult_charge += amount
	
	if current_ult_charge >= max_ult_charge:
		current_ult_charge = max_ult_charge
func activate_cursed_energy():
	is_cursed_enhanced = true
	anim_suffix ="_ce"
	ce_duration = 12
	if ce_tween: ce_tween.kill()
	ce_tween = create_tween().set_loops()
	ce_tween.tween_property($AnimatedSprite2D, "modulate", Color(1.2, 1.5, 2), 0.5)
	ce_tween.tween_property($AnimatedSprite2D, "modulate", Color(1, 1, 1), 0.5)
	
func deactivate_cursed_energy():
	is_cursed_enhanced = false
	anim_suffix = ""
	ce_cooldown = 15
	if ce_tween: ce_tween.kill()
	$AnimatedSprite2D.modulate = Color(1,1,1)
