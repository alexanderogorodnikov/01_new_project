extends SceneTree
## Capture demo PNGs of the improved winter models.
## Run: godot --xr-mode off --path . -s res://scripts/tools/demo_capture.gd


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
	current_scene = main

	await process_frame
	await process_frame

	var player := root.get_node_or_null("Main/Player") as Node3D
	var bot := root.get_node_or_null("Main/Bot") as Node3D
	if player == null or bot == null:
		push_error("[demo] Player/Bot missing")
		quit(1)
		return

	# Hide HUD for a cleaner model showcase.
	var hud := root.get_node_or_null("Main/HUD")
	if hud:
		hud.visible = false
	var nameplate := bot.get_node_or_null("Nameplate")
	if nameplate:
		nameplate.visible = false

	player.global_position = Vector3(4, 0.2, 4)
	bot.global_position = Vector3(0, 0.2, 0)
	bot.rotation = Vector3(0, deg_to_rad(35), 0)

	# Dedicated showcase camera (3/4 view).
	var cam := Camera3D.new()
	cam.name = "DemoCamera"
	main.add_child(cam)
	cam.global_position = Vector3(2.4, 1.55, 3.2)
	cam.look_at(Vector3(0, 1.15, 0), Vector3.UP)
	cam.current = true

	if bot.has_method("force_throw_at_target"):
		# Point bot roughly toward camera-left so throw silhouette is visible.
		bot.rotation = Vector3(0, deg_to_rad(20), 0)
		bot.call("force_throw_at_target")

	await create_timer(0.55).timeout
	for i in 6:
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
	img.save_png(out_user)
	var project_out := ProjectSettings.globalize_path("res://").path_join("demo_bot.png")
	img.save_png(project_out)
	print("[demo] saved: ", project_out)
	print("[demo] OK")
	quit(0)
