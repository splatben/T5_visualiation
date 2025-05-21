extends FileDialog

signal is_loaded(gltf:Node)
signal load_failed(err:String)
signal load_ann(ann:Node3D)

var _annotation = preload("res://material/Annotation/Annotation.tscn")
var _thread:Thread

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
		_thread.start(Callable(self, "_load_gltf").bind(file,false))
	elif ext == "tscn" :
		_thread.start(Callable(self, "_load").bind(file))
	elif ext == "xyz":
		_thread.start(Callable(self, "_load_xyz").bind(file,false))
	elif ext == "dat":
		_thread.start(Callable(self, "_load_data").bind(file))
	elif ext == "ply":
		_thread.start(Callable(self, "_load_ply_point").bind(file,false))
	hide()

func _load(file:String):
	var nodePacked = load(file) #charger une scène qui n'est pas deja dans la scène 
	if nodePacked == null:
		load_failed.emit.call_deferred("no scene")
		return;
	var node = nodePacked.instantiate()
	add_static_body(node)
	is_loaded.emit.call_deferred(node)
	
func _load_gltf(file:String,quiet : bool):
	var gltf_state: GLTFState = GLTFState.new()
	gltf_state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var err = ERR_FILE_CANT_OPEN
	var gltf_doc = GLTFDocument.new()
	GlobalScope.mutex.lock()
	gltf_doc.image_format = GlobalScope.format
	GlobalScope.mutex.unlock()
	err = gltf_doc.append_from_file(file, gltf_state)
	var gltf:Node3D = null
	
	if err == OK:
		gltf = gltf_doc.generate_scene(gltf_state)
		add_static_body(gltf)
		if(gltf is MeshInstance3D):
			var node = gltf.get_parent().get_parent()
			node.set_meta("file",file)
			if !quiet:
				is_loaded.emit.call_deferred(node)
			return node
		else:
			gltf.set_meta("file",file)
			if !quiet:
				is_loaded.emit.call_deferred(gltf)
			return gltf
	else:
		if !quiet:
			load_failed.emit.call_deferred(str(err))
		return null

func _load_xyz(filePath:String, quiet:bool):
	var points = PackedVector3Array()
	var file = FileAccess.open(filePath, FileAccess.READ)
	var ligne : String = file.get_line()
	if(ligne == ""):
		if !quiet:
			load_failed.emit.call_deferred(str(file.get_error()))
		return null;
	while ligne != "":
		if ligne[0] != "#" :
			var pos = Vector3(0,0,0)
			var array = ligne.split(" ",false)
			if(array.length() != 3):
				if !quiet:
					load_failed.emit.call_deferred("corrompu")
				return null;
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
	mesh_instance.get_parent().get_parent().set_meta("file",filePath)
	if !quiet:
		is_loaded.emit.call_deferred(mesh_instance.get_parent().get_parent())
	return mesh_instance.get_parent().get_parent();

func _load_ply_point(filePath:String, quiet:bool):
	var dico = {}
	var file = FileAccess.open(filePath, FileAccess.READ)
	var ligne : String = file.get_line()
	if(ligne == ""):
		if !quiet:
			load_failed.emit.call_deferred()
		return null;
	var headers = []
	var headers_required = ["property float x","property float y","property float z",
	"property uchar red","property uchar green","property uchar blue"]
	while ligne!= "end_header":
		print(ligne)
		if ligne.get_slice(" ",1) == "face":
			if !quiet:
				load_failed.emit.call_deferred("not point cloud")
			return null;
		headers.append(ligne)
		ligne = file.get_line()
	for h in headers_required:
		if h not in headers:
			if !quiet:
				load_failed.emit.call_deferred("bad header need position and color")
			return null;
	ligne = file.get_line()
	while ligne != "":
		var pos = Vector3(0,0,0)
		var color = Vector3(0,0,0)
		var array = ligne.split(" ",false)
		if(len(array)!= 6):
			if !quiet:
				load_failed.emit.call_deferred("corrompu")
			return null;
		pos.x = array[0].to_float()
		pos.y = array[1].to_float()
		pos.z = array[2].to_float()
		color.x = array[3].to_float()
		color.y = array[4].to_float()
		color.z = array[5].to_float()
		dico[str(color.x)+"/"+str(color.y)+"/"+str(color.z)].append(pos)
		ligne = file.get_line()
	file.close()
	# Create the ArrayMesh.
	var arr_mesh = ArrayMesh.new()
	for color in dico:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dico[color]
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
		
		#Material for array mesh (1 surface)
		var mat = ORMMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.use_point_size = true
		mat.point_size = 3
		var colors = color.split("/")
		mat.albedo_color = Color(colors[0],colors[1],colors[2])
		mat.set_flag(BaseMaterial3D.FLAG_ALBEDO_FROM_VERTEX_COLOR,true)
		arr_mesh.surface_set_material(0,mat)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = arr_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	#fini
	add_static_body(mesh_instance)
	mesh_instance.get_parent().get_parent().set_meta("file",filePath)
	if !quiet:
		is_loaded.emit.call_deferred(mesh_instance.get_parent().get_parent())
	return mesh_instance.get_parent().get_parent();
	
func _load_data(filePath:String):
	var file = FileAccess.open(filePath, FileAccess.READ)
	var com = file.get_var()
	for data_node in com:
		var node = null
		var ext = data_node["file"].get_extension()
		if(!FileAccess.file_exists(data_node["file"])):
			data_node["file"] = "./"+data_node["file"].get_slice("/", data_node["file"].get_slice_count("/")-1)
		if(ext == "glb" or ext == "gltf"):
			node = _load_gltf(data_node["file"],true)
		elif(ext == "xyz"):
			node = _load_xyz(data_node["file"],true)
		if(node == null):
			load_failed.emit.call_deferred("no object file")
			return;
		var body = node.get_child(0)
		body.set_position(Vector3(data_node["position"].x,data_node["position"].y,data_node["position"].z))
		body.set_rotation(Vector3(data_node["rotation"].x,data_node["rotation"].y,data_node["rotation"].z))
		body.set_scale(Vector3(data_node["taille"].x,data_node["taille"].y,data_node["taille"].z))
		for data_ann in data_node.annotations:
			var ann = _annotation.instantiate()
			ann.set_text(data_ann.text)
			ann.set_police(data_ann.police)
			var body2 = ann.get_child(0)
			body2.set_position(Vector3(data_ann["position"].x,data_ann["position"].y,data_ann["position"].z))
			body2.set_rotation(Vector3(data_ann["rotation"].x,data_ann["rotation"].y,data_ann["rotation"].z))
			body2.set_scale(Vector3(data_ann["taille"].x,data_ann["taille"].y,data_ann["taille"].z))
			body.add_child(ann)
			load_ann.emit.call_deferred(ann)
		is_loaded.emit.call_deferred(node)

func get_center(arr_mesh : Mesh) -> Vector3 : 
	return arr_mesh.get_aabb().get_center() #centre de la boundingBox (AABB)

#func update_mesh_origin(coord : Vector3, arr_mesh:Mesh) -> void : 
#	for surf in arr_mesh.get_surface_count():
#		var points = arr_mesh.surface_get_arrays(surf)[0]
#		for i in range(len(points)):
#			points[i] = points[i]+coord
#		arr_mesh.surface_update_vertex_region(surf,0,points.to_byte_array())

func update_shape_origin(coord : Vector3, shape : ConvexPolygonShape3D) ->  void: 
	var points = shape.get_points()
	for i in range(len(points)):
		points[i] = points[i]+coord
	shape.set_points(points)

func add_static_body(node):
	if node != null:
		if node is MeshInstance3D:
			node.position = Vector3(0,0,0)
			var coord = get_center(node.mesh)
			var body = StaticBody3D.new()
			var colision = CollisionShape3D.new()
			colision.shape = node.mesh.create_convex_shape(true) #cree colision
			update_shape_origin(-coord,colision.shape)
			
			var parent:Node3D= null
			if(node.get_parent() != null):# modifier le parent pour retirer le mesh
				parent = node.get_parent()
				parent.remove_child(node)
				node.owner = null
			else : 
				parent = Node3D.new()#ou le crée
			parent.add_child(body,true)
			node.transform.basis = Basis()
			node.transform.origin = Vector3(0,0,0)
			node.translate(-coord) # recentrer
			#colision.translate(-coord)# avec la boite de colision c'est mieux
			var parent_mesh_instance = Node3D.new()
			parent_mesh_instance.add_child(node)
			
			body.add_child(parent_mesh_instance)
			body.add_child(colision,true)
			body.set_collision_layer_value(1, true)
			body.set_collision_mask_value(1, true)
			return ;
			
		# Continuer l'itération seulement si pas de mesh instance 3D
		for child in node.get_children():
			if child is PhysicsBody3D:
				break
				return;
			add_static_body(child)

func _exit_tree():
	if(_thread):
		_thread.wait_to_finish()

func debug_point(pos : Vector3)-> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	var material = ORMMaterial3D.new()
	
	mesh_instance.position = pos
	sphere_mesh.radius = 0.025
	sphere_mesh.height = 0.05
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE_SMOKE
	sphere_mesh.material = material
	mesh_instance.mesh = sphere_mesh
	
	return mesh_instance
