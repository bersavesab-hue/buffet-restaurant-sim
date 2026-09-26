class_name KitchenFacility
extends PlaceableEntity

@onready var prep_point: Marker2D = $PrepPoint

func get_prep_position() -> Vector2:
	return prep_point.global_position
