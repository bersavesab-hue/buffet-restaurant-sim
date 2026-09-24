class_name FoodStation
extends Node2D

@export var capacity: int = 8
@export var starting_stock: int = 8
@export var satiation_per_portion: float = 28.0

var stock: int = 0

func _ready() -> void:
	stock = clampi(starting_stock, 0, capacity)

func has_food() -> bool:
	return stock > 0

func take_portion() -> float:
	if stock <= 0:
		return 0.0
	stock -= 1
	return satiation_per_portion

func refill(amount: int) -> int:
	var before := stock
	stock = clampi(stock + amount, 0, capacity)
	return stock - before
