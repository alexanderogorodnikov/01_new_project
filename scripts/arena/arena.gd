extends Node3D
## Snow arena helpers: spawn points and boundary clamps for future AI / netcode.

@export var arena_half_size: float = 18.0

@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var bot_spawn: Marker3D = $BotSpawn


func get_player_spawn_transform() -> Transform3D:
	return player_spawn.global_transform if player_spawn else global_transform


func get_bot_spawn_transform() -> Transform3D:
	return bot_spawn.global_transform if bot_spawn else global_transform


func clamp_to_arena(world_pos: Vector3) -> Vector3:
	var half := arena_half_size - 0.5
	return Vector3(
		clampf(world_pos.x, -half, half),
		world_pos.y,
		clampf(world_pos.z, -half, half)
	)
