class_name KitchenSystem
extends Node

signal batch_started(station_name: String)
signal batch_prepared(station_name: String, food_units: float, raw_units: float)
signal ingredient_shortage(station_name: String, ingredient_id: String)

@export var batch_units: float = 4.0
@export var refill_threshold: float = 0.48

var stations: Array[FoodStation] = []
var pantry: PantrySystem
var active := true
var priority_tag: String = "auto"
var claimed_station: FoodStation

func setup(available_stations: Array[FoodStation], pantry_system: PantrySystem) -> void:
	stations = available_stations
	pantry = pantry_system
	claimed_station = null

func set_active(value: bool) -> void:
	active = value

func set_priority(food_tag: String) -> void:
	priority_tag = food_tag

func claim_next_job() -> FoodStation:
	if not active or pantry == null or claimed_station != null:
		return null
	claimed_station = _pick_station()
	if claimed_station != null:
		emit_signal("batch_started", claimed_station.station_name)
	return claimed_station

func complete_job(station: FoodStation) -> Dictionary:
	if station == null or pantry == null:
		_release_claim(station)
		return {}
	if claimed_station != null and claimed_station != station:
		return {}

	var requested_food_units := minf(batch_units, station.get_remaining_capacity())
	var requested_raw := station.raw_needed_for(requested_food_units)
	var available_raw := pantry.get_stock(station.ingredient_id)
	var actual_raw := minf(requested_raw, available_raw)

	if actual_raw <= 0.001:
		emit_signal("ingredient_shortage", station.station_name, station.ingredient_id)
		_release_claim(station)
		return {}

	var food_units := station.food_units_from_raw(actual_raw)
	food_units = minf(food_units, station.get_remaining_capacity())
	actual_raw = station.raw_needed_for(food_units)
	var consumed_raw := pantry.consume(station.ingredient_id, actual_raw)
	var producible_food := station.food_units_from_raw(consumed_raw)
	var actual_food := station.refill(producible_food)

	if actual_food > 0.0:
		emit_signal("batch_prepared", station.station_name, actual_food, consumed_raw)

	_release_claim(station)
	return {
		"food_units": actual_food,
		"raw_units": consumed_raw,
		"station_name": station.station_name
	}

func cancel_claim(station: FoodStation) -> void:
	_release_claim(station)

func _release_claim(station: FoodStation) -> void:
	if claimed_station == station or station == null:
		claimed_station = null

func _pick_station() -> FoodStation:
	var best: FoodStation = null
	var best_score := -999.0

	for station in stations:
		if not station.is_refill_enabled():
			continue
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
	if claimed_station == null:
		return "厨房：等待厨师任务｜优先 %s" % priority_tag
	return "厨房：%s处理中｜优先 %s" % [claimed_station.station_name, priority_tag]
