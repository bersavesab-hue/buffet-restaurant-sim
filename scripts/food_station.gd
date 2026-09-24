class_name FoodStation
extends Node2D

@export var station_name: String = "餐台"
@export_enum("staple", "meat", "seafood") var food_tag: String = "staple"
@export var ingredient_id: String = "rice"
@export var raw_units_per_food_unit: float = 0.40
@export var capacity: float = 12.0
@export var starting_stock: float = 12.0
@export var satiation_per_unit: float = 18.0
@export var perceived_value_per_unit: float = 8.0
@export var cost_per_unit: float = 3.0

@onready var service_point: Marker2D = get_node_or_null("ServicePoint") as Marker2D

var stock: float = 0.0

func _ready() -> void:
	stock = clampf(starting_stock, 0.0, capacity)

func has_food(min_units: float = 0.25) -> bool:
	return stock >= min_units

func get_service_position() -> Vector2:
	if service_point != null:
		return service_point.global_position
	return global_position

func take_portion(requested_units: float) -> Dictionary:
	if stock <= 0.0:
		return {}

	var actual_units := minf(stock, maxf(0.25, requested_units))
	stock = maxf(0.0, stock - actual_units)

	return {
		"station_name": station_name,
		"food_tag": food_tag,
		"units": actual_units,
		"satiation": satiation_per_unit * actual_units,
		"perceived_value": perceived_value_per_unit * actual_units,
		"cost": cost_per_unit * actual_units
	}

func refill(units: float) -> float:
	var before := stock
	stock = clampf(stock + units, 0.0, capacity)
	return stock - before

func get_stock_ratio() -> float:
	return clampf(stock / maxf(0.01, capacity), 0.0, 1.0)

func get_remaining_capacity() -> float:
	return maxf(0.0, capacity - stock)

func raw_needed_for(food_units: float) -> float:
	return maxf(0.0, food_units) * raw_units_per_food_unit

func food_units_from_raw(raw_units: float) -> float:
	return maxf(0.0, raw_units) / maxf(0.001, raw_units_per_food_unit)
