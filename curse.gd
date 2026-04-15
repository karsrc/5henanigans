extends CharacterBody2D

var speed: int = 130
var player = null
var max_hp: int = 30
var current_hp: int = 30

func _ready():
	player = get_tree().get_first_node_in_group("player")
	current_hp = max_hp

func _physics_process(delta: float):
	if player:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
	move_and_slide()

func take_damage(damage_amount: int):
	current_hp -= damage_amount
	print('enemy-hit', current_hp)
	
	if current_hp <= 0:
		die()
		
func die():
	queue_free()
