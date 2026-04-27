extends Camera2D

var shake_strength: float = 0.0
var shake_decay: float = 15.0

func _ready():
	var map = get_tree().current_scene.find_child("TileMap")
	
	if map:
		var map_rect = map.get_used_rect()
		var cell_size = map.tile_set.tile_size
		
		limit_left = map_rect.position.x * cell_size.x
		limit_top = map_rect.position.y * cell_size.y
		limit_right = map_rect.end.x * cell_size.x
		limit_bottom = map_rect.end.y * cell_size.y

func _process(delta):
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		offset = Vector2.ZERO

func apply_shake(strength: float):
	shake_strength = strength
