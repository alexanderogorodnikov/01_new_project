extends Node
## Shared match/session state for future multiplayer and AI stages.

signal health_changed(target_id: StringName, health: float, max_health: float)
signal snowball_hit(attacker_id: StringName, target_id: StringName, damage: float)

const DEFAULT_MAX_HEALTH := 100.0

var player_health: float = DEFAULT_MAX_HEALTH
var max_health: float = DEFAULT_MAX_HEALTH
var is_vr_active: bool = false


func reset_match() -> void:
	player_health = max_health
	health_changed.emit(&"player", player_health, max_health)


func apply_damage(target_id: StringName, damage: float, attacker_id: StringName = &"") -> void:
	if target_id == &"player":
		player_health = maxf(0.0, player_health - damage)
		health_changed.emit(target_id, player_health, max_health)
	snowball_hit.emit(attacker_id, target_id, damage)
