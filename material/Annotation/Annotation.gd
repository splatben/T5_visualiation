class_name Annotation
extends Node3D

static var next_id := 1

var id : int

var text1:Node

var text2:Node

@export var _text:= "[color=red]Hello [/color] [b]world [/b][i]! [/i]"

@export var _police := 40

func _ready():
	text1 = get_node("StaticBody3D/Viewport2Din3D").get_scene_instance()
	text2 = get_node("StaticBody3D/Viewport2Din3D2").get_scene_instance()
	set_text(_text)
	set_police(_police)
	#get_node("StaticBody3D").set_global_position(get_node("StaticBody3D").get_position())

func set_text(text:String):
	text1.set_text(text)
	text2.set_text(text)
	_text = text

func set_police(police:int):
	if police > 0:
		text1.push_font_size(police)
		text2.push_font_size(police)
		_police = police

func get_text() -> String:
	return _text

func get_police() -> int:
	return _police
