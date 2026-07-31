extends CharacterBody3D
class_name Player
## Dual-mode player: OpenXR (headset + hands) or PC first-person.

signal mode_changed(vr: bool)

const WALK_SPEED := 4.5
const SPRINT_SPEED := 7.0
const JUMP_VELOCITY := 4.8
const MOUSE_SENSITIVITY := 0.0022
const VR_MOVE_SPEED := 3.5

@export var damage_id: StringName = &"player"
@export var max_health: float = 100.0

var health: float = 100.0
var _pc_yaw: float = 0.0
var _pc_pitch: float = 0.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var pc_root: Node3D = $PCMode
@onready var pc_camera: Camera3D = $PCMode/Camera3D
@onready var pc_hold: Marker3D = $PCMode/Camera3D/HoldPoint
@onready var pc_snow: PCSnowInteract = $PCMode/PCSnowInteract
@onready var vr_origin: XROrigin3D = $VRMode
@onready var vr_camera: XRCamera3D = $VRMode/XRCamera3D
@onready var left_controller: XRController3D = $VRMode/LeftHand
@onready var right_controller: XRController3D = $VRMode/RightHand
@onready var body_mesh: MeshInstance3D = $BodyMesh


func _ready() -> void:
	add_to_group("damageable")
	add_to_group("player")
	health = max_health
	GameState.max_health = max_health
	GameState.player_health = health

	if pc_snow:
		pc_snow.camera = pc_camera
		pc_snow.hold_point = pc_hold
		pc_snow.owner_id = damage_id

	XRManager.xr_session_changed.connect(_on_xr_session_changed)
	_apply_mode(XRManager.is_xr_active)

	if not XRManager.is_xr_active:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if XRManager.is_xr_active:
		return

	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		_pc_yaw -= motion.relative.x * MOUSE_SENSITIVITY
		_pc_pitch -= motion.relative.y * MOUSE_SENSITIVITY
		_pc_pitch = clampf(_pc_pitch, deg_to_rad(-85.0), deg_to_rad(85.0))
		rotation.y = _pc_yaw
		pc_camera.rotation.x = _pc_pitch


func _physics_process(delta: float) -> void:
	if XRManager.is_xr_active:
		_process_vr_movement(delta)
	else:
		_process_pc_movement(delta)


func on_snowball_hit(_damage: float, _attacker_id: StringName) -> void:
	# Health is owned by GameState; this only handles local feedback.
	health = GameState.player_health
	if body_mesh and body_mesh.material_override is StandardMaterial3D:
		var mat := body_mesh.material_override as StandardMaterial3D
		var original := mat.albedo_color
		mat.albedo_color = Color(1.0, 0.45, 0.45)
		await get_tree().create_timer(0.12).timeout
		if is_instance_valid(mat):
			mat.albedo_color = original


func _on_xr_session_changed(active: bool) -> void:
	_apply_mode(active)


func _apply_mode(vr: bool) -> void:
	pc_root.visible = not vr
	pc_camera.current = not vr
	vr_origin.visible = vr
	vr_camera.current = vr
	body_mesh.visible = not vr
	# Keep a capsule for locomotion in both modes.
	collision_shape.disabled = false
	mode_changed.emit(vr)


func _process_pc_movement(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()


func _process_vr_movement(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Locomotion from left controller thumbstick, oriented by headset yaw.
	var stick := Vector2.ZERO
	if left_controller and left_controller.get_is_active():
		stick = Vector2(
			left_controller.get_vector2("primary").x,
			-left_controller.get_vector2("primary").y
		)

	var yaw_basis := Basis(Vector3.UP, vr_camera.global_rotation.y)
	var direction := (yaw_basis * Vector3(stick.x, 0.0, stick.y))
	if direction.length_squared() > 0.01:
		direction = direction.normalized()
		velocity.x = direction.x * VR_MOVE_SPEED
		velocity.z = direction.z * VR_MOVE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, VR_MOVE_SPEED)
		velocity.z = move_toward(velocity.z, 0.0, VR_MOVE_SPEED)

	# Snap-turn with right stick X.
	if right_controller and right_controller.get_is_active():
		var turn := right_controller.get_vector2("primary").x
		if absf(turn) > 0.65:
			rotate_y(deg_to_rad(-45.0 * signf(turn)) * delta * 4.0)

	move_and_slide()

	# Keep XR origin glued to character capsule for world locomotion.
	vr_origin.global_position = global_position
