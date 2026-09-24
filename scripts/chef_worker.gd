class_name ChefWorker
extends CharacterBody2D

signal task_changed(label: String)

enum State {
	IDLE,
	MOVING_TO_PREP,
	COOKING,
	DELIVERING
}

@export var speed: float = 135.0
@export var cook_seconds: float = 3.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var visual: ActorVisual = $Visual

var state: State = State.IDLE
var kitchen: KitchenSystem
var prep_position := Vector2.ZERO
var current_station: FoodStation
var cook_timer := 0.0
var navigation_ready := false

func _ready() -> void:
	visual.set_carry_visible(false)
	visual.set_action("idle")
	call_deferred("_begin_navigation")

func setup(kitchen_system: KitchenSystem, prep_point: Vector2) -> void:
	kitchen = kitchen_system
	prep_position = prep_point

func _begin_navigation() -> void:
	await get_tree().physics_frame
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	navigation_ready = true

func _process(delta: float) -> void:
	z_index = int(global_position.y)
	if not navigation_ready or kitchen == null:
		return
	if state == State.IDLE:
		_try_claim_job()
	elif state == State.COOKING:
		cook_timer -= delta
		if cook_timer <= 0.0:
			visual.set_action("idle")
			visual.set_carry_visible(true)
			state = State.DELIVERING
			navigation_agent.target_position = current_station.get_refill_position()
			emit_signal("task_changed", "厨师：端菜去" + current_station.station_name)

func _physics_process(_delta: float) -> void:
	if not navigation_ready or state not in [State.MOVING_TO_PREP, State.DELIVERING]:
		return
	if NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	if navigation_agent.is_navigation_finished():
		_arrive()
		return
	var next_position := navigation_agent.get_next_path_position()
	var desired_velocity := global_position.direction_to(next_position) * speed
	visual.set_motion(desired_velocity)
	if navigation_agent.avoidance_enabled:
		navigation_agent.velocity = desired_velocity
	else:
		velocity = desired_velocity
		move_and_slide()

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if state not in [State.MOVING_TO_PREP, State.DELIVERING]:
		return
	velocity = safe_velocity
	visual.set_motion(safe_velocity)
	move_and_slide()

func _try_claim_job() -> void:
	current_station = kitchen.claim_next_job()
	if current_station == null:
		return
	state = State.MOVING_TO_PREP
	visual.set_action("idle")
	navigation_agent.target_position = prep_position
	emit_signal("task_changed", "厨师：准备" + current_station.station_name)

func _arrive() -> void:
	if state == State.MOVING_TO_PREP:
		state = State.COOKING
		cook_timer = cook_seconds
		velocity = Vector2.ZERO
		visual.set_motion(Vector2.ZERO)
		visual.set_action("cook")
		emit_signal("task_changed", "厨师：制作" + current_station.station_name)
	elif state == State.DELIVERING:
		kitchen.complete_job(current_station)
		visual.set_carry_visible(false)
		visual.set_action("idle")
		current_station = null
		state = State.IDLE
		emit_signal("task_changed", "厨师：待命")

func get_status() -> String:
	match state:
		State.MOVING_TO_PREP:
			return "厨师：去后厨准备"
		State.COOKING:
			return "厨师：制作 %.1fs" % maxf(0.0, cook_timer)
		State.DELIVERING:
			return "厨师：正在补菜"
		_:
			return "厨师：待命"
