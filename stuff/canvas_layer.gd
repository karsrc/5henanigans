extends CanvasLayer

var player: CharacterBody2D:
	set(value):
		player = value
		_update_hud_identity()

@onready var ult_bar = $UltBar
@onready var ult_label = %Label
@onready var score_label = $MarginContainer2/ScoreLabel

@onready var hearts = [
	$MarginContainer/HBoxContainer/Heart1,
	$MarginContainer/HBoxContainer/Heart2,
	$MarginContainer/HBoxContainer/Heart3
]

func _ready() -> void:
	add_to_group("hud")
	update_score_display()

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		if "current_ult_charge" in player and "max_ult_charge" in player:
			ult_bar.max_value = player.max_ult_charge
			ult_bar.value = player.current_ult_charge
		
		if "current_hp" in player:
			var hp = player.current_hp
			for i in range(hearts.size()):
				if hp >= (i + 1) * 2:
					hearts[i].modulate = Color(1, 1, 1, 1) 
				elif hp == (i * 2) + 1:
					hearts[i].modulate = Color(1, 1, 1, 0.4) 
				else:
					hearts[i].modulate = Color(0.1, 0.1, 0.1, 0.5) 

func update_score_display() -> void:
	if is_instance_valid(score_label):
		score_label.text = "SCORE: " + str(Global.total_score)

func _update_hud_identity() -> void:
	if not is_instance_valid(player):
		return
		
	var fill_style = ult_bar.get_theme_stylebox("fill").duplicate()
	
	if player.has_method("enter_awakening"):
		ult_label.text = "   COME, RIKA"
		fill_style.bg_color = Color("#a23e8c")
	else:
		ult_label.text = "   THE ZONE"
		fill_style.bg_color = Color(0.647, 0.190, 0.190, 0.813)
		
	ult_bar.add_theme_stylebox_override("fill", fill_style)
