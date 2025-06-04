extends Node

var format:String = "PNG"
var mutex := Mutex.new()
var sceneT5 :Node3D = null

signal glasses_connected()
signal new_comment(com:Node3D)
