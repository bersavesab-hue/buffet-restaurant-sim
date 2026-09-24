extends Node2D

const CUSTOMER_SCENE := preload("res://scenes/customer.tscn")

@export var ticket_price: float = 69.0
@export var day_duration_seconds: float = 75.0
@export var spawn_interval_seconds: float = 4.5
@export var max_customers_today: int = 12

@onready var customer_layer: Node2D = $CustomerLayer
@onready var cashier_counter: Marker2D = $Points/CashierCounter
@onready var entrance: Marker2D = $Points/Entrance
@onready var exit_point: Marker2D = $Points/Exit
@onready var stats_label: Label = $CanvasLayer/UI/VBox/StatsLabel
@onready var economy_label: Label = $CanvasLayer/UI/VBox/EconomyLabel
@onready var stock_label: Label = $CanvasLayer/UI/VBox/StockLabel
@onready var status_label: Label = $CanvasLayer/UI/VBox/StatusLabel

var stations: Array[FoodStation] = []
var seats: Array[BuffetSeat] = []
var active_customers: Array[BuffetCustomer] = []
var cashier_queue: Array[BuffetCustomer] = []
var cashier_service_customer: BuffetCustomer

var day_remaining: float = 0.0
var spawn_timer: float = 0.0
var spawned_today: int = 0
var finished_today: int = 0
var ticket_revenue: float = 0.0
var food_cost: float = 0.0
var total_payback_ratio: float = 0.0
var day_settled := false
var rng := RandomNumberGenerator.new()

var customer_profiles := [
	{
		"name": "普通顾客",
		"stomach_capacity": 100.0,
		"portion_units": 0.9,
		"value_seeking": 0.55,
		"max_rounds": 6,
		"preferences": {"staple": 1.0, "meat": 1.2, "seafood": 1.1},
		"color": Color(0.25, 0.49, 0.78, 1.0)
	},
	{
		"name": "健身顾客",
		"stomach_capacity": 130.0,
		"portion_units": 1.1,
		"value_seeking": 0.7,
		"max_rounds": 7,
		"preferences": {"staple": 0.55, "meat": 1.8, "seafood": 1.35},
		"color": Color(0.30, 0.68, 0.40, 1.0)
	},
	{
		"name": "大胃王",
		"stomach_capacity": 180.0,
		"portion_units": 1.3,
		"value_seeking": 0.9,
		"max_rounds": 9,
		"preferences": {"staple": 0.75, "meat": 1.55, "seafood": 1.65},
		"color": Color(0.78, 0.30, 0.25, 1.0)
	}
]

func _ready() -> void:
	rng.randomize()
	_collect_world_objects()
	day_remaining = day_duration_seconds
	spawn_timer = 0.4
	status_label.text = "营业中：69元大众自助"

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart_demo"):
		get_tree().reload_current_scene()
		return

	if not day_settled:
		_update_day(delta)
		_update_cashier_queue()

	_update_debug_ui()

func _collect_world_objects() -> void:
	for node in $FoodStations.get_children():
		if node is FoodStation:
			stations.append(node as FoodStation)

	for node in $Seats.get_children():
		if node is BuffetSeat:
			seats.append(node as BuffetSeat)

func _update_day(delta: float) -> void:
	if day_remaining > 0.0:
		day_remaining = maxf(0.0, day_remaining - delta)
		spawn_timer -= delta
		if spawn_timer <= 0.0 and spawned_today < max_customers_today:
			_spawn_customer()
			spawn_timer = spawn_interval_seconds
	elif active_customers.is_empty():
		_settle_day()

func _spawn_customer() -> void:
	var customer := CUSTOMER_SCENE.instantiate() as BuffetCustomer
	customer_layer.add_child(customer)
	customer.global_position = entrance.global_position + Vector2(rng.randf_range(-24.0, 24.0), rng.randf_range(-12.0, 12.0))

	var profile: Dictionary = customer_profiles[rng.randi_range(0, customer_profiles.size() - 1)]
	customer.state_changed.connect(_on_customer_state_changed)
	customer.metrics_changed.connect(_on_customer_metrics_changed)
	customer.cashier_requested.connect(_on_cashier_requested)
	customer.ticket_paid.connect(_on_ticket_paid)
	customer.portion_taken.connect(_on_portion_taken)
	customer.finished.connect(_on_customer_finished)
	active_customers.append(customer)
	spawned_today += 1

	customer.setup(
		entrance.global_position,
		exit_point.global_position,
		stations,
		seats,
		profile,
		ticket_price
	)

func _on_cashier_requested(customer: BuffetCustomer) -> void:
	if not cashier_queue.has(customer):
		cashier_queue.append(customer)
	_refresh_queue_targets()

func _update_cashier_queue() -> void:
	if cashier_service_customer != null:
		return
	if cashier_queue.is_empty():
		return

	var first := cashier_queue[0]
	if not is_instance_valid(first):
		cashier_queue.remove_at(0)
		_refresh_queue_targets()
		return

	if first.has_reached_queue_target():
		cashier_queue.remove_at(0)
		cashier_service_customer = first
		first.begin_cashier_service(cashier_counter.global_position)
		_refresh_queue_targets()

func _refresh_queue_targets() -> void:
	var start := cashier_counter.global_position + Vector2(0.0, 78.0)
	for i in range(cashier_queue.size()):
		var customer := cashier_queue[i]
		if is_instance_valid(customer):
			customer.set_cashier_queue_target(start + Vector2(0.0, 54.0 * float(i)))

func _on_ticket_paid(customer: BuffetCustomer, amount: float) -> void:
	ticket_revenue += amount
	if cashier_service_customer == customer:
		cashier_service_customer = null

func _on_portion_taken(_customer: BuffetCustomer, cost: float) -> void:
	food_cost += cost

func _on_customer_finished(customer: BuffetCustomer, result: Dictionary) -> void:
	finished_today += 1
	total_payback_ratio += float(result.get("payback_ratio", 0.0))
	active_customers.erase(customer)
	cashier_queue.erase(customer)
	if cashier_service_customer == customer:
		cashier_service_customer = null
	customer.queue_free()
	_refresh_queue_targets()

func _on_customer_state_changed(_customer: BuffetCustomer, _label: String) -> void:
	pass

func _on_customer_metrics_changed(_customer: BuffetCustomer, _fullness_ratio: float, _payback_ratio: float) -> void:
	pass

func _settle_day() -> void:
	day_settled = true
	var profit := ticket_revenue - food_cost
	var average_payback := 0.0
	if finished_today > 0:
		average_payback = total_payback_ratio / float(finished_today)
	status_label.text = "营业结束｜顾客 %d｜平均回本感 %d%%｜毛利 ¥%.1f" % [
		finished_today,
		int(round(average_payback * 100.0)),
		profit
	]

func _update_debug_ui() -> void:
	stats_label.text = "时间 %02d秒｜进店 %d/%d｜店内 %d｜收银队列 %d" % [
		int(ceil(day_remaining)),
		spawned_today,
		max_customers_today,
		active_customers.size(),
		cashier_queue.size()
	]

	var profit := ticket_revenue - food_cost
	economy_label.text = "门票 ¥%.1f｜食材 ¥%.1f｜当前毛利 ¥%.1f" % [ticket_revenue, food_cost, profit]

	var parts: Array[String] = []
	for station in stations:
		parts.append("%s %.1f/%.0f" % [station.station_name, station.stock, station.capacity])
	stock_label.text = "餐台：" + "  |  ".join(parts)
