extends CharacterBody2D

@onready var health_bar = $ProgressBar
@onready var damage_aura = $DamageAura

var attack_cooldown: float = 1.0 
var current_attack_cooldown: float = 0.0
var speed: int = 130
var player = null
var max_hp: int = 30
var current_hp: int = 30
var is_stunned: bool = false


func _ready():
	player = get_tree().get_first_node_in_group("player")
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp

func _physics_process(delta: float):
	if current_attack_cooldown > 0:
		current_attack_cooldown -= delta
		
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		if distance > 40: 
			var direction = global_position.direction_to(player.global_position)
			velocity = direction * speed
		else:
			velocity = Vector2.ZERO 
			
		if not is_stunned and current_attack_cooldown <= 0:
			var overlapping_bodies = damage_aura.get_overlapping_bodies()
			
			print("Enemy attack check: Found ", overlapping_bodies.size(), " things in aura.")
			
			for body in overlapping_bodies:
				if body.is_in_group("player"):
					print("Enemy sees the Player! Trying to punch...")
					
					if body.has_method("take_damage"):
						print("Punch landed!")
						body.take_damage(15) 
						current_attack_cooldown = attack_cooldown
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
	print('enemy-hit', current_hp)
	
	health_bar.value = current_hp
	
	if current_hp <= 0:
		die()
		
func die():
	queue_free()


func _on_damage_aura_body_entered(body: Node2D) -> void:
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(15)


func stun(duration: float):
	if is_stunned: return
	is_stunned = true
	print("Enemy is stunned for", duration, "seconds!")
	await get_tree().create_timer(duration, false, false, true).timeout
	is_stunned = false
