extends SceneTree
## Headless smoke test: load main scene, verify bot, spawn & throw a snowball.
## Run: godot --headless --xr-mode off --path . -s res://scripts/tools/smoke_test.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[smoke] Loading main scene...")
	var packed := load("res://scenes/main.tscn")
	if packed == null:
		push_error("[smoke] Failed to load main.tscn")
		quit(1)
		return

	var main: Node = packed.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var player := root.get_node_or_null("Main/Player")
	var bot := root.get_node_or_null("Main/Bot")
	if player == null:
		push_error("[smoke] Player missing")
		quit(1)
		return
	if bot == null:
		push_error("[smoke] Bot missing")
		quit(1)
		return

	var snowball_scene: PackedScene = load("res://scenes/snowball/snowball.tscn")
	if snowball_scene == null:
		push_error("[smoke] Snowball scene missing")
		quit(1)
		return

	var ball: Node = snowball_scene.instantiate()
	main.add_child(ball)
	if ball is Node3D:
		(ball as Node3D).global_position = Vector3(0, 2, 0)
	if ball.has_method("throw_with_velocity"):
		ball.call("throw_with_velocity", Vector3(0, 1, -8))
	else:
		push_error("[smoke] throw_with_velocity missing")
		quit(1)
		return

	# Bot throw path.
	if bot.has_method("force_throw_at_target"):
		bot.call("force_throw_at_target")

	# Direct hit registration check.
	var game_state := root.get_node_or_null("GameState")
	if game_state:
		game_state.call("apply_damage", &"bot", 20.0, &"player")
		if bot.has_method("on_snowball_hit"):
			bot.call("on_snowball_hit", 20.0, &"player")

	await create_timer(0.5).timeout

	print("[smoke] Bot at: ", bot.global_position)
	print("[smoke] Player at: ", player.global_position)
	if game_state:
		var bot_hp: float = game_state.call("get_health", &"bot")
		print("[smoke] player HP: ", game_state.call("get_health", &"player"))
		print("[smoke] bot HP: ", bot_hp)
		if bot_hp > 80.0:
			push_error("[smoke] Expected bot HP <= 80 after hit")
			quit(1)
			return

	print("[smoke] OK")
	quit(0)
