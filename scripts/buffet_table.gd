class_name BuffetTable
extends Node2D

signal became_dirty(table: BuffetTable)
signal cleaned(table: BuffetTable)

@export var table_name: String = "餐桌"

@onready var body: Polygon2D = get_node_or_null("Body") as Polygon2D
@onready var clean_point: Marker2D = get_node_or_null("CleanPoint") as Marker2D

var seat_points: Array[Marker2D] = []
var occupants: Dictionary = {}
var dirty := false
var has_been_used := false

func _ready() -> void:
	for node in $SeatPoints.get_children():
		if node is Marker2D:
			seat_points.append(node as Marker2D)
	_update_visual()

func has_available_seat() -> bool:
	return not dirty and occupants.size() < seat_points.size()

func reserve(customer: Node) -> bool:
	if dirty or occupants.has(customer):
		return false
	for i in range(seat_points.size()):
		if not occupants.values().has(i):
			occupants[customer] = i
			has_been_used = true
			_update_visual()
			return true
	return false

func release(customer: Node) -> void:
	if not occupants.has(customer):
		return
	occupants.erase(customer)
	if occupants.is_empty() and has_been_used:
		dirty = true
		has_been_used = false
		emit_signal("became_dirty", self)
	_update_visual()

func get_customer_seat_position(customer: Node) -> Vector2:
	if not occupants.has(customer):
		return global_position
	var index := int(occupants[customer])
	if index < 0 or index >= seat_points.size():
		return global_position
	return seat_points[index].global_position

func get_clean_position() -> Vector2:
	if clean_point != null:
		return clean_point.global_position
	return global_position

func mark_clean() -> void:
	if not dirty:
		return
	dirty = false
	_update_visual()
	emit_signal("cleaned", self)

func is_dirty() -> bool:
	return dirty

func get_capacity() -> int:
	return seat_points.size()

func get_occupied_count() -> int:
	return occupants.size()

func _update_visual() -> void:
	if body == null:
		return
	if dirty:
		body.color = Color(0.42, 0.34, 0.27, 1.0)
	elif not occupants.is_empty():
		body.color = Color(0.49, 0.31, 0.18, 1.0)
	else:
		body.color = Color(0.37, 0.25, 0.16, 1.0)
