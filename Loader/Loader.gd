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
		_thread.start(Callable(self, "_load_ply").bind(file,false))
	else:
		load_failed.emit("mauvaise extension")
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
			gltf.material.cull_mode = BaseMaterial3D.CULL_DISABLED
			var node = gltf.get_owner()
			node.set_meta("file",file)
			if(node.name == ""):
				node.name = file.get_slice("/",file.get_slice_count("/")-1).get_slice(".",0)
			if !quiet:
				is_loaded.emit.call_deferred(node)
			return node
		else:
			gltf.set_meta("file",file)
			if !quiet:
				is_loaded.emit.call_deferred(gltf)
			return gltf
	else:
		load_failed.emit.call_deferred("Ereur au chargement :"+str(err))
		return ;


func create_mesh(arrays:Array,pointCloud:bool)->MeshInstance3D:
	var mesh = ArrayMesh.new()
	
	if(pointCloud):
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
	else :
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
	# Création d'un ArrayMesh et ajout d'une surface avec les tableaux préparés
	var mat = ORMMaterial3D.new()
	mat.set_flag(BaseMaterial3D.FLAG_ALBEDO_FROM_VERTEX_COLOR,true)
	mesh.surface_set_material(0,mat)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	return mesh_instance

func create_encapsulation(mesh_instance:MeshInstance3D,filePath:String):
	add_static_body(mesh_instance)
	mesh_instance.get_owner().set_meta("file",filePath)
	mesh_instance.get_owner().name = filePath.get_slice("/",filePath.get_slice_count("/")-1).get_slice(".",0)
	return mesh_instance.get_owner();
	
func _load_xyz(filePath:String, quiet:bool):
	var points = PackedVector3Array()
	var file = FileAccess.open(filePath, FileAccess.READ)
	var ligne : String = file.get_line()
	if(ligne == ""):
		load_failed.emit.call_deferred("Ereur au chargement :"+str(file.get_error()))
		return ;
	while ligne != "":
		if ligne[0] != "#" :
			var pos = Vector3(0,0,0)
			var array = ligne.split(" ",false)
			if(len(array) != 3):
				load_failed.emit.call_deferred("ERR_FILE_CORRUPT")
				return ;
			pos.x = array[0].to_float()
			pos.y = array[1].to_float()
			pos.z = array[2].to_float()
			points.append(pos)
		ligne = file.get_line()
	file.close()
	# Create the ArrayMesh.
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	
	var mesh_instance = create_mesh(arrays,true)
	#fini
	var owner_mesh = create_encapsulation(mesh_instance,filePath)
	if !quiet:
		is_loaded.emit.call_deferred(owner_mesh)
	return owner_mesh;

func face_to_indices(faces:Array):
	var indices = PackedInt32Array()
	for face in faces:
		if face.size() == 3:#cree un triangle
			#ont crée deux triangle a la foi pour le backface culling
			indices.append_array(face)
			indices.append_array([face[2],face[1],face[1]])
		elif face.size() > 3:#cree plusieur triangle avec pour "centre" le point 0 si plus de 3 point
			for j in range(1, face.size() - 1):
				indices.append(face[0])
				indices.append(face[j])
				indices.append(face[j + 1])
				indices.append(face[j + 1])
				indices.append(face[j])
				indices.append(face[0])
	return indices

func data_to_arrays(vertices,indices,colors,normals,uv_mapping):
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	if !colors.is_empty():
		arrays[Mesh.ARRAY_COLOR] = colors
	if !indices.is_empty():
		arrays[Mesh.ARRAY_INDEX] = indices
	if !normals.is_empty():
		arrays[Mesh.ARRAY_NORMAL] = normals
	if !uv_mapping.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = uv_mapping
	return arrays

func _read_ascii_ply(file:FileAccess,property:Array,vertex_count : int,face_count :int) :
	var faces = []
	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	var normals = PackedVector3Array()
	var uv_mapping = PackedVector2Array()
	var line :String
	for i in range(vertex_count):
		line = file.get_line()
		var parts = line.split(" ")
		var data = {"nx":null,"ny":null,"nz":null,"red" : null, "green" : null,
		 "blue" : null,"alpha":null,"radius":null,"s":null,"t":null}
		for j in range(len(property)-1):
			data[property[j]] = float(parts[j])
		#est toujours present
		vertices.append(Vector3(data["x"],data["y"],data["z"]))
		#donnée optionnel
		if data["nx"] != null and data["ny"] != null and data["nz"] != null:
			normals.append(Vector3(data["nx"],data["ny"],data["nz"]))
		if data["red"] != null and data["green"] != null and data["blue"] != null:
			if(data["alpha"] != null):
				colors.append(Color(data["red"]/255,data["green"]/255,data["blue"]/255,data["alpha"]/255))
			else:
				colors.append(Color(data["red"]/255,data["green"]/255,data["blue"]/255))
		if(data["s"] != null and data["t"] != null):
			uv_mapping.append(Vector2(data["s"],data["t"]))

	# Lecture des faces.
	for i in range(face_count):
		line = file.get_line()
		var parts = line.split(" ")
		if parts.size() < 4:
			load_failed.emit.call_deferred("ERR_FILE_CORRUPT")
			return [];
		# La première valeur indique le nombre de sommets dans la face
		var n = int(parts[0])
		var face_indices = []
		for j in range(n):
			face_indices.append(int(parts[j + 1]))
		faces.append(face_indices)
	return data_to_arrays(vertices,face_to_indices(faces),colors,normals,uv_mapping)

func read_for_type(file,type):
	match type:
				"char","int8","uchar","uint8":
					return file.get_8()
				"short","int16","ushort","uint16":
					return file.get_16()
				"int","int32","uint","uint32":
					return file.get_32()
				"float","float32":
					return file.get_float()
				"double","float64":
					return file.get_double()

func _read_binary_ply(file:FileAccess,property:Array,property_type:Array,face_type :Array,vertex_count : int,face_count :int):
	var faces = []
	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	var normals = PackedVector3Array()
	var uv_mapping = PackedVector2Array()

	for i in range(vertex_count):
		var data = {"nx":null,"ny":null,"nz":null,"red" : null, "green" : null,
		 "blue" : null,"alpha":null,"radius":null,"s":null,"t":null}
		for j in range(property.size()):
			data[property[j]] = read_for_type(file,property_type[j])
		#est toujours present
		vertices.append(Vector3(data["x"],data["y"],data["z"]))
		#donnée optionnel
		if data["nx"] != null and data["ny"] != null and data["nz"] != null:
			normals.append(Vector3(data["nx"],data["ny"],data["nz"]))
		if data["red"] != null and data["green"] != null and data["blue"] != null:
			if(data["alpha"] != null):
				colors.append(Color(data["red"]/255,data["green"]/255,data["blue"]/255,data["alpha"]/255))
			else:
				colors.append(Color(data["red"]/255,data["green"]/255,data["blue"]/255))
		if(data["s"] != null and data["t"] != null):
			uv_mapping.append(Vector2(data["s"],data["t"]))

	# Lecture des faces.
	for i in range(face_count):
		var n = read_for_type(file,face_type[0])
		var face_indices = []
		for j in range(n):
			face_indices.append(read_for_type(file,face_type[1]))
		faces.append(face_indices)
	return data_to_arrays(vertices,face_to_indices(faces),colors,normals,uv_mapping)


func _load_ply(filePath:String, quiet:bool):
	var file = FileAccess.open(filePath, FileAccess.READ)
	var is_ascii := true #else binary
	var line : String
	var vertex_count := 0
	var face_count := 0
	var property := []
	var property_type := []
	var arrays := []
	var face_type = []
	
	if file == null:
		load_failed.emit.call_deferred("Erreur au chargement :"+str(file.get_error()))
		return;
	
	if file.get_line().strip_edges() != "ply":# Vérification du header PLY
		load_failed.emit.call_deferred("Ce fichier n’est pas un fichier PLY valide.")
		return ;
	
	# Vérification que le format est ASCII
	line = file.get_line()
	if not line.strip_edges().begins_with("format ascii"):
		if line.strip_edges().begins_with("format binary_little_endian 1.0"):
			is_ascii = false
		else : 
			load_failed.emit.call_deferred("format inconnu : " + line.strip_edges())
			return ;
	
	line = file.get_line()
	# Lecture de l'en-tête pour extraire le nombre de sommets et de faces
	while line != "end_header":
		if line.begins_with("element vertex"):
			vertex_count = int(line.get_slice(" ",2))
		elif line.begins_with("element face"):
			face_count = int(line.get_slice(" ",2))
			line = file.get_line()
			face_type.append(line.get_slice(" ",2))
			face_type.append(line.get_slice(" ",3))
		elif line.begins_with("property") && ! line.begins_with("property list"): 
			property.append(line.get_slice(" ",2))
			if(!is_ascii):
				property_type.append(line.get_slice(" ",1))
		line = file.get_line()
	
	if vertex_count == 0 or property.size() < 3:
		load_failed.emit.call_deferred("no vertex")
		return ;
	
	# Lecture des sommets.
	if(is_ascii):
		arrays = _read_ascii_ply(file,property,vertex_count,face_count)
	else:
		arrays = _read_binary_ply(file,property,property_type,face_type,vertex_count,face_count)
	if arrays == []:
		return;
	file.close()
	arrays.resize(Mesh.ARRAY_MAX)
	
	var mesh_instance = create_mesh(arrays,face_count==0)
	var owner_mesh = create_encapsulation(mesh_instance,filePath)
	if !quiet:
		is_loaded.emit.call_deferred(owner_mesh)
	return owner_mesh

func _load_data(filePath:String):
	var file = FileAccess.open(filePath, FileAccess.READ)
	var com = file.get_var()
	var n = 0;
	for data_node in com:
		var node = null
		var ext = data_node["file"].get_extension()
		if(!FileAccess.file_exists(data_node["file"])):
			data_node["file"] = filePath.get_slice(".", 0).get_slice("-",0)+"."+ext
			if(!FileAccess.file_exists(data_node["file"])):
				var slice = data_node["file"].split(".")
				data_node['file'] = slice[0]+"-"+str(n)+"."+slice[1]
		n=n+1
		if(ext == "glb" or ext == "gltf"):
			node = _load_gltf(data_node["file"],true)
		elif(ext == "xyz"):
			node = _load_xyz(data_node["file"],true)
		elif(ext == "ply"):
			node = _load_ply(data_node["file"],true)
		else :
			load_failed.emit.call_deferred("bad extension")
			return;
		if(node == null):
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
			parent_mesh_instance.add_child(node,true)
			
			body.add_child(parent_mesh_instance,true)
			body.add_child(colision,true)
			body.set_collision_layer_value(1, true)
			body.set_collision_mask_value(1, true)
			body.collision_mask = 0
			node.owner = parent
			body.owner = parent
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
