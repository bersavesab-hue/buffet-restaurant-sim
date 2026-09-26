class_name FoodStation
extends PlaceableEntity

@export var station_name: String = "餐台"
@export_enum("staple", "meat", "seafood") var food_tag: String = "staple"
@export var ingredient_id: String = "rice"
@export var raw_units_per_food_unit: float = 0.40
@export var capacity: float = 12.0
@export var starting_stock: float = 12.0
@export var satiation_per_unit: float = 18.0
@export var perceived_value_per_unit: float = 8.0
@export var cost_per_unit: float = 3.0
@export var queue_spacing: float = 54.0
@export var queue_direction: Vector2 = Vector2(0, 1)

@onready var service_point: Marker2D = get_node_or_null("ServicePoint") as Marker2D
@onready var refill_point: Marker2D = get_node_or_null("RefillPoint") as Marker2D

var stock: float = 0.0
var refill_enabled := true
var customer_queue: Array[Node] = []
var total_units_taken := 0.0
var total_cost_served := 0.0
var total_perceived_value_served := 0.0
var dish_visuals: Array[CanvasItem] = []

func _ready() -> void:
	super()
	stock = clampf(starting_stock, 0.0, capacity)
	for node_name in ["DishA", "DishB"]:
		var item := get_node_or_null(node_name) as CanvasItem
		if item != null:
			dish_visuals.append(item)
	_update_dish_visuals()

func has_food(min_units: float = 0.25) -> bool:
	return stock >= min_units

func set_refill_enabled(value: bool) -> void:
	refill_enabled = value

func is_refill_enabled() -> bool:
	return refill_enabled

func get_service_position() -> Vector2:
	if service_point != null:
		return service_point.global_position
	return global_position

func get_refill_position() -> Vector2:
	if refill_point != null:
		return refill_point.global_position
	return global_position

func enqueue_customer(customer: Node) -> void:
	if customer == null or customer_queue.has(customer):
		return
	customer_queue.append(customer)
	_refresh_queue_targets()

func remove_customer(customer: Node) -> void:
	customer_queue.erase(customer)
	_refresh_queue_targets()

func update_queue_service() -> void:
	_cleanup_queue()
	if customer_queue.is_empty():
		return
	var customer := customer_queue[0]
	if not has_food():
		return
	if customer.has_method("has_reached_food_queue_target") and bool(customer.call("has_reached_food_queue_target", self)):
		customer_queue.remove_at(0)
		if customer.has_method("begin_food_service"):
			customer.call("begin_food_service", self)
		_refresh_queue_targets()

func _cleanup_queue() -> void:
	for i in range(customer_queue.size() - 1, -1, -1):
		var customer := customer_queue[i]
		if not is_instance_valid(customer):
			customer_queue.remove_at(i)
		elif customer.has_method("is_waiting_for_food") and not bool(customer.call("is_waiting_for_food", self)):
			customer_queue.remove_at(i)

func _refresh_queue_targets() -> void:
	var direction := queue_direction.normalized()
	for i in range(customer_queue.size()):
		var customer := customer_queue[i]
		if not is_instance_valid(customer):
			continue
		var target := get_service_position() + direction * queue_spacing * float(i)
		if customer.has_method("set_food_queue_target"):
			customer.call("set_food_queue_target", self, target)

func get_queue_size() -> int:
	_cleanup_queue()
	return customer_queue.size()

func refresh_queue_targets() -> void:
	_refresh_queue_targets()

func take_portion(requested_units: float) -> Dictionary:
	if stock <= 0.0:
		return {}

	var actual_units := minf(stock, maxf(0.25, requested_units))
	stock = maxf(0.0, stock - actual_units)
	_update_dish_visuals()
	var actual_cost := cost_per_unit * actual_units
	var actual_value := perceived_value_per_unit * actual_units
	total_units_taken += actual_units
	total_cost_served += actual_cost
	total_perceived_value_served += actual_value

	return {
		"station_name": station_name,
		"food_tag": food_tag,
		"units": actual_units,
		"satiation": satiation_per_unit * actual_units,
		"perceived_value": actual_value,
		"cost": actual_cost
	}

func refill(units: float) -> float:
	var before := stock
	stock = clampf(stock + units, 0.0, capacity)
	_update_dish_visuals()
	return stock - before

func _update_dish_visuals() -> void:
	var ratio := get_stock_ratio()
	for item in dish_visuals:
		item.visible = ratio > 0.015
		var tint := item.modulate
		tint.a = clampf(0.18 + ratio * 0.82, 0.0, 1.0)
		item.modulate = tint

func get_stock_ratio() -> float:
	return clampf(stock / maxf(0.01, capacity), 0.0, 1.0)

func get_remaining_capacity() -> float:
	return maxf(0.0, capacity - stock)

func raw_needed_for(food_units: float) -> float:
	return maxf(0.0, food_units) * raw_units_per_food_unit

func food_units_from_raw(raw_units: float) -> float:
	return maxf(0.0, raw_units) / maxf(0.001, raw_units_per_food_unit)

func get_contribution_text() -> String:
	return "%s %.1f/%.0f 队%d｜成本%.1f 价值%.1f｜补菜%s" % [
		station_name,
		stock,
		capacity,
		get_queue_size(),
		total_cost_served,
		total_perceived_value_served,
		("开" if refill_enabled else "停")
	]
