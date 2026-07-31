extends SceneTree
## Capture a demo PNG of the bot fight for PR/docs.
## Run (with display):
##   godot --xr-mode off --path . -s res://scripts/tools/demo_capture.gd
## Output: user://demo_bot.png and optional -- copy to artifacts via shell.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	print("[demo] Loading arena...")
	var packed := load("res://scenes/main.tscn")
	if packed == null:
		push_error("[demo] main.tscn missing")
		quit(1)
		return

	var main: Node = packed.instantiate()
	root.add_child(main)
	# Make this the current scene so snowballs reparent correctly.
	current_scene = main

	await process_frame
	await process_frame

	var player := root.get_node_or_null("Main/Player") as Node3D
	var bot := root.get_node_or_null("Main/Bot") as Node
	if player == null or bot == null:
		push_error("[demo] Player/Bot missing")
		quit(1)
		return

	# Stage a clear confrontation shot.
	player.global_position = Vector3(0, 0.2, 8)
	player.rotation = Vector3.ZERO
	if bot is Node3D:
		(bot as Node3D).global_position = Vector3(0, 0.2, -2)
		(bot as Node3D).look_at(player.global_position, Vector3.UP)

	var pc_camera := player.get_node_or_null("PCMode/Camera3D") as Camera3D
	if pc_camera:
		pc_camera.current = true
		pc_camera.rotation.x = deg_to_rad(-8.0)

	# Force a visible throw from the bot.
	if bot.has_method("force_throw_at_target"):
		bot.call("force_throw_at_target")

	# Let physics + particles settle into a nice frame.
	await create_timer(0.85).timeout
	for i in 8:
		await process_frame

	await RenderingServer.frame_post_draw
	var tex := root.get_viewport().get_texture()
	if tex == null:
		push_error("[demo] No viewport texture")
		quit(1)
		return
	var img := tex.get_image()
	if img == null:
		push_error("[demo] No image")
		quit(1)
		return

	var out_user := "user://demo_bot.png"
	var err := img.save_png(out_user)
	var abs_user := ProjectSettings.globalize_path(out_user)
	print("[demo] saved user path: ", abs_user, " err=", err)

	# Also write next to project for easy pickup.
	var project_out := ProjectSettings.globalize_path("res://").path_join("demo_bot.png")
	img.save_png(project_out)
	print("[demo] saved project path: ", project_out)
	print("[demo] OK")
	quit(0)
