class_name PantrySystem
extends Node

signal inventory_changed(ingredient_id: String, remaining: float)
signal stockout(ingredient_id: String)

var stock := {
	"rice": 70.0,
	"meat": 42.0,
	"seafood": 30.0
}

var purchase_cost_per_raw_unit := {
	"rice": 0.75,
	"meat": 5.2,
	"seafood": 4.6
}

func get_stock(ingredient_id: String) -> float:
	return float(stock.get(ingredient_id, 0.0))

func can_consume(ingredient_id: String, raw_units: float) -> bool:
	return get_stock(ingredient_id) >= raw_units

func consume(ingredient_id: String, raw_units: float) -> float:
	var available := get_stock(ingredient_id)
	var actual := minf(maxf(0.0, raw_units), available)
	stock[ingredient_id] = available - actual
	emit_signal("inventory_changed", ingredient_id, get_stock(ingredient_id))
	if get_stock(ingredient_id) <= 0.001:
		emit_signal("stockout", ingredient_id)
	return actual

func get_initial_purchase_cost() -> float:
	var total := 0.0
	for ingredient_id in stock.keys():
		total += float(stock[ingredient_id]) * float(purchase_cost_per_raw_unit.get(ingredient_id, 0.0))
	return total

func get_inventory_text() -> String:
	return "原料 主食 %.1f｜肉 %.1f｜海鲜 %.1f" % [
		get_stock("rice"),
		get_stock("meat"),
		get_stock("seafood")
	]
