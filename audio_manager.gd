extends Node

@export var light_impacts: Array[AudioStream]
@export var heavy_impacts: Array[AudioStream]
@export var light_whiffs: Array[AudioStream]
@export var heavy_whiffs: Array[AudioStream]
@export var blocks: Array[AudioStream]
@export var dashes: Array[AudioStream]
@export var footsteps_run: Array[AudioStream]
@export var footsteps_walk: Array[AudioStream]

func play_random_sound(sound_array: Array[AudioStream], base_pitch: float = 1.0, pitch_variance: float = 0.1, volume_change: float = 0.0):
	if sound_array.is_empty(): 
		return
		
	var player = AudioStreamPlayer.new()
	player.stream = sound_array.pick_random()
	player.bus = "SFX"
	
	player.pitch_scale = randf_range(base_pitch - pitch_variance, base_pitch + pitch_variance)
	
	player.volume_db = volume_change
	
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
