extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main scene must load")
	if packed == null:
		_finish()
		return

	var main := packed.instantiate()
	root.add_child(main)

	# Let the scene enter the tree so _ready/@onready and deferred layout
	# registration complete before build mode is exercised.
	await process_frame
	await process_frame

	var controller := main.get_node_or_null("BuildModeController") as RestaurantBuildMode
	var grid := main.get_node_or_null("RestaurantWorld/BuildGrid") as RestaurantGrid
	var camera := main.get_node_or_null("WorldCamera") as RestaurantCamera
	var panel := main.get_node_or_null("CanvasLayer/BuildPanel") as Control

	_expect(controller != null, "BuildModeController missing")
	_expect(grid != null, "RestaurantGrid missing")
	_expect(camera != null, "RestaurantCamera missing")
	_expect(panel != null, "BuildPanel missing")

	if controller != null and grid != null and camera != null and panel != null:
		controller.enter_build_mode()
		_expect(paused, "entering build mode must pause SceneTree")
		_expect(panel.visible, "build panel must become visible")
		_expect(grid.build_overlay_visible, "build grid overlay must be visible")
		_expect(camera.navigation_enabled, "camera navigation must enable in build mode")

		controller.exit_build_mode()
		_expect(not paused, "leaving build mode must restore unpaused state")
		_expect(not panel.visible, "build panel must hide after exit")
		_expect(not grid.build_overlay_visible, "grid overlay must hide after exit")
		_expect(not camera.navigation_enabled, "camera navigation must disable after exit")

	main.queue_free()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("[BUILD_MODE_TEST PASS] pause, overlay, camera and build panel lifecycle OK")
		quit(0)
	else:
		for failure in failures:
			push_error("[BUILD_MODE_TEST FAIL] " + failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
