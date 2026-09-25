extends SceneTree

const MobileLayoutClass = preload("res://scripts/mobile_layout.gd")

var failures: Array[String] = []

func _init() -> void:
	_check_project_settings()
	_check_profile("16:9", Vector2(720, 1280), "16:9")
	_check_profile("18:9", Vector2(720, 1440), "长屏")
	_check_profile("19.5:9", Vector2(720, 1560), "超长屏")
	_check_profile("20:9", Vector2(720, 1600), "超长屏")
	_check_profile("wide", Vector2(900, 1280), "宽屏")
	_check_safe_area_offsets()
	_check_wide_screen_centering()
	_check_camera_alignment()

	if failures.is_empty():
		print("[MOBILE_TEST PASS] 7 layout checks passed")
		quit(0)
	else:
		for failure in failures:
			push_error("[MOBILE_TEST FAIL] " + failure)
		quit(1)

func _check_project_settings() -> void:
	var width := int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	var height := int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	var mode := str(ProjectSettings.get_setting("display/window/stretch/mode", ""))
	var aspect := str(ProjectSettings.get_setting("display/window/stretch/aspect", ""))

	_expect(width == 720, "base viewport width should be 720")
	_expect(height == 1280, "base viewport height should be 1280")
	_expect(mode == "canvas_items", "stretch mode should be canvas_items")
	_expect(aspect == "expand", "stretch aspect should be expand")

func _check_profile(label: String, size: Vector2, expected: String) -> void:
	var actual := MobileLayoutClass.profile_for_size(size)
	_expect(actual == expected, "%s expected %s but got %s" % [label, expected, actual])

func _check_safe_area_offsets() -> void:
	var metrics := MobileLayoutClass.calculate_layout_metrics(
		Vector2(720, 1560),
		Vector4(0, 42, 0, 36)
	)
	_expect(is_equal_approx(float(metrics["left"]), 16.0), "safe-area left inset mismatch")
	_expect(is_equal_approx(float(metrics["right"]), 16.0), "safe-area right inset mismatch")
	_expect(is_equal_approx(float(metrics["top"]), 54.0), "safe-area top inset mismatch")
	_expect(is_equal_approx(float(metrics["bottom"]), 50.0), "safe-area bottom inset mismatch")

func _check_wide_screen_centering() -> void:
	var metrics := MobileLayoutClass.calculate_layout_metrics(
		Vector2(900, 1280),
		Vector4.ZERO
	)
	_expect(is_equal_approx(float(metrics["left"]), 106.0), "wide-screen left centering mismatch")
	_expect(is_equal_approx(float(metrics["right"]), 106.0), "wide-screen right centering mismatch")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _check_camera_alignment() -> void:
	var base := MobileLayoutClass.calculate_camera_position(Vector2(720, 1280))
	var tall := MobileLayoutClass.calculate_camera_position(Vector2(720, 1600))
	_expect(base == Vector2(360, 640), "base camera position mismatch")
	_expect(tall == Vector2(360, 800), "tall-screen camera should top-align 1280 core scene")
