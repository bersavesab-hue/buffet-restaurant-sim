class_name BuffetCustomer
extends CharacterBody2D

signal state_changed(label: String)
signal metrics_changed(fullness: float)
signal finished(customer: BuffetCustomer)

enum State {
	ENTER,
	CASHIER,
	FOOD,
	SEAT,
	EAT,
	EXIT,
	DONE
}

@export var speed: float = 105.0
@export var eat_seconds: float = 1.8
@export var fullness_target: float = 75.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var state: State = State.ENTER
var entrance_position := Vector2.ZERO
var cashier_position := Vector2.ZERO
var exit_position := Vector2.ZERO
var food_station: FoodStation
var seats: Array[BuffetSeat] = []
var reserved_seat: BuffetSeat
var fullness: float = 0.0
var eat_timer: float = 0.0
var navigation_ready := false

func setup(
	entrance: Vector2,
	cashier: Vector2,
	station: FoodStation,
	available_seats: Array[BuffetSeat],
	exit_point: Vector2
) -> void:
	entrance_position = entrance
	cashier_position = cashier
	food_station = station
	seats = available_seats
	exit_position = exit_point
	call_deferred("_begin_navigation")

func _begin_navigation() -> void:
	await get_tree().physics_frame
	navigation_ready = true
	_set_state(State.ENTER)

func _physics_process(_delta: float) -> void:
	if not navigation_ready or state == State.DONE or state == State.EAT:
		velocity = Vector2.ZERO
		return

	if navigation_agent.is_navigation_finished():
		_arrive()
		return

	var next_position := navigation_agent.get_next_path_position()
	var direction := global_position.direction_to(next_position)
	velocity = direction * speed
	move_and_slide()

func _process(delta: float) -> void:
	if state != State.EAT:
		return

	eat_timer -= delta
	if eat_timer > 0.0:
		return

	if fullness < fullness_target and food_station != null and food_station.has_food():
		_set_state(State.FOOD)
	else:
		_release_seat()
		_set_state(State.EXIT)

func _arrive() -> void:
	match state:
		State.ENTER:
			_set_state(State.CASHIER)
		State.CASHIER:
			_set_state(State.FOOD)
		State.FOOD:
			_take_food()
			if reserved_seat == null:
				reserved_seat = _reserve_first_seat()
			if reserved_seat == null:
				_release_seat()
				_set_state(State.EXIT)
			else:
				_set_state(State.SEAT)
		State.SEAT:
			_set_state(State.EAT)
		State.EXIT:
			_set_state(State.DONE)
		State.EAT, State.DONE:
			pass

func _set_state(next_state: State) -> void:
	state = next_state
	match state:
		State.ENTER:
			_set_target(entrance_position)
			emit_signal("state_changed", "进店")
		State.CASHIER:
			_set_target(cashier_position)
			emit_signal("state_changed", "收银")
		State.FOOD:
			_set_target(food_station.global_position)
			emit_signal("state_changed", "取餐")
		State.SEAT:
			_set_target(reserved_seat.global_position)
			emit_signal("state_changed", "回座")
		State.EAT:
			eat_timer = eat_seconds
			emit_signal("state_changed", "吃饭")
		State.EXIT:
			_set_target(exit_position)
			emit_signal("state_changed", "离店")
		State.DONE:
			visible = false
			emit_signal("state_changed", "完成")
			emit_signal("finished", self)

func _set_target(position: Vector2) -> void:
	navigation_agent.target_position = position

func _take_food() -> void:
	if food_station == null:
		return
	var gained := food_station.take_portion()
	fullness = clampf(fullness + gained, 0.0, 100.0)
	emit_signal("metrics_changed", fullness)

func _reserve_first_seat() -> BuffetSeat:
	for seat in seats:
		if seat.is_available() and seat.reserve(self):
			return seat
	return null

func _release_seat() -> void:
	if reserved_seat != null:
		reserved_seat.release(self)
		reserved_seat = null
