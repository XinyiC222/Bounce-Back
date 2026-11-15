extends Control

@export var solo_mode := true   # true = one person switches, false = two players

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

var active := 0


func _ready() -> void:
	players[1].sub_viewport.world_2d = players[0].sub_viewport.world_2d

	for info in players:
		info.camera.target_player = info.player

	if solo_mode:
		#Both charcter uses WASD
		players[1].player.action_prefix = ""
		_set_active(0)
	else:
		#Co-op: both always controlled, each with their own keys
		for info in players:
			info.player.controlled = true
			info.container.modulate = Color.WHITE


#this switches between characters during solo mode
func _process(_delta: float) -> void:
	if solo_mode and Input.is_action_just_pressed("switch"):
		_set_active(1 - active)


func _set_active(index: int) -> void:
	active = index
	for i in players.size():
		var is_active := (i == active)
		players[i].player.controlled = is_active
		# Dim the inactive half so it's clear who you control
		players[i].container.modulate = Color.WHITE if is_active else Color(0.5, 0.5, 0.5)
