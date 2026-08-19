extends CharacterBody3D
class_name SnowBot
## Arena opponent: patrols, dodges incoming snowballs, and throws at the player.

enum State { PATROL, ENGAGE, DODGE, THROW, STUN }

const MOVE_SPEED := 3.6
const DODGE_SPEED := 7.2
const TURN_SPEED := 8.0
const PREFERRED_DIST := 10.0
const MIN_DIST := 4.5
const MAX_DIST := 16.0
const THROW_COOLDOWN := 2.2
const THROW_WINDUP := 0.35
const SNOWBALL_SPEED := 14.0
const ARENA_HALF := 17.0
const SNOWBALL_SCENE := preload("res://scenes/snowball/snowball.tscn")

@export var damage_id: StringName = &"bot"
@export var max_health: float = 100.0
@export var target_path: NodePath

var health: float = 100.0
var _state: State = State.PATROL
var _target: Node3D
var _throw_cd: float = 1.0
var _state_time: float = 0.0
var _patrol_point: Vector3 = Vector3.ZERO
var _dodge_dir: Vector3 = Vector3.ZERO

@onready var visual: CharacterVisual = $Visual
@onready var throw_point: Marker3D = $ThrowPoint
@onready var threat_area: Area3D = $ThreatSensor
@onready var nameplate: Label3D = $Nameplate


func _ready() -> void:
	add_to_group("damageable")
	add_to_group("bot")
	health = max_health
	GameState.register_fighter(damage_id, max_health)
	_pick_patrol_point()
	_resolve_target()
	if threat_area:
		threat_area.body_entered.connect(_on_threat_entered)
	_throw_cd = randf_range(0.6, 1.4)
	_set_state(State.ENGAGE)


func _physics_process(delta: float) -> void:
	_throw_cd = maxf(0.0, _throw_cd - delta)
	_state_time += delta
	if not is_on_floor():
		velocity += get_gravity() * delta

	_resolve_target()
	match _state:
		State.PATROL:
			_tick_patrol(delta)
		State.ENGAGE:
			_tick_engage(delta)
		State.DODGE:
			_tick_dodge(delta)
		State.THROW:
			_tick_throw(delta)
		State.STUN:
			_tick_stun(delta)

	_clamp_to_arena()
	move_and_slide()


func on_snowball_hit(damage: float, _attacker_id: StringName) -> void:
	health = GameState.get_health(damage_id)
	_flash_hit()
	_state = State.STUN
	_state_time = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	if health <= 0.0:
		_respawn()


func _resolve_target() -> void:
	if _target and is_instance_valid(_target):
		return
	if target_path != NodePath():
		_target = get_node_or_null(target_path) as Node3D
	if _target == null:
		_target = get_tree().get_first_node_in_group("player") as Node3D


func _tick_patrol(delta: float) -> void:
	if _target and _distance_to_target() <= MAX_DIST:
		_set_state(State.ENGAGE)
		return
	_move_toward(_patrol_point, MOVE_SPEED * 0.75, delta)
	if global_position.distance_to(_patrol_point) < 1.2:
		_pick_patrol_point()


func _tick_engage(delta: float) -> void:
	if _target == null:
		_set_state(State.PATROL)
		return

	var dist := _distance_to_target()
	if dist > MAX_DIST + 2.0:
		_set_state(State.PATROL)
		return

	_face_target(delta)

	var to_target := _flat_dir_to(_target.global_position)
	if dist > PREFERRED_DIST + 1.5:
		_apply_horizontal(to_target * MOVE_SPEED)
	elif dist < MIN_DIST:
		_apply_horizontal(-to_target * MOVE_SPEED)
	else:
		# Strafe to stay lively.
		var side := to_target.cross(Vector3.UP).normalized()
		var strafe := side * sin(_state_time * 1.7)
		_apply_horizontal(strafe * MOVE_SPEED * 0.85)

	if _throw_cd <= 0.0 and dist <= MAX_DIST and dist >= MIN_DIST * 0.8:
		_set_state(State.THROW)


func _tick_dodge(delta: float) -> void:
	_apply_horizontal(_dodge_dir * DODGE_SPEED)
	if _state_time >= 0.35:
		_set_state(State.ENGAGE)


func _tick_throw(delta: float) -> void:
	_apply_horizontal(Vector3.ZERO)
	if _target:
		_face_target(delta)
	if _state_time >= THROW_WINDUP:
		_do_throw()
		_throw_cd = THROW_COOLDOWN + randf_range(-0.3, 0.5)
		_set_state(State.ENGAGE)


func _tick_stun(_delta: float) -> void:
	_apply_horizontal(Vector3.ZERO)
	if _state_time >= 0.45:
		_set_state(State.ENGAGE if _target else State.PATROL)


func force_throw_at_target() -> void:
	## Public helper for demos / tests.
	_do_throw()


func _do_throw() -> void:
	if _target == null or throw_point == null:
		return
	var ball: Snowball = SNOWBALL_SCENE.instantiate()
	ball.owner_id = damage_id
	var world := get_tree().current_scene
	if world == null:
		world = get_tree().root.get_node_or_null("Main")
	if world == null:
		world = get_tree().root
	world.add_child(ball)
	ball.global_position = throw_point.global_position
	# Ensure _ready ran before throw.
	if not ball.is_inside_tree():
		return
	ball.throw_with_velocity(_aim_velocity())


func _aim_velocity() -> Vector3:
	var origin := throw_point.global_position
	var target_pos := _target.global_position + Vector3(0, 1.2, 0)
	# Simple lead: assume constant player velocity if CharacterBody3D.
	if _target is CharacterBody3D:
		var lead := (_target as CharacterBody3D).velocity * (origin.distance_to(target_pos) / SNOWBALL_SPEED)
		target_pos += lead * 0.65
	var to := target_pos - origin
	var dist := to.length()
	var dir := to.normalized()
	# Arc compensation.
	var up := clampf(dist * 0.045, 0.35, 1.6)
	dir = (dir + Vector3.UP * (up / maxf(dist, 0.01))).normalized()
	return dir * SNOWBALL_SPEED


func _on_threat_entered(body: Node) -> void:
	if _state == State.DODGE or _state == State.STUN or _state == State.THROW:
		return
	if not (body is Snowball):
		return
	var ball := body as Snowball
	if ball.owner_id == damage_id:
		return
	if not ball.is_in_flight():
		return
	# Dodge perpendicular to incoming velocity.
	var incoming: Vector3 = ball.linear_velocity
	if incoming.length_squared() < 1.0:
		incoming = global_position - ball.global_position
	var side := incoming.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.01:
		side = Vector3.RIGHT
	if randf() > 0.5:
		side = -side
	_dodge_dir = side
	_set_state(State.DODGE)


func _set_state(next: State) -> void:
	_state = next
	_state_time = 0.0
	if nameplate:
		nameplate.text = "Бот · %s" % _state_name(next)


func _state_name(state: State) -> String:
	match state:
		State.PATROL:
			return "патруль"
		State.ENGAGE:
			return "бой"
		State.DODGE:
			return "уклон"
		State.THROW:
			return "бросок"
		State.STUN:
			return "удар"
	return "?"


func _pick_patrol_point() -> void:
	_patrol_point = Vector3(
		randf_range(-ARENA_HALF * 0.7, ARENA_HALF * 0.7),
		0.2,
		randf_range(-ARENA_HALF * 0.7, ARENA_HALF * 0.7)
	)


func _move_toward(point: Vector3, speed: float, delta: float) -> void:
	var dir := _flat_dir_to(point)
	if dir.length_squared() > 0.001:
		_face_direction(dir, delta)
		_apply_horizontal(dir * speed)
	else:
		_apply_horizontal(Vector3.ZERO)


func _face_target(delta: float) -> void:
	if _target == null:
		return
	_face_direction(_flat_dir_to(_target.global_position), delta)


func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.0001:
		return
	var target_yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(TURN_SPEED * delta, 0.0, 1.0))


func _flat_dir_to(point: Vector3) -> Vector3:
	var d := point - global_position
	d.y = 0.0
	return d.normalized() if d.length_squared() > 0.0001 else Vector3.ZERO


func _distance_to_target() -> float:
	if _target == null:
		return INF
	var a := global_position
	var b := _target.global_position
	a.y = 0.0
	b.y = 0.0
	return a.distance_to(b)


func _apply_horizontal(v: Vector3) -> void:
	velocity.x = v.x
	velocity.z = v.z


func _clamp_to_arena() -> void:
	global_position.x = clampf(global_position.x, -ARENA_HALF, ARENA_HALF)
	global_position.z = clampf(global_position.z, -ARENA_HALF, ARENA_HALF)


func _flash_hit() -> void:
	if visual:
		await visual.flash_hit()


func _respawn() -> void:
	health = max_health
	GameState.set_health(damage_id, health)
	global_position = Vector3(0, 0.2, -12)
	_set_state(State.PATROL)
	_pick_patrol_point()
	print("Bot respawned")
