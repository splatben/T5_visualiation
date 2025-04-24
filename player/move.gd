extends Node

@export var boutton_zoom := "button_a";
@export var boutton_dezoom := "button_y";
@export var boutton_reinitialisation := "button_1";

var target_node = StaticBody3D

var last_node = StaticBody3D

var _pointer = T5ToolsPointer

var _controller = T5Controller3D

var _origin = T5Origin3D

func _ready() -> void:
	target_node = null
	_origin = T5ToolsPlayer.find_instance(self).get_origin()
	_pointer = get_parent() as T5ToolsPointer
	_controller = _pointer.get_parent() as T5Controller3D
	_pointer.pointer_pressed.connect(on_pointer_pressed)
	_pointer.pointer_released.connect(on_pointer_released)
	_pointer.pointer_moved.connect(on_pointer_move)
	_controller.input_vector2_changed.connect(_on_stick_move)
	_controller.button_pressed.connect(_on_button_pressed)

func on_pointer_pressed(target : Node3D, _pos : Vector3) -> void :
	target_node = target
	print("got it")
	
func on_pointer_released(_target : Node3D, _pos : Vector3) -> void:
	print("no more")
	last_node = target_node
	target_node = null
	
func on_pointer_move(_target : Node3D, from_pos : Vector3, to_pos : Vector3) -> void :
	if target_node != null :
		target_node.move_and_collide(to_pos-from_pos)

func _on_stick_move(_name: String, value: Vector2) -> void :
	if target_node != null and ((value.x > 0.1 or value.y > 0.1) or (value.x < -0.1 or value.y < -0.1)):
		if abs(value.x) > abs(value.y) : 
			print(value)
			target_node.rotate(Vector3(0,value.x,0).normalized(),0.075)
		else : 
			print(value)
			target_node.rotate(Vector3(0,0,-value.y).normalized(),0.075)

func _on_button_pressed(p_name : String) -> void:
	if target_node != null :
		match p_name: 
			boutton_zoom:
				target_node.scale_object_local(Vector3(1.15,1.15,1.15))
			boutton_dezoom:
				target_node.scale_object_local(Vector3(0.85,0.85,0.85))
			boutton_reinitialisation:
				target_node.set_scale(Vector3(1,1,1))
				target_node.set_rotation(Vector3(0,0,0))
				target_node.move_and_collide(-target_node.get_position())
	else :
		match p_name: 
			boutton_zoom:
				_origin.gameboard_scale = _origin.gameboard_scale * 1.15		
			boutton_dezoom:
				_origin.gameboard_scale = _origin.gameboard_scale / 1.15		
			boutton_reinitialisation:	
				if (last_node != null):
					last_node.set_scale(Vector3(1,1,1))
					last_node.set_rotation(Vector3(0,0,0))
					last_node.move_and_collide(-last_node.get_position())
