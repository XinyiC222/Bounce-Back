extends Camera2D

var target_player: Node2D
@export var view_center_y: float = 360.0/2.0

func _ready() -> void:
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	position_smoothing_enabled = false
	limit_left = 0
	limit_right = 1280*2
	limit_top = -10000000
	limit_bottom = 10000000
	

func _process(_delta: float) -> void:
	if is_instance_valid(target_player):
		global_position.x = target_player.global_position.x
	global_position.y = view_center_y - offset.y
