class_name ServiceWorker
extends CharacterBody2D

signal task_changed(label: String)

enum State {
	IDLE,
	MOVING_TO_TABLE,
	COLLECTING,
	CLEANING
}

@export var speed: float = 145.0
@export var collect_seconds: float = 0.9
@export var clean_seconds: float = 1.6

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var visual: ActorVisual = $Visual

var state: State = State.IDLE
var task_queue: Array[BuffetTable] = []
var current_table: BuffetTable
var action_timer := 0.0
var navigation_ready := false

func _ready() -> void:
	call_deferred("_begin_navigation")

func _begin_navigation() -> void:
	await get_tree().physics_frame
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	navigation_ready = true
	emit_signal("task_changed", "服务员：待命")

func enqueue_clean(table: BuffetTable) -> void:
	if table == null:
		return
	if current_table == table or task_queue.has(table):
		return
	task_queue.append(table)
	if state == State.IDLE:
		visual.set_action("idle")
		_start_next_task()

func _physics_process(_delta: float) -> void:
	if not navigation_ready or state != State.MOVING_TO_TABLE:
		return
	if NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	if navigation_agent.is_navigation_finished():
		state = State.COLLECTING
		action_timer = collect_seconds
		velocity = Vector2.ZERO
		visual.set_motion(Vector2.ZERO)
		visual.set_action("collect")
		emit_signal("task_changed", "服务员：收盘")
		return
	var next_position := navigation_agent.get_next_path_position()
	var desired_velocity := global_position.direction_to(next_position) * speed
	visual.set_motion(desired_velocity)
	if navigation_agent.avoidance_enabled:
		navigation_agent.velocity = desired_velocity
	else:
		velocity = desired_velocity
		move_and_slide()

func _process(delta: float) -> void:
	z_index = int(global_position.y)
	if state not in [State.COLLECTING, State.CLEANING]:
		return
	action_timer -= delta
	if action_timer > 0.0:
		return
	if state == State.COLLECTING:
		state = State.CLEANING
		visual.set_action("clean")
		action_timer = clean_seconds
		emit_signal("task_changed", "服务员：擦桌")
		return
	if current_table != null and is_instance_valid(current_table):
		current_table.mark_clean()
	current_table = null
	state = State.IDLE
	visual.set_action("idle")
	_start_next_task()

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if state != State.MOVING_TO_TABLE:
		return
	velocity = safe_velocity
	visual.set_motion(safe_velocity)
	move_and_slide()

func _start_next_task() -> void:
	while not task_queue.is_empty():
		var table := task_queue.pop_front()
		if is_instance_valid(table) and table.is_dirty():
			current_table = table
			state = State.MOVING_TO_TABLE
			visual.set_action("idle")
			navigation_agent.target_position = table.get_clean_position()
			emit_signal("task_changed", "服务员：前往脏桌")
			return
	state = State.IDLE
	emit_signal("task_changed", "服务员：待命")

func get_status() -> String:
	match state:
		State.MOVING_TO_TABLE:
			return "服务员：前往脏桌｜待办 %d" % task_queue.size()
		State.COLLECTING:
			return "服务员：收盘 %.1fs｜待办 %d" % [maxf(0.0, action_timer), task_queue.size()]
		State.CLEANING:
			return "服务员：擦桌 %.1fs｜待办 %d" % [maxf(0.0, action_timer), task_queue.size()]
		_:
			return "服务员：待命｜待办 %d" % task_queue.size()
