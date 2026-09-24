class_name BuffetSeat
extends Node2D

var reserved_by: Node = null

func is_available() -> bool:
	return reserved_by == null

func reserve(customer: Node) -> bool:
	if reserved_by != null and reserved_by != customer:
		return false
	reserved_by = customer
	return true

func release(customer: Node) -> void:
	if reserved_by == customer:
		reserved_by = null
