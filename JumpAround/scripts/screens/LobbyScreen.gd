extends Node
onready var start_button = $MarginContainer/HBoxContainer/MarginContainer/StartButton
onready var start_button_label = $MarginContainer/HBoxContainer/MarginContainer/StartButton/Label
onready var player_list = $MarginContainer/HBoxContainer/VSplitContainer/MarginContainer/Panel/PlayerList
onready var player_name_edit = $MarginContainer/HBoxContainer/MarginContainer2/VSplitContainer2/HSplitContainer/NameEdit
onready var avatar_texture = $MarginContainer/HBoxContainer/MarginContainer2/VSplitContainer2/HSplitContainer2/AvatarTexture
var my_unique_id
var my_item_list_idx = 0
var am_ready = false

func _ready():
	my_unique_id = get_tree().get_network_unique_id()
	Lobby.connect('connection_failed', self, '_on_connection_failed')
	Lobby.connect('connection_succeeded', self, '_on_connection_success')
	Lobby.connect('player_list_changed', self, 'refresh_lobby')
	Lobby.connect('enable_start', self, 'on_enable_start')
	Lobby.connect('disable_start', self, 'on_disable_start')
	
	if is_network_master():
		start_button.set_disabled(true)
	else:
		start_button_label.set_text('Ready')
	refresh_lobby()
	
	
# Refresh player list and take care of name colors and avatars
func refresh_lobby():
	var players = Lobby.players
	player_list.clear()
	var item_idx = 0
	for p in players:
		if p == my_unique_id:
			player_list.add_item(players[p][0] + ' (You)')
			my_item_list_idx = item_idx
		else:
			player_list.add_item(players[p][0])
		if players[p][1]:
			player_list.set_item_custom_fg_color(item_idx, Color(0.0, 1.0, 0.0))
		else:
			player_list.set_item_custom_fg_color(item_idx, Color(1.0, 0.0, 0.0))
		item_idx += 1
		avatar_texture.set_texture(load('res://Sprites/ships/' + players[my_unique_id][2]))

# Start the game or set peer ready
func _on_StartButton_pressed():
	if is_network_master():
		Lobby.set_spawn_points()
	else:
		if am_ready:
			Lobby.rpc('toggle_lobby_ready', my_unique_id, !am_ready)
			start_button_label.set_text('Ready')
			am_ready = false
		else:
			Lobby.rpc('toggle_lobby_ready', my_unique_id, !am_ready)
			start_button_label.set_text('Unready')
			am_ready = true
		refresh_lobby()		

func _on_SetNameButton_pressed():
	var new_name = player_name_edit.get_text()
	if new_name.length() < 3:
		return
	Lobby.rpc('change_player_name', player_name_edit.get_text(), my_unique_id)

# Aske server for another avatar
func _on_NextTextureButton_pressed():
	Lobby.rpc('change_avatar', my_unique_id)
	
	# Leave the lobby
func _on_ExitButton_pressed():
	Lobby.exit_lobby(false)

func on_enable_start():
	start_button.set_disabled(false)
	
func on_disable_start():
	start_button.set_disabled(true)
	
func on_game_error(error_text):
	pass