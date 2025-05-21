extends Node

var format:String = "PNG"
var mutex := Mutex.new()

signal glasses_connected()
signal new_comment(com:Node3D)
