extends Node2D

var enemy_scene = preload("res://curse.tscn")
var tile_size = 16
var spawn_radius: float = 400

func _ready():
	randomize()

func _on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var random_angle = randf() * TAU
	var new_enemy = enemy_scene.instantiate()
	var spawn_radius = 16 * tile_size
	var spawn_offset = Vector2.RIGHT.rotated(random_angle) * spawn_radius
	var center_of_map = Vector2(7.5 * tile_size, 7.5 * tile_size)
	var spawn_pos = center_of_map + Vector2.RIGHT.rotated(random_angle) * spawn_radius
	
	new_enemy.global_position = spawn_pos
	get_tree().current_scene.add_child(new_enemy)
