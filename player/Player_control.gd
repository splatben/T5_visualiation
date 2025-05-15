extends Node

@export_category("Assignement des boutons")
@export var boutton_zoom := "button_a";
@export var boutton_dezoom := "button_y";
@export var boutton_lock := "button_x";
@export var boutton_reinitialisation := "button_1";
@export var boutton_annotation := "button_2";
@export var boutton_annotation_edit := "button_3";
@export var boutton_menu := "button_b";

@export_category("option")
@export_range(1,1.9,0.01) var zoom_step := 1.2;
@export_range(1,1.9,0.01) var length_pointeur_step = 1.02;

var _pointer = T5ToolsPointer
var _controller = T5Controller3D
var last_node : PhysicsBody3D
var _node_pointed : PhysicsBody3D
var _origin : T5Origin3D
var wand : Node3D
var _pos : Vector3
var _rotation_precedente : Vector3
var _first : bool
var distance_obj := 0.5

signal new_comment(pos:Vector3,node:Node3D)
signal edit(comment:Node3D)

func _ready() -> void:
	_origin = T5ToolsPlayer.find_instance(self).get_origin()
	_pointer = get_parent() as T5ToolsPointer
	wand = _pointer.get_parent()
	_rotation_precedente = wand.get_global_rotation()
	_controller = _pointer.get_parent() as T5Controller3D
	_pointer.pointer_pressed.connect(on_pointer_pressed)
	_pointer.pointer_moved.connect(on_pointer_move)
	_controller.input_vector2_changed.connect(_on_stick_move)
	_controller.button_pressed.connect(_on_button_pressed)
	_pointer.pointer_entered.connect(on_pointer_entered)
	_pointer.pointer_exited.connect(on_pointer_exited)


func on_pointer_move(_target : Node3D, from_pos : Vector3, to_pos : Vector3) -> void :
	if _pointer._locked_target != null && from_pos != to_pos:
		if(_first):
			var origin_ray = _pointer._raycast.global_transform.origin
			distance_obj = _pos.distance_to(origin_ray)/_pointer.length+0.05 #entre 0 et 1
			_first = false
		var at = _pointer._raycast.to_global(Vector3(0, 0, -_pointer.length*distance_obj))
		_pointer._locked_target.move_and_collide(at-_pointer._locked_target.get_position())
		to_pos = _pointer._locked_target.position
	else : 
		_first = true
		_pos = to_pos

func _on_stick_move(_name: String, value: Vector2) -> void :
	if _pointer._locked_target != null :
		if  value.y > 0.25:
			if(distance_obj + length_pointeur_step-1 >= 0.99):
				_pointer.length *= length_pointeur_step
			else :
				distance_obj += length_pointeur_step-1
		elif value.y < -0.25:
			if not(distance_obj - 0.01 <= 0.09):
				distance_obj -= length_pointeur_step-1
	else:
		if  value.y > 0.25:
			_pointer.length *= length_pointeur_step
		elif value.y < -0.25:
			_pointer.length /= length_pointeur_step

func _on_button_pressed(p_name : String) -> void:
	match p_name: 
		boutton_zoom:
			if _pointer._locked_target != null :
				_pointer._locked_target.scale_object_local(Vector3(zoom_step,zoom_step,zoom_step))
			else: 
				_origin.gameboard_scale = _origin.gameboard_scale / zoom_step # en baisant la 
				# taille des lunettes le reste devient plus grand
				_pointer.length = _pointer.length / zoom_step
				_pointer.arc_radius = _pointer.arc_radius / zoom_step
				_pointer.target_radius = _pointer.target_radius / zoom_step
		boutton_dezoom:
			if _pointer._locked_target != null :
				_pointer._locked_target.scale_object_local(Vector3(2-zoom_step,2-zoom_step,2-zoom_step))
			else : 
				_origin.gameboard_scale = _origin.gameboard_scale * zoom_step  # en augmentant 
				_pointer.length = _pointer.length * zoom_step
				_pointer.arc_radius = _pointer.arc_radius * zoom_step
				_pointer.target_radius = _pointer.target_radius * zoom_step
		boutton_reinitialisation: #tout mettre a zero
			if (last_node != null):
				last_node.set_rotation(Vector3(0,0,0))
				last_node.move_and_collide(-last_node.get_position())
		boutton_annotation:
			if _node_pointed != null:
				new_comment.emit.call_deferred(_pos,_node_pointed.get_parent())
		boutton_annotation_edit:
			if _node_pointed != null:
				edit.emit.call_deferred(_node_pointed.get_parent())
		boutton_lock:
			if _node_pointed != null && _node_pointed is PhysicsBody3D:
				_node_pointed.axis_lock_linear_z = !_node_pointed.axis_lock_linear_z
				_node_pointed.axis_lock_linear_y = !_node_pointed.axis_lock_linear_y
				_node_pointed.axis_lock_linear_x = !_node_pointed.axis_lock_linear_x
		boutton_menu:
			var menu = get_node("../../../Camera/T5-glasses/Viewport2Din3D")
			menu.visible = !menu.visible

func on_pointer_pressed(target : Node3D, _at : Vector3) -> void:
	last_node = target

func on_pointer_entered(target : Node3D, _at:Vector3)->void:
	_node_pointed = target

func on_pointer_exited(_target : Node3D, _at:Vector3)->void:
	_node_pointed = null

func _physics_process(delta: float) -> void:
	if _pointer._locked_target != null:
		var rotation = wand.get_global_rotation()-_rotation_precedente
		_pointer._locked_target.set_rotation(_pointer._locked_target.get_rotation()+rotation)
	_rotation_precedente = wand.get_global_rotation()
