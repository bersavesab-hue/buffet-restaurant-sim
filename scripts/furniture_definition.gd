class_name FurnitureDefinition
extends Resource

enum Category {
	TABLE,
	FOOD_STATION,
	KITCHEN,
	FACILITY,
	DECORATION
}

@export var item_id: String = ""
@export var display_name: String = ""
@export var category: Category = Category.DECORATION
@export var footprint: Vector2i = Vector2i.ONE
@export var build_cost: float = 0.0
@export var required_stage: int = 0
@export var allow_rotation: bool = true
@export var comfort: float = 0.0
@export var tags: PackedStringArray = PackedStringArray()

func get_footprint(rotation_index: int = 0) -> Vector2i:
	var normalized := posmod(rotation_index, 4)
	if allow_rotation and normalized % 2 == 1:
		return Vector2i(footprint.y, footprint.x)
	return footprint

func is_valid_definition() -> bool:
	return (
		not item_id.is_empty()
		and footprint.x > 0
		and footprint.y > 0
		and required_stage >= 0
		and build_cost >= 0.0
	)
