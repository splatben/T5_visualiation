@tool
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "ply_importer"

func _get_visible_name() -> String:
	return "PLY Importer (ASCII Text with Color)"

func _get_recognized_extensions() -> PackedStringArray:
	return ["ply"]

func _get_save_extension() -> String:
	return "mesh"

func _get_resource_type() -> String:
	return "ArrayMesh"

func _get_priority() -> float:
	return 1.0

func _get_preset_count() -> int:
	return 0

func _get_import_order() -> int:
	return 0

func _get_import_options(path: String, preset: int) -> Array[Dictionary]:
	return []

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> int:
	# Ouverture du fichier avec FileAccess (Godot 4.x)
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		push_error("Impossible d’ouvrir le fichier : " + source_file)
		return ERR_CANT_OPEN
	
	# Lecture complète du contenu du fichier en texte
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	var line_index = 0
	
	# Vérification du header PLY
	if lines.size() == 0 or lines[line_index].strip_edges() != "ply":
		push_error("Ce fichier n’est pas un fichier PLY valide.")
		return ERR_FILE_CORRUPT
	line_index += 1
	
	# Vérification que le format est ASCII
	if not lines[line_index].strip_edges().begins_with("format ascii"):
		push_error("Seuls les fichiers PLY ASCII sont supportés.")
		return ERR_FILE_CORRUPT
	line_index += 1
	
	# Lecture de l'en-tête pour extraire le nombre de sommets et de faces
	var vertex_count = 0
	var face_count = 0
	while line_index < lines.size():
		var line = lines[line_index].strip_edges()
		if line.begins_with("element vertex"):
			var parts = line.split(" ")
			if parts.size() >= 3:
				vertex_count = int(parts[2])
		elif line.begins_with("element face"):
			var parts = line.split(" ")
			if parts.size() >= 3:
				face_count = int(parts[2])
		elif line == "end_header":
			line_index += 1
			break
		line_index += 1
	
	if vertex_count == 0:
		push_error("Aucune définition de sommet trouvée dans le fichier PLY!")
		return ERR_FILE_CORRUPT
	
	# Lecture des sommets et des couleurs.
	# Chaque vertex doit contenir 6 valeurs : x, y, z, red, green, blue.
	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	for i in range(vertex_count):
		if (line_index + i) >= lines.size():
			break
		var parts = lines[line_index + i].strip_edges().split(" ")
		if parts.size() < 6:
			# Si moins de 6 valeurs, on ignore ce vertex
			continue
		var x = float(parts[0])
		var y = float(parts[1])
		var z = float(parts[2])
		vertices.append(Vector3(x, y, z))
		# Conversion des couleurs de 0–255 vers 0.0–1.0
		var r = float(parts[3]) / 255.0
		var g = float(parts[4]) / 255.0
		var b = float(parts[5]) / 255.0
		colors.append(Color(r, g, b))
	line_index += vertex_count
	
	# Lecture des faces.
	# Chaque face commence par le nombre de sommets suivi des indices des sommets.
	var faces = []
	for i in range(face_count):
		if (line_index + i) >= lines.size():
			break
		var parts = lines[line_index + i].strip_edges().split(" ")
		if parts.size() < 4:
			continue
		# La première valeur indique le nombre de sommets dans la face
		var n = int(parts[0])
		var face_indices = []
		for j in range(n):
			face_indices.append(int(parts[j + 1]))
		faces.append(face_indices)
	line_index += face_count
	
	# Préparation des tableaux pour ArrayMesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	
	# Construction de la liste d'indices via une triangulation en "fan" pour les faces à plus de 3 sommets
	var indices = PackedInt32Array()
	for face in faces:
		if face.size() == 3:
			indices.append_array(face)
		elif face.size() > 3:
			for j in range(1, face.size() - 1):
				indices.append(face[0])
				indices.append(face[j])
				indices.append(face[j + 1])
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Création d'un ArrayMesh et ajout d'une surface avec les tableaux préparés
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0, material)
	# Sauvegarde du mesh : l'appel se fait sous la forme ResourceSaver.save(mesh, save_file)
	var save_file = save_path + "." + _get_save_extension()
	var err = ResourceSaver.save(mesh, save_file)
	if err != OK:
		push_error("Échec de la sauvegarde de la ressource mesh : " + save_file)
		return err
	
	return OK
