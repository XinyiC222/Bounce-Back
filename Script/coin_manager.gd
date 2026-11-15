extends Node2D

@export var pickup_radius := 40.0
# coin type (animation name) -> which character can collect it
@export var coin_owners := {"yellow": "cowboy", "red": "knight"}


func _ready() -> void:
	for coin in get_children():
		if coin is AnimatedSprite2D:
			coin.play()   # plays whichever animation is set on that coin


func _physics_process(_delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	for coin in get_children():
		if not coin is AnimatedSprite2D or coin.is_queued_for_deletion():
			continue
		var type: String = coin.animation
		var owner_group: String = coin_owners.get(type, "")
		for p in players:
			if owner_group != "" and not p.is_in_group(owner_group):
				continue
			if coin.global_position.distance_to(p.global_position) <= pickup_radius:
				coin.queue_free()
				Inventory.add_coin(type, 1)
				break
