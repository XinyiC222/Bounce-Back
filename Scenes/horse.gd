extends Area2D

@export var goal_for := "cowboy"   # horse = "cowboy", sword = "knight"
var reached := false


func _ready() -> void:
	add_to_group("goal")


func _physics_process(_delta: float) -> void:
	if reached:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group(goal_for):
			reached = true   # stays reached once touched


func clear() -> void:
	reached = false
