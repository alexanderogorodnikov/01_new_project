extends Node3D
## Bootstraps the arena session and places the player on the spawn marker.

@onready var arena: Node3D = $Arena
@onready var player: Player = $Player


func _ready() -> void:
	GameState.reset_match()
	if arena and player and arena.has_method("get_player_spawn_transform"):
		var spawn: Transform3D = arena.get_player_spawn_transform()
		player.global_transform = spawn
	print("VR Snowball Fight ready. XR active: ", XRManager.is_xr_active)
