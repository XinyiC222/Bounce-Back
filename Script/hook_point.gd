extends Area2D

@export var required_item := "lasso"
@export var reach := 300.0         # grapple range
@export var touch_radius := 60.0   # how close counts as "touching" for jumping

func _ready() -> void:
	add_to_group("hook")
