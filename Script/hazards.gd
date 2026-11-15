extends Area2D

enum Kind { SPIKES, LAVA }
@export var kind := Kind.SPIKES


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.has_method("hazard_hit"):
			body.hazard_hit(kind == Kind.LAVA)
