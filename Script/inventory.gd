extends Node

signal changed
signal coins_changed

var coins := {}   # e.g. {"gold": 3, "gem": 1}

signal reset_requested

var items: Array[String] = []

func add(item: String) -> void:
	if item not in items:
		items.append(item)
		changed.emit()

func has(item: String) -> bool:
	return item in items

func reset() -> void:
	items.clear()
	coins.clear()
	changed.emit()
	coins_changed.emit()

func add_coin(type: String, amount: int = 1) -> void:
	coins[type] = coins.get(type, 0) + amount
	coins_changed.emit()

func get_coins(type: String) -> int:
	return coins.get(type, 0)
