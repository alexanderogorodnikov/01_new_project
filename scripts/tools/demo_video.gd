extends SceneTree
## Short automated gameplay clip for screen recording.
## Run (with display + ffmpeg capture), or alone:
##   godot --xr-mode off --path . -s res://scripts/tools/demo_video.gd


const DEMO_SECONDS := 10.0
const STEP := 1.0 / 30.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_position(Vector2i(40, 40))
	print("[demo_video] loading...")

	var packed := load("res://scenes/main.tscn")
	if packed == null:
		push_error("[demo_video] main.tscn missing")
		quit(1)
		return

	var main: Node = packed.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var player := root.get_node_or_null("Main/Player") as Node3D
	var bot := root.get_node_or_null("Main/Bot") as Node3D
	if player == null or bot == null:
		push_error("[demo_video] fighters missing")
		quit(1)
		return

	player.global_position = Vector3(0, 0.2, 8)
	player.rotation = Vector3.ZERO
	bot.global_position = Vector3(1.5, 0.2, -1)
	bot.look_at(player.global_position, Vector3.UP)

	var pc_cam := player.get_node_or_null("PCMode/Camera3D") as Camera3D
	if pc_cam:
		pc_cam.current = true
		pc_cam.rotation.x = deg_to_rad(-8.0)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("[demo_video] simulating for ", DEMO_SECONDS, "s")

	var elapsed := 0.0
	var throw_timer := 0.0
	var toss_count := 0
	while elapsed < DEMO_SECONDS:
		elapsed += STEP
		throw_timer += STEP

		if pc_cam and is_instance_valid(bot):
			var to_bot := (bot.global_position + Vector3(0, 1.2, 0)) - pc_cam.global_position
			var flat := Vector3(to_bot.x, 0.0, to_bot.z)
			if flat.length_squared() > 0.001:
				var target_yaw := atan2(-flat.x, -flat.z)
				player.rotation.y = lerp_angle(player.rotation.y, target_yaw, 0.08)
			var n := to_bot.normalized()
			var pitch := clampf(-asin(clampf(n.y, -1.0, 1.0)), deg_to_rad(-25.0), deg_to_rad(10.0))
			pc_cam.rotation.x = lerp_angle(pc_cam.rotation.x, pitch, 0.08)

		if throw_timer >= 1.6 and bot.has_method("force_throw_at_target"):
			throw_timer = 0.0
			bot.call("force_throw_at_target")

		# A few player throws spaced through the clip.
		if toss_count < 4 and elapsed > 1.2 + float(toss_count) * 2.0:
			toss_count += 1
			_player_throw(main, player, bot)

		await create_timer(STEP).timeout

	print("[demo_video] done")
	quit(0)


func _player_throw(main: Node, player: Node3D, bot: Node3D) -> void:
	var snowball_scene: PackedScene = load("res://scenes/snowball/snowball.tscn")
	if snowball_scene == null or bot == null:
		return
	var ball: Node = snowball_scene.instantiate()
	main.add_child(ball)
	var origin := player.global_position + Vector3(0.2, 1.4, 0)
	if ball is Node3D:
		(ball as Node3D).global_position = origin
	if "owner_id" in ball:
		ball.set("owner_id", &"player")
	var dir := (bot.global_position + Vector3(0, 1.2, 0) - origin).normalized()
	dir = (dir + Vector3.UP * 0.12).normalized()
	if ball.has_method("throw_with_velocity"):
		ball.call("throw_with_velocity", dir * 14.0)
