# This class is just boilerplate methods unrelated to authentication.
# Esta clase son solo métodos repetitivos que no están relacionados con la autenticación.
class_name Test extends Node

const ADDRESS = "localhost"
const PORT = 1234

var client_connecting = false

func host():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT)
	if !error: multiplayer.multiplayer_peer = peer
	return error == OK

func join():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ADDRESS, PORT)
	var success = error == OK
	
	client_connecting = success
	if success: multiplayer.multiplayer_peer = peer
	return success

func _on_connected_to_server():
	client_connecting = false

func _on_connection_failed():
	client_connecting = false

func _on_peer_authentication_failed(_id: int):
	client_connecting = false

func wait_for_connecting(timeout: float = 10.0) -> Error:
	timeout = Time.get_ticks_msec() + timeout * 1000
	
	while client_connecting || multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
		await get_tree().process_frame
		if Time.get_ticks_msec() > timeout:
			return ERR_TIMEOUT
	
	return OK
