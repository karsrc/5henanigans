extends Node2D

var slime_scene = preload("res://curse.tscn")
var dragon_scene = preload("res://dragon.tscn")

# Configurable Spawner Settings
var spawn_interval: float = 3.5 
var dragon_chance: float = 0.15 

# Proximity Settings
var min_spawn_distance: float = 150.0 # Prevents spawning directly on Yuji
var max_spawn_distance: float = 400.0 # Keeps them close to the action

func _ready():
	$Timer.stop()
	$Timer.wait_time = spawn_interval
	
	await get_tree().create_timer(5.0, false, false, true).timeout
	$Timer.start()

func _on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
		
	var safe_spawns = get_tree().get_nodes_in_group("EnemySpawns")
	if safe_spawns.size() == 0:
		return
		
	# 1. Filter the spawns to find the "Goldilocks Zone"
	var valid_spawns = []
	for spawn in safe_spawns:
		var distance = spawn.global_position.distance_to(player.global_position)
		if distance >= min_spawn_distance and distance <= max_spawn_distance:
			valid_spawns.append(spawn)
			
	# 2. Pick a spawn point
	var chosen_spawn = null
	if valid_spawns.size() > 0:
		chosen_spawn = valid_spawns.pick_random()
	else:
		# Fallback: If Yuji is in a weird corner and no spawns match the criteria perfectly, 
		# just pick a completely random one so the game doesn't stop spawning enemies.
		chosen_spawn = safe_spawns.pick_random()
		
	# 3. Roll for Dragon vs Slime
	var selected_enemy_scene = null
	if randf() < dragon_chance:
		selected_enemy_scene = dragon_scene
	else:
		selected_enemy_scene = slime_scene
		

	var new_enemy = selected_enemy_scene.instantiate()
	new_enemy.global_position = chosen_spawn.global_position
	
	get_tree().current_scene.add_child(new_enemy)
