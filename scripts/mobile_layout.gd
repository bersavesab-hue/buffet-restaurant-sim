class_name MobileLayout
extends Node

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const SIDE_PADDING := 16.0

@onready var canvas_layer: CanvasLayer = get_parent() as CanvasLayer
@onready var world_camera: Camera2D = canvas_layer.get_parent().get_node_or_null("WorldCamera") as Camera2D

var safe_margins := Vector4.ZERO
var layout_profile := "16:9"

func _ready() -> void:
	get_viewport().size_changed.connect(_apply_layout)
	call_deferred("_apply_layout")

func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return

	safe_margins = _get_safe_margins(viewport_size)
	layout_profile = _profile_for(viewport_size)

	if world_camera != null:
		if world_camera.has_method("refresh_for_viewport"):
			world_camera.call("refresh_for_viewport", viewport_size)
		else:
			world_camera.position = calculate_camera_position(viewport_size)

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

static func calculate_camera_position(viewport_size: Vector2) -> Vector2:
	return Vector2(
		DESIGN_SIZE.x * 0.5,
		maxf(DESIGN_SIZE.y * 0.5, viewport_size.y * 0.5)
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


func refresh_layout() -> void:
	call_deferred("_apply_layout")
