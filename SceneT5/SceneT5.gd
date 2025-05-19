extends Node3D

@export var MenuLoader := "../Window_Menu/MenuLoader"

@onready var delete_list := get_node(MenuLoader+"/DeleteList")
@onready var print_text = get_node(MenuLoader+"/PrintError")
@onready var window := get_node("../Window2")
@onready var text_edit := window.get_node("MenuAnotation/TextEdit")
@onready var police := window.get_node("MenuAnotation/LineEdit")

var annotation = preload("res://material/Annotation/Annotation.tscn")

var timer := Timer.new()

var _connected_comment = null

var to_delete_list = []

func _ready():
	var Loader = get_node(MenuLoader+"/Button/FileDialog") # les bouton deroulant du menu
	delete_list.item_selected.connect(_on_pressed_delete)
	Loader.is_loaded.connect(_on_load)
	Loader.load_failed.connect(_print_error)
	Loader.load_ann.connect(_on_load_ann)
	text_edit.text_changed.connect(_on_text_changed)
	police.text_changed.connect(_on_police_changed)
	window.close_requested.connect(_on_window_close_requested)
	GlobalVar.glasses_connected.connect(_on_glasses_connected,4)

func _on_load_ann(ann:Node3D):
	to_delete_list.append(ann)

func _on_load(node:Node):
	add_child(node,true)
	print_text.text="Import Successfull of "+node.name
	to_delete_list.append(node)
	maj_button_Delete()

func _print_error():
	print_text.text="Import failed"

func _on_pressed_delete(number : int) -> void:
	var item = to_delete_list[number]
	to_delete_list.remove_at(number)
	for child in item.get_child(0).get_children():
		if(to_delete_list.has(child)):
			to_delete_list.remove_at(to_delete_list.find(child));
	item.get_parent().remove_child(item)
	item.queue_free() #mettre en queue pour supression, pas suprimmée instantanément
	maj_button_Delete()

func maj_button_Delete() -> void:
	delete_list.clear()
	for i in range(len(to_delete_list)):
		delete_list.add_item(to_delete_list[i].get_name(),i)#recupère le dernier 

func _on_glasses_connected():
	var controller = get_node("/root/Main/TiltFiveGlasses/Player/Origin/Wand_1/Pointer/Control")
	controller.new_comment.connect(_on_new_comment)
	controller.edit.connect(_on_edit)

func _on_new_comment(pos:Vector3,parent:Node3D):
	var node = annotation.instantiate()
	node.set_position(pos)
	parent.add_child(node,true)
	node.add_to_group("Annotation",true)
	var body = node.get_child(0)
	body.axis_lock_linear_z = true
	body.axis_lock_linear_y = true
	body.axis_lock_linear_x = true
	_on_edit(node)
	to_delete_list.append(node)
	maj_button_Delete()

func _on_window_close_requested():
	_connected_comment = null
	text_edit.text = ""
	police.text = "40"

func _on_edit(node:Node):
	if not(node.is_in_group("Annotation")):
		return;
	if window.visible == true:
		window.emit_signal("close_requested")
	window.show()
	print(node.get_position(),", ",node.get_global_position())
	_connected_comment = node
	text_edit.text = _connected_comment.get_text()
	police.text = str(_connected_comment.get_police())

func _on_text_changed():
	if _connected_comment != null:
		_connected_comment.set_text(text_edit.text)
		_connected_comment.print_text()

func _on_police_changed(text : String):
	if _connected_comment != null:
		if text.is_valid_int():
			_connected_comment.set_police(text.to_int())
			_connected_comment.print_police()
