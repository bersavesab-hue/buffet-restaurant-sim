class_name FurniturePlacementManager
extends Node

signal entity_placed(entity: PlaceableEntity)
signal entity_moved(entity: PlaceableEntity)
signal entity_removed(entity: PlaceableEntity)

@export var grid_path: NodePath

var restaurant_grid: RestaurantGrid

func _ready() -> void:
	_resolve_grid()

func _resolve_grid() -> void:
	if restaurant_grid != null:
		return
	if grid_path.is_empty():
		return
	restaurant_grid = get_node_or_null(grid_path) as RestaurantGrid

var occupied_cells: Dictionary = {}
var entity_cells: Dictionary = {}

func can_place(
	entity: PlaceableEntity,
	anchor: Vector2i,
	rotation_index: int = 0
) -> bool:
	if entity == null or entity.furniture_definition == null:
		return false

	_resolve_grid()
	if restaurant_grid == null:
		return false

	entity.set_restaurant_grid(restaurant_grid)
	if not entity.can_use_cell(anchor, rotation_index):
		return false

	for cell in entity.get_occupied_cells(anchor, rotation_index):
		if occupied_cells.has(cell) and occupied_cells[cell] != entity:
			return false
	return true

func place(
	entity: PlaceableEntity,
	anchor: Vector2i,
	rotation_index: int = 0
) -> bool:
	if not can_place(entity, anchor, rotation_index):
		return false

	var was_registered := entity_cells.has(entity)
	_clear_entity_cells(entity)

	if not entity.apply_grid_placement(anchor, rotation_index):
		return false

	var cells := entity.get_occupied_cells()
	entity_cells[entity] = cells
	for cell in cells:
		occupied_cells[cell] = entity

	if was_registered:
		emit_signal("entity_moved", entity)
	else:
		emit_signal("entity_placed", entity)
	return true

func remove(entity: PlaceableEntity) -> void:
	if entity == null or not entity_cells.has(entity):
		return
	_clear_entity_cells(entity)
	entity.use_grid_placement = false
	emit_signal("entity_removed", entity)

func register_existing(entity: PlaceableEntity) -> bool:
	if entity == null or not entity.use_grid_placement:
		return false
	return place(entity, entity.grid_position, entity.rotation_index)

func is_cell_occupied(cell: Vector2i) -> bool:
	return occupied_cells.has(cell)

func get_entity_at(cell: Vector2i) -> PlaceableEntity:
	if not occupied_cells.has(cell):
		return null
	return occupied_cells[cell] as PlaceableEntity

func get_registered_entities() -> Array[PlaceableEntity]:
	var result: Array[PlaceableEntity] = []
	for entity in entity_cells.keys():
		if is_instance_valid(entity):
			result.append(entity as PlaceableEntity)
	return result

func _clear_entity_cells(entity: PlaceableEntity) -> void:
	if not entity_cells.has(entity):
		return
	var cells: Array = entity_cells[entity]
	for cell in cells:
		if occupied_cells.get(cell) == entity:
			occupied_cells.erase(cell)
	entity_cells.erase(entity)
