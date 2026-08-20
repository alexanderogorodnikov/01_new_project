extends Node
## Shared match/session state for fighters, hits, and future multiplayer.

signal health_changed(target_id: StringName, health: float, max_health: float)
signal snowball_hit(attacker_id: StringName, target_id: StringName, damage: float)

const DEFAULT_MAX_HEALTH := 100.0

var player_health: float = DEFAULT_MAX_HEALTH
var max_health: float = DEFAULT_MAX_HEALTH
var is_vr_active: bool = false

var _health: Dictionary = {} # StringName -> float
var _max_health: Dictionary = {} # StringName -> float


func _ready() -> void:
	register_fighter(&"player", DEFAULT_MAX_HEALTH)


func reset_match() -> void:
	for id in _max_health.keys():
		_health[id] = _max_health[id]
		health_changed.emit(id, _health[id], _max_health[id])
	player_health = get_health(&"player")
	max_health = get_max_health(&"player")


func register_fighter(fighter_id: StringName, fighter_max_health: float = DEFAULT_MAX_HEALTH) -> void:
	_max_health[fighter_id] = fighter_max_health
	_health[fighter_id] = fighter_max_health
	if fighter_id == &"player":
		max_health = fighter_max_health
		player_health = fighter_max_health
	health_changed.emit(fighter_id, fighter_max_health, fighter_max_health)


func get_health(fighter_id: StringName) -> float:
	return float(_health.get(fighter_id, DEFAULT_MAX_HEALTH))


func get_max_health(fighter_id: StringName) -> float:
	return float(_max_health.get(fighter_id, DEFAULT_MAX_HEALTH))


func set_health(fighter_id: StringName, value: float) -> void:
	var mx := get_max_health(fighter_id)
	_health[fighter_id] = clampf(value, 0.0, mx)
	if fighter_id == &"player":
		player_health = _health[fighter_id]
	health_changed.emit(fighter_id, _health[fighter_id], mx)


func apply_damage(target_id: StringName, damage: float, attacker_id: StringName = &"") -> void:
	if target_id == attacker_id:
		return
	if not _health.has(target_id):
		register_fighter(target_id, DEFAULT_MAX_HEALTH)
	_health[target_id] = maxf(0.0, float(_health[target_id]) - damage)
	if target_id == &"player":
		player_health = _health[target_id]
	health_changed.emit(target_id, _health[target_id], get_max_health(target_id))
	snowball_hit.emit(attacker_id, target_id, damage)
