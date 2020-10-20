extends Node
const DEFAULT_PORT = 10500
const MAX_PEERS = 6
const ROUNDS = 3
# Dictionary {unique_id : [String name, bool ready, String avatar, int wins, int gold]}
var players = {}
master var available_avatars = ['ship_blue.png', 'ship_green.png', 'ship_orange.png', 'ship_purple.png', 'ship_red.png', 'ship_tyrk.png', 'ship_yellow.png']
var current_round = 1
var players_loaded = []
var game_in_progress = false
	
# Signals to let lobby GUI know what's going on
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal enable_start()
signal disable_start()

func _ready():
# Server and Clients
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
# Clients only
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
# Return from lobby, popup disconnect if abnormal
func exit_lobby(abnormaly):
	var screen = load('res://scenes/screens/TitleScreen.tscn')
	get_tree().set_network_peer(null)
	reset_lobby_variables()
	get_tree().change_scene_to(screen)
	if has_node("/root/World"):
		get_node("/root/World").queue_free()
	if abnormaly:
		yield(get_tree().create_timer(0.5), 'timeout')
		if has_node("/root/TitleScreen"):
			get_node('/root/TitleScreen').popup_disconnect()

master func change_avatar(id):
	if players[id][2] != '':
		available_avatars.append(players[id][2])
	players[id][2] = available_avatars.front()
	available_avatars.pop_front()
	rpc('update_puppets', players)
	emit_signal('player_list_changed')
	
remotesync func change_player_name(new_name, id):
	players[id][0] = new_name
	emit_signal("player_list_changed")

func create_server():
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)
	players[1] = ['Server', true, '', 0, 0]
	change_avatar(1)

func connect_to_server(ip):
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)

func _connected_ok():
	emit_signal("connection_succeeded")
	
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")
	
puppet func update_puppets(updated_players):
	players = updated_players
	emit_signal("player_list_changed")

func _player_connected(id):
	if is_network_master():
		players[id] = [str(id), false, '', 0, 0]
		change_avatar(id)
		rpc('update_puppets', players)
		emit_signal("player_list_changed")

func _player_disconnected(id):
	if is_network_master():
		available_avatars.append(players[id][2])
		players.erase(id)
		if players.size() < 2 and game_in_progress:
			end_game(false)
		rpc('update_puppets', players)
		emit_signal("player_list_changed")
		
func _server_disconnected():
	exit_lobby(true)

# Server sets spawn points for everybody
func set_spawn_points():
	var spawn_points_dict = {}
	var spawn_pt = [0, 1, 2, 3, 4, 5]
	for p in players:
		randomize()
		var random_pt = randi() % spawn_pt.size()
		spawn_points_dict[p] = spawn_pt[random_pt]
		spawn_pt.remove(random_pt)
	rpc("load_game", spawn_points_dict)

# Everybody loads world
remotesync func load_game(spawn_points):
	get_tree().set_pause(true) # Pre-pause
	var world = load("res://scenes/World.tscn").instance()
	get_tree().get_root().add_child(world)
	if has_node('/root/LobbyScreen'):
			get_node('/root/LobbyScreen').queue_free()
	var player_scene = load("res://scenes/Player.tscn")
	
	# Spawn every player
	for p_id in spawn_points:
		var spawn_pos = world.get_node("PlayerSpawnPoints/" + str(spawn_points[p_id])).position
		var player = player_scene.instance()
		player.set_name(str(p_id))
		player.position = spawn_pos
		player.set_network_master(p_id)
		player.get_node('ShipSprite').set_texture(load('res://Sprites/ships/' + players[p_id][2]))
		world.get_node("Players").add_child(player)
		
	# Tell server im done loading
	rpc("register_loaded", get_tree().get_network_unique_id())

# Register player as loaded
master func register_loaded(id):
	if not id in players_loaded:
		players_loaded.append(id)
	if players_loaded.size() == players.size():
		rpc('start_round')

# Start round synced
remotesync func start_round():
	game_in_progress = true
	get_node('/root/World/Label/AnimationPlayer').play('CountDown')
	yield(get_node('/root/World/Label/AnimationPlayer'), "animation_finished")
	get_tree().set_pause(false)
	if is_network_master():
		get_node("/root/World/ElementSpawner").start_spawn()

# Tell evryobody im ready, if all players are ready enable start	
remotesync func toggle_lobby_ready(id, ready):
	if ready:
		players[id][1] = true
	else:
		players[id][1] = false
	emit_signal('player_list_changed')
	if is_network_master():
		var ready_count = 0
		for player in players:
			if players[player][1] == true:
				ready_count += 1
		if ready_count == players.size():
			emit_signal("enable_start")
		elif ready_count < players.size():
			emit_signal("disable_start")

#---------------------------------------------------------------------------------------------------------------------------
# Check if there is a winner 
func check_end_round():
	if has_node("/root/World/Players"): 
		var player_count = get_node("/root/World/Players").get_child_count()
		if player_count < 2 and player_count > 0:
			var player = get_node("/root/World/Players").get_child(0)
			player.set_winner()
			players[player.get_network_master()][3] += 1
			get_tree().set_pause(true)
			yield(get_tree().create_timer(3), "timeout")
			get_tree().set_pause(false)
			end_round()
		
func end_round():
	if has_node("/root/World"):
		get_node('/root/World').queue_free()
	players_loaded.clear()
	current_round += 1
	if current_round > ROUNDS:
		end_game(true)
	else:
		if is_network_master():
			var timer = Timer.new()
			timer.set_autostart(true)
			timer.set_one_shot(true)
			timer.set_wait_time(0.05)
			timer.connect("timeout", self, 'set_spawn_points')
			add_child(timer)
			print('started spawning')
		
	
func end_game(normaly):
	current_round = 1
	game_in_progress = false
	if normaly:
		get_tree().change_scene('res://scenes/screens/ResultScreen.tscn')
	else:
		if has_node("/root/World"):
			get_node('/root/World').queue_free()
		get_tree().change_scene('res://scenes/screens/LobbyScreen.tscn')
		reset_score()
		
func reset_lobby_variables():
	players.clear()
	players_loaded.clear()
	available_avatars = ['ship_blue.png', 'ship_green.png', 'ship_orange.png', 'ship_purple.png', 'ship_red.png', 'ship_tyrk.png', 'ship_yellow.png']
	current_round = 1
	game_in_progress = false
	
func reset_score():
	for p in Lobby.players:
		Lobby.players[p][3] = 0
		Lobby.players[p][3] = 0
		if p != 1:
			Lobby.players[p][1] = false
	
