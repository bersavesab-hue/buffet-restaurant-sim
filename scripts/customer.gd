class_name BuffetCustomer
extends CharacterBody2D

signal state_changed(customer: BuffetCustomer, label: String)
signal metrics_changed(customer: BuffetCustomer, fullness_ratio: float, payback_ratio: float)
signal cashier_requested(customer: BuffetCustomer)
signal food_station_requested(customer: BuffetCustomer, station: FoodStation)
signal table_requested(customer: BuffetCustomer)
signal restroom_requested(customer: BuffetCustomer)
signal restroom_released(customer: BuffetCustomer)
signal ticket_paid(customer: BuffetCustomer, amount: float)
signal portion_taken(customer: BuffetCustomer, cost: float)
signal finished(customer: BuffetCustomer, result: Dictionary)

enum State {
	ENTER,
	WAIT_CASHIER,
	CASHIER,
	CASHIER_SERVICE,
	WAIT_FOOD,
	FOOD_SERVICE,
	WAIT_TABLE,
	TABLE,
	EAT,
	WAIT_RESTROOM,
	RESTROOM,
	RESTROOM_USE,
	EXIT,
	DONE
}

@export var speed: float = 125.0
@export var eat_seconds: float = 1.4
@export var cashier_service_seconds: float = 0.75
@export var food_service_seconds: float = 0.55
@export var restroom_use_seconds: float = 2.6

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var body: Polygon2D = $Body
@onready var plate: Polygon2D = $Plate

var state: State = State.ENTER
var entrance_position := Vector2.ZERO
var exit_position := Vector2.ZERO
var queue_target := Vector2.ZERO
var food_queue_target := Vector2.ZERO
var table_wait_target := Vector2.ZERO
var restroom_queue_target := Vector2.ZERO
var cashier_counter_position := Vector2.ZERO
var restroom_position := Vector2.ZERO

var stations: Array[FoodStation] = []
var tables: Array[BuffetTable] = []
var reserved_table: BuffetTable
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
var has_plate := false

var patience_max: float = 34.0
var patience: float = 34.0
var comfort_score: float = 100.0
var current_temperature: float = 26.0
var restroom_need: float = 0.0
var restroom_threshold: float = 55.0
var restroom_wait_seconds: float = 0.0
var leave_after_restroom := false
var last_issue: String = ""

var eat_timer: float = 0.0
var cashier_timer: float = 0.0
var food_service_timer: float = 0.0
var restroom_timer: float = 0.0
var navigation_ready := false
var rng := RandomNumberGenerator.new()

func setup(
	entrance: Vector2,
	exit_point: Vector2,
	available_stations: Array[FoodStation],
	available_tables: Array[BuffetTable],
	customer_profile: Dictionary,
	price: float
) -> void:
	entrance_position = entrance
	exit_position = exit_point
	stations = available_stations
	tables = available_tables
	profile = customer_profile.duplicate(true)
	ticket_price = price
	stomach_capacity = float(profile.get("stomach_capacity", 100.0))
	portion_units = float(profile.get("portion_units", 1.0))
	value_seeking = float(profile.get("value_seeking", 0.6))
	max_rounds = int(profile.get("max_rounds", 6))
	patience_max = float(profile.get("patience", 34.0))
	patience = patience_max
	restroom_threshold = float(profile.get("restroom_threshold", 55.0))
	var tint: Color = profile.get("color", Color(0.25, 0.49, 0.78, 1.0))
	body.color = tint
	plate.visible = false
	rng.randomize()
	call_deferred("_begin_navigation")

func _begin_navigation() -> void:
	await get_tree().physics_frame
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	navigation_ready = true
	_set_state(State.ENTER)

func _physics_process(_delta: float) -> void:
	if not navigation_ready:
		return
	if state in [State.DONE, State.EAT, State.CASHIER_SERVICE, State.FOOD_SERVICE, State.RESTROOM_USE]:
		velocity = Vector2.ZERO
		return

	if NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return

	if navigation_agent.is_navigation_finished():
		_arrive()
		return

	var next_position := navigation_agent.get_next_path_position()
	var desired_velocity := global_position.direction_to(next_position) * speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.velocity = desired_velocity
	else:
		velocity = desired_velocity
		move_and_slide()

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if state in [State.DONE, State.EAT, State.CASHIER_SERVICE, State.FOOD_SERVICE, State.RESTROOM_USE]:
		return
	velocity = safe_velocity
	move_and_slide()

func _process(delta: float) -> void:
	_update_comfort(delta)
	_update_waiting_patience(delta)
	if state in [State.EXIT, State.DONE]:
		return

	match state:
		State.EAT:
			eat_timer -= delta
			if eat_timer <= 0.0:
				_after_eating()
		State.CASHIER_SERVICE:
			cashier_timer -= delta
			if cashier_timer <= 0.0:
				has_plate = true
				plate.visible = true
				emit_signal("ticket_paid", self, ticket_price)
				_choose_next_food_or_leave()
		State.FOOD_SERVICE:
			food_service_timer -= delta
			if food_service_timer <= 0.0:
				_finish_food_service()
		State.RESTROOM_USE:
			restroom_timer -= delta
			if restroom_timer <= 0.0:
				_finish_restroom_use()
		_:
			pass

func update_environment(temperature: float) -> void:
	current_temperature = temperature

func _update_comfort(delta: float) -> void:
	if state in [State.ENTER, State.DONE]:
		return
	var difference := absf(current_temperature - 24.0)
	if difference <= 2.0:
		comfort_score = minf(100.0, comfort_score + 0.22 * delta)
	else:
		comfort_score = maxf(0.0, comfort_score - (difference - 2.0) * 0.20 * delta)

func _update_waiting_patience(delta: float) -> void:
	if state not in [State.WAIT_CASHIER, State.WAIT_FOOD, State.WAIT_TABLE, State.WAIT_RESTROOM]:
		return

	patience = maxf(0.0, patience - delta)
	if state == State.WAIT_RESTROOM:
		restroom_wait_seconds += delta

	if patience > 0.0:
		return

	match state:
		State.WAIT_CASHIER:
			last_issue = "收银排队太久"
		State.WAIT_FOOD:
			last_issue = "取餐排队太久"
		State.WAIT_TABLE:
			last_issue = "等座太久"
		State.WAIT_RESTROOM:
			last_issue = "厕所排队太久"
	_set_state(State.EXIT)

func set_cashier_queue_target(target: Vector2) -> void:
	queue_target = target
	if state == State.WAIT_CASHIER:
		_set_target(queue_target)

func has_reached_queue_target() -> bool:
	return state == State.WAIT_CASHIER and global_position.distance_to(queue_target) <= 16.0

func is_waiting_for_cashier() -> bool:
	return state == State.WAIT_CASHIER

func begin_cashier_service(counter_position: Vector2) -> void:
	cashier_counter_position = counter_position
	_set_state(State.CASHIER)

func set_food_queue_target(station: FoodStation, target: Vector2) -> void:
	if state != State.WAIT_FOOD or selected_station != station:
		return
	food_queue_target = target
	_set_target(food_queue_target)

func has_reached_food_queue_target(station: FoodStation) -> bool:
	return state == State.WAIT_FOOD and selected_station == station and global_position.distance_to(food_queue_target) <= 16.0

func is_waiting_for_food(station: FoodStation) -> bool:
	return state == State.WAIT_FOOD and selected_station == station

func begin_food_service(station: FoodStation) -> void:
	if state != State.WAIT_FOOD or selected_station != station:
		return
	state = State.FOOD_SERVICE
	food_service_timer = food_service_seconds
	velocity = Vector2.ZERO
	emit_signal("state_changed", self, "夹菜：" + station.station_name)

func set_table_wait_target(target: Vector2) -> void:
	table_wait_target = target
	if state == State.WAIT_TABLE:
		_set_target(table_wait_target)

func is_waiting_for_table() -> bool:
	return state == State.WAIT_TABLE

func assign_table(table: BuffetTable) -> void:
	if state != State.WAIT_TABLE:
		return
	reserved_table = table
	_set_state(State.TABLE)

func set_restroom_queue_target(target: Vector2) -> void:
	restroom_queue_target = target
	if state == State.WAIT_RESTROOM:
		_set_target(restroom_queue_target)

func has_reached_restroom_queue_target() -> bool:
	return state == State.WAIT_RESTROOM and global_position.distance_to(restroom_queue_target) <= 16.0

func is_waiting_for_restroom() -> bool:
	return state == State.WAIT_RESTROOM

func begin_restroom_use(target: Vector2) -> void:
	restroom_position = target
	_set_state(State.RESTROOM)

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
			emit_signal("state_changed", self, "付款取盘")
		State.WAIT_FOOD:
			velocity = Vector2.ZERO
		State.WAIT_TABLE:
			velocity = Vector2.ZERO
		State.TABLE:
			_set_state(State.EAT)
		State.WAIT_RESTROOM:
			velocity = Vector2.ZERO
		State.RESTROOM:
			state = State.RESTROOM_USE
			restroom_timer = restroom_use_seconds
			emit_signal("state_changed", self, "使用厕所")
		State.EXIT:
			_set_state(State.DONE)
		_:
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
		State.WAIT_FOOD:
			_set_target(food_queue_target)
			emit_signal("state_changed", self, "等待取餐：" + selected_station.station_name)
		State.TABLE:
			if reserved_table != null:
				_set_target(reserved_table.get_customer_seat_position(self))
				emit_signal("state_changed", self, "端盘回桌")
		State.EAT:
			eat_timer = eat_seconds
			emit_signal("state_changed", self, "吃饭")
		State.WAIT_TABLE:
			_set_target(table_wait_target)
			emit_signal("state_changed", self, "等座")
		State.WAIT_RESTROOM:
			_set_target(restroom_queue_target)
			emit_signal("state_changed", self, "厕所排队")
		State.RESTROOM:
			_set_target(restroom_position)
			emit_signal("state_changed", self, "前往厕所")
		State.RESTROOM_USE:
			restroom_timer = restroom_use_seconds
			emit_signal("state_changed", self, "使用厕所")
		State.EXIT:
			_release_table()
			has_plate = false
			plate.visible = false
			_set_target(exit_position)
			emit_signal("state_changed", self, "离店")
		State.DONE:
			emit_signal("state_changed", self, "完成")
			emit_signal("finished", self, _build_result())

func _set_target(position: Vector2) -> void:
	navigation_agent.target_position = position

func _choose_next_food_or_leave() -> void:
	if rounds_taken >= max_rounds or not _should_continue_eating():
		_leave_or_use_restroom()
		return

	selected_station = _select_station()
	if selected_station == null:
		if last_issue.is_empty():
			last_issue = "想吃的餐台没菜了"
		_leave_or_use_restroom()
		return

	state = State.WAIT_FOOD
	food_queue_target = selected_station.get_service_position()
	emit_signal("state_changed", self, "前往" + selected_station.station_name)
	emit_signal("food_station_requested", self, selected_station)

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
		var queue_penalty := float(station.get_queue_size()) * 1.4
		var score := preference * 10.0
		score += value_seeking * value_efficiency * 10.0
		score -= queue_penalty
		score += rng.randf_range(0.0, 4.0)
		if score > best_score:
			best_score = score
			best_station = station
	return best_station

func _finish_food_service() -> void:
	_take_food()
	if reserved_table == null:
		reserved_table = _reserve_first_table()
	if reserved_table == null:
		state = State.WAIT_TABLE
		emit_signal("state_changed", self, "等待座位")
		emit_signal("table_requested", self)
	else:
		_set_state(State.TABLE)

func _take_food() -> void:
	if selected_station == null:
		return
	var request_units := portion_units * rng.randf_range(0.85, 1.15)
	var portion := selected_station.take_portion(request_units)
	if portion.is_empty():
		if last_issue.is_empty():
			last_issue = selected_station.station_name + "刚好空盘"
		return

	rounds_taken += 1
	var actual_units := float(portion.get("units", 0.0))
	fullness = minf(stomach_capacity, fullness + float(portion.get("satiation", 0.0)))
	perceived_value += float(portion.get("perceived_value", 0.0))
	restroom_need = minf(100.0, restroom_need + actual_units * rng.randf_range(10.0, 15.0))
	emit_signal("portion_taken", self, float(portion.get("cost", 0.0)))
	emit_signal("metrics_changed", self, get_fullness_ratio(), get_payback_ratio())

func _after_eating() -> void:
	if restroom_need >= restroom_threshold:
		_request_restroom(false)
	else:
		_choose_next_food_or_leave()

func _leave_or_use_restroom() -> void:
	if restroom_need >= restroom_threshold * 0.85:
		_request_restroom(true)
	else:
		_set_state(State.EXIT)

func _request_restroom(leave_after: bool) -> void:
	leave_after_restroom = leave_after
	state = State.WAIT_RESTROOM
	emit_signal("state_changed", self, "寻找厕所")
	emit_signal("restroom_requested", self)

func _finish_restroom_use() -> void:
	restroom_need = 0.0
	emit_signal("restroom_released", self)
	if leave_after_restroom:
		_set_state(State.EXIT)
	else:
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

func get_patience_ratio() -> float:
	return clampf(patience / maxf(1.0, patience_max), 0.0, 1.0)

func _reserve_first_table() -> BuffetTable:
	for table in tables:
		if table.has_available_seat() and table.reserve(self):
			return table
	return null

func _release_table() -> void:
	if reserved_table != null:
		reserved_table.release(self)
		reserved_table = null

func _build_result() -> Dictionary:
	var payback_ratio := get_payback_ratio()
	var fullness_ratio := get_fullness_ratio()
	var patience_ratio := get_patience_ratio()
	var comfort_ratio := clampf(comfort_score / 100.0, 0.0, 1.0)
	var rating_score := minf(1.0, payback_ratio) * 0.40
	rating_score += fullness_ratio * 0.22
	rating_score += patience_ratio * 0.18
	rating_score += comfort_ratio * 0.20
	if restroom_wait_seconds > 8.0:
		rating_score -= minf(0.18, restroom_wait_seconds / 100.0)
	var rating := clampf(1.0 + rating_score * 4.0, 1.0, 5.0)
	return {
		"profile_name": str(profile.get("name", "顾客")),
		"fullness_ratio": fullness_ratio,
		"perceived_value": perceived_value,
		"payback_ratio": payback_ratio,
		"patience_ratio": patience_ratio,
		"comfort_score": comfort_score,
		"restroom_wait_seconds": restroom_wait_seconds,
		"rounds": rounds_taken,
		"rating": rating,
		"review": _build_review(payback_ratio, rating)
	}

func _build_review(payback_ratio: float, rating: float) -> String:
	if not last_issue.is_empty():
		return last_issue
	if payback_ratio < 0.62:
		return "没觉得吃回本"
	if comfort_score < 58.0:
		if current_temperature > 26.0:
			return "店里有点热"
		return "店里有点冷"
	if restroom_wait_seconds > 8.0:
		return "厕所排队太久"
	if get_patience_ratio() < 0.45:
		return "排队有点久"
	if rating >= 4.4:
		return "吃得挺值，下次还来"
	return "整体还可以"
