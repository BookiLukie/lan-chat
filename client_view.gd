extends Control

func _ready() -> void:
	$"Text Boxes/IPAddress".text = "Connected to: " + Global.host_ip
