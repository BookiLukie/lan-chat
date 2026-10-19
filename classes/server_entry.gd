extends Panel
class_name ServerEntry

var server_ip: String = ""
var server_name: String = ""
var server_desc: String = ""
var player_count: int = 0
var username = "User"

func setup(ip: String, data: Dictionary, usable_width: float, usernamenew = "User") -> void:
	username = usernamenew
	server_ip = ip
	server_name = data.get("name", "Unnamed Server")
	server_desc = data.get("description", "No description")
	player_count = data.get("players", 1)
	print(usable_width)
	custom_minimum_size = Vector2(usable_width, 70)
	
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.position = Vector2(10, 10)
	label.custom_minimum_size = Vector2(usable_width - 100, 50)
	label.text = "[b]%s[/b]\n[color=#808080]%s[/color] | Players: %d\nIP: %s" % [server_name, server_desc, player_count, server_ip]
	add_child(label)
	
	var connect_btn = Button.new()
	connect_btn.text = "Connect"
	connect_btn.position = Vector2(usable_width - 100, 15)
	connect_btn.custom_minimum_size = Vector2(90, 40)
	connect_btn.pressed.connect(_on_connect_pressed)
	add_child(connect_btn)

func _on_connect_pressed() -> void:
	Global.host_ip = server_ip
	Global.current_client["user"] = username
	LanHandler.client_info.set("name", Global.current_client.user)
	if LanHandler.join_lobby(server_ip):
		get_tree().change_scene_to_file("res://client_view.tscn")
