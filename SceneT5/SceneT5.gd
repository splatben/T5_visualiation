extends Node3D

var annotation = preload("res://material/Annotation/Annotation.tscn")

var timer := Timer.new()

@export var MenuLoader := "../Window_Menu/MenuLoader"
@onready var delete_list := get_node(MenuLoader+"/DeleteList")
@onready var print_text = get_node(MenuLoader+"/PrintError")


@onready var window := get_node("../Window2")
@onready var text_edit := window.get_node("MenuAnotation/TextEdit")
@onready var police := window.get_node("MenuAnotation/LineEdit")
var _connected_comment = null

func _ready():
	#timer to wait glasses to be connnected
	get_parent().add_child.call_deferred(timer)
	timer.wait_time = 10 # 10 second
	timer.one_shot = true # don't loop, run once
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	
	var Loader = get_node(MenuLoader+"/Button/FileDialog") # les bouton deroulant du menu
	delete_list.item_selected.connect(_on_pressed_delete)
	Loader.is_loaded.connect(_on_load)
	Loader.load_failed.connect(_print_error)
	text_edit.text_changed.connect(_on_text_changed)
	police.text_changed.connect(_on_police_changed)
	window.close_requested.connect(_on_window_close_requested)

func _on_load(node:Node):
	add_child(node,true)
	print_text.text="Import Successfull of "+node.name
	maj_button_Delete()

func _print_error():
	print_text.text="Import failed"

func _on_pressed_delete(number : int) -> void:
	var item = get_children()[number]
	remove_child(item)
	item.queue_free() #mettre en queue pour supression, pas suprimmée instantanément
	maj_button_Delete()

func maj_button_Delete() -> void:
	delete_list.clear()
	for n in range(len(get_children())):
		delete_list.add_item(get_children()[n].get_name(),n)#recupère le dernier 
		# élément du chemin du node pour l'afficher dans la liste des "à suprimmer"

func _on_new_comment(pos:Vector3,parent:Node3D):
	var node = annotation.instantiate()
	parent.add_child(node,true)
	node.set_position(parent.to_local(pos))
	node.add_to_group("Annotation",true)
	_on_edit(node)
	maj_button_Delete()

func _on_timer_timeout() -> void:
	if get_node("/root/Main/TiltFiveGlasses/Player/Origin/Wand_1/Pointer/Control") == null:
		timer.wait_time = 10
		timer.start()
	else:
		var controller = get_node("/root/Main/TiltFiveGlasses/Player/Origin/Wand_1/Pointer/Control")
		controller.new_comment.connect(_on_new_comment)
		controller.edit.connect(_on_edit)
		get_parent().remove_child(timer)# removes from scene
		timer.queue_free()#delete

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
	_connected_comment = node
	text_edit.text = _connected_comment.get_text()
	police.text = str(_connected_comment.get_police())

func _on_text_changed():
	if _connected_comment != null:
		_connected_comment.set_text(text_edit.text)

func _on_police_changed(text : String):
	if _connected_comment != null:
		if text.is_valid_int():
			_connected_comment.set_police(text.to_int())
