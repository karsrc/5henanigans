extends CharacterBody2D

var speed: int = 130
var player = null

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float):
	if player:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
	move_and_slide()
