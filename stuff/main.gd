extends Node2D

@onready var player = $Player
@onready var spawner = $Spawner
@onready var gameplay_hud = $hud
@onready var main_menu_layer = $MainMenuLayer

@onready var bg_void = %BackgroundVoid
@onready var logo_sprite = $MainMenuLayer/LogoSprite
@onready var start_label = $MainMenuLayer/StartLabel
@onready var char_sprite = $MainMenuLayer/CharacterRow/SpriteSpacer/AnimatedSprite2D
@onready var char_name_label = $MainMenuLayer/CharNameLabel
@onready var left_btn = %LeftArrowBtn
@onready var right_btn = %RightArrowBtn

@onready var menu_camera = %MenuCamera

var roster = [
	"VESSEL", 
	"THE KING OF CURSES", 
	"10 SHADOWS", 
	"THE HONORED ONE", 
	"SEANCE", 
	"CURSED SPEECH", 
	"POISON", 
	"HEAD OF THE HEI", 
	"MAVERICK OUTCAST", 
	"THE CANNON", 
	"STRAW DOLL"
]

var current_idx = 0
var is_starting = false 
var logo_timer = 0.0
var is_logo_resting = false
var total_score: int = 0

func _ready():
	get_tree().paused = false
	Input.set_custom_mouse_cursor(null)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Global.total_score = 0
	get_tree().call_group("hud", "update_score_display")
	if is_instance_valid(menu_camera):
		menu_camera.make_current()
	
	if is_instance_valid(bg_void):
		bg_void.material = null
		bg_void.color = Color(0.06, 0.08, 0.12, 0.85) 
	
	if is_instance_valid(player): 
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.hide()
	if is_instance_valid(spawner): spawner.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(gameplay_hud): gameplay_hud.hide()
	if is_instance_valid(left_btn):
		if left_btn.has_signal("pressed"):
			left_btn.pressed.connect(func(): cycle_character(-1))
		else:
			left_btn.mouse_filter = Control.MOUSE_FILTER_PASS
			left_btn.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					cycle_character(-1)
			)

	if is_instance_valid(right_btn):
		if right_btn.has_signal("pressed"):
			right_btn.pressed.connect(func(): cycle_character(1))
		else:
			right_btn.mouse_filter = Control.MOUSE_FILTER_PASS
			right_btn.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					cycle_character(1)
			)
		
	update_character_display()
	
	if is_instance_valid(logo_sprite):
		if logo_sprite.sprite_frames != null and logo_sprite.sprite_frames.has_animation("default"):
			logo_sprite.sprite_frames.set_animation_loop("default", false)
		logo_sprite.play("default")
		if not logo_sprite.animation_finished.is_connected(_on_logo_finished):
			logo_sprite.animation_finished.connect(_on_logo_finished)
		var start_y: float = logo_sprite.position.y
		var float_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		float_tween.tween_property(logo_sprite, "position:y", start_y - 12.0, 2.0)
		float_tween.tween_property(logo_sprite, "position:y", start_y, 2.0)
		
	play_opening_bars()

func _process(delta):
	if main_menu_layer.visible and is_logo_resting:
		logo_timer += delta
		if logo_timer >= 10.0:
			logo_timer = 0.0
			is_logo_resting = false
			logo_sprite.play("default")

func _on_player_enemy_hit(points: int, multiplier: int):
	$Player.enemy_hit.connect(_on_player_enemy_hit)

func _input(event):
	if not main_menu_layer.visible or is_starting: return
	
	if event.is_action_pressed("ui_left"): cycle_character(-1)
	elif event.is_action_pressed("ui_right"): cycle_character(1)
	elif event.is_action_pressed("ui_accept"): _on_play_pressed()

func cycle_character(direction: int):
	current_idx += direction
	if current_idx < 0: current_idx = roster.size() - 1
	elif current_idx >= roster.size(): current_idx = 0
		
	var tap = AudioStreamPlayer.new()
	tap.stream = load("res://addons/ASSETS/sounds/tap.wav") 
	if tap.stream:
		add_child(tap)
		tap.play()
		tap.finished.connect(tap.queue_free)
		
	update_character_display()
	
	if is_instance_valid(char_sprite):
		var tw = create_tween()
		char_sprite.modulate = Color(10, 10, 10, 1) 
		tw.tween_property(char_sprite, "modulate", Color(1, 1, 1, 1), 0.15)

func update_character_display():
	char_name_label.text = roster[current_idx]
	
	if is_instance_valid(char_sprite):
		char_sprite.stop()
		char_sprite.frame = 0
		
		if roster[current_idx] != "VESSEL":
			char_sprite.self_modulate = Color("#090a14")
		else:
			char_sprite.self_modulate = Color(1, 1, 1, 1)

func _on_logo_finished():
	logo_sprite.stop()
	logo_sprite.frame = 0
	is_logo_resting = true

func _on_play_pressed():
	if is_starting: return
	if roster[current_idx] != "VESSEL":
		var err = AudioStreamPlayer.new()
		err.stream = load("res://graphics3/sounds/Block.wav")
		if err.stream:
			err.pitch_scale = 0.9
			add_child(err)
			err.play()
			err.finished.connect(err.queue_free)
			
		var shake = create_tween()
		var start_x = char_name_label.position.x
		for i in range(3):
			shake.tween_property(char_name_label, "position:x", start_x - 8, 0.04)
			shake.tween_property(char_name_label, "position:x", start_x + 8, 0.04)
		shake.tween_property(char_name_label, "position:x", start_x, 0.04)
		return 
		
	is_starting = true
	
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = load("res://addons/ASSETS/sounds/GameBegin.wav")
	if sfx_player.stream:
		sfx_player.pitch_scale = 0.8 
		add_child(sfx_player)
		sfx_player.play()
	
	if is_instance_valid(start_label):
		var blink_tw = create_tween().set_loops(4)
		blink_tw.tween_property(start_label, "modulate:a", 0.0, 0.05)
		blink_tw.tween_property(start_label, "modulate:a", 1.0, 0.05)
	
	await get_tree().create_timer(0.2).timeout
	
	var transition_layer = CanvasLayer.new()
	transition_layer.layer = main_menu_layer.layer
	add_child(transition_layer)
	
	var screen_size = get_viewport_rect().size
	var num_bars = 5
	var bar_width = screen_size.x / float(num_bars)
	var bars = []
	for i in range(num_bars):
		var bar = ColorRect.new()
		bar.color = Color("#090a14")
		bar.size = Vector2(ceil(bar_width) + 2, screen_size.y)
		bar.position = Vector2(-bar.size.x, 0)
		transition_layer.add_child(bar)
		bars.append(bar)
	var wipe_in = create_tween().set_parallel(true)
	var delay = 0.0
	for i in range(num_bars):
		var target_x = i * bar_width
		wipe_in.tween_property(bars[i], "position:x", target_x, 0.2).set_delay(delay).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		delay += 0.04 
	await wipe_in.finished
	main_menu_layer.hide()
	if is_instance_valid(player): 
		for child in player.get_children():
			if child is Camera2D:
				child.make_current()
				break
		player.process_mode = Node.PROCESS_MODE_INHERIT
		player.show()
	if is_instance_valid(spawner): spawner.process_mode = Node.PROCESS_MODE_INHERIT
	if is_instance_valid(gameplay_hud): gameplay_hud.show()

	var wipe_out = create_tween().set_parallel(true)
	delay = 0.0
	for i in range(num_bars):
		var target_x = screen_size.x + 10 
		wipe_out.tween_property(bars[i], "position:x", target_x, 0.2).set_delay(delay).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		delay += 0.04
		
	await wipe_out.finished
	
	transition_layer.queue_free()
	if sfx_player: sfx_player.queue_free()

func _on_player_died():
	if is_inside_tree():
		get_tree().call_deferred("reload_current_scene")

func play_opening_bars():
	var master_shader = get_tree().get_first_node_in_group("master_shader")
	
	if master_shader and master_shader.material:
		var mat = master_shader.material
		
		mat.set_shader_parameter("bw_blend", 0.0)
		mat.set_shader_parameter("blur_amount", 0.0)
		mat.set_shader_parameter("pixel_size", 1.0)
		mat.set_shader_parameter("bar_progress", 0.5)
		
		var tw = create_tween()
		tw.tween_method(
			func(v): mat.set_shader_parameter("bar_progress", v), 
			0.5, 
			0.0, 
			0.4
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
