extends FileDialog

signal is_loaded(gltf:Node)
signal load_failed()

var _thread:Thread
var mutex := Mutex.new()
var formats := ["None","PNG","JPEG","Lossless WebP","Lossy WebP"]
var format := 0

func _ready():
	self.file_selected.connect(_on_file_selected)

func _on_file_selected(file:String):
	if(_thread):
		if(_thread.is_alive()):
			return;
		else:
			_thread.wait_to_finish()
	_thread = Thread.new()
	
	var ext = file.get_extension()
	if ext == "glb" or ext == "gltf":
		_thread.start(Callable(self, "_load_gltf").bind(file))
	elif ext == "tscn" :
		_thread.start(Callable(self, "_load").bind(file))
	elif ext == "xyz":
		_thread.start(Callable(self, "_load_xyz").bind(file))
	hide()

func _load(file:String):
	var nodePacked = load(file) #charger une scène qui n'est pas deja dans la scène 
	if nodePacked == null:
		_emit_load_failed.call_deferred()
		return;
	var node = nodePacked.instantiate()
	add_static_body(node)
	_emit_load.call_deferred(node)
	
func _load_gltf(file:String):
	var gltf_state: GLTFState = GLTFState.new()
	gltf_state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var err = ERR_FILE_CANT_OPEN
	var gltf_doc = GLTFDocument.new()
	mutex.lock()
	gltf_doc.image_format = formats[format]
	mutex.unlock()
	err = gltf_doc.append_from_file(file, gltf_state)
	var gltf:Node = null
	
	if err == OK:
		gltf = gltf_doc.generate_scene(gltf_state)
		add_static_body(gltf)
		_emit_load.call_deferred(gltf)
	else:
		_emit_load_failed.call_deferred()

func _load_xyz(filePath:String):
	var points = PackedVector3Array()
	var file = FileAccess.open(filePath, FileAccess.READ)
	var ligne : String = file.get_line()
	if(ligne == ""):
		_emit_load_failed.call_deferred()
		return;
	while ligne != "":
		if ligne[0] != "#" :
			var pos = Vector3(0,0,0)
			var array = ligne.split(" ",false)
			pos.x = array[0].to_float()
			pos.y = array[1].to_float()
			pos.z = array[2].to_float()
			points.append(pos)
		ligne = file.get_line()
	file.close()
	# Create the ArrayMesh.
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
	
	#Material for array mesh (1 surface)
	var mat = ORMMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.use_point_size = true
	mat.point_size = 3
	#mat.albedo_color = Color(255,255,255)# fonctionne pas 
	#mat.set_flag(BaseMaterial3D.FLAG_ALBEDO_FROM_VERTEX_COLOR,true)
	arr_mesh.surface_set_material(0,mat)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = arr_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	#fini
	add_static_body(mesh_instance)
	_emit_load.call_deferred(mesh_instance)
	

func _emit_load(node) -> void:
	is_loaded.emit(node)
	
func _emit_load_failed() -> void:
	load_failed.emit()
	
func _exit_tree():
	if(_thread):
		_thread.wait_to_finish()

func _on_format_selected(index: int) -> void:
	mutex.lock()
	format = index
	mutex.unlock()

func get_point_middle(arr_mesh : Mesh) -> Vector3 : 
	var points = []
	for surf in arr_mesh.get_surface_count():
		points.append_array(arr_mesh.surface_get_arrays(surf)[0])
	var pos_middle = Vector3(0,0,0)
	for point in points : 
		pos_middle += point
	pos_middle = pos_middle / len(points)
	return pos_middle

func add_static_body(node):
	if node != null:
		print(node.get_tree_string_pretty())
		if node is MeshInstance3D:
			
			node.position = Vector3(0,0,0)
			
			var body = StaticBody3D.new()
			var colision = CollisionShape3D.new()
			colision.shape = node.mesh.create_convex_shape(true) #cree colision
			
			var parent:Node3D= null
			
			if(node.get_parent() != null):# modifier le parent pour mettre le body et non le mesh en enfant
				parent = node.get_parent()
				parent.remove_child(node)
				node.owner = null
				parent.add_child(body,true)
				
			node.translate(-get_point_middle(node.mesh)) # recentrer
			colision.translate(-get_point_middle(node.mesh))# avec la boite de colision c'est mieux
				
			body.add_child(node,true)
			body.add_child(colision,true)
			body.set_collision_layer_value(1, true)
			body.set_collision_mask_value(1, true)
			return ;
			
		# Continuer l'itération seulement si pas de mesh instance 3D
		for child in node.get_children():
			if child is StaticBody3D:
				break
				return;
			add_static_body(child)
