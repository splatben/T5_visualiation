extends Node3D

@export var MenuLoader := "../MenuLoader"

var controller:Node
var annotation = preload("res://material/Annotation/Annotation.tscn")

func _ready():
	var Loader = get_node(MenuLoader+"/Button/FileDialog") # les bouton deroulant du menu
	Loader.is_loaded.connect(_on_load)
	GlobalScope.glasses_connected.connect(_on_glasses_connected,4)
	GlobalScope.sceneT5 = self

func _on_load(node:Node):
	add_child(node,true)

func _on_glasses_connected():
	controller = get_node("/root/Main/TiltFiveGlasses/Player/Origin/Wand_1/Pointer/Control")
	controller.new_comment.connect(_on_new_comment)

func _on_new_comment(pos:Vector3,parent:Node3D):
	var node = annotation.instantiate()
	parent.add_child(node,true)
	node.add_to_group("Annotation",true)
	var body = node.get_child(0)
	body.set_global_position(pos)
	body.axis_lock_linear_z = true
	body.axis_lock_linear_y = true
	body.axis_lock_linear_x = true
	GlobalScope.new_comment.emit(node)
	controller.edit.emit(node)
