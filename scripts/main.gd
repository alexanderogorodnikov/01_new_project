extends Node3D
## Bootstraps the arena session and places fighters on spawn markers.

@onready var arena: Node3D = $Arena
@onready var player: Player = $Player
@onready var bot: SnowBot = $Bot


func _ready() -> void:
	GameState.reset_match()
	if arena and arena.has_method("get_player_spawn_transform") and player:
		player.global_transform = arena.get_player_spawn_transform()
	if arena and arena.has_method("get_bot_spawn_transform") and bot:
		bot.global_transform = arena.get_bot_spawn_transform()
	print("VR Snowball Fight ready. XR active: ", XRManager.is_xr_active)
	if bot:
		print("Bot spawned at: ", bot.global_position)
