extends KinematicBody

onready var gun_3 = $Head/Camera/Hand/Gun3
onready var gun_2 = $Head/Camera/Hand/Gun2
onready var gun_1 = $Head/Camera/Hand/Gun1
onready var gun_camera = $Head/Camera/ViewportContainer/Viewport/GunCamera
onready var camera = $Head/Camera
onready var gun_cast = $Head/Camera/GunCast
onready var tween = $Tween
onready var chest_ray = $WallCheckChest
onready var head_rays = $HeadRays
onready var debug_overlay = $CanvasLayer/Control/DebugOverlay
onready var ground_check = $GroundCheck
onready var jump_cayote_timer = $JumpCayoteTimer
onready var head_bumper_cast = $HeadBumperCast
onready var jump_buffer_timer = $JumpBufferTimer
onready var sprint_timer = $SprintTimer
onready var wall_run_timer = $WallRunTimer
onready var head = $Head
onready var gun_fire_sfx = $GunFireSFX
onready var grapple_cast = $Head/Camera/GrappleCast

var full_contact = false
var sprinting = false
var w_runnable = false
var called_climb = false
var can_climb = false
var can_jump = false
var grappling = false
var hookpoint_get = false


export var gravity = 20
export var jump_speed = 10
export var wall_friction = 10

export var default_speed = 7
export var sprint_speed = 14
export var air_accel = 2
export var normal_accel = 8

export var mouse_sens = .08


var speed
var h_accel = 0
var v_vel = 0
var cur_weapon = 1

var hook_point = Vector3()
var wall_normal = Vector3()
var gravity_vec = Vector3()
var h_vel = Vector3()
var movement = Vector3()
var dir = Vector3()

enum{
	IDLE,
	MOVING,
	CLIMBING
}
var cur_state = IDLE

func _input(event):
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				if cur_weapon < 3:
					cur_weapon += 1
				else:
					cur_weapon = 1
			elif event.button_index == BUTTON_WHEEL_DOWN:
				if cur_weapon > 1:
					cur_weapon -= 1
				else:
					cur_weapon = 3
	# CAPTURE MOUSE SYSTEM
	if event is InputEventMouseMotion and cur_state != CLIMBING:
		rotate_y(deg2rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
	if Input.is_mouse_button_pressed(1):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	gun_camera.global_transform = camera.global_transform	
func _physics_process(delta):
	
	
	# DEBUG OVERLAY - start -----------------
	debug_overlay()
	# DEBUG OVERLAY - end  ------------------
	
	# WEAPON SELECT
	weapon_select()

	# SET DEFAULT VARS
	speed = default_speed
	dir = Vector3()
	
	# GET INPUT
	dir = get_input_dir()
	
	# CHECK IF CAN CLIMB
	can_climb_check()
	
	# FIRE GUN
#	fire_gun()
	
	match cur_state:
		IDLE:
			if dir.length() != 0 and gravity_vec.y != 0:
				cur_state = MOVING
			# APPLY GRAVITY
			apply_gravity(delta)
			# JUMP
			jump()
			# CLIMB
			if Input.is_action_pressed("jump") and can_climb:
				grab_ledge()
			grapple()
			
			pass
		MOVING:
			if dir.length() == 0:
				cur_state = IDLE
			# SRPINT
			sprint()
			# APPLY GRAVITY
			apply_gravity(delta)
			# WALL RUN
			wall_run()
			# JUMP
			jump()
			# CLIMB
			if Input.is_action_pressed("jump") and can_climb:
				grab_ledge()
			grapple()
			pass
		CLIMBING:

			# Climb
			pass
	# APPLY VELOCITY
	h_vel = h_vel.linear_interpolate(dir * speed, h_accel * delta)
	movement.z = h_vel.z + gravity_vec.z
	movement.x = h_vel.x + gravity_vec.x
	movement.y = gravity_vec.y
	
	move_and_slide(movement, Vector3.UP)

func weapon_select():
	if Input.is_action_just_pressed("weapon_1"):
		cur_weapon = 1
	elif Input.is_action_just_pressed("weapon_2"):
		cur_weapon = 2
	elif Input.is_action_just_pressed("weapon_3"):
		cur_weapon = 3
	
	if cur_weapon == 1:
		gun_1.visible = true
		gun_1.fire(.5, 10,0)
	else:
		gun_1.visible = false
	if cur_weapon == 2:
		gun_2.visible = true
		gun_2.fire(1, 50,0)
	else:
		gun_2.visible = false
	if cur_weapon == 3:
		gun_3.visible = true
		gun_3.fire(.2, 25,1)
	else:
		gun_3.visible = false

#func fire_gun():
#	if Input.is_action_pressed("shoot"):
#		if not animation_player.is_playing():
#			gun_fire_sfx.pitch_scale = rand_range(1,.8)
#			gun_fire_sfx.play()
#			camera.translation = lerp(camera.translation, Vector3(rand_range(MAX_CAM_SHAKE, -MAX_CAM_SHAKE),rand_range(MAX_CAM_SHAKE, -MAX_CAM_SHAKE),0), .5)
#			if gun_cast.is_colliding():
#				var target = gun_cast.get_collider()
#				if target.is_in_group('Enemy'):
#					target.health -= damage
#		animation_player.play("fire")
#	else:
#		camera.translation = Vector3()
#		animation_player.stop()
func apply_gravity(delta):
	if ground_check.is_colliding():
		full_contact = true
	else: 
		full_contact = false
		
	if not is_on_floor():
		gravity_vec += gravity * Vector3.DOWN * delta
		h_accel = air_accel
		jump_cayote()
	elif is_on_floor() and full_contact:
		can_jump = true
		gravity_vec = -get_floor_normal() * gravity
		h_accel = normal_accel
		w_runnable = false
	else:
		can_jump = true
		gravity_vec = -get_floor_normal()
		h_accel = normal_accel


func get_input_dir():
	if Input.is_action_pressed("move_up"):
		dir -= transform.basis.z
	if Input.is_action_pressed("move_down"):
		dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		dir += transform.basis.x
	dir = dir.normalized()
	return dir

func sprint():
	if Input.is_action_just_pressed("ability") and not sprinting:
		sprinting = true
#		sprint_timer.start()
	elif Input.is_action_just_pressed("ability") and sprinting:
		sprinting = false
		
	if sprinting:
		speed = sprint_speed

func wall_run():
	if w_runnable:
		if Input.is_action_pressed("move_up"):
			if is_on_wall():
				wall_normal = get_slide_collision(0)
				yield(get_tree().create_timer(.15), "timeout")
				gravity_vec.y = gravity_vec.y/2
				dir = -wall_normal.normal 
				yield(get_tree().create_timer(.15), "timeout")
				gravity_vec.y = gravity_vec.y
				


func jump():
	# JUMP BUFFER (IF YOU PRESS JUMP .2 SECONDS BEFORE LANDING IT WILL APPLY YOUR INPUT)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()
	if !jump_buffer_timer.is_stopped() and is_on_floor():
		gravity_vec = jump_speed * Vector3.UP
		w_runnable = true
		wall_run_timer.start()
	# MAIN JUMP CODE
	if Input.is_action_just_pressed("jump") and can_jump:
		gravity_vec = jump_speed * Vector3.UP
		w_runnable = true
		wall_run_timer.start()
	# WALL JUMP
	if Input.is_action_just_pressed("jump") and is_on_wall() and w_runnable :
		wall_run_timer.stop()
		wall_run_timer.start()
		wall_normal = get_slide_collision(0)
		h_vel += wall_normal.normal * jump_speed
#		gravity_vec.y = jump_speed/2

func jump_cayote():
	yield(get_tree().create_timer(.1), "timeout")
	can_jump = false

# CLIMBING SYSTEM START ----------- 
 
func can_climb_check():
	if !chest_ray.is_colliding():
		can_climb = false
	else:
		can_climb = true
	for r in head_rays.get_children():
		if r.is_colliding():
			can_climb = false
	pass
func grab_ledge():
	dir = Vector3.ZERO
	h_vel = Vector3.ZERO
	gravity_vec = Vector3.ZERO
	cur_state = CLIMBING
	climb_ledge()
	print('grab_ledge')
	pass
func climb_ledge():
	if called_climb:
		return
	called_climb = true
	climb()
	print('climb_ledge')
	pass
func climb():
	h_vel = Vector3.ZERO
	movement = Vector3.ZERO
	var v_climb_move_duration = .3
	var h_climb_move_duration = .15
	
	var v_climb_move = global_transform.origin + Vector3(0,3,0)
	tween.interpolate_property(self, 'global_transform:origin', null,v_climb_move, v_climb_move_duration, Tween.TRANS_CUBIC, Tween.EASE_IN)
	
	tween.start()
	
	yield(tween, "tween_all_completed")
	
	var h_climb_move = global_transform.origin + (-global_transform.basis.z * 1.2)
	tween.interpolate_property(self, 'global_transform:origin', null,h_climb_move, h_climb_move_duration, Tween.TRANS_CUBIC, Tween.EASE_IN)
	
	tween.start()
	climb_ledge_completed()
	pass

func climb_ledge_completed():
	called_climb = false
	cur_state = IDLE
	print('climbed ledge')

# CLIMBING SYSTEM END ----------- 

func grapple():
	if Input.is_action_just_pressed("grapple"):
		if grapple_cast.is_colliding():
			if not grappling:
				grappling = true
	if grappling:
		gravity_vec.y = 0
		if not hookpoint_get:
			hook_point = grapple_cast.get_collision_point() + Vector3(0,1.5,0)
			hookpoint_get = true
		if hook_point.distance_to(transform.origin) > 1:
			if hookpoint_get:
				transform.origin = lerp(transform.origin, hook_point, .2)
		else:
			grappling = false
			hookpoint_get = false
	if head_bumper_cast.is_colliding():
		grappling = false
		hook_point = null
		hookpoint_get = false
		global_translate(Vector3(0,-1,0))
	pass

func debug_overlay():
	debug_overlay.text = str(
		'fps: ', Engine.get_frames_per_second(), '\n',
		'Input/ Velocity: ', dir,'(',dir.length(),')','/ ', Vector3(floor(movement.x),floor(movement.y),floor(movement.z)),'(', floor(movement.length()),')', '\n',
		
		'Input/ Velocity: ','(',dir.length(),')','/ ','(', floor(h_vel.length()),')','(',dir.length(),')', '\n',
		
		'is on floor/ wall: ', is_on_floor(),'/ ',is_on_wall(), '\n',
		'wall runnable: ', w_runnable,'\n',
		'can climb: ', can_climb,'\n',
		'current state: ' , cur_state,'\n',
		'can jump: ', can_jump, '\n'
		
	)


func _on_SprintTimer_timeout():
	sprinting = false


func _on_WallRunTimer_timeout():
	w_runnable = false
