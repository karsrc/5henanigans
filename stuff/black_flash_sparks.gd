extends Node2D

@onready var huge_spark = $HugeSpark
@onready var small_spark = $SmallSpark
@onready var audio1 = $Audio1
@onready var audio2 = $Audio2

var spark_velocity = Vector2.ZERO

func _ready():
	set_as_top_level(true)
	
	if audio1:
		audio1.volume_db = 8.0
		audio1.play()
	if audio2:
		audio2.volume_db = 8.0
		audio2.play()
		
	if huge_spark:
		huge_spark.rotation_degrees = randf_range(0, 360)
		huge_spark.flip_h = randf() > 0.5
		huge_spark.flip_v = randf() > 0.5
		huge_spark.scale = Vector2(4.0, 4.0)
		huge_spark.play()
		
	if small_spark:
		var random_offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		small_spark.position = random_offset
		small_spark.rotation_degrees = randf_range(0, 360)
		small_spark.scale = Vector2(2.5, 2.5)
		small_spark.play()
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	fade_tween.finished.connect(queue_free)

func _physics_process(delta):
	if spark_velocity != Vector2.ZERO:
		global_position += spark_velocity * delta
		spark_velocity = spark_velocity.move_toward(Vector2.ZERO, 3500 * delta)
