extends Node
## Initializes OpenXR when a headset is available; falls back to PC FPS otherwise.

signal xr_session_changed(active: bool)

var xr_interface: XRInterface
var is_xr_active: bool = false


func _ready() -> void:
	# Headless / CI / explicit --xr-mode off → stay in PC mode.
	if DisplayServer.get_name() == "headless" or OS.has_feature("DedicatedServer"):
		print("XRManager: headless/server detected — PC mode.")
		_set_xr_active(false)
		return
	_try_start_xr()


func _try_start_xr() -> bool:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface == null:
		push_warning("OpenXR interface not found — using PC first-person mode.")
		_set_xr_active(false)
		return false

	# Avoid blocking initialize() when no OpenXR runtime is present.
	if not xr_interface.is_initialized():
		if not _runtime_seems_available():
			push_warning("No OpenXR runtime detected — using PC first-person mode.")
			_set_xr_active(false)
			return false
		if not xr_interface.initialize():
			push_warning("OpenXR failed to initialize — using PC first-person mode.")
			_set_xr_active(false)
			return false

	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().use_xr = true
	_set_xr_active(true)
	print("OpenXR started: ", xr_interface.get_name())
	return true


func _runtime_seems_available() -> bool:
	# Common hints that an OpenXR loader/runtime is configured.
	if OS.has_environment("XR_RUNTIME_JSON"):
		return true
	if OS.has_environment("VR_OVERRIDE_PATH"):
		return true
	# SteamVR / Monado typical paths (Linux).
	var home := OS.get_environment("HOME")
	var candidates := [
		home.path_join(".config/openxr/1/active_runtime.json"),
		"/etc/xdg/openxr/1/active_runtime.json",
		"/usr/share/openxr/1/openxr_monado.json",
	]
	for path in candidates:
		if FileAccess.file_exists(path):
			return true
	return false


func _set_xr_active(active: bool) -> void:
	is_xr_active = active
	GameState.is_vr_active = active
	xr_session_changed.emit(active)


func stop_xr() -> void:
	if xr_interface and xr_interface.is_initialized():
		get_viewport().use_xr = false
		xr_interface.uninitialize()
	_set_xr_active(false)


func restart_xr() -> bool:
	stop_xr()
	return _try_start_xr()
