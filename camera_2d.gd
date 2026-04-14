extends Camera2D

func _ready():
	var map = get_tree().current_scene.find_child("TileMap")
	
	if map:
		var map_rect = map.get_used_rect()
		var cell_size = map.tile_set.tile_size
		
		limit_left = map_rect.position.x * cell_size.x
		limit_top = map_rect.position.y * cell_size.y
		limit_right = map_rect.end.x * cell_size.x
		limit_bottom = map_rect.end.y * cell_size.y
