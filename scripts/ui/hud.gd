extends CanvasLayer
## Lightweight PC HUD: controls hint, health, throw charge.

@onready var health_bar: ProgressBar = $Root/HealthBar
@onready var status_label: Label = $Root/StatusLabel
@onready var charge_bar: ProgressBar = $Root/ChargeBar
@onready var hint_label: Label = $Root/HintLabel

var _player: Player


func _ready() -> void:
	visible = not GameState.is_vr_active
	XRManager.xr_session_changed.connect(_on_xr_changed)
	GameState.health_changed.connect(_on_health_changed)
	_on_health_changed(&"player", GameState.player_health, GameState.max_health)
	call_deferred("_bind_player")


func _process(_delta: float) -> void:
	if _player == null or GameState.is_vr_active:
		return
	var pc_snow: PCSnowInteract = _player.get_node_or_null("PCMode/PCSnowInteract")
	if pc_snow:
		charge_bar.value = pc_snow.get_charge() * 100.0
		charge_bar.visible = pc_snow.get_charge() > 0.0 or pc_snow.has_snowball()
		status_label.text = "Снежок готов" if pc_snow.has_snowball() else "Смотрите на снег · E / ПКМ — слепить"


func _bind_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player


func _on_xr_changed(active: bool) -> void:
	visible = not active


func _on_health_changed(target_id: StringName, health: float, max_health: float) -> void:
	if target_id != &"player":
		return
	health_bar.max_value = max_health
	health_bar.value = health
