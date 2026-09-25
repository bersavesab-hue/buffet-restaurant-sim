class_name CustomerAppearanceLibrary
extends RefCounted

const APPEARANCE_COUNT := 5

const BASE_F1 := preload("res://assets/vertical_slice/actors/customer_front_1.svg")
const BASE_F2 := preload("res://assets/vertical_slice/actors/customer_front_2.svg")
const BASE_B1 := preload("res://assets/vertical_slice/actors/customer_back_1.svg")
const BASE_B2 := preload("res://assets/vertical_slice/actors/customer_back_2.svg")

const GREEN_F1 := preload("res://assets/vertical_slice/actors/customer_green_front_1.svg")
const GREEN_F2 := preload("res://assets/vertical_slice/actors/customer_green_front_2.svg")
const GREEN_B1 := preload("res://assets/vertical_slice/actors/customer_green_back_1.svg")
const GREEN_B2 := preload("res://assets/vertical_slice/actors/customer_green_back_2.svg")

const RED_F1 := preload("res://assets/vertical_slice/actors/customer_red_front_1.svg")
const RED_F2 := preload("res://assets/vertical_slice/actors/customer_red_front_2.svg")
const RED_B1 := preload("res://assets/vertical_slice/actors/customer_red_back_1.svg")
const RED_B2 := preload("res://assets/vertical_slice/actors/customer_red_back_2.svg")

const YELLOW_F1 := preload("res://assets/vertical_slice/actors/customer_yellow_front_1.svg")
const YELLOW_F2 := preload("res://assets/vertical_slice/actors/customer_yellow_front_2.svg")
const YELLOW_B1 := preload("res://assets/vertical_slice/actors/customer_yellow_back_1.svg")
const YELLOW_B2 := preload("res://assets/vertical_slice/actors/customer_yellow_back_2.svg")

const PURPLE_F1 := preload("res://assets/vertical_slice/actors/customer_purple_front_1.svg")
const PURPLE_F2 := preload("res://assets/vertical_slice/actors/customer_purple_front_2.svg")
const PURPLE_B1 := preload("res://assets/vertical_slice/actors/customer_purple_back_1.svg")
const PURPLE_B2 := preload("res://assets/vertical_slice/actors/customer_purple_back_2.svg")

static func get_count() -> int:
	return APPEARANCE_COUNT

static func apply_to(visual: ActorVisual, index: int) -> void:
	var normalized := posmod(index, APPEARANCE_COUNT)
	match normalized:
		0:
			visual.set_directional_textures(BASE_F1, BASE_F2, BASE_B1, BASE_B2)
		1:
			visual.set_directional_textures(GREEN_F1, GREEN_F2, GREEN_B1, GREEN_B2)
		2:
			visual.set_directional_textures(RED_F1, RED_F2, RED_B1, RED_B2)
		3:
			visual.set_directional_textures(YELLOW_F1, YELLOW_F2, YELLOW_B1, YELLOW_B2)
		_:
			visual.set_directional_textures(PURPLE_F1, PURPLE_F2, PURPLE_B1, PURPLE_B2)
