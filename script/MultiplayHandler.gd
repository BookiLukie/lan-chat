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
	print("Joining Game",address)
	return true

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	clients.clear()
	
# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)


# Every peer will call this when they have loaded the game scene.
@rpc("any_peer")
func player_loaded():
	if multiplayer.is_server():
		clients_loaded += 1
		if clients_loaded == clients.size():
			$/root/Game.start_game()
			clients_loaded = 0

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_client_connected(id):
	_register_client.rpc_id(id, client_info)

@rpc("any_peer", "reliable")
func _register_client(new_client_info):
	var new_client_id = multiplayer.get_remote_sender_id()
	clients[new_client_id] = new_client_info
	client_connected.emit(new_client_id, new_client_info)
	Global.rpc("updateplayerlist",new_client_id, new_client_info)
	
func _on_client_disconnected(id):
	clients.erase(id)
	client_disconnected.emit(id)

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	clients[peer_id] = client_info
	client_connected.emit(peer_id, client_info)
	print("YEYEYYEYEYYE")

func _on_connected_fail():
	remove_multiplayer_peer()
	print("DIEEEEE")

func _on_server_disconnected():
	remove_multiplayer_peer()
	clients.clear()
	server_disconnected.emit()
