extends Node2D

var enemy_scene = preload("res://curse.tscn")
var tile_size = 16

func _on_timer_timeout():
	var new_enemy = enemy_scene.instantiate()
	var spawn_pos = Vector2.ZERO
	


	var edge = randi() % 4
	
	match edge:
		0: # gora
			spawn_pos.x = randf_range(-3 * tile_size, 18 * tile_size)
			spawn_pos.y = -3 * tile_size
		1: #dol
			spawn_pos.x = randf_range(-3 * tile_size, 18 * tile_size)
			spawn_pos.y = 18 * tile_size 
		2: #lewo
			spawn_pos.x = -3 * tile_size
			spawn_pos.y = randf_range(-3 * tile_size, 18 * tile_size)
		3: #prawo
			spawn_pos.x = 18 * tile_size
			spawn_pos.y = randf_range(-3 * tile_size, 18 * tile_size)
			
	new_enemy.global_position = spawn_pos
	get_tree().current_scene.add_child(new_enemy)
