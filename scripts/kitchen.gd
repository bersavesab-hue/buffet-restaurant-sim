class_name KitchenSystem
extends Node

signal batch_started(station_name: String)
signal batch_prepared(station_name: String, food_units: float, raw_units: float)
signal ingredient_shortage(station_name: String, ingredient_id: String)

@export var production_seconds: float = 3.2
@export var batch_units: float = 4.0
@export var refill_threshold: float = 0.48

var stations: Array[FoodStation] = []
var pantry: PantrySystem
var current_station: FoodStation
var production_timer: float = 0.0
var active := true
var priority_tag: String = "auto"

func setup(available_stations: Array[FoodStation], pantry_system: PantrySystem) -> void:
	stations = available_stations
	pantry = pantry_system
	current_station = null
	production_timer = 0.0

func set_active(value: bool) -> void:
	active = value

func set_priority(food_tag: String) -> void:
	priority_tag = food_tag

func _process(delta: float) -> void:
	if not active or stations.is_empty() or pantry == null:
		return

	if current_station == null or current_station.get_stock_ratio() >= refill_threshold:
		current_station = _pick_station()
		production_timer = 0.0
		if current_station != null:
			emit_signal("batch_started", current_station.station_name)

	if current_station == null:
		return

	production_timer += delta
	if production_timer < production_seconds:
		return

	_prepare_current_batch()
	current_station = null
	production_timer = 0.0

func _prepare_current_batch() -> void:
	var requested_food_units := minf(batch_units, current_station.get_remaining_capacity())
	var requested_raw := current_station.raw_needed_for(requested_food_units)
	var available_raw := pantry.get_stock(current_station.ingredient_id)
	var actual_raw := minf(requested_raw, available_raw)

	if actual_raw <= 0.001:
		emit_signal("ingredient_shortage", current_station.station_name, current_station.ingredient_id)
		return

	var food_units := current_station.food_units_from_raw(actual_raw)
	food_units = minf(food_units, current_station.get_remaining_capacity())
	actual_raw = current_station.raw_needed_for(food_units)
	var consumed_raw := pantry.consume(current_station.ingredient_id, actual_raw)
	var producible_food := current_station.food_units_from_raw(consumed_raw)
	var actual_food := current_station.refill(producible_food)

	if actual_food > 0.0:
		emit_signal("batch_prepared", current_station.station_name, actual_food, consumed_raw)

func _pick_station() -> FoodStation:
	var best: FoodStation = null
	var best_score := -999.0

	for station in stations:
		var ratio := station.get_stock_ratio()
		if ratio >= refill_threshold:
			continue
		if pantry.get_stock(station.ingredient_id) <= 0.001:
			continue

		var score := (1.0 - ratio) * 10.0
		if priority_tag != "auto" and station.food_tag == priority_tag:
			score += 8.0
		if score > best_score:
			best_score = score
			best = station

	return best

func get_status() -> String:
	if not active:
		return "厨房：已停工"
	if current_station == null:
		return "厨房：待命"
	var remaining := maxf(0.0, production_seconds - production_timer)
	return "厨房：制作%s %.1fs｜优先 %s" % [
		current_station.station_name,
		remaining,
		priority_tag
	]
