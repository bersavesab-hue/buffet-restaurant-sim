class_name MobileLayout
extends Node

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const SIDE_PADDING := 16.0

@onready var canvas_layer: CanvasLayer = get_parent() as CanvasLayer
@onready var top_panel: Control = canvas_layer.get_node("UI") as Control
@onready var supply_panel: Control = canvas_layer.get_node("SupplyControls") as Control
@onready var priority_panel: Control = canvas_layer.get_node("PriorityControls") as Control
@onready var controls_panel: Control = canvas_layer.get_node("Controls") as Control
@onready var device_label: Label = canvas_layer.get_node_or_null("UI/VBox/DeviceLabel") as Label

var safe_margins := Vector4.ZERO
var layout_profile := "16:9"

func _ready() -> void:
	_configure_touch_targets()
	get_viewport().size_changed.connect(_apply_layout)
	call_deferred("_apply_layout")

func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return

	safe_margins = _get_safe_margins(viewport_size)
	layout_profile = _profile_for(viewport_size)

	var metrics := calculate_layout_metrics(viewport_size, safe_margins)
	var left := float(metrics["left"])
	var right := float(metrics["right"])
	var top := float(metrics["top"])
	var bottom := float(metrics["bottom"])

	top_panel.offset_left = left
	top_panel.offset_right = -right
	top_panel.offset_top = top
	var top_height := clampf(top_panel.get_combined_minimum_size().y + 10.0, 220.0, 258.0)
	top_panel.offset_bottom = top + top_height

	var row_height := 56.0
	var row_gap := 4.0

	controls_panel.offset_left = left
	controls_panel.offset_right = -right
	controls_panel.offset_top = -(row_height + bottom)
	controls_panel.offset_bottom = -bottom

	priority_panel.offset_left = left
	priority_panel.offset_right = -right
	priority_panel.offset_top = -(row_height * 2.0 + row_gap + bottom)
	priority_panel.offset_bottom = -(row_height + row_gap + bottom)

	supply_panel.offset_left = left
	supply_panel.offset_right = -right
	supply_panel.offset_top = -(row_height * 3.0 + row_gap * 2.0 + bottom)
	supply_panel.offset_bottom = -(row_height * 2.0 + row_gap * 2.0 + bottom)

	if device_label != null:
		device_label.text = "设备：%dx%d｜%s｜安全区 L%d T%d R%d B%d" % [
			int(round(viewport_size.x)),
			int(round(viewport_size.y)),
			layout_profile,
			int(round(safe_margins.x)),
			int(round(safe_margins.y)),
			int(round(safe_margins.z)),
			int(round(safe_margins.w))
		]

	print("[MOBILE_LAYOUT] viewport=%dx%d profile=%s safe=%s" % [
		int(round(viewport_size.x)),
		int(round(viewport_size.y)),
		layout_profile,
		str(safe_margins)
	])

func _get_safe_margins(viewport_size: Vector2) -> Vector4:
	var platform := OS.get_name()
	if platform not in ["Android", "iOS"]:
		return Vector4.ZERO

	var physical_window := DisplayServer.window_get_size()
	var safe_area := DisplayServer.get_display_safe_area()
	if physical_window.x <= 0 or physical_window.y <= 0:
		return Vector4.ZERO
	if safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return Vector4.ZERO

	var window_position := DisplayServer.window_get_position()
	var local_safe_position := Vector2i(
		safe_area.position.x - window_position.x,
		safe_area.position.y - window_position.y
	)

	var scale_x := viewport_size.x / float(physical_window.x)
	var scale_y := viewport_size.y / float(physical_window.y)

	var left := maxf(0.0, float(local_safe_position.x) * scale_x)
	var top := maxf(0.0, float(local_safe_position.y) * scale_y)
	var right_physical := physical_window.x - (local_safe_position.x + safe_area.size.x)
	var bottom_physical := physical_window.y - (local_safe_position.y + safe_area.size.y)
	var right := maxf(0.0, float(right_physical) * scale_x)
	var bottom := maxf(0.0, float(bottom_physical) * scale_y)

	return Vector4(
		minf(left, 96.0),
		minf(top, 120.0),
		minf(right, 96.0),
		minf(bottom, 120.0)
	)

static func calculate_layout_metrics(viewport_size: Vector2, margins: Vector4) -> Dictionary:
	var extra_width := maxf(0.0, (viewport_size.x - DESIGN_SIZE.x) * 0.5)
	var profile := profile_for_size(viewport_size)
	return {
		"left": extra_width + SIDE_PADDING + margins.x,
		"right": extra_width + SIDE_PADDING + margins.z,
		"top": 12.0 + margins.y,
		"bottom": 14.0 + margins.w,
		"profile": profile
	}

static func profile_for_size(viewport_size: Vector2) -> String:
	var ratio := viewport_size.y / maxf(1.0, viewport_size.x)
	if ratio >= 2.12:
		return "超长屏"
	if ratio >= 1.92:
		return "长屏"
	if ratio >= 1.72:
		return "16:9"
	return "宽屏"

func _profile_for(viewport_size: Vector2) -> String:
	return profile_for_size(viewport_size)


func _configure_touch_targets() -> void:
	for panel in [supply_panel, priority_panel, controls_panel]:
		for node in panel.find_children("*", "Button", true, false):
			var button := node as Button
			if button == null:
				continue
			button.custom_minimum_size.y = 52.0
			button.add_theme_font_size_override("font_size", 14)
			button.focus_mode = Control.FOCUS_NONE
