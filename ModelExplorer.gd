extends FileDialog

signal is_loaded(gltf:Node)
signal load_failed()
	
var _thread:Thread
var _gltf_doc = GLTFDocument.new()

func _ready():
	self.file_selected.connect(_on_file_selected)

func _on_file_selected(file:String):
	var ext = file.get_extension()
	if ext == "glb" or ext == "gltf":
		if(_thread):
			if(_thread.is_alive()):
				return;
			else:
				_thread.wait_to_finish()
		_thread = Thread.new()
		_thread.start(Callable(self, "_load_gltf").bind(file))
	elif ext == "tscn" :
		if(_thread):
			if(_thread.is_alive()):
				return;
			else:
				_thread.wait_to_finish()
		_thread = Thread.new()
		_thread.start(Callable(self, "_load_gltf").bind(file))
	hide()

func _load(file:String):
	var nodePacked = load(file) #charger une scène qui n'est pas deja dans la scène 
	var node = nodePacked.instantiate()
	_emit_load.call_deferred(node)
	
func _load_gltf(file:String):
	var gltf_state: GLTFState = GLTFState.new()
	gltf_state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var err = ERR_FILE_CANT_OPEN

	err = _gltf_doc.append_from_file(file, gltf_state)
	
	var gltf:Node = null
	
	if err == OK:
		gltf = _gltf_doc.generate_scene(gltf_state)
		_emit_load.call_deferred(gltf)
	else:
		_emit_load_failed.call_deferred()

func _emit_load(gltf) -> void:
	is_loaded.emit(gltf)
	
func _emit_load_failed() -> void:
	print("echec")
	load_failed.emit()
	
func _exit_tree():
	_thread.wait_to_finish()
