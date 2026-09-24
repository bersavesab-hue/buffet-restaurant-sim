class_name KitchenSystem
extends Node

signal batch_prepared(station_name: String, units: float, cost: float)

@export var production_seconds: float = 3.2
@export var batch_units: float = 4.0
@export var refill_threshold: float = 0.48

var stations: Array[FoodStation] = []
var current_station: FoodStation
var production_timer: float = 0.0
var active := true

func setup(available_stations: Array[FoodStation]) -> void:
	stations = available_stations
	current_station = null
	production_timer = 0.0

func set_active(value: bool) -> void:
	active = value

func _process(delta: float) -> void:
	if not active or stations.is_empty():
		return

	if current_station == null or current_station.get_stock_ratio() >= refill_threshold:
		current_station = _pick_station()
		production_timer = 0.0

	if current_station == null:
		return

	production_timer += delta
	if production_timer < production_seconds:
		return

	var requested_units := minf(batch_units, current_station.get_remaining_capacity())
	var actual_units := current_station.refill(requested_units)
	if actual_units > 0.0:
		var cost := actual_units * current_station.cost_per_unit
		emit_signal("batch_prepared", current_station.station_name, actual_units, cost)

	current_station = null
	production_timer = 0.0

func _pick_station() -> FoodStation:
	var best: FoodStation = null
	var lowest_ratio := 2.0

	for station in stations:
		var ratio := station.get_stock_ratio()
		if ratio < refill_threshold and ratio < lowest_ratio:
			lowest_ratio = ratio
			best = station

	return best

func get_status() -> String:
	if not active:
		return "厨房：已停工"
	if current_station == null:
		return "厨房：待命"
	var remaining := maxf(0.0, production_seconds - production_timer)
	return "厨房：补%s %.1fs" % [current_station.station_name, remaining]
