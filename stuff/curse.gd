extends CharacterBody2D

@onready var health_bar = $ProgressBar
@onready var anim = $AnimatedSprite2D
@onready var soft_collision = $SoftCollision


@export_enum("slime", "dragon") var enemy_type: String = "slime"

var color_prefix: String = ""
var is_spawning: bool = true

# Core Stats
var max_hp: int = 30
var current_hp: int = 30
var speed: float = 130.0
var soft_push_force: float = 400.0

# Combat & States
var player = null
var attack_cooldown: float = 1.0 
var current_attack_cooldown: float = 0.0
var attack_range: float = 55.0
var separation_distance: float = 30.0

# Brawler Physics Additions
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 600.0

# State Flags
var is_stunned: bool = false
var is_slowed: bool = false
var is_preparing_attack: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp

	var slime_colors = ["green", "blue", "orange", "brown"]
	var dragon_colors = ["yellow", "green", "purple"]
	
	var chosen_color = slime_colors.pick_random() if enemy_type == "slime" else dragon_colors.pick_random()
	color_prefix = enemy_type + "_" + chosen_color + "_"
	
	var spawn_anim = "spawn1" if randi() % 2 == 0 else "spawn2"
	anim.play(color_prefix + spawn_anim)
	
	await anim.animation_finished
	is_spawning = false

func _physics_process(delta: float):
	if is_spawning or current_hp <= 0:
		return

	if current_attack_cooldown > 0:
		current_attack_cooldown -= delta

	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		velocity = knockback_velocity
		move_and_slide()
		return

	if is_stunned or is_preparing_attack:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		var direction_to_player = global_position.direction_to(player.global_position)
		
		var desired_velocity = Vector2.ZERO
		if distance_to_player > attack_range:
			desired_velocity = direction_to_player * speed
		
		var separation_vector = Vector2.ZERO
		var all_enemies = get_tree().get_nodes_in_group("enemy")
		for ally in all_enemies:
			if ally != self and is_instance_valid(ally):
				if abs(global_position.x - ally.global_position.x) < separation_distance and abs(global_position.y - ally.global_position.y) < separation_distance:
					var distance_to_ally = global_position.distance_to(ally.global_position)
					if distance_to_ally < separation_distance and distance_to_ally > 0:
						var push_direction = ally.global_position.direction_to(global_position)
						separation_vector += push_direction * (separation_distance - distance_to_ally)
					
		velocity = (desired_velocity + (separation_vector * 5)).limit_length(speed)
			
		if current_attack_cooldown <= 0 and distance_to_player <= attack_range and not is_slowed:
			prepare_and_attack()
	var push_vector = Vector2.ZERO
	if soft_collision:
		var overlapping_bodies = soft_collision.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body != self and body.is_in_group("enemy"):
				push_vector += global_position.direction_to(body.global_position) * -1
				
	velocity += push_vector.normalized() * soft_push_force * delta
	
	move_and_slide()
	update_animation()

func update_animation():
	if is_spawning or is_preparing_attack or is_stunned or current_hp <= 0:
		return 
		
	if player and knockback_velocity == Vector2.ZERO:
		anim.flip_h = global_position.x > player.global_position.x

	if velocity.length() > 10:
		anim.play(color_prefix + "walk")
	else:
		anim.play(color_prefix + "idle")

func take_damage(damage_amount: int, source_position: Vector2 = Vector2.ZERO, knockback_force: float = 250.0):
	current_hp -= damage_amount
	health_bar.value = current_hp
	
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("shake_camera"):
		player_node.shake_camera(6)
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("apply_shake"):
		camera.apply_shake(8.0)
	
	var flash_tween = create_tween()
	anim.self_modulate = Color(20, 20, 20, 1) 
	flash_tween.tween_property(anim, "self_modulate", Color(1, 1, 1, 1), 0.1)
	
	if source_position != Vector2.ZERO:
		var knockback_dir = source_position.direction_to(global_position)
		knockback_velocity = knockback_dir * knockback_force
	
	if current_hp <= 0:
		die()
	else:
		stun(0.15)

func die():
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	var death_anim = "death1" if randi() % 2 == 0 else "death2"
	anim.play(color_prefix + death_anim)
	
	await anim.animation_finished
	queue_free()

func stun(duration: float):
	is_stunned = true
	is_preparing_attack = false
	anim.play(color_prefix + "hurt")
	
	await get_tree().create_timer(duration, false, false, true).timeout
	
	if current_hp > 0:
		is_stunned = false

func apply_slow():
	if is_slowed: return
	is_slowed = true
	var original_speed = speed
	speed = original_speed * 0.4
	await get_tree().create_timer(0.6, false, false, true).timeout
	speed = original_speed
	is_slowed = false

func prepare_and_attack():
	is_preparing_attack = true
	
	if enemy_type == "dragon":
		var attack_anim = color_prefix + ("attack1" if randi() % 2 == 0 else "attack2")
		
		if anim.sprite_frames.has_animation(attack_anim):
			anim.play(attack_anim)
			var fps = anim.sprite_frames.get_animation_speed(attack_anim)
			var frames = anim.sprite_frames.get_frame_count(attack_anim)
			if fps > 0:
				var time_to_hit = (frames / fps) / 2.0
				await get_tree().create_timer(time_to_hit, false, false, true).timeout
		else:
			await get_tree().create_timer(0.5, false, false, true).timeout
	else:
		anim.play(color_prefix + "idle")
		await get_tree().create_timer(0.4, false, false, true).timeout
	if not is_instance_valid(self) or is_stunned or current_hp <= 0:
		is_preparing_attack = false
		return
	
	if player and global_position.distance_to(player.global_position) <= attack_range:
		if player.has_method("take_damage"):
			player.take_damage(1.5)
			
	if enemy_type == "dragon":
		await anim.animation_finished
	else:
		if get_tree() == null:
			return
		else:
			await get_tree().create_timer(0.2, false, false, true).timeout
		
	current_attack_cooldown = attack_cooldown
	is_preparing_attack = false
