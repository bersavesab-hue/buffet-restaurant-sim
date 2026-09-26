extends SceneTree

const RestaurantGridClass = preload("res://scripts/restaurant_grid.gd")

var failures: Array[String] = []

func _init() -> void:
	var grid := RestaurantGridClass.new()
	root.add_child(grid)

	_expect(grid.GRID_SIZE == Vector2i(44, 36), "final grid must be 44x36")
	_expect(grid.get_stage_count() == 5, "expansion must have five stages")
	_expect(grid.get_stage_rect(0) == Rect2i(13, 9, 18, 18), "stage0 must be 18x18")
	_expect(grid.get_stage_rect(4) == Rect2i(0, 0, 44, 36), "final stage must unlock whole grid")

	for stage in range(grid.get_stage_count() - 1):
		var a := grid.get_stage_rect(stage)
		var b := grid.get_stage_rect(stage + 1)
		_expect(_rect_contains_rect(b, a), "stage %d must be contained by stage %d" % [stage, stage + 1])

	var probes := [
		Vector2i(0, 0),
		Vector2i(13, 9),
		Vector2i(22, 18),
		Vector2i(30, 26),
		Vector2i(43, 35)
	]
	for cell in probes:
		var world := grid.grid_to_world(cell)
		var roundtrip := grid.world_to_grid(world)
		_expect(roundtrip == cell, "grid/world roundtrip failed for %s" % str(cell))

	grid.set_stage(0)
	_expect(grid.is_cell_unlocked(Vector2i(22, 18)), "center cell should be unlocked at stage0")
	_expect(not grid.is_cell_unlocked(Vector2i(0, 0)), "corner cell should remain locked at stage0")

	grid.set_stage(4)
	_expect(grid.is_cell_unlocked(Vector2i(0, 0)), "corner cell should unlock at final stage")
	_expect(grid.is_cell_unlocked(Vector2i(43, 35)), "far corner should unlock at final stage")

	var full_bounds := grid.get_full_world_bounds()
	_expect(full_bounds.size.x > 2000.0, "final world should exceed one phone width")
	_expect(full_bounds.size.y > 1100.0, "final world should have substantial depth")

	if failures.is_empty():
		print("[RESTAURANT_WORLD_TEST PASS] 44x36 grid, five expansion stages, coordinate mapping OK")
		quit(0)
	else:
		for failure in failures:
			push_error("[RESTAURANT_WORLD_TEST FAIL] " + failure)
		quit(1)

func _rect_contains_rect(outer: Rect2i, inner: Rect2i) -> bool:
	return outer.has_point(inner.position) and outer.has_point(inner.end - Vector2i.ONE)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
