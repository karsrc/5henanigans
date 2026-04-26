extends CharacterBody2D

@onready var health_bar = $ProgressBar

var attack_cooldown: float = 1.0 
var current_attack_cooldown: float = 0.0
var speed: int = 130
var player = null
var max_hp: int = 30
var current_hp: int = 30
var is_stunned: bool = false
var attack_range: float = 55
var stopping_distance: float = 40
var separation_distance: float = 30
var is_slowed: bool = false
var is_preparing_attack: bool = false


func _ready():
	player = get_tree().get_first_node_in_group("player")
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp

func _physics_process(delta: float):
	if current_attack_cooldown > 0:
		current_attack_cooldown -= delta
		
	if player and not is_stunned:
		var distance_to_player = global_position.distance_to(player.global_position)
		var direction_to_player = global_position.direction_to(player.global_position)
		
		var desired_velocity = Vector2.ZERO
		if distance_to_player > stopping_distance:
			desired_velocity = direction_to_player * speed
		elif distance_to_player < stopping_distance - 15:
			desired_velocity = -direction_to_player * speed
		
		var separation_vector = Vector2.ZERO
		var all_enemies = get_tree().get_nodes_in_group("enemy")
		
		for ally in all_enemies:
			if ally != self and is_instance_valid(ally):
				var distance_to_ally = global_position.distance_to(ally.global_position)
				if distance_to_ally < separation_distance:
					var push_direction = ally.global_position.direction_to(global_position)
					var push_strength = separation_distance - distance_to_ally
					separation_vector += push_direction * push_strength
		if desired_velocity != Vector2.ZERO:
			velocity = (desired_velocity + (separation_vector * 5)).limit_length(speed)
		else:
			velocity = (separation_vector * 5).limit_length(speed)
			
			if current_attack_cooldown <= 0 and distance_to_player <= attack_range and not is_slowed and not is_preparing_attack:
				prepare_and_attack()
		
	if is_preparing_attack:
		velocity = Vector2.ZERO
		
	if not is_stunned:
		move_and_slide()

func flash():
	$AnimatedSprite2D.modulate = Color(5,5,5)
	await get_tree().create_timer(0.05, false, false, true).timeout
	
	if is_stunned:
		$AnimatedSprite2D.modulate = Color(1, 1, 0)
	else:
		$AnimatedSprite2D.modulate = Color(1,1,1)

func take_damage(damage_amount: int):
	current_hp -= damage_amount
	
	health_bar.value = current_hp
	
	if current_hp <= 0:
		die()
		
func die():
	queue_free()

func stun(duration: float):
	if is_stunned: return
	is_stunned = true
	await get_tree().create_timer(duration, false, false, true).timeout
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
	await get_tree().create_timer(0.5, false, false, true).timeout
	if not is_instance_valid(self): return
	if player and global_position.distance_to(player.global_position) <= attack_range:
		if player.has_method("take_damage"):
			player.take_damage(5)
	current_attack_cooldown = attack_cooldown
	is_preparing_attack = false
