extends CharacterBody2D

var speed: int = 130
var player = null
var max_hp: int = 30
var current_hp: int = 30
var is_stunned: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
	current_hp = max_hp

func _physics_process(delta: float):
	if player:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
	if not is_stunned:
		move_and_slide()

func take_damage(damage_amount: int):
	current_hp -= damage_amount
	print('enemy-hit', current_hp)
	
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
	$AnimatedSprite2D.modulate = Color(1, 1, 0)
	print("Enemy is stunned for", duration, "seconds!")
	
	await get_tree().create_timer(duration, false, false, true).timeout
	
	is_stunned = false
	$AnimatedSprite2D.modulate = Color(1,1,1) 
