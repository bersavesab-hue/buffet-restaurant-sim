class_name GameHUD
extends Control

@onready var main := get_parent().get_parent()
@onready var mobile_layout := get_parent().get_node_or_null("MobileLayout")

@onready var top_hud: Control = $TopHUD
@onready var bottom_nav: Control = $BottomNav
@onready var drawer: Control = $Drawer

@onready var day_time_label: Label = $TopHUD/VBox/Primary/DayCard/DayTime
@onready var business_label: Label = $TopHUD/VBox/Primary/BusinessCard/Business
@onready var revenue_label: Label = $TopHUD/VBox/Primary/RevenueCard/Revenue
@onready var rating_label: Label = $TopHUD/VBox/Primary/RatingCard/Rating

@onready var occupancy_label: Label = $TopHUD/VBox/Secondary/Occupancy
@onready var queue_label: Label = $TopHUD/VBox/Secondary/Queue
@onready var temperature_label: Label = $TopHUD/VBox/Secondary/Temperature
@onready var profit_label: Label = $TopHUD/VBox/Secondary/Profit

@onready var supply_nav: Button = $BottomNav/Bar/Supply
@onready var kitchen_nav: Button = $BottomNav/Bar/Kitchen
@onready var ac_nav: Button = $BottomNav/Bar/AC
@onready var business_nav: Button = $BottomNav/Bar/Business
@onready var speed_nav: Button = $BottomNav/Bar/Speed
@onready var settings_button: Button = $TopHUD/VBox/Primary/Settings

@onready var drawer_title: Label = $Drawer/VBox/Title
@onready var supply_row: Control = $Drawer/VBox/SupplyRow
@onready var kitchen_row: Control = $Drawer/VBox/KitchenRow
@onready var ac_row: Control = $Drawer/VBox/ACRow
@onready var business_box: Control = $Drawer/VBox/BusinessBox
@onready var settings_row: Control = $Drawer/VBox/SettingsRow

@onready var supply_staple: Button = $Drawer/VBox/SupplyRow/Staple
@onready var supply_meat: Button = $Drawer/VBox/SupplyRow/Meat
@onready var supply_seafood: Button = $Drawer/VBox/SupplyRow/Seafood

@onready var priority_auto: Button = $Drawer/VBox/KitchenRow/Auto
@onready var priority_staple: Button = $Drawer/VBox/KitchenRow/Staple
@onready var priority_meat: Button = $Drawer/VBox/KitchenRow/Meat
@onready var priority_seafood: Button = $Drawer/VBox/KitchenRow/Seafood

@onready var ac_toggle: Button = $Drawer/VBox/ACRow/Toggle
@onready var temp_down: Button = $Drawer/VBox/ACRow/Down
@onready var temp_value: Label = $Drawer/VBox/ACRow/Value
@onready var temp_up: Button = $Drawer/VBox/ACRow/Up

@onready var business_summary: Label = $Drawer/VBox/BusinessBox/Summary
@onready var review_summary: Label = $Drawer/VBox/BusinessBox/Review
@onready var build_button: Button = $Drawer/VBox/BusinessBox/Build
@onready var next_day_button: Button = $Drawer/VBox/BusinessBox/NextDay

@onready var close_button: Button = $Drawer/VBox/Close

var active_drawer := ""
var update_timer := 0.0
var build_mode_active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawer.visible = false

	supply_nav.pressed.connect(func(): _toggle_drawer("supply"))
	kitchen_nav.pressed.connect(func(): _toggle_drawer("kitchen"))
	ac_nav.pressed.connect(func(): _toggle_drawer("ac"))
	business_nav.pressed.connect(func(): _toggle_drawer("business"))
	settings_button.pressed.connect(func(): _toggle_drawer("settings"))
	speed_nav.pressed.connect(_cycle_speed)
	close_button.pressed.connect(_close_drawer)

	supply_staple.pressed.connect(func(): main.call("_toggle_station_refill", "staple"))
	supply_meat.pressed.connect(func(): main.call("_toggle_station_refill", "meat"))
	supply_seafood.pressed.connect(func(): main.call("_toggle_station_refill", "seafood"))

	priority_auto.pressed.connect(func(): main.call("_set_kitchen_priority", "auto"))
	priority_staple.pressed.connect(func(): main.call("_set_kitchen_priority", "staple"))
	priority_meat.pressed.connect(func(): main.call("_set_kitchen_priority", "meat"))
	priority_seafood.pressed.connect(func(): main.call("_set_kitchen_priority", "seafood"))

	ac_toggle.pressed.connect(func(): main.call("_on_ac_switch_pressed"))
	temp_down.pressed.connect(func(): main.call("_on_temp_down_pressed"))
	temp_up.pressed.connect(func(): main.call("_on_temp_up_pressed"))

	build_button.pressed.connect(_enter_build_mode)
	next_day_button.pressed.connect(func(): main.call("start_next_day"))

	get_viewport().size_changed.connect(_apply_layout)
	call_deferred("_finish_setup")

func _finish_setup() -> void:
	_apply_layout()
	_refresh_all()

func _process(delta: float) -> void:
	update_timer -= delta
	if update_timer > 0.0:
		return
	update_timer = 0.20
	_refresh_all()

func set_build_mode_active(value: bool) -> void:
	build_mode_active = value
	bottom_nav.visible = not value
	if value:
		_close_drawer()
	else:
		bottom_nav.visible = true
	_refresh_all()

func _apply_layout() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0:
		return

	var margins := Vector4.ZERO
	if mobile_layout != null:
		margins = mobile_layout.safe_margins

	var extra_width := maxf(0.0, (viewport_size.x - 720.0) * 0.5)
	var left := extra_width + 12.0 + margins.x
	var right := extra_width + 12.0 + margins.z
	var top := 10.0 + margins.y
	var bottom := 10.0 + margins.w

	top_hud.offset_left = left
	top_hud.offset_right = -right
	top_hud.offset_top = top
	top_hud.offset_bottom = top + 104.0

	bottom_nav.offset_left = left
	bottom_nav.offset_right = -right
	bottom_nav.offset_top = -86.0 - bottom
	bottom_nav.offset_bottom = -bottom

	drawer.offset_left = left
	drawer.offset_right = -right
	var drawer_height := 320.0 if active_drawer == "business" else (220.0 if active_drawer == "settings" else 196.0)
	drawer.offset_top = -drawer_height - bottom
	drawer.offset_bottom = -92.0 - bottom

func _refresh_all() -> void:
	_refresh_primary_stats()
	_refresh_drawer_controls()

func _refresh_primary_stats() -> void:
	var remaining := float(main.get("day_remaining"))
	var duration := maxf(1.0, float(main.get("day_duration_seconds")))
	var progress := clampf(1.0 - remaining / duration, 0.0, 1.0)
	var total_minutes := 10 * 60 + int(round(progress * 10.0 * 60.0))
	var hour := total_minutes / 60
	var minute := total_minutes % 60

	day_time_label.text = "第%d天  %02d:%02d" % [int(main.get("day_index")), hour, minute]

	var settled := bool(main.get("day_settled"))
	business_label.text = "已打烊" if settled else ("收店中" if remaining <= 0.0 else "营业中")

	var revenue := float(main.get("ticket_revenue"))
	revenue_label.text = "营业额  ¥%d" % int(round(revenue))

	var finished := int(main.get("finished_today"))
	var total_rating_value := float(main.get("total_rating"))
	var rating := total_rating_value / float(finished) if finished > 0 else 0.0
	rating_label.text = "★ %.1f" % rating if finished > 0 else "★ --"

	var active_customers: Array = main.get("active_customers")
	var tables: Array = main.get("tables")
	var capacity := 0
	for table in tables:
		if is_instance_valid(table):
			capacity += (table as BuffetTable).get_capacity()
	occupancy_label.text = "店内 %d/%d" % [active_customers.size(), capacity]

	var cashier_queue: Array = main.get("cashier_queue")
	var table_queue: Array = main.get("table_wait_queue")
	var restroom_queue: Array = main.get("restroom_queue")
	var food_queue := int(main.call("_get_food_queue_total"))
	var queue_total := cashier_queue.size() + table_queue.size() + restroom_queue.size() + food_queue
	queue_label.text = "排队 %d" % queue_total

	temperature_label.text = "室温 %d°C" % int(round(float(main.get("indoor_temperature"))))

	var food_cost := float(main.get("food_cost"))
	var utility_cost := float(main.get("utility_cost"))
	var profit := revenue - food_cost - utility_cost
	profit_label.text = "今日利润 " + _format_signed_money(profit)

	speed_nav.text = "%d×" % int(round(float(main.get("selected_speed"))))

func _refresh_drawer_controls() -> void:
	var staple := main.call("_get_station_by_tag", "staple") as FoodStation
	var meat := main.call("_get_station_by_tag", "meat") as FoodStation
	var seafood := main.call("_get_station_by_tag", "seafood") as FoodStation

	if staple != null:
		supply_staple.text = "主食  %s" % ("补菜中" if staple.is_refill_enabled() else "已暂停")
	if meat != null:
		supply_meat.text = "肉类  %s" % ("补菜中" if meat.is_refill_enabled() else "已暂停")
	if seafood != null:
		supply_seafood.text = "海鲜  %s" % ("补菜中" if seafood.is_refill_enabled() else "已暂停")

	var kitchen = main.get("kitchen")
	var priority := "auto"
	if kitchen != null:
		priority = str(kitchen.priority_tag)
	priority_auto.text = "自动" + (" ·" if priority == "auto" else "")
	priority_staple.text = "主食" + (" ·" if priority == "staple" else "")
	priority_meat.text = "肉类" + (" ·" if priority == "meat" else "")
	priority_seafood.text = "海鲜" + (" ·" if priority == "seafood" else "")

	var ac_enabled := bool(main.get("ac_enabled"))
	var setpoint := float(main.get("ac_setpoint"))
	ac_toggle.text = "空调 " + ("开启" if ac_enabled else "关闭")
	temp_value.text = "%d°C" % int(round(setpoint))

	var revenue := float(main.get("ticket_revenue"))
	var food_cost := float(main.get("food_cost"))
	var utility_cost := float(main.get("utility_cost"))
	var profit := revenue - food_cost - utility_cost
	business_summary.text = "营业额 ¥%.0f   食材 ¥%.0f   电费 ¥%.1f\n利润 %s   资金 ¥%.0f" % [
		revenue, food_cost, utility_cost, _format_signed_money(profit), float(main.get("cash_balance"))
	]
	review_summary.text = "顾客反馈：" + str(main.get("last_review"))
	next_day_button.visible = bool(main.get("day_settled"))

func _toggle_drawer(name: String) -> void:
	if build_mode_active:
		return
	if active_drawer == name and drawer.visible:
		_close_drawer()
		return

	active_drawer = name
	drawer.visible = true
	supply_row.visible = name == "supply"
	kitchen_row.visible = name == "kitchen"
	ac_row.visible = name == "ac"
	business_box.visible = name == "business"
	settings_row.visible = name == "settings"

	match name:
		"supply":
			drawer_title.text = "补菜管理"
		"kitchen":
			drawer_title.text = "厨房优先级"
		"ac":
			drawer_title.text = "空调与室温"
		"business":
			drawer_title.text = "经营概况"
		"settings":
			drawer_title.text = "设置"
	_refresh_drawer_controls()
	_apply_layout()

func _close_drawer() -> void:
	active_drawer = ""
	drawer.visible = false
	_apply_layout()

func _cycle_speed() -> void:
	if build_mode_active:
		return
	var speed := float(main.get("selected_speed"))
	if speed < 1.5:
		main.call("_set_speed", 2.0)
	elif speed < 2.5:
		main.call("_set_speed", 3.0)
	else:
		main.call("_set_speed", 1.0)
	_refresh_all()

func _enter_build_mode() -> void:
	_close_drawer()
	var controller := main.get_node_or_null("BuildModeController")
	if controller != null:
		controller.call("enter_build_mode")

func _format_signed_money(value: float) -> String:
	var rounded := int(round(value))
	if rounded > 0:
		return "+¥%d" % rounded
	if rounded < 0:
		return "-¥%d" % abs(rounded)
	return "¥0"
