extends SceneTree

const SAVE := "user://buffet_progress_v1.json"
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_clear_save()
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var manager := main.get_node("RestaurantWorld/PlacementManager") as FurniturePlacementManager
	var table := main.get_node("Tables/TableA") as PlaceableEntity
	var original := table.grid_position
	var destination := original
	for y in range(8, 26):
		for x in range(12, 28):
			var candidate := Vector2i(x, y)
			if candidate != original and manager.can_place(table, candidate):
				destination = candidate
				break
		if destination != original:
			break
	_expect(destination != original, "test must find a free furniture cell")
	_expect(manager.place(table, destination), "table must move to free cell")
	main.on_build_furniture_moved(table)
	var removed := main.get_node("FoodStations/MeatStation") as PlaceableEntity
	_expect(main.remove_build_furniture(removed), "idle station must be removable")
	main.ticket_revenue = 500.0
	main._settle_day()
	_expect(main.day_settled, "day must settle")
	_expect(FileAccess.file_exists(SAVE), "settlement must save progress")
	var expected_cash: float = main.cash_balance
	main.queue_free()
	await process_frame
	await process_frame

	var restored := packed.instantiate()
	root.add_child(restored)
	await process_frame
	await process_frame
	await process_frame
	_expect(restored.day_index == 2, "next launch must start on day 2")
	_expect(is_equal_approx(restored.cash_balance, expected_cash), "cash must survive reload")
	var restored_table := restored.get_node("Tables/TableA") as PlaceableEntity
	_expect(restored_table.grid_position == destination, "furniture position must survive reload")
	_expect(restored.get_node_or_null("FoodStations/MeatStation") == null, "removed furniture must remain removed")
	_expect(restored.get_node("RestaurantWorld/PlacementManager").get_registered_count() == 8, "restored grid must match furniture count")
	_expect(restored.day_remaining > 0.0 and not restored.day_settled, "new day must operate")
	restored.queue_free()
	await process_frame
	_clear_save()
	if failures.is_empty():
		print("[DAY_PROGRESSION_TEST PASS] settlement, next day, cash and furniture recovery")
		quit(0)
	else:
		for failure in failures:
			push_error("[DAY_PROGRESSION_TEST FAIL] " + failure)
		quit(1)

func _clear_save() -> void:
	for path in [SAVE, SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
