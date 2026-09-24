class_name BuffetSeat
extends Node2D

signal became_dirty(seat: BuffetSeat)
signal cleaned(seat: BuffetSeat)

@onready var service_point: Marker2D = get_node_or_null("ServicePoint") as Marker2D
@onready var body: Polygon2D = get_node_or_null("Body") as Polygon2D

var reserved_by: Node = null
var dirty := false

func is_available() -> bool:
	return reserved_by == null and not dirty

func reserve(customer: Node) -> bool:
	if dirty:
		return false
	if reserved_by != null and reserved_by != customer:
		return false
	reserved_by = customer
	_update_visual()
	return true

func release(customer: Node) -> void:
	if reserved_by != customer:
		return
	reserved_by = null
	dirty = true
	_update_visual()
	emit_signal("became_dirty", self)

func mark_clean() -> void:
	if not dirty:
		return
	dirty = false
	_update_visual()
	emit_signal("cleaned", self)

func is_dirty() -> bool:
	return dirty

func get_service_position() -> Vector2:
	if service_point != null:
		return service_point.global_position
	return global_position

func _update_visual() -> void:
	if body == null:
		return
	if dirty:
		body.color = Color(0.42, 0.34, 0.27, 1.0)
	elif reserved_by != null:
		body.color = Color(0.49, 0.31, 0.18, 1.0)
	else:
		body.color = Color(0.37, 0.25, 0.16, 1.0)
