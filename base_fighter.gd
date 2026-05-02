extends CharacterBody2D
class_name BaseFighter

signal player_died

# UNIVERSAL NODES
@onready var crosshair = $Crosshair
@onready var aim_pivot = $AimPivot
@onready var attack_area = $AimPivot/AttackArea
@onready var anim_sprite = $AnimatedSprite2D
@onready var audio_manager = $AudioManager
@onready var tile_map = get_parent().get_node_or_null("board")

# UNIVERSAL STATS & STATES
@export var max_hp: int = 6
@export var walk_speed: float = 180.0
@export var run_speed: float = 300.0
@export var dash_speed: int = 700
@export var dash_cooldown: float = 1.2
@export var combo_drop_time: float = 1.0

var last_anim_dir: String = "right"
var anim_suffix: String = ""
var current_hp: int
var direction: Vector2 = Vector2(1,1)
var speed: float = walk_speed
var is_under_overlay: bool = false
var is_attacking: bool = false
var is_blocking: bool = false
var is_dashing: bool = false
var is_using_skill: bool = false
var is_invincible: bool = false

var current_combo: int = 0
var time_since_last_hit: float = 0
var current_dash_cooldown: float = 0
var punch_cooldown: float = 0
var enemies_hit_this_punch: Array = []

func _ready() -> void:
	current_hp = max_hp
	
	var death_screen = get_tree().get_first_node_in_group("death_screen")
	if death_screen and death_screen.material:
		death_screen.visible = true
		var mat = death_screen.material
		
		mat.set_shader_parameter("bw_blend", 0.0)
		mat.set_shader_parameter("bar_progress", 0.0)
		mat.set_shader_parameter("global_blur", 0.0)
		mat.set_shader_parameter("vignette_blur", 4.0) 
		
		var tween = create_tween()
		tween.tween_method(func(val): mat.set_shader_parameter("vignette_blur", val), 4.0, 0.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		await tween.finished
		death_screen.visible = false


func _physics_process(delta: float):
	if current_hp <= 0: return
	
	if current_dash_cooldown > 0: current_dash_cooldown -= delta
	if punch_cooldown > 0: punch_cooldown -= delta
	if tile_map:
		var player_tile_pos = tile_map.local_to_map(tile_map.to_local(global_position))
		var has_tile_above = tile_map.get_cell_source_id(3, player_tile_pos) != -1
		if has_tile_above != is_under_overlay:
			is_under_overlay = has_tile_above
			fade_tilemap_layer(3, 0.3 if is_under_overlay else 1)
	if crosshair: crosshair.global_position = get_global_mouse_position()
	if aim_pivot and not is_attacking and not is_using_skill:
		aim_pivot.look_at(get_global_mouse_position())
		
	if current_combo > 0 and not is_attacking:
		time_since_last_hit += delta
		if time_since_last_hit >= 0.8: 
			current_combo = 0
	

	if not is_using_skill and not is_dashing:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		if Input.is_action_pressed("sprint") and direction != Vector2.ZERO and punch_cooldown <= 0 and not is_attacking:
			speed = run_speed
		else:
			speed = walk_speed
			
		if is_attacking or (punch_cooldown > 0 and Input.is_action_pressed("attack")):
			velocity = direction * (speed * 0.3)
			if anim_sprite: anim_sprite.flip_h = get_global_mouse_position().x < global_position.x
			
		elif Input.is_key_pressed(KEY_F):
			if not is_blocking: 
				if audio_manager: audio_manager.play_random_sound(audio_manager.light_whiffs, 0.8, 0.1, -5.0)
			is_blocking = true
			velocity = direction * (speed * 0.3)
		else:
			is_blocking = false
			velocity = direction * speed
			
		if Input.is_key_pressed(KEY_Q) and current_dash_cooldown <= 0:
			perform_dash()
		elif Input.is_action_pressed("attack") and not is_attacking and punch_cooldown <= 0:
			perform_punch()

	move_and_slide()
	update_animation()

# UNIVERSAL MECHANICS
func perform_dash():
	is_using_skill = true 
	is_dashing = true 
	is_invincible = true
	current_dash_cooldown = dash_cooldown
	if audio_manager: audio_manager.play_random_sound(audio_manager.dashes)
	
	var dash_dir = direction
	if dash_dir == Vector2.ZERO:
		dash_dir = global_position.direction_to(get_global_mouse_position())
		
	velocity = dash_dir.normalized() * dash_speed
	
	var anim_name = "dash-up" if dash_dir.y < 0 else "dash"
	if anim_sprite:
		anim_sprite.play(anim_name)
		anim_sprite.flip_h = dash_dir.x < 0
		await anim_sprite.animation_finished 
	
	velocity = Vector2.ZERO 
	is_using_skill = false
	is_dashing = false 
	is_invincible = false

func perform_punch():
	is_attacking = true
	if aim_pivot: aim_pivot.look_at(get_global_mouse_position())
	time_since_last_hit = 0
	enemies_hit_this_punch.clear()
	
	current_combo += 1
	if current_combo > 3: current_combo = 1
		
	var mouse_pos = get_global_mouse_position()
	var lunge_dir = global_position.direction_to(mouse_pos)
	if current_combo == 2: global_position += lunge_dir * 8.0
	elif current_combo == 3: global_position += lunge_dir * 18.0
	
	var facing_front = mouse_pos.y > global_position.y
	var suffix = "-front" if facing_front else ""
	
	var anim_to_play = "m1"
	if current_combo == 1: anim_to_play = "m1-1-front" if facing_front else "m1"
	elif current_combo == 2: anim_to_play = "m1-2" + suffix
	elif current_combo == 3: anim_to_play = "m1-3" + suffix
		
	if anim_sprite:
		anim_sprite.play(anim_to_play)
		anim_sprite.flip_h = mouse_pos.x < global_position.x
	
	if audio_manager: audio_manager.play_random_sound(audio_manager.light_whiffs)

	var aim_sprite_node = $AimPivot/AimSprite if has_node("AimPivot/AimSprite") else null
	if aim_sprite_node:
		aim_sprite_node.show() 
		if current_combo == 1 or current_combo == 3:
			aim_sprite_node.play("swipe1")
			aim_sprite_node.flip_v = false
		elif current_combo == 2:
			aim_sprite_node.play("swipe2")
			aim_sprite_node.flip_v = true

	await get_tree().create_timer(0.15, false, false, true).timeout
	if is_attacking: execute_hitbox()

func execute_hitbox():
	pass 

func take_damage(damage_amount: int, knockback_force: Vector2 = Vector2.ZERO, attacker_pos: Vector2 = Vector2.ZERO):
	if is_invincible: return
	if is_blocking:
		if audio_manager: audio_manager.play_random_sound(audio_manager.blocks)
		velocity = knockback_force * 0.5 
		damage_amount = int(damage_amount * 0.2)
		shake_camera(3)
		move_and_slide()
	if is_using_skill and not is_blocking: return
	current_hp -= damage_amount
	if current_hp <= 0:
		die()
	else:
		is_invincible = true 
		if anim_sprite:
			var flash_tween = get_tree().create_tween()
			flash_tween.set_loops(5)
			flash_tween.tween_property(anim_sprite, "modulate", Color(10, 10, 10, 1), 0.05)
			flash_tween.tween_property(anim_sprite, "modulate", Color(1,1,1,1), 0.05)
			await get_tree().create_timer(0.5, false, false, true).timeout
			if is_instance_valid(flash_tween): flash_tween.kill()
			anim_sprite.modulate = Color(1,1,1,1)
			is_invincible = false



func die():
	set_physics_process(false)
	velocity = Vector2.ZERO
	is_invincible = true
	if audio_manager:
		audio_manager.play_random_sound(audio_manager.death_sounds, 1.0, 0.05, 2.0)
	
	if anim_sprite:
		anim_sprite.play("death")
	
	var master_shader = get_tree().get_first_node_in_group("master_shader")
	if master_shader and master_shader.material:
		var mat = master_shader.material
		var dissolve_tween = create_tween().set_parallel(true)
		dissolve_tween.tween_method(func(v): mat.set_shader_parameter("bw_blend", v), 0.0, 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		dissolve_tween.tween_method(func(v): mat.set_shader_parameter("blur_amount", v), 0.0, 5.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		dissolve_tween.tween_method(func(v): mat.set_shader_parameter("pixel_size", v), 1.0, 32.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		await dissolve_tween.finished
		
		var focus_tween = create_tween().set_parallel(true)
		focus_tween.tween_method(func(v): mat.set_shader_parameter("pixel_size", v), 32.0, 1.0, 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		focus_tween.tween_method(func(v): mat.set_shader_parameter("blur_amount", v), 5.0, 0.0, 0.6).set_trans(Tween.TRANS_SINE)
		
		await focus_tween.finished
		var bar_tween = create_tween()
		bar_tween.tween_method(
			func(v): mat.set_shader_parameter("bar_progress", v), 
			0.0, 
			0.5, 
			0.3
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		
		await bar_tween.finished
	elif anim_sprite:
		await anim_sprite.animation_finished
	player_died.emit()

func shake_camera(intensity: float):
	var camera = $Camera2D if has_node("Camera2D") else null
	if not camera: return
	var shake_tween = create_tween()
	for i in range(4):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		shake_tween.tween_property(camera, "offset", offset, 0.04)
		intensity *= 0.5
	shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)

func trigger_hit_stop():
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.1, true, false, true).timeout
	Engine.time_scale = 1.0
	
func update_animation():
	if is_attacking or is_dashing or (punch_cooldown > 0 and Input.is_action_pressed("attack")):
		return 
		
	var anim = "" 
	
	if velocity != Vector2.ZERO:
		if speed == run_speed:
			if velocity.y < 0 and abs(velocity.y) > abs(velocity.x):
				anim = "up-run"
				last_anim_dir = "up"
			else:
				anim = "right-run"
				last_anim_dir = "right"
		else:
			if velocity.y < 0 and abs(velocity.y) > abs(velocity.x):
				anim = "up-walk" 
				last_anim_dir = "up"
			else:
				anim = "right-walk"
				last_anim_dir = "right"

		if velocity.x != 0 and anim_sprite:
			anim_sprite.flip_h = velocity.x < 0
	else:
		anim = last_anim_dir

	if anim_sprite:
		anim_sprite.play(anim + anim_suffix)

func fade_tilemap_layer(layer_index: int, target_alpha: float):
	if not tile_map: return
	var tween = create_tween()
	var current_color = tile_map.get_layer_modulate(layer_index)
	var target_color = Color(current_color.r, current_color.g, current_color.b, target_alpha)
	tween.tween_method(
		func(c): tile_map.set_layer_modulate(layer_index, c),
		current_color,
		target_color,
		0.25
	)
