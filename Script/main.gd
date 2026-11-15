extends Control

@export var end_delay := 3.0   # seconds before the finish screen appears

var solo_mode := false
var swapped := false
var active := 0
var finished := false

@onready var players: Array[Dictionary] = [
	{
		sub_viewport = %LeftSubViewport,
		container = $HBoxContainer/LeftSubViewportContainer,
		camera = %LeftCamera2D,
		player = %World/Player,
	},
	{
		sub_viewport = %RightSubViewport,
		container = $HBoxContainer/RightSubViewportContainer2,
		camera = %RightCamera2D,
		player = %World/Player2,
	},
]

@onready var inv_label: Label = $InvetoryLabel
@onready var solo_button: Button = %SoloButton
@onready var coop_button: Button = %CoopButton
@onready var title_image: Control = %TitleImage
@onready var end_screen: Control = %EndScreen
@onready var restart_button: Button = _get_or_make_restart_button()


func _ready() -> void:
	players[1].sub_viewport.world_2d = players[0].sub_viewport.world_2d

	# Each screen always follows the same character
	for info in players:
		info.camera.target_player = info.player

	Inventory.changed.connect(_update_label)
	Inventory.coins_changed.connect(_update_label)
	Inventory.reset_requested.connect(reset_all)
	_update_label()

	# Menu and end-screen nodes keep working while the game is paused
	for n in [solo_button, coop_button, title_image, end_screen, restart_button]:
		n.process_mode = Node.PROCESS_MODE_ALWAYS
	solo_button.pressed.connect(_start_game.bind(true))
	coop_button.pressed.connect(_start_game.bind(false))
	restart_button.pressed.connect(_on_restart_pressed)

	end_screen.hide()
	get_tree().paused = true   # waits for a mode button


func _get_or_make_restart_button() -> Button:
	var existing := get_node_or_null("%RestartButton")
	if existing:
		return existing
	var b := Button.new()
	b.text = "Restart"
	b.custom_minimum_size = Vector2(120, 40)
	b.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	%EndScreen.add_child(b)
	return b


# ---------- Start ----------

func _start_game(solo: bool) -> void:
	solo_mode = solo
	if solo_mode:
		players[0].player.action_prefix = ""
		players[1].player.action_prefix = ""
		_set_active(0)
	else:
		players[0].player.action_prefix = ""
		players[1].player.action_prefix = "p2_"
		for info in players:
			info.player.controlled = true
			info.container.modulate = Color.WHITE

	title_image.hide()
	solo_button.hide()
	coop_button.hide()
	get_tree().paused = false


func _process(_delta: float) -> void:
	if finished or get_tree().paused:
		return
	if Input.is_action_just_pressed("switch"):
		if solo_mode:
			_set_active(1 - active)
		else:
			swap_worlds()
	_check_win()


# ---------- Winning ----------

func _check_win() -> void:
	var goals := get_tree().get_nodes_in_group("goal")
	if goals.is_empty():
		return
	for g in goals:
		if not g.reached:
			return
	finished = true
	_show_end_screen()


func _show_end_screen() -> void:
	await get_tree().create_timer(end_delay).timeout
	end_screen.show()
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	Inventory.reset()
	get_tree().reload_current_scene()   # comes back to the title


# ---------- Swapping (co-op) ----------

# The characters trade places, so each one ends up in the other's world.
# Each person keeps their own character and keys.
func swap_worlds() -> void:
	var a: CharacterBody2D = players[0].player
	var b: CharacterBody2D = players[1].player
	var pos_a := a.global_position
	var pos_b := b.global_position
	a.teleport_to(pos_b)
	b.teleport_to(pos_a)
	_swap_camera_bands()
	swapped = !swapped


# Each camera shows the band (forest or desert) where its character now is
func _swap_camera_bands() -> void:
	var y0: float = players[0].camera.view_center_y
	players[0].camera.view_center_y = players[1].camera.view_center_y
	players[1].camera.view_center_y = y0
	# Snap the cameras straight to their targets
	for info in players:
		info.camera.global_position.x = info.player.global_position.x
		info.camera.reset_smoothing()


# ---------- Hazards ----------

# A hazard hit sends both characters back to their start and clears the goals
func reset_all() -> void:
	if finished:
		return
	for info in players:
		info.player.respawn()
	if swapped:
		_swap_camera_bands()
		swapped = false
	get_tree().call_group("goal", "clear")


# ---------- Solo mode ----------
func _set_active(index: int) -> void:
	active = index
	for i in players.size():
		var is_active := (i == active)
		players[i].player.controlled = is_active
		# Dim the inactive half so it's clear who you control
		players[i].container.modulate = Color.WHITE if is_active else Color(0.5, 0.5, 0.5)


# ---------- UI ----------

func _update_label() -> void:
	var parts: Array[String] = []
	for type in Inventory.coins:
		parts.append("%s: %d" % [type, Inventory.coins[type]])
	inv_label.text = "Coins: %s | Items: %s" % [", ".join(parts), ", ".join(Inventory.items)]
