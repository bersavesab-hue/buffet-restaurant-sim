class_name RestaurantBuildMode
extends Node

signal build_mode_changed(active: bool)

@onready var main := get_parent()
@onready var grid: RestaurantGrid = main.get_node("RestaurantWorld/BuildGrid") as RestaurantGrid
@onready var placement_manager: FurniturePlacementManager = main.get_node("RestaurantWorld/PlacementManager") as FurniturePlacementManager
@onready var world_camera: RestaurantCamera = main.get_node("WorldCamera") as RestaurantCamera
@onready var preview: BuildPlacementPreview = main.get_node("BuildPreview") as BuildPlacementPreview

@onready var enter_button: Button = main.get_node("CanvasLayer/Controls/HBox/BuildMode") as Button
@onready var build_panel: Control = main.get_node("CanvasLayer/BuildPanel") as Control
@onready var selected_label: Label = main.get_node("CanvasLayer/BuildPanel/VBox/SelectedLabel") as Label
@onready var status_label: Label = main.get_node("CanvasLayer/BuildPanel/VBox/StatusLabel") as Label
@onready var rotate_button: Button = main.get_node("CanvasLayer/BuildPanel/VBox/Actions/Rotate") as Button
@onready var confirm_button: Button = main.get_node("CanvasLayer/BuildPanel/VBox/Actions/Confirm") as Button
@onready var cancel_button: Button = main.get_node("CanvasLayer/BuildPanel/VBox/Actions/Cancel") as Button
@onready var remove_button: Button = main.get_node("CanvasLayer/BuildPanel/VBox/Actions/Remove") as Button
@onready var exit_button: Button = main.get_node("CanvasLayer/BuildPanel/VBox/Actions/Exit") as Button

@onready var supply_controls: CanvasItem = main.get_node("CanvasLayer/SupplyControls") as CanvasItem
@onready var priority_controls: CanvasItem = main.get_node("CanvasLayer/PriorityControls") as CanvasItem
@onready var operation_controls: CanvasItem = main.get_node("CanvasLayer/Controls") as CanvasItem

var build_mode := false
var previous_pause_state := false
var selected_entity: PlaceableEntity
var preview_anchor := Vector2i.ZERO
var preview_rotation := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	build_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	build_panel.visible = false

	enter_button.pressed.connect(enter_build_mode)
	rotate_button.pressed.connect(_rotate_selected)
	confirm_button.pressed.connect(_confirm_selected)
	cancel_button.pressed.connect(_cancel_selected)
	remove_button.pressed.connect(_remove_selected)
	exit_button.pressed.connect(exit_build_mode)
	_update_panel_state()

func enter_build_mode() -> void:
	if build_mode:
		return

	build_mode = true
	previous_pause_state = get_tree().paused
	build_panel.visible = true
	supply_controls.visible = false
	priority_controls.visible = false
	operation_controls.visible = false

	grid.set_build_overlay_visible(true)
	world_camera.process_mode = Node.PROCESS_MODE_ALWAYS
	world_camera.set_navigation_enabled(true)
	get_tree().paused = true

	status_label.text = "点选家具后拖到目标格；空白处拖动可浏览餐厅"
	selected_label.text = "未选择家具"
	_update_panel_state()
	emit_signal("build_mode_changed", true)
	print("[BUILD MODE] entered")

func exit_build_mode() -> void:
	if not build_mode:
		return

	_clear_selection()
	grid.set_build_overlay_visible(false)
	preview.clear_preview()
	world_camera.set_navigation_enabled(false)
	world_camera.process_mode = Node.PROCESS_MODE_INHERIT

	build_panel.visible = false
	supply_controls.visible = true
	priority_controls.visible = true
	operation_controls.visible = true
	build_mode = false
	get_tree().paused = previous_pause_state

	emit_signal("build_mode_changed", false)
	print("[BUILD MODE] exited")

func _unhandled_input(event: InputEvent) -> void:
	if not build_mode:
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_handle_pointer(touch.position)
		return

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if selected_entity != null:
			_update_preview_from_screen(drag.position)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			_handle_pointer(mouse.position)
		return

	if event is InputEventMouseMotion and selected_entity != null:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var motion := event as InputEventMouseMotion
			_update_preview_from_screen(motion.position)
			get_viewport().set_input_as_handled()

func _handle_pointer(screen_position: Vector2) -> void:
	var world_position := _screen_to_world(screen_position)
	var cell := grid.world_to_grid(world_position)
	var entity := placement_manager.get_entity_at(cell)

	if entity != null:
		_select_entity(entity)
		get_viewport().set_input_as_handled()
		return

	if selected_entity != null:
		preview_anchor = cell
		_refresh_preview()
		get_viewport().set_input_as_handled()

func _select_entity(entity: PlaceableEntity) -> void:
	if entity == null:
		return

	var reason := ""
	if main.has_method("get_furniture_move_block_reason"):
		reason = str(main.call("get_furniture_move_block_reason", entity))
	if not reason.is_empty():
		status_label.text = reason
		return

	_clear_selection()
	selected_entity = entity
	selected_entity.modulate = Color(1.0, 0.92, 0.62, 1.0)
	preview_anchor = entity.grid_position
	preview_rotation = entity.rotation_index
	world_camera.set_navigation_enabled(false)

	var display_name := entity.name
	if entity.furniture_definition != null:
		display_name = entity.furniture_definition.display_name
	selected_label.text = "%s｜格 %s" % [display_name, str(entity.grid_position)]
	status_label.text = "拖动到新位置，确认后才真正移动"
	_refresh_preview()
	_update_panel_state()

func _clear_selection() -> void:
	if selected_entity != null and is_instance_valid(selected_entity):
		selected_entity.modulate = Color.WHITE
	selected_entity = null
	preview.clear_preview()
	if build_mode:
		world_camera.set_navigation_enabled(true)
	selected_label.text = "未选择家具"
	_update_panel_state()

func _update_preview_from_screen(screen_position: Vector2) -> void:
	var world_position := _screen_to_world(screen_position)
	preview_anchor = grid.world_to_grid(world_position)
	_refresh_preview()

func _refresh_preview() -> void:
	if selected_entity == null:
		preview.clear_preview()
		return

	var cells := selected_entity.get_occupied_cells(preview_anchor, preview_rotation)
	var valid := placement_manager.can_place(selected_entity, preview_anchor, preview_rotation)
	preview.show_preview(cells, valid)

	if valid:
		status_label.text = "绿色：可以放置｜目标格 %s" % str(preview_anchor)
	else:
		status_label.text = "红色：区域未解锁或与其他家具冲突"

	confirm_button.disabled = not valid

func _rotate_selected() -> void:
	if selected_entity == null:
		return
	if selected_entity.furniture_definition == null or not selected_entity.furniture_definition.allow_rotation:
		status_label.text = "该家具当前不支持旋转"
		return

	preview_rotation = posmod(preview_rotation + 1, 4)
	_refresh_preview()

func _confirm_selected() -> void:
	if selected_entity == null:
		return

	var reason := ""
	if main.has_method("get_furniture_move_block_reason"):
		reason = str(main.call("get_furniture_move_block_reason", selected_entity))
	if not reason.is_empty():
		status_label.text = reason
		return

	if not placement_manager.place(selected_entity, preview_anchor, preview_rotation):
		status_label.text = "当前位置不能放置"
		_refresh_preview()
		return

	var moved := selected_entity
	if main.has_method("on_build_furniture_moved"):
		main.call("on_build_furniture_moved", moved)

	status_label.text = "已移动 %s" % moved.name
	_clear_selection()

func _cancel_selected() -> void:
	if selected_entity == null:
		return
	status_label.text = "已取消本次移动"
	_clear_selection()

func _remove_selected() -> void:
	if selected_entity == null:
		return

	var reason := "当前家具不能移除"
	if main.has_method("get_furniture_remove_block_reason"):
		reason = str(main.call("get_furniture_remove_block_reason", selected_entity))
	if not reason.is_empty():
		status_label.text = reason
		return

	var entity := selected_entity
	_clear_selection()
	if main.has_method("remove_build_furniture") and bool(main.call("remove_build_furniture", entity)):
		status_label.text = "家具已移除；正式资金系统接入后改为出售退款"
	else:
		status_label.text = "移除失败"

func _update_panel_state() -> void:
	var has_selection := selected_entity != null
	rotate_button.disabled = not has_selection
	confirm_button.disabled = not has_selection
	cancel_button.disabled = not has_selection
	remove_button.disabled = not has_selection

func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position
