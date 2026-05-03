extends Marker2D

@onready var label = $Label

func _ready():
	z_index = 999
	z_as_relative = false 

func setup(amount: int, combo_hit: int, is_black_flash: bool = false):
	label.text = str(amount)
	
	var target_color = Color.WHITE
	# Reduced base scale (was 1.0)
	var target_scale = Vector2(0.6, 0.6) 
	
	if is_black_flash:
		target_color = Color("#a53030") 
		target_scale = Vector2(1.1, 1.1) 
	elif combo_hit >= 3:
		target_color = Color("#e8c170") 
		target_scale = Vector2(0.85, 0.85) 
	
	label.modulate = target_color
	
	label.scale = target_scale * 0.3
	
	var random_x = randf_range(-40, 40)
	var target_pos = position + Vector2(random_x, -60)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", target_pos, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", target_scale, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.2).set_delay(0.1)
	
	await tween.finished
	queue_free()
