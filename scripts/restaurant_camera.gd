class_name RestaurantCamera
extends Camera2D

@export var navigation_enabled := false
@export var grid_path: NodePath
@export var expansion_path: NodePath
@export var min_zoom := 0.55
@export var max_zoom := 1.35
@export var zoom_step := 0.10
@export var bounds_margin := 96.0

@onready var grid: RestaurantGrid = get_node(grid_path) as RestaurantGrid
@onready var expansion: RestaurantExpansion = get_node(expansion_path) as RestaurantExpansion

var touches: Dictionary = {}
var mouse_dragging := false
var last_pinch_distance := 0.0

func _ready() -> void:
	if expansion != null:
		expansion.expansion_changed.connect(_on_expansion_changed)

func set_navigation_enabled(value: bool) -> void:
	navigation_enabled = value
	if not value:
		touches.clear()
		mouse_dragging = false
		last_pinch_distance = 0.0

func focus_unlocked_region() -> void:
	var bounds := grid.get_unlocked_world_bounds()
	position = bounds.get_center()
	_clamp_position()

func set_zoom_level(value: float) -> void:
	var level := clampf(value, min_zoom, max_zoom)
	zoom = Vector2(level, level)
	_clamp_position()

func _unhandled_input(event: InputEvent) -> void:
	if not navigation_enabled:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
		return

	if event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)
		return

	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			mouse_dragging = mouse.pressed
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_zoom_level(zoom.x + zoom_step)
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_zoom_level(zoom.x - zoom_step)
		return

	if event is InputEventMouseMotion and mouse_dragging:
		var motion := event as InputEventMouseMotion
		position -= motion.relative / maxf(0.001, zoom.x)
		_clamp_position()

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touches[event.index] = event.position
	else:
		touches.erase(event.index)

	if touches.size() == 2:
		last_pinch_distance = _current_pinch_distance()
	else:
		last_pinch_distance = 0.0

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not touches.has(event.index):
		touches[event.index] = event.position

	var previous := touches[event.index] as Vector2
	touches[event.index] = event.position

	if touches.size() == 1:
		var delta := event.position - previous
		position -= delta / maxf(0.001, zoom.x)
		_clamp_position()
	elif touches.size() == 2:
		var distance := _current_pinch_distance()
		if last_pinch_distance > 0.0:
			var factor := distance / last_pinch_distance
			set_zoom_level(zoom.x * factor)
		last_pinch_distance = distance

func _current_pinch_distance() -> float:
	if touches.size() != 2:
		return 0.0
	var keys := touches.keys()
	var a := touches[keys[0]] as Vector2
	var b := touches[keys[1]] as Vector2
	return a.distance_to(b)

func _clamp_position() -> void:
	if grid == null:
		return

	var bounds := grid.get_unlocked_world_bounds().grow(bounds_margin)
	var visible_size := get_viewport_rect().size / maxf(0.001, zoom.x)
	var half := visible_size * 0.5

	if bounds.size.x <= visible_size.x:
		position.x = bounds.get_center().x
	else:
		position.x = clampf(position.x, bounds.position.x + half.x, bounds.end.x - half.x)

	if bounds.size.y <= visible_size.y:
		position.y = bounds.get_center().y
	else:
		position.y = clampf(position.y, bounds.position.y + half.y, bounds.end.y - half.y)

func _on_expansion_changed(_stage: int, _name: String, _rect: Rect2i) -> void:
	if navigation_enabled:
		_clamp_position()
