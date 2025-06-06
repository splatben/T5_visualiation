class_name Wand_Control
extends Node

#public
@export_category("Assignement des boutons")
@export var zoom : Wand_button = Wand_button.A
@export var dezoom : Wand_button = Wand_button.Y
@export var lock : Wand_button = Wand_button.X
@export var reinitialisation : Wand_button = Wand_button._1
@export var ajouter_modifier_annotation : Wand_button = Wand_button.STICK
@export var menu : Wand_button = Wand_button.B
@export var saisie: Wand_button = Wand_button.GACHETTE
@export var supression_annotation = Wand_button._2

@export_category("option")
@export_range(1,1.9,0.05) var zoom_step := 1.2;
@export_range(1,1.2,0.01) var length_pointeur_step = 1.02;

enum Wand_button {
	A,
	B,
	Y,
	X,
	_1,
	_2,
	STICK,
	MIDDLE,
	GACHETTE
}

var _button_name_to_enum:Dictionary ={
	"button_a":Wand_button.A,
	"button_b":Wand_button.B,
	"button_y":Wand_button.Y,
	"button_x":Wand_button.X,
	"button_1":Wand_button._1,
	"button_2":Wand_button._2,
	"button_3":Wand_button.STICK,
	"button_t5":Wand_button.MIDDLE,
	"trigger_click":Wand_button.GACHETTE
}

#"privée"
var _last_node : PhysicsBody3D
var _pointer = T5ToolsPointer
var _node_pointed : PhysicsBody3D
var _origin : T5Origin3D
var _wand : T5Controller3D
var _menu : Node
var _thread : Thread
var mutex := Mutex.new()

#Deplacement voir _on_pointer_move() && _on_stick_move()
var _pos : Vector3
var _first : bool
var _distance_obj : float

#Rotation voir _on_stick_move() && physics_process()
var _initial_grab_rotation: Quaternion  # Stocke la rotation au moment de la saisie
var _is_grabbed = false

#pouvoir changer de parent une annotation
var _node_locked : Node3D
var outline_node : MeshInstance3D = null
var outline_node_parent :MeshInstance3D = null

#pourvoir changer la face d'un annotation
var reverse : bool
var changed : bool

signal new_comment(pos:Vector3,node:Node3D)
signal edit(comment:Node3D)

func _ready() -> void:
	_origin = T5ToolsPlayer.find_instance(self).get_origin()
	_pointer = get_parent()
	_wand = _pointer.get_parent() 
	_menu = _origin.get_node("Camera/T5-glasses/Viewport2Din3D")
	_pointer.pointer_pressed.connect(on_pointer_pressed)
	_pointer.pointer_moved.connect(on_pointer_move)
	_wand.input_vector2_changed.connect(_on_stick_move)
	_wand.button_pressed.connect(_on_button_pressed)
	_pointer.pointer_entered.connect(on_pointer_entered)
	_pointer.pointer_exited.connect(on_pointer_exited)
	GlobalScope.glasses_connected.emit()

func on_pointer_move(_target : Node3D, from_pos : Vector3, to_pos : Vector3) -> void :
	if(from_pos != to_pos):
		if _pointer._locked_target != null:
			if(_first):
				var origin_ray = _pointer._raycast.global_transform.origin
				_distance_obj = _pos.distance_to(origin_ray)/_pointer.length #entre 0 et 1
				_first = false
			var at = _pointer._raycast.to_global(Vector3(0, 0, -_pointer.length*_distance_obj))
			_pointer._locked_target.move_and_collide(at-_pos)
			_pos = at
			_pointer._last_at = _pos
		else : 
			_first = true
			_pos = to_pos

func _on_stick_move(_name: String, value: Vector2) -> void :
	if _pointer._locked_target != null :
		#pouvoir rapprocher ou éloigner l'objet
		if  value.y > 0.25:
			if(_distance_obj + length_pointeur_step-1 > 0.99):
				_pointer.length *= length_pointeur_step
			else :
				_distance_obj += length_pointeur_step-1.0
		elif value.y < -0.25:
			if _distance_obj - (length_pointeur_step-1) > 0.10:
				_distance_obj -= length_pointeur_step-1.0
		#pouvoir rotate sur l'axe des y avec le stick c'est plus simple
		if value.x > 0.5: 
			if _pointer._locked_target.is_in_group("Annotation") && changed:
				reverse= !reverse
				changed = false
				return ;
			_is_grabbed = false #eviter conflict avec physics_proccess
			_pointer._locked_target.rotate_y(0.1) 
		elif value.x < -0.5:
			if _pointer._locked_target.is_in_group("Annotation") && changed:
				reverse= !reverse
				changed = false
				return ;
			_is_grabbed = false
			_pointer._locked_target.rotate_y(-0.1)
		else : 
			changed = true
	else:
		#pouvoir agrandir ou reduire la taille du pointeur
		if  value.y > 0.25:
			_pointer.length *= length_pointeur_step
		elif value.y < -0.25:
			_pointer.length /= length_pointeur_step

func _on_button_pressed(p_name : String) -> void:
	match _button_name_to_enum[p_name]: 
		zoom:
			if _node_pointed != null :
				_node_pointed.scale_object_local(Vector3(zoom_step,zoom_step,zoom_step))
			else: 
				_origin.gameboard_scale = _origin.gameboard_scale / zoom_step # en baisant la 
				# taille des lunettes le reste devient plus grand
				_pointer.length = _pointer.length / zoom_step
				_pointer.arc_radius = _pointer.arc_radius / zoom_step
				_pointer.target_radius = _pointer.target_radius / zoom_step
		dezoom:
			if _node_pointed != null :
				_node_pointed.scale_object_local(Vector3(2-zoom_step,2-zoom_step,2-zoom_step))
			else : 
				_origin.gameboard_scale = _origin.gameboard_scale * zoom_step  # en augmentant 
				_pointer.length = _pointer.length * zoom_step
				_pointer.arc_radius = _pointer.arc_radius * zoom_step
				_pointer.target_radius = _pointer.target_radius * zoom_step
		reinitialisation: #tout mettre a zero
			if (_last_node != null):
				_last_node.set_rotation(Vector3(0,0,0))
				_last_node.move_and_collide(-_last_node.get_position())
		ajouter_modifier_annotation:
			if _node_pointed != null:
				if _node_pointed.is_in_group("Annotation"):
					edit.emit.call_deferred(_node_pointed.get_parent())
				else :
					new_comment.emit.call_deferred(_pos,_node_pointed)
		lock:
			if _node_pointed != null:
				if _node_pointed.is_in_group("Annotation"):
					if _node_locked != null:
						if _node_locked != _node_pointed:
							remove_outline(_node_locked)
							_node_locked = _node_pointed
							add_outline(_node_locked)
						else:
							remove_outline(_node_locked)
							_node_locked = null
					else:
						_node_locked = _node_pointed
						add_outline(_node_locked)
				elif _node_locked != null and _node_pointed != _node_locked.get_parent().get_parent():
					remove_outline(_node_locked)
					var parent_body = _node_locked.get_parent()
					if parent_body.get_parent():
						parent_body.get_parent().remove_child(parent_body)
					_node_pointed.add_child(parent_body)
					add_outline(_node_locked)
		menu:
			_menu.visible = !_menu.visible
		supression_annotation:
			if (_node_pointed != null and _node_pointed.is_in_group("Annotation")):
				remove_outline(_node_pointed)
				GlobalScope.comment_delete.emit(_node_pointed.get_parent())
				_node_pointed = null

func on_pointer_pressed(target : Node3D, _at : Vector3) -> void:
	_last_node = target

func on_pointer_entered(target : Node3D, _at:Vector3)->void:
	_node_pointed = target

func on_pointer_exited(_target : Node3D, _at:Vector3)->void:
	_node_pointed = null

func _physics_process(_delta):
	if _pointer._locked_target != null :
		if  !_pointer._locked_target.is_in_group("Annotation"):
			if not _is_grabbed:  # Détecte la première saisie
				_is_grabbed = true
				#if _pointer._locked_target.is_in_group("Annotation"):
				#	_initial_grab_rotation = _wand.quaternion.inverse() *_pointer._locked_target.quaternion#difference objet modifier et baton
				#else :
				_initial_grab_rotation = _wand.quaternion.inverse() * _pointer._locked_target.quaternion#difference objet modifier et baton

			var rotation_change = _wand.quaternion * _initial_grab_rotation#ajout de la rotation du baton a la rotation d'un objet
			_pointer._locked_target.quaternion = _pointer._locked_target.quaternion.slerp(rotation_change, 1)
		else :
			_pointer._locked_target.look_at(_wand.global_position,Vector3(0,1,0),reverse);# fonctionnne mais manque de possibilité pour le faire tourner sur lui meme 
	else:
		_is_grabbed = false

func add_outline(body: Node) -> void:
	mutex.lock()
	if outline_node_parent != null or outline_node != null:
		remove_outline(body)
		return
	mutex.unlock()
	if(_thread):
		if(_thread.is_alive()):
			return;
		else:
			_thread.wait_to_finish()
	var body_parent = body.get_parent().get_parent()
	_thread = Thread.new()
	if(body_parent):
		_thread.start(calculate_outline.bind(body.get_node("CollisionShape3D").shape,body,body_parent.get_node("CollisionShape3D").shape,body_parent))
	else:
		_thread.start(calculate_outline.bind(body.get_node("CollisionShape3D").shape,body))

func remove_outline(body: Node) -> void:
	mutex.lock()
	if outline_node != null and outline_node.get_parent() == body :
		body.remove_child(outline_node)
		outline_node.queue_free()
		outline_node = null
	if outline_node_parent != null and outline_node_parent.get_parent() !=null:
		outline_node_parent.get_parent().remove_child(outline_node_parent)
		outline_node_parent.queue_free()
		outline_node_parent = null
	mutex.unlock()

func calculate_outline(shape:Shape3D,body:StaticBody3D,shape_parent:Shape3D=null,body_parent:StaticBody3D=null):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = shape.get_debug_mesh()
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.AQUA
	mesh_instance.mesh.surface_set_material(0,material)
	mesh_instance.position = Vector3(0.244,0.111,0)
	mutex.lock()
	outline_node = mesh_instance
	body.add_child.call_deferred(outline_node,true)
	mutex.unlock()
	
	if(body_parent != null):
		mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = shape_parent.get_debug_mesh()
		material = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color.RED
		mesh_instance.mesh.surface_set_material(0,material)
		mutex.lock()
		outline_node_parent = mesh_instance
		body_parent.add_child.call_deferred(outline_node_parent,true)
		mutex.unlock()

func _exit_tree() -> void:
	if(_thread):
		_thread.wait_to_finish()
