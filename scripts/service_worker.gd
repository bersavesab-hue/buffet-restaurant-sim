class_name ServiceWorker
extends CharacterBody2D

signal task_changed(label: String)

enum State {
	IDLE,
	MOVING_TO_TABLE,
	CLEANING
}

@export var speed: float = 145.0
@export var clean_seconds: float = 2.2

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var state: State = State.IDLE
var task_queue: Array[BuffetSeat] = []
var current_seat: BuffetSeat
var clean_timer := 0.0
var navigation_ready := false

func _ready() -> void:
	call_deferred("_begin_navigation")

func _begin_navigation() -> void:
	await get_tree().physics_frame
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	navigation_ready = true
	emit_signal("task_changed", "服务员：待命")

func enqueue_clean(seat: BuffetSeat) -> void:
	if seat == null:
		return
	if current_seat == seat or task_queue.has(seat):
		return
	task_queue.append(seat)
	if state == State.IDLE:
		_start_next_task()

func _physics_process(_delta: float) -> void:
	if not navigation_ready or state != State.MOVING_TO_TABLE:
		return

	if NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return

	if navigation_agent.is_navigation_finished():
		state = State.CLEANING
		clean_timer = clean_seconds
		velocity = Vector2.ZERO
		emit_signal("task_changed", "服务员：清桌")
		return

	var next_position := navigation_agent.get_next_path_position()
	var desired_velocity := global_position.direction_to(next_position) * speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.velocity = desired_velocity
	else:
		velocity = desired_velocity
		move_and_slide()

func _process(delta: float) -> void:
	if state != State.CLEANING:
		return
	clean_timer -= delta
	if clean_timer > 0.0:
		return

	if current_seat != null and is_instance_valid(current_seat):
		current_seat.mark_clean()

	current_seat = null
	state = State.IDLE
	_start_next_task()

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if state != State.MOVING_TO_TABLE:
		return
	velocity = safe_velocity
	move_and_slide()

func _start_next_task() -> void:
	while not task_queue.is_empty():
		var seat := task_queue.pop_front()
		if is_instance_valid(seat) and seat.is_dirty():
			current_seat = seat
			state = State.MOVING_TO_TABLE
			navigation_agent.target_position = seat.get_service_position()
			emit_signal("task_changed", "服务员：前往清理")
			return

	state = State.IDLE
	emit_signal("task_changed", "服务员：待命")

func get_status() -> String:
	if state == State.CLEANING and current_seat != null:
		return "服务员：清桌 %.1fs｜待办 %d" % [maxf(0.0, clean_timer), task_queue.size()]
	if state == State.MOVING_TO_TABLE:
		return "服务员：前往脏桌｜待办 %d" % task_queue.size()
	return "服务员：待命｜待办 %d" % task_queue.size()
