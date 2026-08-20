extends CanvasLayer
## PC HUD: player/bot health, throw charge, controls.

@onready var health_bar: ProgressBar = $Root/HealthBar
@onready var bot_health_bar: ProgressBar = $Root/BotHealthBar
@onready var status_label: Label = $Root/StatusLabel
@onready var charge_bar: ProgressBar = $Root/ChargeBar
@onready var hint_label: Label = $Root/HintLabel
@onready var hit_toast: Label = $Root/HitToast

var _player: Player
var _toast_time: float = 0.0


func _ready() -> void:
	visible = not GameState.is_vr_active
	XRManager.xr_session_changed.connect(_on_xr_changed)
	GameState.health_changed.connect(_on_health_changed)
	GameState.snowball_hit.connect(_on_snowball_hit)
	_on_health_changed(&"player", GameState.get_health(&"player"), GameState.get_max_health(&"player"))
	_on_health_changed(&"bot", GameState.get_health(&"bot"), GameState.get_max_health(&"bot"))
	if hit_toast:
		hit_toast.visible = false
	call_deferred("_bind_player")


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0 and hit_toast:
			hit_toast.visible = false

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
	if target_id == &"player":
		health_bar.max_value = max_health
		health_bar.value = health
	elif target_id == &"bot" and bot_health_bar:
		bot_health_bar.max_value = max_health
		bot_health_bar.value = health


func _on_snowball_hit(attacker_id: StringName, target_id: StringName, damage: float) -> void:
	if hit_toast == null:
		return
	hit_toast.text = "%s → %s (−%d)" % [attacker_id, target_id, int(damage)]
	hit_toast.visible = true
	_toast_time = 1.4
