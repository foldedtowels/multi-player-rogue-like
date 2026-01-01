extends Node
## Central network manager for multiplayer
## Handles server/client connections, player management, and network events

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal server_disconnected()
signal connection_failed()
signal all_players_ready()

const PORT = 7777
const MAX_PLAYERS = 3

var peer: ENetMultiplayerPeer = null
var players: Dictionary = {}  # peer_id -> {name: String, character_index: int}
var is_host: bool = false
var players_ready: Dictionary = {}  # For scene transitions

func create_server() -> bool:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		push_error("[NetworkManager] Failed to create server: " + str(error))
		return false

	multiplayer.multiplayer_peer = peer
	is_host = true

	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

	print("[NetworkManager] Server created on port " + str(PORT))
	# Add host as first player
	var host_id = multiplayer.get_unique_id()
	add_player(host_id, "Host")
	return true

func join_server(address: String) -> bool:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error != OK:
		push_error("[NetworkManager] Failed to join server: " + str(error))
		connection_failed.emit()
		return false

	multiplayer.multiplayer_peer = peer
	is_host = false

	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	print("[NetworkManager] Connecting to " + address + ":" + str(PORT))
	return true

func _on_player_connected(id: int):
	print("[NetworkManager] Player connected: " + str(id))
	player_connected.emit(id)

func _on_player_disconnected(id: int):
	print("[NetworkManager] Player disconnected: " + str(id))
	remove_player(id)
	player_disconnected.emit(id)

func _on_connected_to_server():
	print("[NetworkManager] Connected to server!")
	var my_id = multiplayer.get_unique_id()
	# Send player info to server
	rpc_id(1, "register_player", my_id, "Player_" + str(my_id))

func _on_connection_failed():
	print("[NetworkManager] Connection failed!")
	connection_failed.emit()

func _on_server_disconnected():
	print("[NetworkManager] Server disconnected!")
	server_disconnected.emit()

@rpc("any_peer", "call_local", "reliable")
func register_player(id: int, player_name: String):
	add_player(id, player_name)

func add_player(id: int, player_name: String):
	players[id] = {
		"name": player_name,
		"character_index": -1
	}
	print("[NetworkManager] Player added: " + player_name + " (ID: " + str(id) + ")")
	# Emit signal so lobby UI updates
	player_connected.emit(id)

func remove_player(id: int):
	if players.has(id):
		players.erase(id)

func get_player_count() -> int:
	return players.size()

func get_player_name(id: int) -> String:
	if players.has(id):
		return players[id].name
	return "Unknown"

## Synchronized scene transitions
@rpc("authority", "call_local", "reliable")
func change_scene_synchronized(scene_path: String):
	print("[NetworkManager] Changing scene to: " + scene_path)
	get_tree().change_scene_to_file(scene_path)
	# Client notifies server when ready
	if not is_host:
		rpc_id(1, "player_scene_ready", multiplayer.get_unique_id())

@rpc("any_peer", "call_remote", "reliable")
func player_scene_ready(peer_id: int):
	players_ready[peer_id] = true
	print("[NetworkManager] Player " + str(peer_id) + " ready (" + str(players_ready.size()) + "/" + str(MAX_PLAYERS) + ")")

	if players_ready.size() >= get_player_count():
		print("[NetworkManager] All players ready!")
		all_players_ready.emit()
		players_ready.clear()
