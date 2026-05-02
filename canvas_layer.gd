extends CanvasLayer

@onready var health_bar = $ProgressBar
@onready var awakening_bar = $AwakeningBar

func _process(_delta):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		health_bar.max_value = player.max_hp
		health_bar.value = player.current_hp
		
		awakening_bar.max_value = player.max_ult_charge
		awakening_bar.value = player.current_ult_charge
