extends Node2D

@onready var player = $Player
@onready var spawner = $Spawner
@onready var gameplay_hud = $hud
@onready var main_menu_layer = $MainMenuLayer

@onready var bg_void = $MainMenuLayer/BackgroundVoid
@onready var logo_sprite = $MainMenuLayer/LogoSprite
@onready var play_button = $MainMenuLayer/PlayButton
@onready var char_sprite = $MainMenuLayer/CharacterRow/SpriteSpacer/AnimatedSprite2D
@onready var char_name_label = $MainMenuLayer/CharNameLabel
@onready var left_btn = $MainMenuLayer/CharacterRow/LeftArrowBtn
@onready var right_btn = $MainMenuLayer/CharacterRow/RightArrowBtn

var roster = ["VESSEL", "THE KING OF CURSES"]
var current_idx = 0
var is_starting = false 
var logo_timer = 0.0
var is_logo_resting = false

func _ready():
	var crosshair_texture = load("res://graphics3/player/crosshair.png")
	Input.set_custom_mouse_cursor(crosshair_texture, Input.CURSOR_ARROW, Vector2(16, 16))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if is_instance_valid(bg_void):
		var blur_shader = Shader.new()
		blur_shader.code = """
		shader_type canvas_item;
		uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
		void fragment() {
			vec4 blurred = textureLod(screen_texture, SCREEN_UV, 2.5);
			vec4 dark_tint = vec4(0.063, 0.078, 0.122, 1.0);
			COLOR = mix(blurred, dark_tint, 0.75); 
		}
		"""
		var blur_mat = ShaderMaterial.new()
		blur_mat.shader = blur_shader
		bg_void.material = blur_mat
	
	if is_instance_valid(player): 
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.hide()
	if is_instance_valid(spawner): spawner.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(gameplay_hud): gameplay_hud.hide()
	
	if is_instance_valid(play_button): play_button.pressed.connect(_on_play_pressed)
	if is_instance_valid(left_btn): left_btn.pressed.connect(func(): cycle_character(-1))
	if is_instance_valid(right_btn): right_btn.pressed.connect(func(): cycle_character(1))
		
	update_character_display()
	start_flashing_play_text()
	
	if is_instance_valid(logo_sprite):
		if logo_sprite.sprite_frames != null and logo_sprite.sprite_frames.has_animation("default"):
			logo_sprite.sprite_frames.set_animation_loop("default", false)
		logo_sprite.play("default")
		if not logo_sprite.animation_finished.is_connected(_on_logo_finished):
			logo_sprite.animation_finished.connect(_on_logo_finished)
		var float_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var start_y = logo_sprite.position.y
		float_tween.tween_property(logo_sprite, "position:y", start_y - 12.0, 2.0)
		float_tween.tween_property(logo_sprite, "position:y", start_y, 2.0)

func _process(delta):
	if main_menu_layer.visible and is_logo_resting:
		logo_timer += delta
		if logo_timer >= 10.0:
			logo_timer = 0.0
			is_logo_resting = false
			logo_sprite.play("default")

func _input(event):
	if not main_menu_layer.visible or is_starting: return
	
	if event.is_action_pressed("ui_left"): cycle_character(-1)
	elif event.is_action_pressed("ui_right"): cycle_character(1)
	elif event.is_action_pressed("ui_accept"): _on_play_pressed()

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
	if roster[current_idx] == "THE KING OF CURSES":
		char_sprite.self_modulate = Color.WHITE
	else:
		char_sprite.self_modulate = Color.WHITE
		
	if is_instance_valid(char_sprite):
		if char_sprite.sprite_frames != null and char_sprite.sprite_frames.has_animation("right"):
			char_sprite.sprite_frames.set_animation_loop("right", true)
		char_sprite.play("right")

func _on_logo_finished():
	logo_sprite.stop()
	logo_sprite.frame = 0
	is_logo_resting = true

func start_flashing_play_text():
	if is_instance_valid(play_button):
		var tw = create_tween().set_loops()
		tw.tween_property(play_button, "modulate:a", 0.4, 0.4)
		tw.tween_property(play_button, "modulate:a", 1.0, 0.4)

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
