extends Node2D

const CUSTOMER_SCENE := preload("res://scenes/customer.tscn")

@export var ticket_price: float = 69.0
@export var day_duration_seconds: float = 90.0
@export var spawn_interval_seconds: float = 4.0
@export var max_customers_today: int = 16
@export var outdoor_temperature: float = 32.0

@onready var customer_layer: Node2D = $CustomerLayer
@onready var kitchen: KitchenSystem = $Kitchen
@onready var pantry: PantrySystem = $Pantry
@onready var service_worker: ServiceWorker = $Staff/ServiceWorker
@onready var chef_worker: ChefWorker = $Staff/ChefWorker

@onready var cashier_counter: Marker2D = $Points/CashierCounter
@onready var table_wait_point: Marker2D = $Points/TableWait
@onready var restroom_queue_point: Marker2D = $Points/RestroomQueue
@onready var restroom_use_point: Marker2D = $Points/RestroomUse
@onready var chef_prep_point: Marker2D = $Points/ChefPrep
@onready var entrance: Marker2D = $Points/Entrance
@onready var exit_point: Marker2D = $Points/Exit

@onready var stats_label: Label = $CanvasLayer/UI/VBox/StatsLabel
@onready var economy_label: Label = $CanvasLayer/UI/VBox/EconomyLabel
@onready var stock_label: Label = $CanvasLayer/UI/VBox/StockLabel
@onready var pantry_label: Label = $CanvasLayer/UI/VBox/PantryLabel
@onready var environment_label: Label = $CanvasLayer/UI/VBox/EnvironmentLabel
@onready var kitchen_label: Label = $CanvasLayer/UI/VBox/KitchenLabel
@onready var chef_label: Label = $CanvasLayer/UI/VBox/ChefLabel
@onready var staff_label: Label = $CanvasLayer/UI/VBox/StaffLabel
@onready var review_label: Label = $CanvasLayer/UI/VBox/ReviewLabel
@onready var status_label: Label = $CanvasLayer/UI/VBox/StatusLabel

@onready var ac_switch_button: Button = $CanvasLayer/Controls/HBox/ACSwitch
@onready var temp_down_button: Button = $CanvasLayer/Controls/HBox/TempDown
@onready var temp_up_button: Button = $CanvasLayer/Controls/HBox/TempUp
@onready var speed_1_button: Button = $CanvasLayer/Controls/HBox/Speed1
@onready var speed_2_button: Button = $CanvasLayer/Controls/HBox/Speed2
@onready var speed_3_button: Button = $CanvasLayer/Controls/HBox/Speed3

@onready var priority_auto_button: Button = $CanvasLayer/PriorityControls/HBox/Auto
@onready var priority_staple_button: Button = $CanvasLayer/PriorityControls/HBox/Staple
@onready var priority_meat_button: Button = $CanvasLayer/PriorityControls/HBox/Meat
@onready var priority_seafood_button: Button = $CanvasLayer/PriorityControls/HBox/Seafood

@onready var supply_staple_button: Button = $CanvasLayer/SupplyControls/HBox/Staple
@onready var supply_meat_button: Button = $CanvasLayer/SupplyControls/HBox/Meat
@onready var supply_seafood_button: Button = $CanvasLayer/SupplyControls/HBox/Seafood

var stations: Array[FoodStation] = []
var tables: Array[BuffetTable] = []
var active_customers: Array[BuffetCustomer] = []
var cashier_queue: Array[BuffetCustomer] = []
var table_wait_queue: Array[BuffetCustomer] = []
var restroom_queue: Array[BuffetCustomer] = []

var cashier_service_customer: BuffetCustomer
var restroom_service_customer: BuffetCustomer

var day_remaining := 0.0
var spawn_timer := 0.0
var spawned_today := 0
var finished_today := 0

var ticket_revenue := 0.0
var food_cost := 0.0
var consumed_food_cost := 0.0
var opening_prepared_food_cost := 0.0
var utility_cost := 0.0

var total_payback_ratio := 0.0
var total_rating := 0.0
var last_review := "暂无评价"

var indoor_temperature := 29.0
var heat_load := 0.0
var ac_enabled := true
var ac_setpoint := 24.0
var selected_speed := 1.0

var day_settled := false
var rng := RandomNumberGenerator.new()

var customer_profiles := [
	{
		"name": "普通顾客",
		"stomach_capacity": 100.0,
		"portion_units": 0.9,
		"value_seeking": 0.55,
		"max_rounds": 6,
		"patience": 34.0,
		"restroom_threshold": 58.0,
		"preferences": {"staple": 1.0, "meat": 1.2, "seafood": 1.1},
		"color": Color(0.25, 0.49, 0.78, 1.0)
	},
	{
		"name": "健身顾客",
		"stomach_capacity": 130.0,
		"portion_units": 1.1,
		"value_seeking": 0.7,
		"max_rounds": 7,
		"patience": 30.0,
		"restroom_threshold": 62.0,
		"preferences": {"staple": 0.55, "meat": 1.8, "seafood": 1.35},
		"color": Color(0.30, 0.68, 0.40, 1.0)
	},
	{
		"name": "大胃王",
		"stomach_capacity": 180.0,
		"portion_units": 1.3,
		"value_seeking": 0.9,
		"max_rounds": 9,
		"patience": 42.0,
		"restroom_threshold": 68.0,
		"preferences": {"staple": 0.75, "meat": 1.55, "seafood": 1.65},
		"color": Color(0.78, 0.30, 0.25, 1.0)
	}
]

func _ready() -> void:
	Engine.time_scale = 1.0
	rng.randomize()
	_collect_world_objects()
	_register_initial_inventory_cost()
	kitchen.setup(stations, pantry)
	kitchen.batch_prepared.connect(_on_kitchen_batch_prepared)
	kitchen.ingredient_shortage.connect(_on_kitchen_ingredient_shortage)
	chef_worker.setup(kitchen, chef_prep_point.global_position)
	_connect_controls()
	day_remaining = day_duration_seconds
	spawn_timer = 0.4
	status_label.text = "营业中：69元大众自助"
	_update_control_labels()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart_demo"):
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
		return

	if not day_settled:
		_update_environment(delta)
		_update_customer_environment()
		_update_day(delta)
		_update_cashier_queue()
		_update_food_station_queues()
		_update_table_queue()
		_update_restroom_queue()

	_update_debug_ui()

func _collect_world_objects() -> void:
	for node in $FoodStations.get_children():
		if node is FoodStation:
			stations.append(node as FoodStation)

	for node in $Tables.get_children():
		if node is BuffetTable:
			var table := node as BuffetTable
			tables.append(table)
			table.became_dirty.connect(_on_table_became_dirty)

func _register_initial_inventory_cost() -> void:
	food_cost = pantry.get_initial_purchase_cost()
	for station in stations:
		opening_prepared_food_cost += station.stock * station.cost_per_unit
	food_cost += opening_prepared_food_cost

func _connect_controls() -> void:
	ac_switch_button.pressed.connect(_on_ac_switch_pressed)
	temp_down_button.pressed.connect(_on_temp_down_pressed)
	temp_up_button.pressed.connect(_on_temp_up_pressed)
	speed_1_button.pressed.connect(func(): _set_speed(1.0))
	speed_2_button.pressed.connect(func(): _set_speed(2.0))
	speed_3_button.pressed.connect(func(): _set_speed(3.0))

	priority_auto_button.pressed.connect(func(): _set_kitchen_priority("auto"))
	priority_staple_button.pressed.connect(func(): _set_kitchen_priority("staple"))
	priority_meat_button.pressed.connect(func(): _set_kitchen_priority("meat"))
	priority_seafood_button.pressed.connect(func(): _set_kitchen_priority("seafood"))

	supply_staple_button.pressed.connect(func(): _toggle_station_refill("staple"))
	supply_meat_button.pressed.connect(func(): _toggle_station_refill("meat"))
	supply_seafood_button.pressed.connect(func(): _toggle_station_refill("seafood"))

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
	customer.global_position = entrance.global_position + Vector2(
		rng.randf_range(-24.0, 24.0),
		rng.randf_range(-12.0, 12.0)
	)

	var profile: Dictionary = customer_profiles[rng.randi_range(0, customer_profiles.size() - 1)]
	customer.state_changed.connect(_on_customer_state_changed)
	customer.metrics_changed.connect(_on_customer_metrics_changed)
	customer.cashier_requested.connect(_on_cashier_requested)
	customer.food_station_requested.connect(_on_food_station_requested)
	customer.table_requested.connect(_on_table_requested)
	customer.restroom_requested.connect(_on_restroom_requested)
	customer.restroom_released.connect(_on_restroom_released)
	customer.ticket_paid.connect(_on_ticket_paid)
	customer.portion_taken.connect(_on_portion_taken)
	customer.finished.connect(_on_customer_finished)
	active_customers.append(customer)
	spawned_today += 1

	customer.setup(
		entrance.global_position,
		exit_point.global_position,
		stations,
		tables,
		profile,
		ticket_price
	)
	customer.update_environment(indoor_temperature)

func _update_environment(delta: float) -> void:
	heat_load = minf(4.0, 0.7 + float(active_customers.size()) * 0.10)
	if ac_enabled:
		var effective_target := ac_setpoint + heat_load * 0.30
		indoor_temperature = move_toward(indoor_temperature, effective_target, 0.14 * delta)
		var cooling_load := maxf(0.0, outdoor_temperature + heat_load - ac_setpoint)
		utility_cost += 0.020 * delta * (1.0 + cooling_load / 8.0)
	else:
		var warm_target := outdoor_temperature + heat_load
		indoor_temperature = move_toward(indoor_temperature, warm_target, 0.065 * delta)

func _update_customer_environment() -> void:
	for customer in active_customers:
		if is_instance_valid(customer):
			customer.update_environment(indoor_temperature)

func _on_cashier_requested(customer: BuffetCustomer) -> void:
	if not cashier_queue.has(customer):
		cashier_queue.append(customer)
	_refresh_cashier_queue_targets()

func _update_cashier_queue() -> void:
	while not cashier_queue.is_empty():
		var first := cashier_queue[0]
		if is_instance_valid(first) and first.is_waiting_for_cashier():
			break
		cashier_queue.remove_at(0)

	if cashier_service_customer != null or cashier_queue.is_empty():
		return

	var first := cashier_queue[0]
	if first.has_reached_queue_target():
		cashier_queue.remove_at(0)
		cashier_service_customer = first
		first.begin_cashier_service(cashier_counter.global_position)
		_refresh_cashier_queue_targets()

func _refresh_cashier_queue_targets() -> void:
	var start := cashier_counter.global_position + Vector2(0.0, 78.0)
	for i in range(cashier_queue.size()):
		var customer := cashier_queue[i]
		if is_instance_valid(customer) and customer.is_waiting_for_cashier():
			customer.set_cashier_queue_target(start + Vector2(0.0, 54.0 * float(i)))

func _on_food_station_requested(customer: BuffetCustomer, station: FoodStation) -> void:
	station.enqueue_customer(customer)

func _update_food_station_queues() -> void:
	for station in stations:
		station.update_queue_service()

func _on_table_requested(customer: BuffetCustomer) -> void:
	if not table_wait_queue.has(customer):
		table_wait_queue.append(customer)
	_refresh_table_wait_targets()
	_update_table_queue()

func _update_table_queue() -> void:
	for i in range(table_wait_queue.size() - 1, -1, -1):
		var customer := table_wait_queue[i]
		if not is_instance_valid(customer) or not customer.is_waiting_for_table():
			table_wait_queue.remove_at(i)

	var assigned := true
	while assigned and not table_wait_queue.is_empty():
		assigned = false
		var table := _find_available_table()
		if table == null:
			break
		var customer := table_wait_queue[0]
		if table.reserve(customer):
			table_wait_queue.remove_at(0)
			customer.assign_table(table)
			assigned = true

	_refresh_table_wait_targets()

func _find_available_table() -> BuffetTable:
	for table in tables:
		if table.has_available_seat():
			return table
	return null

func _refresh_table_wait_targets() -> void:
	for i in range(table_wait_queue.size()):
		var customer := table_wait_queue[i]
		if is_instance_valid(customer) and customer.is_waiting_for_table():
			customer.set_table_wait_target(
				table_wait_point.global_position + Vector2(0.0, 46.0 * float(i))
			)

func _on_restroom_requested(customer: BuffetCustomer) -> void:
	if not restroom_queue.has(customer):
		restroom_queue.append(customer)
	_refresh_restroom_queue_targets()

func _update_restroom_queue() -> void:
	for i in range(restroom_queue.size() - 1, -1, -1):
		var customer := restroom_queue[i]
		if not is_instance_valid(customer) or not customer.is_waiting_for_restroom():
			restroom_queue.remove_at(i)

	if restroom_service_customer != null or restroom_queue.is_empty():
		return

	var first := restroom_queue[0]
	if first.has_reached_restroom_queue_target():
		restroom_queue.remove_at(0)
		restroom_service_customer = first
		first.begin_restroom_use(restroom_use_point.global_position)
		_refresh_restroom_queue_targets()

func _refresh_restroom_queue_targets() -> void:
	for i in range(restroom_queue.size()):
		var customer := restroom_queue[i]
		if is_instance_valid(customer) and customer.is_waiting_for_restroom():
			customer.set_restroom_queue_target(
				restroom_queue_point.global_position + Vector2(0.0, 48.0 * float(i))
			)

func _on_restroom_released(customer: BuffetCustomer) -> void:
	if restroom_service_customer == customer:
		restroom_service_customer = null

func _on_ticket_paid(customer: BuffetCustomer, amount: float) -> void:
	ticket_revenue += amount
	if cashier_service_customer == customer:
		cashier_service_customer = null

func _on_portion_taken(_customer: BuffetCustomer, cost: float) -> void:
	consumed_food_cost += cost

func _on_kitchen_batch_prepared(_station_name: String, _food_units: float, _raw_units: float) -> void:
	pass

func _on_kitchen_ingredient_shortage(station_name: String, _ingredient_id: String) -> void:
	last_review = station_name + "原料耗尽，无法继续补菜"

func _on_table_became_dirty(table: BuffetTable) -> void:
	service_worker.enqueue_clean(table)

func _on_customer_finished(customer: BuffetCustomer, result: Dictionary) -> void:
	finished_today += 1
	total_payback_ratio += float(result.get("payback_ratio", 0.0))
	total_rating += float(result.get("rating", 0.0))
	last_review = str(result.get("review", "整体还可以"))

	active_customers.erase(customer)
	cashier_queue.erase(customer)
	table_wait_queue.erase(customer)
	restroom_queue.erase(customer)
	for station in stations:
		station.remove_customer(customer)

	if cashier_service_customer == customer:
		cashier_service_customer = null
	if restroom_service_customer == customer:
		restroom_service_customer = null

	customer.queue_free()
	_refresh_cashier_queue_targets()
	_refresh_table_wait_targets()
	_refresh_restroom_queue_targets()

func _on_customer_state_changed(_customer: BuffetCustomer, _label: String) -> void:
	pass

func _on_customer_metrics_changed(_customer: BuffetCustomer, _fullness_ratio: float, _payback_ratio: float) -> void:
	pass

func _settle_day() -> void:
	day_settled = true
	kitchen.set_active(false)
	Engine.time_scale = 1.0
	selected_speed = 1.0
	_update_control_labels()

	var profit := ticket_revenue - food_cost - utility_cost
	var average_payback := 0.0
	var average_rating := 0.0
	if finished_today > 0:
		average_payback = total_payback_ratio / float(finished_today)
		average_rating = total_rating / float(finished_today)

	status_label.text = "营业结束｜顾客 %d｜回本感 %d%%｜评分 %.1f★｜利润 ¥%.1f" % [
		finished_today,
		int(round(average_payback * 100.0)),
		average_rating,
		profit
	]

func _on_ac_switch_pressed() -> void:
	ac_enabled = not ac_enabled
	_update_control_labels()

func _on_temp_down_pressed() -> void:
	ac_setpoint = maxf(20.0, ac_setpoint - 1.0)
	_update_control_labels()

func _on_temp_up_pressed() -> void:
	ac_setpoint = minf(28.0, ac_setpoint + 1.0)
	_update_control_labels()

func _set_speed(multiplier: float) -> void:
	selected_speed = multiplier
	Engine.time_scale = multiplier
	_update_control_labels()

func _set_kitchen_priority(food_tag: String) -> void:
	kitchen.set_priority(food_tag)
	_update_control_labels()

func _toggle_station_refill(food_tag: String) -> void:
	for station in stations:
		if station.food_tag == food_tag:
			station.set_refill_enabled(not station.is_refill_enabled())
			break
	_update_control_labels()

func _get_station_by_tag(food_tag: String) -> FoodStation:
	for station in stations:
		if station.food_tag == food_tag:
			return station
	return null

func _update_control_labels() -> void:
	ac_switch_button.text = "空调：" + ("开" if ac_enabled else "关")
	temp_down_button.text = "温度-"
	temp_up_button.text = "温度+"
	speed_1_button.text = "1×" + ("●" if selected_speed == 1.0 else "")
	speed_2_button.text = "2×" + ("●" if selected_speed == 2.0 else "")
	speed_3_button.text = "3×" + ("●" if selected_speed == 3.0 else "")

	priority_auto_button.text = "自动" + ("●" if kitchen.priority_tag == "auto" else "")
	priority_staple_button.text = "主食" + ("●" if kitchen.priority_tag == "staple" else "")
	priority_meat_button.text = "肉类" + ("●" if kitchen.priority_tag == "meat" else "")
	priority_seafood_button.text = "海鲜" + ("●" if kitchen.priority_tag == "seafood" else "")

	var staple := _get_station_by_tag("staple")
	var meat := _get_station_by_tag("meat")
	var seafood := _get_station_by_tag("seafood")
	if staple != null:
		supply_staple_button.text = "主食补菜：" + ("开" if staple.is_refill_enabled() else "停")
	if meat != null:
		supply_meat_button.text = "肉类补菜：" + ("开" if meat.is_refill_enabled() else "停")
	if seafood != null:
		supply_seafood_button.text = "海鲜补菜：" + ("开" if seafood.is_refill_enabled() else "停")

func _get_food_queue_total() -> int:
	var total := 0
	for station in stations:
		total += station.get_queue_size()
	return total

func _get_table_stats() -> String:
	var occupied := 0
	var capacity := 0
	var dirty := 0
	for table in tables:
		occupied += table.get_occupied_count()
		capacity += table.get_capacity()
		if table.is_dirty():
			dirty += 1
	return "%d/%d 脏桌%d" % [occupied, capacity, dirty]

func _update_debug_ui() -> void:
	stats_label.text = "时间 %02d秒｜店内%d｜收银%d｜取餐%d｜等座%d｜厕所%d｜桌%s" % [
		int(ceil(day_remaining)),
		active_customers.size(),
		cashier_queue.size(),
		_get_food_queue_total(),
		table_wait_queue.size(),
		restroom_queue.size(),
		_get_table_stats()
	]

	var profit := ticket_revenue - food_cost - utility_cost
	economy_label.text = "门票¥%.1f｜采购+开台¥%.1f｜已吃成本¥%.1f｜电费¥%.1f｜利润¥%.1f" % [
		ticket_revenue,
		food_cost,
		consumed_food_cost,
		utility_cost,
		profit
	]

	var parts: Array[String] = []
	for station in stations:
		parts.append(station.get_contribution_text())
	stock_label.text = "餐台：" + " || ".join(parts)

	pantry_label.text = pantry.get_inventory_text()
	environment_label.text = "室外%.1f℃｜室内%.1f℃｜热负荷+%.1f℃｜空调%s %.0f℃" % [
		outdoor_temperature,
		indoor_temperature,
		heat_load,
		("开" if ac_enabled else "关"),
		ac_setpoint
	]
	kitchen_label.text = kitchen.get_status()
	chef_label.text = chef_worker.get_status()
	staff_label.text = service_worker.get_status()
	review_label.text = "最新评价：" + last_review
