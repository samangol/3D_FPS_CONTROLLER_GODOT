extends KinematicBody

onready var body = $Body
onready var ray_cast = $Body/RayCast

var vel = Vector3()
var v_vel = 0
var gravity = 40
var angular_acceleration = 50
var knockback
var knockback_dir = Vector3.ZERO
export var hp = 500
export var knockback_strength = 10
export var acceleration = 1000
export var friction = 50
export var max_speed = 10
export var enemy_xp = 5

var player

func _ready():
	yield(get_tree(), "idle_frame")
	var tree = get_tree()
	if tree.has_group('Player'):
		player = null

func take_damage(value, damage_source,knockback_multiplier):
	hp -= value
	knockback_dir = (global_translation - damage_source).normalized()
	knockback = knockback_dir * knockback_strength * knockback_multiplier
	
	
func on_death():
	queue_free()
	
	
func _physics_process(delta):
	
	if hp <= 0:
		on_death()
#	print(hp,' ',knockback)
# ---------------------------------- 19 oct 02:06 am ------------------ unfinshed
	if knockback != null:
		knockback = knockback.move_toward(Vector3.ZERO, delta * friction)
		knockback = move_and_slide(knockback, Vector3.UP)
		
	
	if player != null:
		var dir = global_translation.direction_to(player.global_translation)
		vel = vel.move_toward(dir * max_speed, delta * acceleration)
		body.rotation.y = lerp_angle(body.rotation.y, atan2(dir.x, dir.z), delta * angular_acceleration)
	else:
		vel = vel.move_toward(Vector3.ZERO, delta * acceleration)
	
	vel = move_and_slide(vel + (Vector3.UP * v_vel), Vector3.UP,true)
	
	if !is_on_floor():
		v_vel -= gravity * delta
	if ray_cast.is_colliding() and is_on_floor():
		v_vel = 75
	else:
		v_vel = -10
	
	

func _on_Area_body_entered(body):
	if body.is_in_group('Player'):
		player = get_tree().get_nodes_in_group('Player')[0]


func _on_Area_body_exited(body):
	if body.is_in_group('Player'):
		player = null
