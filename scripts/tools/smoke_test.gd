extends SceneTree
## Headless smoke test: load main scene, spawn & throw a snowball.
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
	await process_frame
	await process_frame

	var player := root.get_node_or_null("Main/Player")
	if player == null:
		push_error("[smoke] Player missing")
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

	await create_timer(0.5).timeout

	var xr := root.get_node_or_null("XRManager")
	var game_state := root.get_node_or_null("GameState")
	if xr:
		print("[smoke] XR active: ", xr.get("is_xr_active"))
	print("[smoke] Player at: ", player.global_position)
	if game_state:
		print("[smoke] GameState health: ", game_state.get("player_health"))

	print("[smoke] OK")
	quit(0)
