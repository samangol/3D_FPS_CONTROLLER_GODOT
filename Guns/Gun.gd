extends Spatial

onready var gun_cast = $"../../GunCast"
onready var camera = $"../.."
onready var gun_fire_sfx = $GunFireSFX
onready var animation_player = $AnimationPlayer

const MAX_CAM_SHAKE = .1

func fire(fire_rate, damage, fire_type):
	if fire_type == 0:
		if Input.is_action_just_pressed("shoot"):
			if not animation_player.is_playing():
				gun_fire_sfx.pitch_scale = rand_range(1,.8)
				gun_fire_sfx.play()
				camera.translation = lerp(camera.translation, Vector3(rand_range(MAX_CAM_SHAKE, -MAX_CAM_SHAKE),rand_range(MAX_CAM_SHAKE, -MAX_CAM_SHAKE),0), .5)
				if gun_cast.is_colliding():
					var target = gun_cast.get_collider()
					if target.is_in_group('Enemy'):
						
						target.hp -= damage
			animation_player.play("fire")
			
		else:
			camera.translation = Vector3()
			animation_player.stop()
	if fire_type == 1:
		if Input.is_action_pressed("shoot"):
			if not animation_player.is_playing():
				gun_fire_sfx.pitch_scale = rand_range(1,.8)
				gun_fire_sfx.play()
				camera.translation = lerp(camera.translation, Vector3(rand_range(MAX_CAM_SHAKE, -MAX_CAM_SHAKE),rand_range(MAX_CAM_SHAKE, -MAX_CAM_SHAKE),0), .5)
				if gun_cast.is_colliding():
					var target = gun_cast.get_collider()
					if target.is_in_group('Enemy'):
						target.hp -= damage
			animation_player.play("fire")
			yield(get_tree().create_timer(fire_rate), "timeout")
		else:
			camera.translation = Vector3()
			animation_player.stop()
