extends Node

var host_ip
var current_client = {
	"user" : "none",
	"role" : "none",
	"peerid" : "00000000"
	}
signal server_message_received(message_text)
signal message_received(user,message_text,data_type,image_height)
## WE USE GLOBAL SCRIPT TO RECIVE AND SEND DATA AND SIGNALS 
## WE CALL GLOBAL.RPC("FUNCTION_NAME", FUCNTION ARGS) TO SEND SIGNALS TO ALL LOCATION 
enum actions { 
	TEXT,
	IMAGE,
}
@rpc("authority")
func tell_server(player,data,amount):
	pass

@rpc("any_peer")
func tell_clients(text):
	print(text)
	# Check for the Lobby label
	server_message_received.emit(text)
	print("DEBUG: Signal 'server_message_received' was emitted.")

@rpc("any_peer","call_local")
func new_message(user,text,data_type = "string", image_height = 100):
	print("received message")
	message_received.emit(user,text,data_type, image_height)
	
@rpc("any_peer")
func updateclientlist(client,info):
	LanHandler.client[client] = client
	LanHandler.client[client] = info

@rpc("any_peer")
func callmeeting():
	pass

@rpc("authority")
func checkinfo(client, data : String = "all"):
	pass
