extends Node2D

@onready var player = $Player
@onready var spawner = $Spawner
@onready var gameplay_hud = $hud
@onready var main_menu_layer = $MainMenuLayer
@onready var play_button = $MainMenuLayer/CenterContainer/VBoxContainer/PlayButton
@onready var char_sprite = $MainMenuLayer/CenterContainer/VBoxContainer/CharacterRow/SpriteSpacer/AnimatedSprite2D
@onready var char_name_label = $MainMenuLayer/CenterContainer/VBoxContainer/CharNameLabel
@onready var left_btn = $MainMenuLayer/CenterContainer/VBoxContainer/CharacterRow/LeftArrowBtn
@onready var right_btn = $MainMenuLayer/CenterContainer/VBoxContainer/CharacterRow/RightArrowBtn

var roster = ["VESSEL", "RYOMEN"]
var current_idx = 0
var is_starting = false 

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if is_instance_valid(player): 
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.hide()
	if is_instance_valid(spawner): spawner.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(gameplay_hud): gameplay_hud.hide()
	if is_instance_valid(play_button):
		play_button.pressed.connect(_on_play_pressed)
	if is_instance_valid(left_btn):
		left_btn.pressed.connect(func(): cycle_character(-1))
	if is_instance_valid(right_btn):
		right_btn.pressed.connect(func(): cycle_character(1))
		
	update_character_display()

func _input(event):
	if not main_menu_layer.visible or is_starting: return
	if event.is_action_pressed("ui_left"):
		cycle_character(-1)
	elif event.is_action_pressed("ui_right"):
		cycle_character(1)
	elif event.is_action_pressed("ui_accept"):
		_on_play_pressed()

func cycle_character(direction: int):
	current_idx += direction
	if current_idx < 0: current_idx = roster.size() - 1
	elif current_idx >= roster.size(): current_idx = 0
		
	update_character_display()
	
	if is_instance_valid(char_sprite):
		var tw = create_tween()
		char_sprite.modulate = Color(10, 10, 10, 1)
		tw.tween_property(char_sprite, "modulate", Color(1, 1, 1, 1), 0.15)

func update_character_display():
	char_name_label.text = roster[current_idx]
	if roster[current_idx] == "RYOMEN":
		char_sprite.self_modulate = Color("#df84a5")
	else:
		char_sprite.self_modulate = Color(1, 1, 1)

func _on_play_pressed():
	if is_starting: return
	is_starting = true
	
	var fade_tween = create_tween()
	fade_tween.tween_property(main_menu_layer, "modulate:a", 0.0, 0.8)
	
	fade_tween.tween_callback(func():
		main_menu_layer.hide()
		if is_instance_valid(player): 
			player.process_mode = Node.PROCESS_MODE_INHERIT
			player.show()
		if is_instance_valid(spawner): spawner.process_mode = Node.PROCESS_MODE_INHERIT
		if is_instance_valid(gameplay_hud): gameplay_hud.show()
	)
