extends Spatial

onready var camera = $".."

const ADS_LERP = 20

export var default_pos : Vector3
export var ads_pos : Vector3

func _process(delta):
	if Input.is_action_pressed("fire2"):
		camera.fov = 70
		transform.origin = transform.origin.linear_interpolate(ads_pos, ADS_LERP * delta)
	else:
		camera.fov = 90
		transform.origin = transform.origin.linear_interpolate(default_pos, ADS_LERP * delta)
		
