extends SceneTree

const GridClass = preload("res://scripts/restaurant_grid.gd")
const DefinitionClass = preload("res://scripts/furniture_definition.gd")
const PlaceableClass = preload("res://scripts/placeable_entity.gd")
const ManagerClass = preload("res://scripts/furniture_placement_manager.gd")

var failures: Array[String] = []

func _init() -> void:
	var world := Node2D.new()
	root.add_child(world)

	var grid := GridClass.new()
	grid.name = "Grid"
	world.add_child(grid)
	grid.set_stage(0)

	var manager := ManagerClass.new()
	manager.name = "Manager"
	manager.grid_path = NodePath("../Grid")
	world.add_child(manager)

	var table_def := DefinitionClass.new()
	table_def.item_id = "table_test"
	table_def.display_name = "测试双人桌"
	table_def.category = DefinitionClass.Category.TABLE
	table_def.footprint = Vector2i(2, 3)
	table_def.build_cost = 600.0
	table_def.required_stage = 0
	table_def.allow_rotation = true

	_expect(table_def.is_valid_definition(), "table definition should be valid")
	_expect(table_def.get_footprint(0) == Vector2i(2, 3), "rotation 0 footprint mismatch")
	_expect(table_def.get_footprint(1) == Vector2i(3, 2), "rotation 1 should swap footprint")

	var a := PlaceableClass.new()
	a.furniture_definition = table_def
	world.add_child(a)

	var b := PlaceableClass.new()
	b.furniture_definition = table_def
	world.add_child(b)

	var anchor := Vector2i(16, 12)
	_expect(manager.place(a, anchor, 0), "first table should place")
	_expect(a.position == grid.grid_to_world(anchor), "placed node should snap to grid world position")
	_expect(a.get_occupied_cells().size() == 6, "2x3 table should occupy six cells")
	_expect(manager.is_cell_occupied(anchor), "anchor cell should be occupied")
	_expect(not manager.place(b, anchor + Vector2i(1, 1), 0), "overlapping table should be rejected")

	var free_anchor := Vector2i(24, 14)
	_expect(manager.place(b, free_anchor, 1), "rotated table should place in free space")
	_expect(b.get_footprint() == Vector2i(3, 2), "placed rotated footprint mismatch")

	var old_cell := anchor
	var moved_anchor := Vector2i(18, 18)
	_expect(manager.place(a, moved_anchor, 0), "registered table should be movable")
	_expect(not manager.is_cell_occupied(old_cell), "old cells must clear after move")
	_expect(manager.get_entity_at(moved_anchor) == a, "new cell should point to moved entity")

	var locked_anchor := Vector2i(0, 0)
	_expect(not manager.place(a, locked_anchor, 0), "stage0 must reject locked land")

	grid.set_stage(4)
	_expect(manager.place(a, locked_anchor, 0), "final expansion should allow corner placement")

	manager.remove(a)
	_expect(manager.get_entity_at(locked_anchor) == null, "remove must release occupied cells")

	if failures.is_empty():
		print("[PLACEABLE_TEST PASS] definitions, rotation, snapping, occupancy and expansion gating OK")
		quit(0)
	else:
		for failure in failures:
			push_error("[PLACEABLE_TEST FAIL] " + failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
