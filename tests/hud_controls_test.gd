extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var hud := main.get_node("CanvasLayer/GameHUD") as GameHUD
	_expect(main.get_node_or_null("CanvasLayer/Controls") == null, "legacy controls must be deleted")
	_expect(main.get_node_or_null("CanvasLayer/UI") == null, "legacy debug panel must be deleted")
	_expect(hud != null, "player HUD must exist")
	if hud != null:
		var station := main._get_station_by_tag("staple") as FoodStation
		var original_refill := station.is_refill_enabled()
		hud.supply_nav.pressed.emit()
		hud.supply_staple.pressed.emit()
		_expect(station.is_refill_enabled() != original_refill, "supply action must reach station")
		hud.kitchen_nav.pressed.emit()
		hud.priority_meat.pressed.emit()
		_expect(main.kitchen.priority_tag == "meat", "kitchen action must reach scheduler")
		hud.ac_nav.pressed.emit()
		hud.ac_toggle.pressed.emit()
		_expect(not main.ac_enabled, "AC action must reach environment")
		hud.speed_nav.pressed.emit()
		_expect(main.selected_speed == 2.0, "speed action must reach game clock")
		hud.business_nav.pressed.emit()
		hud.build_button.pressed.emit()
		_expect(main.get_node("BuildModeController").build_mode, "build action must enter construction")
		main.get_node("BuildModeController").exit_build_mode()
		_expect(not paused, "construction exit must resume business")
		hud.settings_button.pressed.emit()
		_expect(hud.settings_row.visible, "settings must show diagnostics")
		_expect(hud.has_node("Drawer/VBox/SettingsRow/DiagnosticsStatus"), "diagnostics status must live in HUD")
	main.queue_free()
	Engine.time_scale = 1.0
	if failures.is_empty():
		print("[HUD_CONTROLS_TEST PASS] player controls drive one gameplay path")
		quit(0)
	else:
		for failure in failures:
			push_error("[HUD_CONTROLS_TEST FAIL] " + failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
