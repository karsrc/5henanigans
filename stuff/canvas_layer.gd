extends CanvasLayer

@onready var player = get_parent().get_node("Player")
@onready var heart_container = $MarginContainer/HBoxContainer 
@onready var score_label = $MarginContainer2/ScoreLabel
@onready var tex_full = preload("res://stuff/heart_full.tres")
@onready var tex_half = preload("res://stuff/heart_half.tres") 
@onready var tex_empty = preload("res://stuff/heart_empty.tres")
@onready var ult_bar = $UltBar

func _ready():
	add_to_group("hud")
	update_score_display()

func _process(_delta):
	if is_instance_valid(player):
		update_hearts()
		update_meters()
		update_score_display()

func update_score_display():
	if score_label:
		score_label.text = "SCORE: " + str(Global.total_score)

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

func update_meters():
	if ult_bar:
		ult_bar.max_value = player.max_ult_charge
		ult_bar.value = lerp(ult_bar.value, float(player.current_ult_charge), 0.1)
		if abs(ult_bar.value - player.current_ult_charge) < 0.5:
			ult_bar.value = player.current_ult_charge
