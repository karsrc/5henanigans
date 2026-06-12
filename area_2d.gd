extends Area2D

var speed: float = 750.0
var damage: int = 40
var direction: Vector2 = Vector2.RIGHT
var enemies_hit = []

func _ready():
	collision_mask = 2 
	if has_node("AnimatedSprite2D"):
		var sprite = $AnimatedSprite2D
		sprite.play()
		sprite.animation_finished.connect(queue_free)
	else:
		await get_tree().create_timer(1.5).timeout
		queue_free()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		if body in enemies_hit: return
		
		enemies_hit.append(body)
		body.take_damage(damage)
		body.global_position += direction * 60.0 
		
		if body.has_method("apply_slow"):
			body.apply_slow()
