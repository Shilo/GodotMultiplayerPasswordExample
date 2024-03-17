# Multiplayer example on how to connect and authenticate clients with server password.
# Ejemplo multijugador sobre cómo conectar y autenticar clientes con la contraseña del servidor.

# This example is only basic authentication. It can be improved with encrypting the password via Crypto hashing.
# Este ejemplo es solo autenticación básica. Se puede mejorar cifrando la contraseña mediante hash criptográfico.
# https://github.com/Faless/gd-mp-password-auth/blob/main/password_auth.gd
extends Test

# Optionally change password to anything.
# Empty string "" will allow all clients to connect.
# Opcionalmente cambie la contraseña a lo que desee.
# Una cadena vacía "" permitirá que todos los clientes se conecten.
const SERVER_PASSWORD = "vH&q43I9DjgT"
#const SERVER_PASSWORD = ""

var client_password
var client_password_attempts = [
	"",
	"password",
	# Third attempt will always succeed.
	# El tercer intento siempre tendrá éxito.
	SERVER_PASSWORD
]

func _ready():
	# Setup signal connections for authentication and connection.
	# Configurar conexiones de señal para autenticación y conexión.
	multiplayer.peer_authenticating.connect(_on_peer_authenticating)
	multiplayer.peer_authentication_failed.connect(_on_peer_authentication_failed)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	# Both client and server need an authenication callback to work.
	# Tanto el cliente como el servidor necesitan una devolución de llamada de autenticación para funcionar.
	multiplayer.auth_callback = _on_receive_auth_request
	
	# Host on first window, join on additional windows.
	# Debugger will show 1 error, but it's expected to force client to join.
	# Hospede en la primera ventana, únase en ventanas adicionales.
	# El depurador mostrará 1 error, pero se espera que obligue al cliente a unirse.
	var is_hosting = host()
	
	# Wait a short time only for cleaner logging.
	# Espere un momento solo para un registro más limpio.
	await get_tree().create_timer(0.1 if is_hosting else 0.2).timeout
	
	if is_hosting:
		print_rich("[color=gray]Hosting server. Server password: \"%s\"." % SERVER_PASSWORD)
		return
	
	join_server()

func join_server():
	# Client will attempt to connect multiple times with different passwords for testing.
	# El cliente intentará conectarse varias veces con diferentes contraseñas para realizar pruebas.
	for password in client_password_attempts:
		client_password = password
		print_rich("[color=gray]Attempting to connect. Client password: \"%s\"." % client_password)
		join()
		
		# Wait till client is connected or disconnected before attempting next password.
		# Espere hasta que el cliente esté conectado o desconectado antes de intentar la siguiente contraseña.
		await wait_for_connecting()

func _on_peer_authenticating(id: int):
	# On server:
	# En el servidor:
	if multiplayer.is_server():
		# If server has no password, we authenticate all clients.
		# Si el servidor no tiene contraseña, autenticamos a todos los clientes.
		if !SERVER_PASSWORD:
			multiplayer.complete_auth(id)
		return
	
	# On client:
	# En el cliente:
	
	# Password sent can not be empty, so we default to " ".
	# La contraseña enviada no puede estar vacía, por lo que por defecto usamos " ".
	var valid_password = client_password if client_password else " "
	# Convert password string to bytes to send.
	# Convertir la cadena de contraseña a bytes para enviar.
	var password_data = valid_password.to_utf8_buffer()
	
	# We send the password request as bytes to server.
	# This will call _on_receive_auth_request on the server.
	# Enviamos la solicitud de contraseña como bytes al servidor.
	# Esto llamará a _on_receive_auth_request en el servidor.
	multiplayer.send_auth(id, password_data)
	
	# Client needs to complete authentication also.
	# El cliente también necesita completar la autenticación.
	multiplayer.complete_auth(id)

func _on_receive_auth_request(id: int, data: PackedByteArray):
	if !multiplayer.is_server(): return
	# On server:
	# En el servidor:
	
	# If server has no password, it already completed authentication so we can exit.
	# Si el servidor no tiene contraseña, ya completó la autenticación para que podamos salir.
	if !SERVER_PASSWORD: return
	
	# Convert the byte data to a string for the password.
	# Convierta los datos del byte en una cadena para la contraseña.
	var request_password = data.get_string_from_utf8()
	
	# Check if the passwords match.
	# Compruebe si las contraseñas coinciden.
	if request_password == SERVER_PASSWORD:
		# If password matches, we complete authentication.
		# When both client and server are authenticated, a connection is complete.
		# Si la contraseña coincide, completamos la autenticación.
		# Cuando tanto el cliente como el servidor están autenticados, se completa la conexión.
		multiplayer.complete_auth(id)
	else:
		# If passwords do not match, we disconnect client.
		# Si las contraseñas no coinciden, desconectamos el cliente.
		multiplayer.multiplayer_peer.disconnect_peer(id)

func _on_peer_authentication_failed(id: int):
	if multiplayer.is_server(): return
	# On client:
	# En el cliente:
	super._on_peer_authentication_failed(id)
	
	print_rich("[color=orange]Failed to authenticate client. Client password: \"%s\", Server password: \"%s\"." % [client_password, SERVER_PASSWORD])

func _on_connection_failed():
	super._on_connection_failed()
	
	# Client failed to connect to server with invalid password or network problem.
	# El cliente no pudo conectarse al servidor con una contraseña no válida o un problema de red.
	print_rich("[color=orange]Failed to connect to server. Client password: \"%s\", Server password: \"%s\"." % [client_password, SERVER_PASSWORD])

func _on_connected_to_server():
	super._on_connected_to_server()
	
	# Client successfully connected to server with valid password.
	# El cliente se conectó exitosamente al servidor con una contraseña válida.
	print_rich("[color=green]Connected to server. Client password: \"%s\", Server password: \"%s\"." % [client_password, SERVER_PASSWORD])
