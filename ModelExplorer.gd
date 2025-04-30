extends FileDialog

signal is_loaded(gltf:Node)
signal load_failed()
	

var gltf_doc = GLTFDocument.new()

func _ready():
	self.file_selected.connect(_on_file_selected)

func _on_file_selected(file:String):
	var ext = file.get_extension()
	if ext == "glb" or ext == "gltf":
		load_gltf(file)
	elif ext == "tscn" :
		var nodePacked = load(file) #charger une scène qui n'est pas deja dans la scène 
		var node = nodePacked.instantiate()
		is_loaded.emit(node)
	hide()

func load_gltf(file:String):
	var gltf_state: GLTFState = GLTFState.new()
	gltf_state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var err = ERR_FILE_CANT_OPEN

	err = gltf_doc.append_from_file(file, gltf_state)
	
	var gltf:Node = null
	
	if err == OK:
		gltf = gltf_doc.generate_scene(gltf_state)
		_emit_gltf_load.call_deferred(gltf)
	else:
		_emit_gltf_load_failed.call_deferred()

func _emit_gltf_load(gltf) -> void:
	is_loaded.emit(gltf)
	
func _emit_gltf_load_failed() -> void:
	print("echec")
	load_failed.emit()
