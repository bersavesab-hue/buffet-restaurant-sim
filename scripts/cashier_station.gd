class_name CashierStation
extends PlaceableEntity

@onready var counter_point: Marker2D = $CounterPoint
@onready var queue_start: Marker2D = $QueueStart

func get_counter_position() -> Vector2:
	return counter_point.global_position

func get_queue_start_position() -> Vector2:
	return queue_start.global_position
