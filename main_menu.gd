extends Node2D

@onready var char_sprite = $UILayer/CenterContainer/VBoxContainer/CharacterRow/CharSprite
@onready var char_name_label = $UILayer/CenterContainer/VBoxContainer/CharNameLabel
@onready var play_button = $UILayer/CenterContainer/VBoxContainer/PlayButton
@onready var crt_shader = $ShaderLayer/ColorRect # Make sure this path is correct!

# Add future characters here
var roster = [
	{"name": "VESSEL", "anim": "right"},
	{"name": "KING OF CURSES", "anim": "right"}  
]
var current_idx = 0

func _ready():
	play_button.focus_mode = Control.FOCUS_NONE 
	play_button.pressed.connect(_on_play_pressed)
	update_character_display()

func _input(event):
	if event.is_action_pressed("ui_left"):
		cycle_character(-1)
	elif event.is_action_pressed("ui_right"):
		cycle_character(1)
func cycle_character(direction: int):
	current_idx += direction
	if current_idx < 0:
		current_idx = roster.size() - 1
	elif current_idx >= roster.size():
		current_idx = 0
	update_character_display()
	var flash_tween = create_tween()
	char_sprite.modulate = Color(10, 10, 10, 1)
	flash_tween.tween_property(char_sprite, "modulate", Color(1, 1, 1, 1), 0.15)

func update_character_display():
	var char_data = roster[current_idx]
	char_name_label.text = char_data["name"]
	if char_sprite.has_method("play"):
		char_sprite.play(char_data["anim"])

func _on_play_pressed():
	play_button.disabled = true
	if crt_shader and crt_shader.material:
		var mat = crt_shader.material
		var glitch_tween = create_tween()
		glitch_tween.tween_method(func(v): mat.set_shader_parameter("rgb_shift", v), 0.002, 0.05, 0.1)
		glitch_tween.tween_method(func(v): mat.set_shader_parameter("scanline_intensity", v), 0.35, 1.0, 0.1)
		glitch_tween.tween_method(func(v): mat.set_shader_parameter("rgb_shift", v), 0.05, 0.002, 0.1)
		glitch_tween.tween_callback(load_actual_game).set_delay(0.2)
	else:
		load_actual_game()

func load_actual_game():
	get_tree().change_scene_to_file("res://main.tscn")
