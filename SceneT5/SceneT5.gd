extends Node3D

@export var MenuLoader := "../MenuLoader"

var _controller:Node
var _annotation = preload("res://material/Annotation/Annotation.tscn")

func _ready():
	var Loader = get_node(MenuLoader+"/Button/FileDialog") # les bouton deroulant du menu
	Loader.is_loaded.connect(_on_load)
	GlobalScope.glasses_connected.connect(_on_glasses_connected)
	GlobalScope.sceneT5 = self

func _on_load(node:Node):
	add_child(node,true)

func _on_glasses_connected():
	_controller = get_node("/root/Main/TiltFiveGlasses/Player/Origin/Wand_1/Pointer/Control")
	_controller.new_comment.connect(_on_new_comment)

func _on_new_comment(pos:Vector3,parent:Node3D):
	if parent.is_in_group("Annotation"):
		return;
	var node = _annotation.instantiate()
	parent.add_child(node,true)
	node.add_to_group("Annotation",true)
	var body = node.get_child(0)
	body.set_global_position(pos)
	var _scale = _controller._origin.gameboard_scale/3
	body.set_scale(Vector3(_scale,_scale,_scale))
	body.scale_object_local(Vector3(pow(parent.scale.x,-1),pow(parent.scale.y,-1),pow(parent.scale.z,-1)))
	body.look_at(_controller.get_parent().get_parent().global_rotation)
	GlobalScope.new_comment.emit(node)#pour etre ajouter a la liste de supression 
	_controller.edit.emit(node)
