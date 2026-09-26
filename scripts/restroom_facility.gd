class_name RestroomFacility
extends PlaceableEntity

@onready var queue_point: Marker2D = $QueuePoint
@onready var use_point: Marker2D = $UsePoint

func get_queue_position() -> Vector2:
	return queue_point.global_position

func get_use_position() -> Vector2:
	return use_point.global_position
