extends Node3D

# 3D Kamera kontroler za orbit kameru

@onready var camera: Camera3D = $Camera3D

var is_rotating = false
var rotation_speed = 0.005
var zoom_speed = 0.5
var min_distance = 2.0
var max_distance = 20.0
var camera_distance = 10.0

var yaw = 0.0  # Rotacija oko Y ose
var pitch = -30.0  # Rotacija oko X ose

var target_position = Vector3.ZERO  # Centar oko kog rotiramo

func _ready():
	# Proveri da li kamera postoji
	if not camera:
		print("GREŠKA: Camera3D ne postoji kao child!")
		return
	
	setup_camera()

func setup_camera():
	# Postavi kameru na početnu poziciju
	update_camera_position()

func _input(event):
	# Rotacija kamere - DESNI KLIK + povlačenje
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_rotating = true
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				is_rotating = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		# Zoom - točkić miša
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = clamp(camera_distance - zoom_speed, min_distance, max_distance)
			update_camera_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = clamp(camera_distance + zoom_speed, min_distance, max_distance)
			update_camera_position()
	
	elif event is InputEventMouseMotion and is_rotating:
		# Rotacija kamere
		yaw -= event.relative.x * rotation_speed
		pitch -= event.relative.y * rotation_speed
		pitch = clamp(pitch, -89.0, 89.0)  # Spreči gimbal lock
		
		update_camera_position()

func update_camera_position():
	if not camera:
		return
	
	# Izračunaj poziciju kamere na osnovu yaw, pitch i distance
	var offset = Vector3.ZERO
	offset.x = camera_distance * cos(deg_to_rad(pitch)) * sin(deg_to_rad(yaw))
	offset.y = camera_distance * sin(deg_to_rad(pitch))
	offset.z = camera_distance * cos(deg_to_rad(pitch)) * cos(deg_to_rad(yaw))
	
	camera.position = target_position + offset
	camera.look_at(target_position, Vector3.UP)

func reset_camera():
	# Resetuj kameru na default poziciju
	yaw = 0.0
	pitch = -30.0
	camera_distance = 10.0
	update_camera_position()
