extends BaseFighter

@onready var aim_sprite = $AimPivot/AimSprite
@onready var black_flash_scene = preload("res://stuff/black_flash_sparks.tscn")
@onready var attack_area = $AimPivot/AttackArea

# special r
var is_pink_aura_active: bool = false
var aura_tween: Tween

# Skill 1: Katana Barrage
var current_skill_1_cooldown: float = 0.0
var skill_1_cooldown: float = 9.0
var is_barraging: bool = false
var barrage_hit_count: int = 0

# Skill 2: CE Pulse
var current_skill_2_cooldown: float = 0.0
var skill_2_cooldown: float = 15.0
var is_pulse_charging: bool = false

# Skill 3: Meteor Leap
var current_skill_3_cooldown: float = 0.0
var skill_3_cooldown: float = 10.0
var is_leaping: bool = false

# Ultimate: Come here Rika, give me everything.
var max_ult_charge: int = 250
var current_ult_charge: int = 0
var is_awakened: bool = false
var awakening_duration: float = 12.0
var awakening_timer: float = 0.0

# General Combat
var current_damage_multiplier: float = 1.0
var was_blocking: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if crosshair: crosshair.z_index = 1000
	current_hp = max_hp
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	if has_node("AimPivot/AimSprite"): $AimPivot/AimSprite.hide()

func _physics_process(delta: float):
	if current_skill_1_cooldown > 0: current_skill_1_cooldown -= delta
	if current_skill_2_cooldown > 0: current_skill_2_cooldown -= delta
	if current_skill_3_cooldown > 0: current_skill_3_cooldown -= delta
	if awakening_timer > 0:
		awakening_timer -= delta
		current_ult_charge = int((awakening_timer / awakening_duration) * max_ult_charge)
		if awakening_timer <= 0 and is_awakened: exit_awakening()
	if is_blocking and not was_blocking:
		$AnimatedSprite2D.play("block")
	elif not is_blocking and was_blocking:
		$AnimatedSprite2D.play_backwards("block")
	was_blocking = is_blocking
	if not is_blocking and not is_using_skill:
		if Input.is_action_just_pressed("special_r"):
			toggle_pink_aura()
			
		elif Input.is_action_just_pressed("skill_1"):
			if current_skill_1_cooldown <= 0: perform_skill_1()
			else: show_cooldown_warning("Barrage")
				
		elif Input.is_action_just_pressed("skill_2"):
			if current_skill_2_cooldown <= 0: perform_skill_2()
			else: show_cooldown_warning("Cursed Pulse")
				
		elif Input.is_action_just_pressed("skill_3"):
			if current_skill_3_cooldown <= 0: perform_skill_3()
			else: show_cooldown_warning("Cursed Meteor")
				
		elif Input.is_action_just_pressed("skill_4"):
			if current_ult_charge >= max_ult_charge and not is_awakened: enter_awakening()
			elif current_ult_charge < max_ult_charge and not is_awakened: show_cooldown_warning("", "Awakening isn't ready yet!")
			
	super._physics_process(delta)
func update_animation():
	if is_attacking or is_dashing or is_leaping or is_barraging or is_pulse_charging or is_blocking or (punch_cooldown > 0 and Input.is_action_pressed("attack")):
		return 
		
	var anim = "" 
	if velocity != Vector2.ZERO:
		if speed == run_speed:
			if velocity.y < 0 and abs(velocity.y) > abs(velocity.x):
				anim = "run_backwards"
				last_anim_dir = "up"
			else:
				anim = "run"
				last_anim_dir = "right"
		else:
			if velocity.y < 0 and abs(velocity.y) > abs(velocity.x):
				anim = "walk_backwards" 
				last_anim_dir = "up"
			else:
				anim = "walk"
				last_anim_dir = "right"

		if velocity.x != 0 and anim_sprite:
			anim_sprite.flip_h = velocity.x < 0
	else:
		anim = "right" 

	if anim_sprite:
		anim_sprite.play(anim + anim_suffix)

func take_damage(damage_amount: int, knockback_force: Vector2 = Vector2.ZERO, attacker_pos: Vector2 = Vector2.ZERO):
	if is_blocking:
		anim_sprite.play("block")
		anim_sprite.frame = 5
		damage_amount = int(damage_amount * 0.2)
	if is_pulse_charging and anim_sprite.animation == "skill2" and anim_sprite.frame < 5:
		is_pulse_charging = false
		is_using_skill = false
		anim_sprite.play("right")
		show_cooldown_warning("", "Interrupted!")
		
	if is_invincible:
		return
		
	super.take_damage(damage_amount, knockback_force, attacker_pos)

func perform_punch():
	if is_blocking: return
	
	is_attacking = true
	var mouse_pos = get_global_mouse_position()
	$AnimatedSprite2D.flip_h = mouse_pos.x < global_position.x
	
	var lunge_dir = global_position.direction_to(mouse_pos)
	velocity = lunge_dir * 350.0 
	
	if has_node("AudioManager"): 
		$AudioManager.play_random_sound($AudioManager.light_whiffs)
	var aim_sprite_node = $AimPivot/AimSprite if has_node("AimPivot/AimSprite") else null
	if aim_sprite_node:
		aim_sprite_node.show() 
		if current_combo == 0 or current_combo == 2:
			aim_sprite_node.play("swipe1")
			aim_sprite_node.flip_v = false
		elif current_combo == 1:
			aim_sprite_node.play("swipe2")
			aim_sprite_node.flip_v = true
	var is_aiming_front = mouse_pos.y > global_position.y + 15.0
	var is_aiming_back = mouse_pos.y < global_position.y - 15.0
	var suffix = ""
	if is_aiming_front: suffix = "-front"
	elif is_aiming_back: suffix = "-backwards"
	
	var anim_to_play = "m1"
	if current_combo == 0: anim_to_play = "m1" + suffix
	elif current_combo == 1: anim_to_play = "m1-2" + suffix
	else: anim_to_play = "m1-3" + suffix
		
	$AnimatedSprite2D.play(anim_to_play)
	
	current_combo += 1

func execute_hitbox():
	var hit_enemy = false
	var last_hit_pos = Vector2.ZERO
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	
	var locked_aim_direction = Vector2.RIGHT
	if has_node("AimPivot"):
		locked_aim_direction = Vector2.RIGHT.rotated($AimPivot.rotation)
	
	for enemy in all_enemies:
		if not is_instance_valid(enemy): continue
		
		var distance = global_position.distance_to(enemy.global_position)
		var dir_to_enemy = global_position.direction_to(enemy.global_position)
		var is_in_front = locked_aim_direction.dot(dir_to_enemy) > 0.3
		
		if attack_area.overlaps_body(enemy) or (distance <= 65 and is_in_front):
			if enemy.has_method("take_damage"):
				if enemy in enemies_hit_this_punch: continue
					
				enemies_hit_this_punch.append(enemy)
				hit_enemy = true
				last_hit_pos = enemy.global_position
				
				score_combo += 1
				Global.total_score += 50 + ((score_combo - 1) * 25)
				get_tree().call_group("hud", "update_score_display")
				
				if is_pink_aura_active:
					if audio_manager: audio_manager.play_random_sound(audio_manager.heavy_impacts, 0.9, 0.1)
				else:
					if audio_manager: audio_manager.play_random_sound(audio_manager.light_impacts)
					
				var base_damage: int = int((15 + (current_combo * 3)) * current_damage_multiplier)
				var knockback_distance: float = (10.0 + (current_combo * 4.0)) * current_damage_multiplier
				
				if is_pink_aura_active:
					knockback_distance += 5.0
					base_damage = int(base_damage * 1.5)
					
				if is_awakened:
					base_damage += 20
					current_hp = min(current_hp + 1, max_hp)
					
				var shove_dir = global_position.direction_to(enemy.global_position)
				enemy.global_position += shove_dir * knockback_distance
				
				enemy.take_damage(base_damage)
				
				if damage_popup_scene:
					var popup = damage_popup_scene.instantiate()
					popup.global_position = enemy.global_position + Vector2(0, -10)
					get_tree().current_scene.add_child(popup)
					popup.setup(base_damage, current_combo, is_awakened)
				
				add_ult_charge(base_damage)
				if enemy.has_method("apply_slow"): enemy.apply_slow()

	if hit_enemy:
		var shake_intensity = 5.0 * current_damage_multiplier
		if current_combo >= 3: shake_intensity = 14.0
		if is_pink_aura_active: shake_intensity += 10.0
		if is_awakened: shake_intensity += 20.0
		shake_camera(shake_intensity)
		
		if (is_pink_aura_active or is_awakened) and last_hit_pos != Vector2.ZERO:
			velocity += -global_position.direction_to(last_hit_pos) * (200.0 if is_awakened else 150.0)
			
		if is_awakened and last_hit_pos != Vector2.ZERO and black_flash_scene != null:
			if audio_manager: audio_manager.play_random_sound(audio_manager.heavy_impacts, 1.5, 0.1, -2.0)
			var sparks = black_flash_scene.instantiate()
			sparks.global_position = last_hit_pos
			get_tree().current_scene.add_child(sparks)
		
		var stop_duration = 0.03
		if is_pink_aura_active: stop_duration = 0.08
		if is_awakened: stop_duration = 0.18
		
		trigger_hit_stop_custom(stop_duration)
func _on_frame_changed():
	var anim = $AnimatedSprite2D.animation
	var frame = $AnimatedSprite2D.frame
	if anim in ["m1", "m1-front", "m1-backwards"]:
		if frame == 1: 
			current_damage_multiplier = 1.0
			execute_hitbox()
			
	elif anim in ["m1-2", "m1-2-front", "m1-2-backwards"]:
		if frame in [1, 6]: 
			enemies_hit_this_punch.clear()
			current_damage_multiplier = 1.0
			execute_hitbox()
			
	elif anim in ["m1-3", "m1-3-front", "m1-3-backwards"]:
		if frame in [1, 6]:
			enemies_hit_this_punch.clear()
			current_damage_multiplier = 1.0
			execute_hitbox()
		elif frame == 10: 
			enemies_hit_this_punch.clear()
			current_damage_multiplier = 2.5
			execute_hitbox()
	elif anim == "skill1":
		if frame in [1, 3, 4]:
			enemies_hit_this_punch.clear()
			current_damage_multiplier = 0.5 
			
			var step_dir = Vector2.LEFT if $AnimatedSprite2D.flip_h else Vector2.RIGHT
			velocity = step_dir * 180.0 
			
			execute_hitbox()
			
		elif frame in [0, 2, 5, 7]:
			velocity = Vector2.ZERO
		if frame == 2:
			$AnimatedSprite2D.speed_scale = 1.55 
		if frame == 5 and is_barraging:
			if barrage_hit_count < 5:
				call_deferred("_loop_barrage") 
				barrage_hit_count += 1
			else:
				$AnimatedSprite2D.speed_scale = 1.0
				is_barraging = false
			
		if frame == 5 and is_barraging:
			if Input.is_action_pressed("skill_1") and barrage_hit_count < 5:
				$AnimatedSprite2D.speed_scale = 1.55
				call_deferred("_loop_barrage")
				barrage_hit_count += 1
			else:
				$AnimatedSprite2D.speed_scale = 1.0
				is_barraging = false
				
	elif anim == "skill2":
		if frame == 5:
			is_invincible = true
			execute_pulse_explosion()
			
	elif anim == "skill3":
		if frame == 1:
			launch_meteor_leap()
		elif frame == 7:
			stop_meteor_leap()
			
	elif anim == "block":
		if frame == 4: 
			$AnimatedSprite2D.pause()

func _on_animation_finished():
	var anim = $AnimatedSprite2D.animation
	
	if anim.begins_with("m1"):
		if has_node("AimPivot/AimSprite"): $AimPivot/AimSprite.hide()
		punch_cooldown = 0.35 if current_combo >= 3 else 0.10
		is_attacking = false
		
	elif anim == "skill1":
		is_using_skill = false
		is_barraging = false
		$AnimatedSprite2D.speed_scale = 1.0
		current_skill_1_cooldown = skill_1_cooldown
		
	elif anim == "skill2":
		is_using_skill = false
		is_pulse_charging = false
		is_invincible = false
		current_skill_2_cooldown = skill_2_cooldown
		
	elif anim == "skill3":
		is_using_skill = false
		is_leaping = false
		current_skill_3_cooldown = skill_3_cooldown

func perform_skill_1():
	is_using_skill = true
	is_barraging = true
	barrage_hit_count = 0
	velocity = Vector2.ZERO
	$AnimatedSprite2D.speed_scale = 1.0
	$AnimatedSprite2D.play("skill1")

func perform_skill_2():
	is_using_skill = true
	is_pulse_charging = true
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("skill2")

func execute_pulse_explosion():
	shake_camera(20.0)
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in all_enemies:
		if global_position.distance_to(enemy.global_position) <= 120.0:
			if enemy.has_method("take_damage"):
				enemy.take_damage(45)
				if enemy.has_method("stun"): enemy.stun(2.0)
				enemy.global_position += global_position.direction_to(enemy.global_position) * 60.0

func _loop_barrage():
	if $AnimatedSprite2D.animation == "skill1":
		$AnimatedSprite2D.frame = 2 

func perform_skill_3():
	is_using_skill = true
	is_leaping = true
	$AnimatedSprite2D.speed_scale = 1.9 
	$AnimatedSprite2D.play("skill3")

func launch_meteor_leap():
	var dash_direction = global_position.direction_to(get_global_mouse_position())
	velocity = dash_direction * 1800.0

func stop_meteor_leap():
	velocity = Vector2.ZERO
	shake_camera(10.0)
	$AnimatedSprite2D.speed_scale = 1.0

func toggle_pink_aura():
	is_pink_aura_active = !is_pink_aura_active
	if aura_tween: aura_tween.kill()
	if is_pink_aura_active:
		$AnimatedSprite2D.modulate = Color(5.0, 3.0, 5.0, 1.0) 
		aura_tween = create_tween()
		aura_tween.tween_property($AnimatedSprite2D, "modulate", Color(2.5, 1.2, 2.0, 1.0), 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	else:
		$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)

func enter_awakening():
	is_using_skill = true
	is_awakened = true
	awakening_timer = awakening_duration
	velocity = Vector2.ZERO
	var flash_layer = CanvasLayer.new()
	flash_layer.layer = 100 
	var flash = ColorRect.new()
	flash.color = Color(0, 0, 0, 1) 
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_layer.add_child(flash)
	add_child(flash_layer)
	Engine.time_scale = 0.05
	shake_camera(25.0)
	await get_tree().create_timer(0.05, true, false, true).timeout
	flash_layer.queue_free()
	Engine.time_scale = 1.0
	
	$AnimatedSprite2D.speed_scale = 1.5
	is_using_skill = false

func exit_awakening():
	is_awakened = false
	$AnimatedSprite2D.speed_scale = 1.0
	$AnimatedSprite2D.modulate = Color(1, 1, 1)

func add_ult_charge(amount: int):
	if current_ult_charge >= max_ult_charge: return
	current_ult_charge += amount
	if current_ult_charge >= max_ult_charge: current_ult_charge = max_ult_charge

func trigger_hit_stop_custom(duration: float):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
