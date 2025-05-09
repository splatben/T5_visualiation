extends Node

@export var boutton_zoom := "button_a";
@export var boutton_dezoom := "button_y";
@export var boutton_reinitialisation := "button_1";
@export var bouton_bulle := "button_2";

var _pointer = T5ToolsPointer

var _controller = T5Controller3D

var last_node : StaticBody3D

var _origin = T5Origin3D

var _pos : Vector3

signal new_comment(pos:Vector3)

func on_pointer_released(_target : Node3D, _at : Vector3) -> void:
	last_node = _target

func _ready() -> void:
	_origin = T5ToolsPlayer.find_instance(self).get_origin()
	_pointer = get_parent() as T5ToolsPointer
	_controller = _pointer.get_parent() as T5Controller3D
	_pointer.pointer_released.connect(on_pointer_released)
	_pointer.pointer_moved.connect(on_pointer_move)
	_controller.input_vector2_changed.connect(_on_stick_move)
	_controller.button_pressed.connect(_on_button_pressed)

	
func on_pointer_move(target : Node3D, from_pos : Vector3, to_pos : Vector3) -> void :
	if _pointer._locked_target != null && from_pos != to_pos:
		var origin_ray = _pointer._raycast.global_transform.origin
		var distance_obj_prct = ((origin_ray - to_pos).length())/_pointer.length*100
		if 10 < distance_obj_prct and distance_obj_prct < 90:
			_pointer._locked_target.move_and_collide(to_pos-from_pos)
			_pos = to_pos
		elif distance_obj_prct > 90:
			#rapprocher
			_pointer._locked_target.move_and_collide(to_pos-from_pos + (origin_ray/500))
			_pos = to_pos + (origin_ray/500)
		elif distance_obj_prct < 10:
			#eloigner
			_pointer._locked_target.move_and_collide(to_pos-from_pos - (origin_ray/500)) #effectue une translation
			_pos = to_pos - (origin_ray/500)
	_pointer._last_at = _pos

func _on_stick_move(_name: String, value: Vector2) -> void :
	if _pointer._locked_target != null and ((value.x > 0.1 or value.y > 0.1) or (value.x < -0.1 or value.y < -0.1)):
		if abs(value.x) > abs(value.y) : # pour faciliter le controle on rotate soit en x soit en y
			_pointer._locked_target.rotate(Vector3(0,value.x,0).normalized(),0.075)
		else : 
			_pointer._locked_target.rotate(Vector3(0,0,-value.y).normalized(),0.075)

func _on_button_pressed(p_name : String) -> void:
	if _pointer._locked_target != null :
		match p_name: 
			boutton_zoom:
				_pointer._locked_target.scale_object_local(Vector3(1.15,1.15,1.15))
			boutton_dezoom:
				_pointer._locked_target.scale_object_local(Vector3(0.85,0.85,0.85))
			boutton_reinitialisation: #tout mettre a zero
				_pointer._locked_target.set_scale(Vector3(1,1,1))
				_pointer._locked_target.set_rotation(Vector3(0,0,0))
				_pointer._locked_target.move_and_collide(-_pointer._locked_target.get_position())
			bouton_bulle:
				new_comment.emit.call_deferred(_pos)
	else :
		match p_name: 
			boutton_zoom:
				_origin.gameboard_scale = _origin.gameboard_scale / 1.15 # en baisant la 
				# taille des lunettes le reste devient plus grand
				_pointer.length = _pointer.length / 1.15
				_pointer.arc_radius = _pointer.arc_radius / 1.15
				_pointer.target_radius = _pointer.target_radius / 1.15
			boutton_dezoom:
				_origin.gameboard_scale = _origin.gameboard_scale * 1.15  # en augmentant 
				# taille des lunettes le reste devient plus petit
				_pointer.length = _pointer.length * 1.15
				_pointer.arc_radius = _pointer.arc_radius * 1.15
				_pointer.target_radius = _pointer.target_radius * 1.15
			boutton_reinitialisation:	
				if (last_node != null):
					last_node.set_scale(Vector3(1,1,1))
					last_node.set_rotation(Vector3(0,0,0))
					last_node.move_and_collide(-last_node.get_position())
			bouton_bulle:
				new_comment.emit.call_deferred(_pos)
