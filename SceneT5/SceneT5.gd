extends Node3D

var bulle_chat = preload("res://material/bulle_chat/bulle_chat.tscn")

var timer := Timer.new()

@export var buttonPath := "../Window/MenuLoader/ButtonListForDelete"# set in the inspector once
@onready var delete_list := get_node(buttonPath)

@onready var print_text = get_node("../Window/MenuLoader/RichTextLabel")

func _ready():
	#timer to wait glasses to be connnected
	get_parent().add_child.call_deferred(timer)
	timer.wait_time = 10 # 10 second
	timer.one_shot = true # don't loop, run once
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	
	var Loader = get_node("../Window/MenuLoader/Button/FileDialog") # les bouton deroulant du menu
	delete_list.item_selected.connect(_on_pressed_delete)
	Loader.is_loaded.connect(_on_load)
	Loader.load_failed.connect(_print_error)

func _on_load(node:Node):
	print_text.text="Import Successfull"
	add_static_body(node);
	if node.get_parent() :
		add_child(node.get_parent(),true);
		print(node.get_parent().get_tree_string_pretty())
	else :
		print(node.get_tree_string_pretty())
		add_child(node,true)
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

func _on_new_comment(pos:Vector3):
	var node = bulle_chat.instantiate()
	#var node = MeshInstance3D.new().mesh.generate_triangle_mesh()
	add_child(node)
	node.owner = self
	node.set_global_position(pos)
	print(pos)

func _on_timer_timeout() -> void:
	if get_node("/root/Main/TiltFiveGlasses/Player/Origin/Wand_1/Pointer/Control") == null:
		timer.wait_time = 10
		timer.start()
	else:
		get_node("/root/Main/TiltFiveGlasses/Player/Origin/Wand_1/Pointer/Control").new_comment.connect(_on_new_comment)
		get_parent().remove_child(timer)# removes from scene
		timer.queue_free()#delete

func add_static_body(node):
	if node != null:
		print(node.get_tree_string_pretty())
		if node is MeshInstance3D:
			var body = StaticBody3D.new()
			var colision = CollisionShape3D.new()
			colision.shape = node.mesh.create_convex_shape(true)
			print(colision.shape.get_points())
			var parent:Node3D= null
			if(node.get_parent() != null):
				parent = node.get_parent()
				parent.remove_child(node)
				node.owner = null
				parent.add_child(body,true)
			body.add_child(node,true)
			body.add_child(colision,true)
			body.set_collision_layer_value(1, true)
			body.set_collision_mask_value(1, true)
			return ;
		# Continuer l'itération sir pas de mesh instance 3D
		for child in node.get_children():
			if child is StaticBody3D:
				break
				return;
			add_static_body(child)
