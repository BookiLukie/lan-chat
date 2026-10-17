extends Control

func _ready() -> void:
	$"Text Boxes/IPAddress".text = "Connected to: " + Global.host_ip

func _on_reconnect_pressed() -> void:
	LanHandler.reconnect_client()
