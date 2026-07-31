extends Node3D
class_name HandSnowInteract
## VR hand: grab snow near the ground (grip), then throw on release with controller impulse.

const GRAB_REACH := 0.55
const MIN_THROW_SPEED := 1.2
const THROW_SCALE := 1.35
const SNOWBALL_SCENE := preload("res://scenes/snowball/snowball.tscn")

@export var controller: XRController3D
@export var snow_probe: RayCast3D
@export var hold_point: Marker3D
@export var owner_id: StringName = &"player"

var _held_snowball: Snowball
var _prev_global_pos: Vector3
var _velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	if controller == null:
		controller = get_parent() as XRController3D
	if snow_probe == null and controller:
		snow_probe = controller.get_node_or_null("SnowProbe") as RayCast3D
	if hold_point == null and controller:
		hold_point = controller.get_node_or_null("HoldPoint") as Marker3D
	_prev_global_pos = global_position
	if controller:
		controller.button_pressed.connect(_on_button_pressed)
		controller.button_released.connect(_on_button_released)


func _physics_process(delta: float) -> void:
	if delta <= 0.0:
		return
	var pos := global_position
	_velocity = (pos - _prev_global_pos) / delta
	_prev_global_pos = pos

	if _held_snowball and is_instance_valid(_held_snowball):
		_held_snowball.global_transform = hold_point.global_transform


func _on_button_pressed(button_name: String) -> void:
	if button_name == "grip_click" or button_name == "trigger_click":
		_try_grab_snow()


func _on_button_released(button_name: String) -> void:
	if button_name == "grip_click" or button_name == "trigger_click":
		_try_throw()


func _try_grab_snow() -> void:
	if _held_snowball and is_instance_valid(_held_snowball):
		return
	if not _is_near_snow():
		return

	var ball: Snowball = SNOWBALL_SCENE.instantiate()
	ball.owner_id = owner_id
	var world := get_tree().current_scene
	if world == null:
		world = get_tree().root.get_node_or_null("Main")
	if world == null:
		world = get_tree().root
	world.add_child(ball)
	ball.attach_to(hold_point)
	_held_snowball = ball


func _try_throw() -> void:
	if _held_snowball == null or not is_instance_valid(_held_snowball):
		_held_snowball = null
		return

	var throw_vel := _velocity * THROW_SCALE
	if throw_vel.length() < MIN_THROW_SPEED:
		# Soft drop if barely moving.
		throw_vel = -global_transform.basis.z * MIN_THROW_SPEED

	_held_snowball.throw_with_velocity(throw_vel)
	_held_snowball = null


func _is_near_snow() -> bool:
	if snow_probe and snow_probe.is_colliding():
		var collider := snow_probe.get_collider()
		if collider and (collider.is_in_group("snow_surface") or collider.is_in_group("world")):
			return snow_probe.get_collision_point().distance_to(global_position) <= GRAB_REACH

	# Fallback: height check against snow plane around y=0.
	return global_position.y <= GRAB_REACH + 0.05
