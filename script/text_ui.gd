extends Control

# Node references based on standard chat layout structure
@onready var message_container: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var message_input: LineEdit = $LineEdit
@onready var send_button: Button = $SendButton

func _ready() -> void:
	# 1. Connect to Global's signal to listen for incoming messages from any peer or the host[cite: 1]
	Global.message_received.connect(_on_message_received)

## Sends the message to all clients and the host via the Global script RPC[cite: 1]
func send_message() -> void:
	if not message_input:
		return
		
	var text_content = message_input.text.strip_edges()
	if text_content.is_empty():
		return
		
	# Retrieve the current player's username from Global or LanHandler[cite: 1, 3, 4]
	var username = Global.current_client.get("user", "none")
	if username == "none" or username.is_empty():
		username = LanHandler.client_info.get("name", "Player")
		
	# Combine username and message into a single payload string using a separator delimiter
	var payload = username + "|||" + text_content
	
	# Call Global RPC to broadcast the message to all connected peers and host[cite: 1]
	Global.rpc("tell_clients", payload)
	
	# Clear the input box after sending
	message_input.clear()

## Receives broadcasted messages from Global, instantiates the msg class, and populates data[cite: 1, 6]
func _on_message_received(message_text: String) -> void:
	# Split payload back into username and message text
	var parts = message_text.split("|||", true, 1)
	var username = "System"
	var content = message_text
	
	if parts.size() > 1:
		username = parts[0]
		content = parts[1]
		
	# Instantiate the msg class script[cite: 6]
	var new_message = msg.new()
	new_message.user = username
	new_message.current_text = content
	
	# Add the message instance to the chat container on every client's end
	if message_container:
		message_container.add_child(new_message)
		
		# Auto-scroll to the bottom of the chat window
		await get_tree().process_frame
		var scroll = $ScrollContainer as ScrollContainer
		if scroll:
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func _on_line_edit_text_submitted(new_text: String) -> void:
	send_message()


func _on_button_pressed() -> void:
	send_message()
