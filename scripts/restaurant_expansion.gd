class_name RestaurantExpansion
extends Node

signal expansion_changed(stage: int, stage_name: String, build_rect: Rect2i)

@export var grid_path: NodePath

@onready var grid: RestaurantGrid = get_node(grid_path) as RestaurantGrid

const STAGE_NAMES := [
	"街角小店",
	"扩建餐厅",
	"中型自助",
	"大型综合自助",
	"旗舰自助餐厅"
]

const STAGE_DESCRIPTIONS := [
	"开局核心经营区",
	"第一次向周边扩展桌位与餐台",
	"允许形成第二就餐区与更完整厨房",
	"支持多品类餐台和更高客流",
	"最终完整44×36建造区域"
]

var current_stage := 0

func _ready() -> void:
	current_stage = grid.current_stage

func get_stage_count() -> int:
	return grid.get_stage_count()

func get_stage_name(stage: int = -1) -> String:
	var target := current_stage if stage < 0 else stage
	return STAGE_NAMES[clampi(target, 0, STAGE_NAMES.size() - 1)]

func get_stage_description(stage: int = -1) -> String:
	var target := current_stage if stage < 0 else stage
	return STAGE_DESCRIPTIONS[clampi(target, 0, STAGE_DESCRIPTIONS.size() - 1)]

func get_current_build_rect() -> Rect2i:
	return grid.get_stage_rect(current_stage)

func can_expand() -> bool:
	return current_stage < get_stage_count() - 1

func set_stage(stage: int) -> void:
	var next_stage := clampi(stage, 0, get_stage_count() - 1)
	current_stage = next_stage
	grid.set_stage(next_stage)
	emit_signal(
		"expansion_changed",
		current_stage,
		get_stage_name(),
		get_current_build_rect()
	)

func advance_stage() -> bool:
	if not can_expand():
		return false
	set_stage(current_stage + 1)
	return true
