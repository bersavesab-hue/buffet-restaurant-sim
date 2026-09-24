extends Node2D

@onready var customer: BuffetCustomer = $Customer
@onready var food_station: FoodStation = $FoodStation
@onready var state_label: Label = $CanvasLayer/UI/VBox/StateLabel
@onready var fullness_label: Label = $CanvasLayer/UI/VBox/FullnessLabel
@onready var stock_label: Label = $CanvasLayer/UI/VBox/StockLabel
@onready var seat_label: Label = $CanvasLayer/UI/VBox/SeatLabel

var seats: Array[BuffetSeat] = []

func _ready() -> void:
	seats = [$Seats/SeatA, $Seats/SeatB]
	customer.state_changed.connect(_on_customer_state_changed)
	customer.metrics_changed.connect(_on_customer_metrics_changed)
	customer.finished.connect(_on_customer_finished)
	_start_customer()

func _process(_delta: float) -> void:
	stock_label.text = "餐台库存：%d / %d" % [food_station.stock, food_station.capacity]
	var occupied := 0
	for seat in seats:
		if not seat.is_available():
			occupied += 1
	seat_label.text = "座位占用：%d / %d" % [occupied, seats.size()]

	if Input.is_action_just_pressed("restart_demo"):
		get_tree().reload_current_scene()

func _start_customer() -> void:
	customer.setup(
		$Points/Entrance.global_position,
		$Points/Cashier.global_position,
		food_station,
		seats,
		$Points/Exit.global_position
	)

func _on_customer_state_changed(label: String) -> void:
	state_label.text = "顾客状态：%s" % label

func _on_customer_metrics_changed(value: float) -> void:
	fullness_label.text = "饱食度：%d%%" % int(round(value))

func _on_customer_finished(_customer: BuffetCustomer) -> void:
	state_label.text = "顾客状态：完成（按 R 重开）"
