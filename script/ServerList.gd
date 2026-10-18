extends Control

@onready var server_container: VBoxContainer = $ScrollContainer/VBoxContainer
var known_servers = {} # IP: server_data dictionary

func _ready() -> void:
	self.visible = false
	# Start listening for LAN broadcasts on the client side
	# Starts when button to open menu is pressed

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	# Continuously listen for incoming UDP packets from servers
	poll_lan_servers()

func poll_lan_servers() -> void:
	while LanHandler.client_udp_peer.get_available_packet_count() > 0:
		var ip = LanHandler.client_udp_peer.get_packet_ip()
		var packet = LanHandler.client_udp_peer.get_packet()
		
		# Parse incoming JSON payload
		var json_string = packet.get_string_from_utf8()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			var data = json.get_data()
			if ip and not known_servers.has(ip):
				known_servers[ip] = data
				add_server_to_ui(ip, data)

func add_server_to_ui(ip: String, data: Dictionary) -> void:
	var parent_width = server_container.size.x if server_container.size.x > 0 else 300.0
	
	# Instantiate our custom ServerEntry class
	var entry = ServerEntry.new()
	entry.setup(ip, data, parent_width)
	server_container.add_child(entry)


func _on_button_pressed() -> void:
	print("Refreshing server search...")
	for child in server_container.get_children():
		child.queue_free()
	known_servers.clear()
	LanHandler.restart_client_discovery()
	
