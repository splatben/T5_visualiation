extends Node

@export var boutton_zoom := "button_a";
@export var boutton_dezoom := "button_y";
@export var boutton_lock := "button_x";
@export var boutton_reinitialisation := "button_1";
@export var boutton_bulle := "button_2";
@export var boutton_edit := "button_3";

var _pointer = T5ToolsPointer

var _controller = T5Controller3D

var last_node : PhysicsBody3D

var _node_pointed : PhysicsBody3D

var _origin = T5Origin3D

var _pos : Vector3

signal new_comment(pos:Vector3)
signal edit(comment:Node3D)

func _ready() -> void:
	_origin = T5ToolsPlayer.find_instance(self).get_origin()
	_pointer = get_parent() as T5ToolsPointer
	_controller = _pointer.get_parent() as T5Controller3D
	_pointer.pointer_pressed.connect(on_pointer_pressed)
	_pointer.pointer_moved.connect(on_pointer_move)
	_controller.input_vector2_changed.connect(_on_stick_move)
	_controller.button_pressed.connect(_on_button_pressed)
	_pointer.pointer_entered.connect(on_pointer_entered)
	_pointer.pointer_exited.connect(on_pointer_exited)


func on_pointer_move(_target : Node3D, from_pos : Vector3, to_pos : Vector3) -> void :
	if _pointer._locked_target != null && from_pos != to_pos:
		_pointer._locked_target.move_and_collide(to_pos-from_pos)
	_pos = to_pos

func _on_stick_move(_name: String, value: Vector2) -> void :
	if _pointer._locked_target != null and ((value.x > 0.1 or value.y > 0.1) or (value.x < -0.1 or value.y < -0.1)):
		if abs(value.x) > abs(value.y) : # pour faciliter le controle on rotate soit en x soit en y
			_pointer._locked_target.rotate(Vector3(0,value.x,0).normalized(),0.075)
		else : 
			_pointer._locked_target.rotate(Vector3(0,0,-value.y).normalized(),0.075)

func _on_button_pressed(p_name : String) -> void:
	match p_name: 
		boutton_zoom:
			if _pointer._locked_target != null :
				_pointer._locked_target.scale_object_local(Vector3(1.15,1.15,1.15))
			else: 
				_origin.gameboard_scale = _origin.gameboard_scale / 1.15 # en baisant la 
				# taille des lunettes le reste devient plus grand
				_pointer.length = _pointer.length / 1.15
				_pointer.arc_radius = _pointer.arc_radius / 1.15
				_pointer.target_radius = _pointer.target_radius / 1.15
		boutton_dezoom:
			if _pointer._locked_target != null :
				_pointer._locked_target.scale_object_local(Vector3(0.85,0.85,0.85))
			else : 
				_origin.gameboard_scale = _origin.gameboard_scale * 1.15  # en augmentant 
				_pointer.length = _pointer.length * 1.15
				_pointer.arc_radius = _pointer.arc_radius * 1.15
				_pointer.target_radius = _pointer.target_radius * 1.15
		boutton_reinitialisation: #tout mettre a zero
			if (last_node != null):
				last_node.set_rotation(Vector3(0,0,0))
				last_node.move_and_collide(-last_node.get_position())
		boutton_bulle:
			new_comment.emit.call_deferred(_pos)
		boutton_edit:
			if _node_pointed != null:
				edit.emit.call_deferred(_node_pointed.get_parent())
		boutton_lock:
			if _node_pointed != null && _node_pointed is PhysicsBody3D:
				_node_pointed.axis_lock_linear_z = !_node_pointed.axis_lock_linear_z
				_node_pointed.axis_lock_linear_y = !_node_pointed.axis_lock_linear_y
				_node_pointed.axis_lock_linear_x = !_node_pointed.axis_lock_linear_x




func on_pointer_pressed(target : Node3D, _at : Vector3) -> void:
	last_node = target

func on_pointer_entered(target : Node3D, _at:Vector3)->void:
	_node_pointed = target

func on_pointer_exited(_target : Node3D, _at:Vector3)->void:
	_node_pointed = null

func _physics_process(delta: float) -> void:
	if _pointer._locked_target != null:
		var origin_ray = _pointer._raycast.global_transform.origin
		var distance_obj_prct = _pos.distance_to(origin_ray)/_pointer.length*100
		var direction = _pos.direction_to(origin_ray)
		if 20 < distance_obj_prct and distance_obj_prct < 80:
			pass
		elif distance_obj_prct > 80:
			#rapprocher
			_pointer._locked_target.move_and_collide(direction/50)
			_pos += (direction/50)
		elif distance_obj_prct < 20:
			#eloigner
			_pointer._locked_target.move_and_collide(-(direction/50))
			_pos -= (direction/50)
		_pointer._last_at = _pos
