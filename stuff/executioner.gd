extends BaseFighter

@onready var aim_sprite = $AimPivot/AimSprite
@onready var attack_area = $AimPivot/AttackArea

var is_pink_aura_active: bool = false
var max_ult_charge: int = 250
var current_ult_charge: int = 0
var aura_tween: Tween

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if crosshair: crosshair.z_index = 1000
	current_hp = max_hp
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	if has_node("AimPivot/AimSprite"): $AimPivot/AimSprite.hide()

func _physics_process(delta: float):
	if Input.is_action_just_pressed("special_r") and not is_using_skill:
		toggle_pink_aura()
		
	super._physics_process(delta)

func update_animation():
	if is_attacking: return
	
	if $AnimatedSprite2D.animation != "normal":
		$AnimatedSprite2D.play("normal")
		
	$AnimatedSprite2D.flip_h = get_global_mouse_position().x < global_position.x

func perform_punch():
	is_attacking = true
	var mouse_pos = get_global_mouse_position()
	
	$AnimatedSprite2D.flip_h = mouse_pos.x < global_position.x
	
	if has_node("AudioManager"): 
		$AudioManager.play_random_sound($AudioManager.light_whiffs)
	
	execute_hitbox()
	
	await get_tree().create_timer(punch_cooldown, false, false, true).timeout
	is_attacking = false

func toggle_pink_aura():
	is_pink_aura_active = !is_pink_aura_active
	
	if aura_tween: aura_tween.kill()
	
	if is_pink_aura_active:
		$AnimatedSprite2D.modulate = Color(5.0, 3.0, 5.0, 1.0) 
		aura_tween = create_tween()
		aura_tween.tween_property($AnimatedSprite2D, "modulate", Color(2.5, 1.2, 2.0, 1.0), 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	else:
		$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)

func _on_frame_changed():
	var current_anim = $AnimatedSprite2D.animation
	var current_frame = $AnimatedSprite2D.frame
	
	if current_anim.begins_with("m1"):
		if current_frame == 1: 
			execute_hitbox()

func execute_hitbox():
	var hit_enemy = false
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	
	var locked_aim_direction = Vector2.RIGHT
	if has_node("AimPivot"):
		locked_aim_direction = Vector2.RIGHT.rotated($AimPivot.rotation)
	
	for enemy in all_enemies:
		if not is_instance_valid(enemy): continue
		
		var distance = global_position.distance_to(enemy.global_position)
		var dir_to_enemy = global_position.direction_to(enemy.global_position)
		var is_in_front = locked_aim_direction.dot(dir_to_enemy) > 0.3
		
		if $AimPivot/AttackArea.overlaps_body(enemy) or (distance <= 65 and is_in_front):
			if enemy.has_method("take_damage"):
				if enemy in enemies_hit_this_punch: continue
					
				enemies_hit_this_punch.append(enemy)
				hit_enemy = true
				
				var base_damage: int = 15 + (current_combo * 3) 
				var knockback_distance: float = 10.0 + (current_combo * 4.0)
				
				if is_pink_aura_active:
					base_damage = int(base_damage * 1.5)
					knockback_distance += 5.0
					
				var shove_dir = global_position.direction_to(enemy.global_position)
				enemy.global_position += shove_dir * knockback_distance
				enemy.take_damage(base_damage)
				
				if "damage_popup_scene" in self and damage_popup_scene:
					var popup = damage_popup_scene.instantiate()
					popup.global_position = enemy.global_position + Vector2(0, -10)
					get_tree().current_scene.add_child(popup)
					if popup.has_method("setup"): popup.setup(base_damage, current_combo, is_pink_aura_active)
				
				if has_method("add_ult_charge"):
					add_ult_charge(base_damage)

	if hit_enemy:
		shake_camera(8.0 if current_combo >= 3 else 4.0)

func _on_animation_finished():
	if $AnimatedSprite2D.animation.begins_with("m1"):
		if has_node("AimPivot/AimSprite"): $AimPivot/AimSprite.hide()
		punch_cooldown = 0.35 if current_combo == 3 else 0.15 
		is_attacking = false

func shake_camera(intensity: float):
	var camera = $Camera2D
	if not camera: return
	var shake_tween = create_tween()
	for i in range(4):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		shake_tween.tween_property(camera, "offset", offset, 0.04)
		intensity *= 0.5
	shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)

func add_ult_charge(amount: int):
	if current_ult_charge >= max_ult_charge: return
	current_ult_charge = min(current_ult_charge + amount, max_ult_charge)
