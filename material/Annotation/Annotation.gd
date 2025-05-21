class_name Annotation
extends Node3D

@export_category("Valeur par défault")
@export var _text:= "[color=red]Hello [/color] [b]world [/b][i]! [/i]"
@export var _police := 40

var text1:Node

var text2:Node

func _ready():
	text1 = get_node("StaticBody3D/Viewport2Din3D").get_scene_instance()
	text2 = get_node("StaticBody3D/Viewport2Din3D2").get_scene_instance()
	print_text()
	print_police()

func set_text(text:String):
	_text = text

func print_text():
	text1.set_text(_text)
	text2.set_text(_text)

func set_police(police:int):
	if police > 0:
		_police = police

func print_police():
	text1.theme.default_font_size = _police
	text2.theme.default_font_size = _police

func get_text() -> String:
	return _text

func get_police() -> int:
	return _police
