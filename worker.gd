class_name Worker

var _thread:Thread
var _callable:Callable

func _init(cb:Callable):
	_callable = cb

func start():
	_thread = Thread.new()
	var _discard = _thread.start(_callable)
	
func _exit_tree():
	_thread.wait_to_finish()
