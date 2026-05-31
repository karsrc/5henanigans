extends CanvasLayer

@onready var player = get_parent().get_node("Player")
@onready var heart_container = $MarginContainer/HBoxContainer 
@onready var score_label = $MarginContainer2/ScoreLabel
@onready var tex_full = preload("res://stuff/heart_full.tres")
@onready var tex_half = preload("res://stuff/heart_half.tres") 
@onready var tex_empty = preload("res://stuff/heart_empty.tres")
@onready var ult_bar = $UltBar

var last_hp: int = -1
var flash_mat: ShaderMaterial

func _ready():
	add_to_group("hud")
	update_score_display()
	
	flash_mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform float flash_value : hint_range(0.0, 1.0) = 0.0;
	void fragment() {
		vec4 c = texture(TEXTURE, UV);
		c.rgb = mix(c.rgb, vec3(1.0, 1.0, 1.0), flash_value);
		COLOR = c;
	}
	"""
	flash_mat.shader = shader
	heart_container.material = flash_mat
	
	for child in heart_container.get_children():
		child.use_parent_material = true

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
	
	if last_hp != -1 and current_hp < last_hp:
		flash_hearts()
	last_hp = current_hp
	
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

func flash_hearts():
	var tween = create_tween()
	
	tween.tween_callback(func(): flash_mat.set_shader_parameter("flash_value", 1.0))
	tween.tween_interval(0.08)
	
	tween.tween_callback(func(): flash_mat.set_shader_parameter("flash_value", 0.0))
	tween.tween_interval(0.08)
	
	tween.tween_callback(func(): flash_mat.set_shader_parameter("flash_value", 1.0))
	tween.tween_interval(0.08)
	
	tween.tween_callback(func(): flash_mat.set_shader_parameter("flash_value", 0.0))

func update_meters():
	if ult_bar:
		ult_bar.max_value = player.max_ult_charge
		ult_bar.value = lerp(ult_bar.value, float(player.current_ult_charge), 0.1)
		if abs(ult_bar.value - player.current_ult_charge) < 0.5:
			ult_bar.value = player.current_ult_charge
