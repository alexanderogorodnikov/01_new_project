extends Node
class_name PCSnowInteract
## PC: aim with mouse, E / RMB to form a snowball, hold LMB to charge throw, release to throw.

const SNOWBALL_SCENE := preload("res://scenes/snowball/snowball.tscn")
const GRAB_MAX_DISTANCE := 3.5
const BASE_THROW_SPEED := 8.0
const MAX_THROW_SPEED := 18.0
const CHARGE_TIME := 0.85

@export var camera: Camera3D
@export var hold_point: Marker3D
@export var owner_id: StringName = &"player"

var _held_snowball: Snowball
var _charging: bool = false
var _charge: float = 0.0


func _physics_process(delta: float) -> void:
	if _held_snowball and is_instance_valid(_held_snowball) and hold_point:
		_held_snowball.global_transform = hold_point.global_transform

	if _charging and _held_snowball:
		_charge = minf(1.0, _charge + delta / CHARGE_TIME)


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_vr_active:
		return

	if event.is_action_pressed("grab_snow"):
		_try_grab_snow()
	elif event.is_action_pressed("throw_snowball"):
		if _held_snowball and is_instance_valid(_held_snowball):
			_charging = true
			_charge = 0.0
		else:
			# Convenience: grab then start charging if looking at snow.
			if _try_grab_snow():
				_charging = true
				_charge = 0.0
	elif event.is_action_released("throw_snowball"):
		if _charging:
			_throw_charged()
		_charging = false


func get_charge() -> float:
	return _charge if _charging else 0.0


func has_snowball() -> bool:
	return _held_snowball != null and is_instance_valid(_held_snowball)


func _try_grab_snow() -> bool:
	if _held_snowball and is_instance_valid(_held_snowball):
		return true
	if camera == null or hold_point == null:
		return false

	var hit := _raycast_from_camera()
	if hit.is_empty():
		return false

	var collider: Object = hit.get("collider")
	if collider == null:
		return false
	if not (collider.is_in_group("snow_surface") or collider.is_in_group("world")):
		return false

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
	return true


func _throw_charged() -> void:
	if _held_snowball == null or not is_instance_valid(_held_snowball):
		_held_snowball = null
		return
	if camera == null:
		return

	var speed := lerpf(BASE_THROW_SPEED, MAX_THROW_SPEED, _charge)
	var direction := -camera.global_transform.basis.z.normalized()
	# Slight upward arc for nicer throws.
	direction = (direction + Vector3.UP * 0.12).normalized()
	_held_snowball.throw_with_velocity(direction * speed)
	_held_snowball = null
	_charge = 0.0


func _raycast_from_camera() -> Dictionary:
	var space := camera.get_world_3d().direct_space_state
	var origin := camera.global_position
	var end := origin + (-camera.global_transform.basis.z) * GRAB_MAX_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = false
	query.collision_mask = 0b1001 # world + snow_surface
	return space.intersect_ray(query)
