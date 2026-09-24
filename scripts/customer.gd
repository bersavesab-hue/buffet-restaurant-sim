class_name BuffetCustomer
extends CharacterBody2D

signal state_changed(customer: BuffetCustomer, label: String)
signal metrics_changed(customer: BuffetCustomer, fullness_ratio: float, payback_ratio: float)
signal cashier_requested(customer: BuffetCustomer)
signal ticket_paid(customer: BuffetCustomer, amount: float)
signal portion_taken(customer: BuffetCustomer, cost: float)
signal finished(customer: BuffetCustomer, result: Dictionary)

enum State {
	ENTER,
	WAIT_CASHIER,
	CASHIER,
	CASHIER_SERVICE,
	FOOD,
	SEAT,
	EAT,
	EXIT,
	DONE
}

@export var speed: float = 125.0
@export var eat_seconds: float = 1.4
@export var cashier_service_seconds: float = 0.75

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var body: Polygon2D = $Body

var state: State = State.ENTER
var entrance_position := Vector2.ZERO
var exit_position := Vector2.ZERO
var queue_target := Vector2.ZERO
var cashier_counter_position := Vector2.ZERO

var stations: Array[FoodStation] = []
var seats: Array[BuffetSeat] = []
var reserved_seat: BuffetSeat
var selected_station: FoodStation

var profile: Dictionary = {}
var ticket_price: float = 69.0
var stomach_capacity: float = 100.0
var portion_units: float = 1.0
var value_seeking: float = 0.6
var fullness: float = 0.0
var perceived_value: float = 0.0
var rounds_taken: int = 0
var max_rounds: int = 6

var eat_timer: float = 0.0
var cashier_timer: float = 0.0
var navigation_ready := false
var rng := RandomNumberGenerator.new()

func setup(
	entrance: Vector2,
	exit_point: Vector2,
	available_stations: Array[FoodStation],
	available_seats: Array[BuffetSeat],
	customer_profile: Dictionary,
	price: float
) -> void:
	entrance_position = entrance
	exit_position = exit_point
	stations = available_stations
	seats = available_seats
	profile = customer_profile.duplicate(true)
	ticket_price = price
	stomach_capacity = float(profile.get("stomach_capacity", 100.0))
	portion_units = float(profile.get("portion_units", 1.0))
	value_seeking = float(profile.get("value_seeking", 0.6))
	max_rounds = int(profile.get("max_rounds", 6))
	var tint: Color = profile.get("color", Color(0.25, 0.49, 0.78, 1.0))
	body.color = tint
	rng.randomize()
	call_deferred("_begin_navigation")

func _begin_navigation() -> void:
	await get_tree().physics_frame
	navigation_ready = true
	_set_state(State.ENTER)

func _physics_process(_delta: float) -> void:
	if not navigation_ready:
		return
	if state in [State.DONE, State.EAT, State.CASHIER_SERVICE]:
		velocity = Vector2.ZERO
		return

	if navigation_agent.is_navigation_finished():
		_arrive()
		return

	var next_position := navigation_agent.get_next_path_position()
	var direction := global_position.direction_to(next_position)
	velocity = direction * speed
	move_and_slide()

func _process(delta: float) -> void:
	if state == State.EAT:
		eat_timer -= delta
		if eat_timer <= 0.0:
			_after_eating()
	elif state == State.CASHIER_SERVICE:
		cashier_timer -= delta
		if cashier_timer <= 0.0:
			emit_signal("ticket_paid", self, ticket_price)
			_choose_next_food_or_leave()

func set_cashier_queue_target(target: Vector2) -> void:
	queue_target = target
	if state == State.WAIT_CASHIER:
		_set_target(queue_target)

func has_reached_queue_target() -> bool:
	return state == State.WAIT_CASHIER and global_position.distance_to(queue_target) <= 16.0

func begin_cashier_service(counter_position: Vector2) -> void:
	cashier_counter_position = counter_position
	_set_state(State.CASHIER)

func _arrive() -> void:
	match state:
		State.ENTER:
			state = State.WAIT_CASHIER
			emit_signal("state_changed", self, "排队结账")
			emit_signal("cashier_requested", self)
		State.WAIT_CASHIER:
			velocity = Vector2.ZERO
		State.CASHIER:
			state = State.CASHIER_SERVICE
			cashier_timer = cashier_service_seconds
			emit_signal("state_changed", self, "付款")
		State.FOOD:
			_take_food()
			if reserved_seat == null:
				reserved_seat = _reserve_first_seat()
			if reserved_seat == null:
				_set_state(State.EXIT)
			else:
				_set_state(State.SEAT)
		State.SEAT:
			_set_state(State.EAT)
		State.EXIT:
			_set_state(State.DONE)
		State.EAT, State.CASHIER_SERVICE, State.DONE:
			pass

func _set_state(next_state: State) -> void:
	state = next_state
	match state:
		State.ENTER:
			_set_target(entrance_position)
			emit_signal("state_changed", self, "进店")
		State.WAIT_CASHIER:
			_set_target(queue_target)
			emit_signal("state_changed", self, "收银排队")
		State.CASHIER:
			_set_target(cashier_counter_position)
			emit_signal("state_changed", self, "前往收银台")
		State.FOOD:
			if selected_station != null:
				_set_target(selected_station.global_position)
				emit_signal("state_changed", self, "取餐：" + selected_station.station_name)
		State.SEAT:
			_set_target(reserved_seat.global_position)
			emit_signal("state_changed", self, "回座")
		State.EAT:
			eat_timer = eat_seconds
			emit_signal("state_changed", self, "吃饭")
		State.EXIT:
			_release_seat()
			_set_target(exit_position)
			emit_signal("state_changed", self, "离店")
		State.DONE:
			emit_signal("state_changed", self, "完成")
			var result := {
				"profile_name": str(profile.get("name", "顾客")),
				"fullness_ratio": get_fullness_ratio(),
				"perceived_value": perceived_value,
				"payback_ratio": get_payback_ratio(),
				"rounds": rounds_taken
			}
			emit_signal("finished", self, result)

func _set_target(position: Vector2) -> void:
	navigation_agent.target_position = position

func _choose_next_food_or_leave() -> void:
	if rounds_taken >= max_rounds or not _should_continue_eating():
		_set_state(State.EXIT)
		return

	selected_station = _select_station()
	if selected_station == null:
		_set_state(State.EXIT)
		return

	_set_state(State.FOOD)

func _select_station() -> FoodStation:
	var candidates: Array[FoodStation] = []
	for station in stations:
		if station.has_food():
			candidates.append(station)

	if candidates.is_empty():
		return null

	var preferences: Dictionary = profile.get("preferences", {})
	var best_station: FoodStation = null
	var best_score := -9999.0

	for station in candidates:
		var preference := float(preferences.get(station.food_tag, 1.0))
		var value_efficiency := station.perceived_value_per_unit / maxf(0.1, station.satiation_per_unit)
		var score := preference * 10.0
		score += value_seeking * value_efficiency * 10.0
		score += rng.randf_range(0.0, 4.0)
		if score > best_score:
			best_score = score
			best_station = station

	return best_station

func _take_food() -> void:
	if selected_station == null:
		return

	var request_units := portion_units * rng.randf_range(0.85, 1.15)
	var portion := selected_station.take_portion(request_units)
	if portion.is_empty():
		return

	rounds_taken += 1
	fullness = minf(stomach_capacity, fullness + float(portion.get("satiation", 0.0)))
	perceived_value += float(portion.get("perceived_value", 0.0))
	emit_signal("portion_taken", self, float(portion.get("cost", 0.0)))
	emit_signal("metrics_changed", self, get_fullness_ratio(), get_payback_ratio())

func _after_eating() -> void:
	_choose_next_food_or_leave()

func _should_continue_eating() -> bool:
	var fullness_ratio := get_fullness_ratio()
	var payback_ratio := get_payback_ratio()

	if fullness_ratio < 0.62:
		return true
	if fullness_ratio >= 0.96:
		return payback_ratio < 0.65 and rng.randf() < value_seeking * 0.25

	var desire := 0.25
	desire += maxf(0.0, 1.0 - payback_ratio) * value_seeking * 0.75
	desire += maxf(0.0, 0.9 - fullness_ratio) * 0.4
	return rng.randf() < clampf(desire, 0.0, 0.95)

func get_fullness_ratio() -> float:
	return clampf(fullness / maxf(1.0, stomach_capacity), 0.0, 1.0)

func get_payback_ratio() -> float:
	return maxf(0.0, perceived_value / maxf(1.0, ticket_price))

func _reserve_first_seat() -> BuffetSeat:
	for seat in seats:
		if seat.is_available() and seat.reserve(self):
			return seat
	return null

func _release_seat() -> void:
	if reserved_seat != null:
		reserved_seat.release(self)
		reserved_seat = null
