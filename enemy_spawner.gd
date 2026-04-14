extends Node2D

var enemy_scene = preload("res://curse.tscn")
var tile_size = 16

func _on_timer_timeout():
	var new_enemy = enemy_scene.instantiate()
	
	var random_x = randf_range(-11 * tile_size, 26 * tile_size)
	var random_y = randf_range(-13 * tile_size, 28 * tile_size)
	
	new_enemy.global_position = Vector2(random_x, random_y)
	get_tree().current_scene.add_child(new_enemy)
	
	
