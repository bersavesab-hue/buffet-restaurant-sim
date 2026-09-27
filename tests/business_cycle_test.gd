extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_path := ProjectSettings.globalize_path("user://buffet_progress_v1.json")
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.day_duration_seconds = 4.0
	main.spawn_interval_seconds = 0.8
	main.max_customers_today = 2
	root.add_child(main)
	await process_frame
	main._set_speed(3.0)
	var timeout := 45.0
	while not main.day_settled and timeout > 0.0:
		await create_timer(0.5, true, false, true).timeout
		timeout -= 0.5
	if not main.day_settled:
		failures.append("customer visit or closing did not finish within 45 seconds")
	if main.spawned_today != 2:
		failures.append("expected two spawned customers")
	if main.finished_today != 2:
		failures.append("expected both customers to exit")
	if main.ticket_revenue <= 0.0:
		failures.append("expected real ticket revenue")
	main.queue_free()
	Engine.time_scale = 1.0
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	if failures.is_empty():
		print("[BUSINESS_CYCLE_TEST PASS] customer payment, visit, exit and closing")
		quit(0)
	else:
		for failure in failures:
			push_error("[BUSINESS_CYCLE_TEST FAIL] " + failure)
		quit(1)
