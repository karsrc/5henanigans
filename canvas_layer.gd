extends CanvasLayer

@onready var player = get_parent().get_node("Player")
@onready var heart_container = $MarginContainer/HBoxContainer 

@onready var tex_full = preload("res://graphics3/heart_full.tres")
@onready var tex_half = preload("res://graphics3/heart_half.tres") 
@onready var tex_empty = preload("res://graphics3/heart_empty.tres")

func _process(_delta):
	if is_instance_valid(player):
		update_hearts()

func update_hearts():
	var current_hp = player.current_hp
	var total_hearts = heart_container.get_child_count()
	for i in range(total_hearts):
		var heart_node = heart_container.get_child(i)
		var reversed_index = (total_hearts - 1) - i 
		var heart_full_value = (reversed_index * 2) + 2 
		if current_hp >= heart_full_value:
			heart_node.texture = tex_full
		elif current_hp >= heart_full_value - 1:
			heart_node.texture = tex_half
		else:
			heart_node.texture = tex_empty
