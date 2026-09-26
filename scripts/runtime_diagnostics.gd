class_name RuntimeDiagnostics
extends Node

@export var stuck_warning_seconds: float = 7.0
@export var queue_warning_seconds: float = 14.0

@onready var main := get_parent()
@onready var diagnostics_label: Label = main.get_node_or_null("CanvasLayer/UI/VBox/DiagnosticsLabel") as Label

var customer_watch: Dictionary = {}
var queue_watch := {
	"cashier": {"size": 0, "seconds": 0.0},
	"food": {"size": 0, "seconds": 0.0},
	"table": {"size": 0, "seconds": 0.0},
	"restroom": {"size": 0, "seconds": 0.0}
}
var active_warnings: Array[String] = []
var self_check_ok := false

func _ready() -> void:
	call_deferred("_run_startup_self_check")

func _process(delta: float) -> void:
	if not self_check_ok:
		return
	active_warnings.clear()
	_track_customers(delta)
	_track_queues(delta)
	_update_label()

func _run_startup_self_check() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	var missing: Array[String] = []
	var required_nodes := [
		"CustomerLayer",
		"RestaurantWorld/BuildGrid",
		"RestaurantWorld/Expansion",
		"RestaurantWorld/PlacementManager",
		"FoodStations",
		"Tables",
		"Kitchen",
		"Pantry",
		"Staff/ServiceWorker",
		"Staff/ChefWorker",
		"FunctionalFurniture/CashierStation",
		"FunctionalFurniture/KitchenFacility",
		"FunctionalFurniture/RestroomFacility",
		"Points/Entrance",
		"Points/Exit"
	]
	for path in required_nodes:
		if not main.has_node(path):
			missing.append(path)

	var required_assets := [
		"res://scenes/customer.tscn",
		"res://scenes/service_worker.tscn",
		"res://scenes/chef_worker.tscn",
		"res://assets/vertical_slice/environment/restaurant_floor.svg",
		"res://assets/vertical_slice/environment/table_double.svg",
		"res://assets/vertical_slice/environment/buffet_station.svg"
	]
	for path in required_assets:
		if not ResourceLoader.exists(path):
			missing.append(path)

	var station_count := main.get_node("FoodStations").get_child_count() if main.has_node("FoodStations") else 0
	var table_count := main.get_node("Tables").get_child_count() if main.has_node("Tables") else 0

	if main.has_node("FoodStations"):
		for node in main.get_node("FoodStations").get_children():
			if not (node is PlaceableEntity):
				missing.append("FoodStationNotPlaceable:" + node.name)
			elif (node as PlaceableEntity).furniture_definition == null:
				missing.append("FurnitureDefinitionMissing:" + node.name)

	if main.has_node("Tables"):
		for node in main.get_node("Tables").get_children():
			if not (node is PlaceableEntity):
				missing.append("TableNotPlaceable:" + node.name)
			elif (node as PlaceableEntity).furniture_definition == null:
				missing.append("FurnitureDefinitionMissing:" + node.name)
	if main.has_node("FunctionalFurniture"):
		for node in main.get_node("FunctionalFurniture").get_children():
			if not (node is PlaceableEntity):
				missing.append("FunctionalFurnitureNotPlaceable:" + node.name)
			elif (node as PlaceableEntity).furniture_definition == null:
				missing.append("FurnitureDefinitionMissing:" + node.name)

	if station_count < 3:
		missing.append("FoodStations<3")
	if table_count < 3:
		missing.append("Tables<3")

	var placement_manager := main.get_node_or_null("RestaurantWorld/PlacementManager") as FurniturePlacementManager
	if placement_manager != null:
		if placement_manager.get_registered_count() != 9:
			missing.append("GridFurnitureRegistered!=9")
		if placement_manager.get_occupied_cell_count() != 57:
			missing.append("GridFurnitureCells!=57")

	if not missing.is_empty():
		var message := "启动自检失败：" + ", ".join(missing)
		push_error(message)
		if diagnostics_label != null:
			diagnostics_label.text = "诊断：失败"
		return

	self_check_ok = true
	print("[SELFTEST PASS] grid layout OK | stations=%d tables=%d furniture=9 cells=57" % [station_count, table_count])
	if diagnostics_label != null:
		diagnostics_label.text = "诊断：OK"

func _track_customers(delta: float) -> void:
	var layer := main.get_node_or_null("CustomerLayer")
	if layer == null:
		return

	var alive_ids: Dictionary = {}
	for node in layer.get_children():
		if not (node is BuffetCustomer):
			continue
		var customer := node as BuffetCustomer
		var id := customer.get_instance_id()
		alive_ids[id] = true

		if not customer_watch.has(id):
			customer_watch[id] = {
				"position": customer.global_position,
				"state": customer.state,
				"seconds": 0.0,
				"warned": false
			}
			continue

		var watch: Dictionary = customer_watch[id]
		var state_changed := int(watch["state"]) != int(customer.state)
		var previous_position: Vector2 = watch["position"]
		var moved := previous_position.distance_to(customer.global_position) > 2.5

		if state_changed or moved or customer.is_expected_stationary_for_diagnostics():
			watch["seconds"] = 0.0
			watch["warned"] = false
		else:
			watch["seconds"] = float(watch["seconds"]) + delta
			if float(watch["seconds"]) >= stuck_warning_seconds:
				var text := "顾客疑似卡住：%s %.1fs" % [
					customer.get_debug_state_label(),
					float(watch["seconds"])
				]
				active_warnings.append(text)
				if not bool(watch["warned"]):
					push_warning(text + " @ " + str(customer.global_position))
					watch["warned"] = true

		watch["position"] = customer.global_position
		watch["state"] = customer.state
		customer_watch[id] = watch

	for id in customer_watch.keys():
		if not alive_ids.has(id):
			customer_watch.erase(id)

func _track_queues(delta: float) -> void:
	var sizes := {
		"cashier": main.cashier_queue.size(),
		"food": main._get_food_queue_total(),
		"table": main.table_wait_queue.size(),
		"restroom": main.restroom_queue.size()
	}

	for key in sizes.keys():
		var size := int(sizes[key])
		var watch: Dictionary = queue_watch[key]
		if size > 0 and int(watch["size"]) == size:
			watch["seconds"] = float(watch["seconds"]) + delta
		else:
			watch["seconds"] = 0.0
		watch["size"] = size
		queue_watch[key] = watch

		if size > 0 and float(watch["seconds"]) >= queue_warning_seconds:
			active_warnings.append("%s队列持续%d人" % [_queue_name(key), size])

func _queue_name(key: String) -> String:
	match key:
		"cashier":
			return "收银"
		"food":
			return "取餐"
		"table":
			return "等座"
		"restroom":
			return "厕所"
		_:
			return key

func _update_label() -> void:
	if diagnostics_label == null:
		return
	if active_warnings.is_empty():
		diagnostics_label.text = "诊断：OK｜FPS %d" % int(Engine.get_frames_per_second())
	else:
		diagnostics_label.text = "诊断：" + "；".join(active_warnings.slice(0, 2))
