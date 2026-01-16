extends Control

var network_manager: Node
var game_manager: Node
var is_test_mode: bool = false

@onready var host_button: Button = $HostButton
@onready var join_button: Button = $JoinButton
@onready var ip_address: LineEdit = $IPAddress
@onready var player_list: VBoxContainer = $PlayerList
@onready var start_button: Button = $StartButton
@onready var status_label: Label = $StatusLabel
@onready var back_button: Button = $BackButton

func _ready():
	network_manager = get_node("/root/NetworkManager")
	game_manager = get_node("/root/GameManager")

	# Check if we're in test mode
	is_test_mode = game_manager.has_meta("test_mode") and game_manager.get_meta("test_mode")

	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)

	network_manager.player_connected.connect(_on_player_connected)
	network_manager.player_disconnected.connect(_on_player_disconnected)
	network_manager.connection_failed.connect(_on_connection_failed)

	# Update UI for test mode
	if is_test_mode:
		status_label.text = "TEST MODE - Waiting for players..."
		start_button.text = "Start Test"

	update_player_list()

func _on_host_pressed():
	if network_manager.create_server():
		host_button.disabled = true
		join_button.disabled = true
		ip_address.editable = false
		start_button.visible = true  # Only host can start
		status_label.text = "Hosting game on port " + str(NetworkManager.PORT)
		update_player_list()

func _on_join_pressed():
	var ip = ip_address.text
	if ip.is_empty():
		ip = "127.0.0.1"  # Localhost for testing

	if network_manager.join_server(ip):
		host_button.disabled = true
		join_button.disabled = true
		ip_address.editable = false
		status_label.text = "Connecting to " + ip + "..."

func _on_start_pressed():
	# Host starts the game
	if network_manager.is_host:
		var player_count = network_manager.get_player_count()
		if player_count == NetworkManager.MAX_PLAYERS:
			status_label.text = "Starting game..."
			# Use synchronized scene change
			network_manager.change_scene_synchronized.rpc("res://scenes/character_selection.tscn")
		else:
			status_label.text = "Need " + str(NetworkManager.MAX_PLAYERS) + " players! (" + str(player_count) + "/3)"

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_player_connected(peer_id: int):
	status_label.text = "Player " + str(peer_id) + " connected"
	update_player_list()

func _on_player_disconnected(peer_id: int):
	status_label.text = "Player " + str(peer_id) + " disconnected"
	update_player_list()

func _on_connection_failed():
	status_label.text = "Connection failed! Check IP address."
	host_button.disabled = false
	join_button.disabled = false
	ip_address.editable = true

func update_player_list():
	# Clear old labels (except the header)
	for child in player_list.get_children():
		if child.name != "PlayersLabel":
			child.queue_free()

	# Add current players
	for peer_id in network_manager.players.keys():
		var player_info = network_manager.players[peer_id]
		var label = Label.new()
		label.text = player_info.name
		if peer_id == multiplayer.get_unique_id():
			label.text += " (You)"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_list.add_child(label)

	# Show player count
	var count = network_manager.get_player_count()
	var max = NetworkManager.MAX_PLAYERS
	status_label.text = "Players: " + str(count) + "/" + str(max)

	# Enable start button only for host when all players connected
	if network_manager.is_host:
		start_button.disabled = (count < max)
