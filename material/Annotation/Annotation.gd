class_name Bulle_Annotation
extends Node3D

static var next_id := 1

var id : int

@onready var text1 = get_node("StaticBody3D/Viewport2Din3D").get_scene_instance()

@onready var text2 = get_node("StaticBody3D/Viewport2Din3D2").get_scene_instance()

func text_update(text:String):
	text1.set_text(text)
	text2.set_text(text)

func police_update(police:String):
	var number = police.to_int()
	if number > 0:
		text1.push_font_size(number)
		text2.push_font_size(number)

func get_text() -> String:
	return text1.text

func get_police() -> int:
	return text1.get_theme_font_size("font_size")
