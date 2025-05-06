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
	var node = nodePacked.instantiate()
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
		_emit_load.call_deferred(gltf)
	else:
		_emit_load_failed.call_deferred()

func _load_xyz(file:String):
	pass

func _emit_load(gltf) -> void:
	is_loaded.emit(gltf)
	
func _emit_load_failed() -> void:
	print("echec")
	load_failed.emit()
	
func _exit_tree():
	if(_thread):
		_thread.wait_to_finish()

func _on_format_selected(index: int) -> void:
	mutex.lock()
	format = index
	mutex.unlock()
