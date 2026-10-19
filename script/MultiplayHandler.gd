extends Control

var IP_ADDRESS = "192.168.56.1"
const PORT : int = 9999
const MAX_CLIENTS = 32

var clients = {}

var client_info = {
	"name": "Name",
	"role": "Role",
}

var clients_loaded = 0

signal client_connected(peer_id, client_info)
signal client_disconnected(peer_id)
signal server_disconnected

### Server finding ###

const DISCOVERY_PORT = 443
var discoverable := false
var client_udp_peer := PacketPeerUDP.new()
var broadcast_timer = 0.0
var discovered_servers = {}
var server_name = "Server"
var server_description = "This is a server"

#func start_server_broadcasting():
	## Close the socket first if it's already open/bound to prevent conflicts
	#if udp_peer.is_bound():
		#udp_peer.close()
		#
	#udp_peer.set_broadcast_enabled(true)
	#udp_peer.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	#
	#var error = udp_peer.bind(DISCOVERY_PORT)
	#if error != OK:
		#print("Failed to bind UDP discovery port on server: ", error)
	#else:
		#print("Server broadcasting successfully bound to port ", DISCOVERY_PORT)

# Call this on the host every frame from hostUI's _process()
func handle_server_broadcasting(delta: float):
	if not multiplayer.is_server() or not discoverable:
		return
		
	broadcast_timer += delta
	if broadcast_timer >= randf_range(1.85,2.15):
		broadcast_timer = 0.0
		var server_data = {
			"name": server_name,
			"description": server_description,
			"players": clients.size()
		}
		var packet_bytes = JSON.stringify(server_data).to_utf8_buffer()
		
		# Send broadcast packet dynamically
		var broadcaster = PacketPeerUDP.new()
		broadcaster.set_broadcast_enabled(true)
		broadcaster.set_dest_address("255.255.255.255", DISCOVERY_PORT)
		broadcaster.put_packet(packet_bytes)

# Call this when opening the join menu to start listening for hosts
func start_client_discovery():
	if client_udp_peer.is_bound():
		client_udp_peer.close()
			
		discovered_servers.clear()
		
		var error = client_udp_peer.bind(DISCOVERY_PORT)
		if error == OK:
			client_udp_peer.set_broadcast_enabled(true)
			print("Client discovery restarted and listening on port ", DISCOVERY_PORT)
		else:
			print("Failed to restart client discovery: ", error)

func restart_client_discovery():
	if client_udp_peer.is_bound():
		client_udp_peer.close()
		
	discovered_servers.clear()
	
	var error = client_udp_peer.bind(DISCOVERY_PORT)
	if error == OK:
		client_udp_peer.set_broadcast_enabled(true)
		print("Client discovery restarted and listening on port ", DISCOVERY_PORT)
	else:
		print("Failed to restart client discovery: ", error)
		
func set_discoverable(state: bool) -> void:
	discoverable = state
	
func _ready():
	multiplayer.peer_connected.connect(_on_client_connected)
	multiplayer.peer_disconnected.connect(_on_client_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
func create_lobby():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

	clients[1] = client_info
	client_connected.emit(1, client_info)
	

func join_lobby(address : String = ""):
	if address.is_empty():
		address = IP_ADDRESS
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(str(address), PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	print("Joining Server: ",address)
	return true

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	clients.clear()

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_client_connected(id):
	_register_client.rpc_id(id, client_info)

@rpc("any_peer", "reliable")
func _register_client(new_client_info):
	var new_client_id = multiplayer.get_remote_sender_id()
	clients[new_client_id] = new_client_info
	client_connected.emit(new_client_id, new_client_info)
	Global.rpc("updateclientlist",new_client_id, new_client_info)
	
func _on_client_disconnected(id):
	clients.erase(id)
	client_disconnected.emit(id)

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	clients[peer_id] = client_info
	client_connected.emit(peer_id, client_info)
	print("Client Is Connected")

func _on_connected_fail():
	remove_multiplayer_peer()
	print("Connection Failed")

func _on_server_disconnected():
	remove_multiplayer_peer()
	clients.clear()
	server_disconnected.emit()

# Restart the host server 
func restart_server() -> Error:
	remove_multiplayer_peer()
	clients.clear()
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error:
		print("Failed to restart server: ", error)
		return error
		
	multiplayer.multiplayer_peer = peer
	clients[1] = client_info
	client_connected.emit(1, client_info)
	print("Server restarted successfully on port ", PORT)
	return OK

# Reconnect client to the previously saved host IP
func reconnect_client() -> Error:
	remove_multiplayer_peer()
	if Global.host_ip and not Global.host_ip.is_empty():
		print("Attempting to reconnect to: ", Global.host_ip)
		return join_lobby(Global.host_ip)
	else:
		print("No valid host IP found for reconnection.")
		return FAILED

func refresh_client_list() -> void:
	if multiplayer.is_server():
		for id in clients:
			if id != 1:
				# Re-broadcast registration info to ensure UI sync
				_register_client.rpc_id(id, clients[id])
		print("Client list refreshed by server.")
