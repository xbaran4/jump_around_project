extends Control
onready var name_label2 = $MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer2/VBoxContainer/NameLabel
onready var name_label1 = $MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer1/VBoxContainer/NameLabel
onready var name_label3 = $MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer3/VBoxContainer/NameLabel

onready var wins_label2 = $MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer2/VBoxContainer/HSplitContainer/VSplitContainer/WinsLabel
onready var wins_label1 = $MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer1/VBoxContainer/HSplitContainer/VSplitContainer/WinsLabel
onready var wins_label3 = $MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer3/VBoxContainer/HSplitContainer/VSplitContainer/WinsLabel

onready var orbs_label2 = $MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer2/VBoxContainer/HSplitContainer/VSplitContainer/OrbsLabel
onready var orbs_label1 = $MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer1/VBoxContainer/HSplitContainer/VSplitContainer/OrbsLabel
onready var orbs_label3 = $MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer3/VBoxContainer/HSplitContainer/VSplitContainer/OrbsLabel

onready var avatar_texture2 = $MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer2/VBoxContainer/HSplitContainer/AvatarRect
onready var avatar_texture1 = $MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer1/VBoxContainer/HSplitContainer/AvatarRect
onready var avatar_texture3 = $MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer3/VBoxContainer/HSplitContainer/AvatarRect

func _ready():
	var first
	var second 
	var third
	var points_dict = {}
	for p in Lobby.players:
		points_dict[p] = Lobby.players[p][3] * 10 + Lobby.players[p][4]
	var points_arr = points_dict.values()
	var players_arr = points_dict.keys()
	if points_dict.size() > 2:
		for i in points_arr.size():
			for x in points_arr.size()-1:
				if points_arr[x] < points_arr[x+1]:
					
					var temp = points_arr[x]
					points_arr[x] = points_arr[x+1]
					points_arr[x+1] = temp
					
					temp = players_arr[x]
					players_arr[x] = players_arr[x+1]
					players_arr[x+1] = temp
					
		first = players_arr[0]
		second = players_arr[1]
		third = players_arr[2]
	else:
		if points_arr[1] > points_arr[0]:
			first = players_arr[1]
			second = players_arr[0]
		else:
			first = players_arr[0]
			second = players_arr[1]
	
	name_label1.set_text(str(Lobby.players[first][0]))
	name_label2.set_text(str(Lobby.players[second][0]))
	
	wins_label1.set_text('Wins:' + str(Lobby.players[first][3]))
	wins_label2.set_text('Wins:' + str(Lobby.players[second][3]))
	
	orbs_label1.set_text('Orbs:' + str(Lobby.players[first][4]))
	orbs_label2.set_text('Orbs:' + str(Lobby.players[second][4]))
	
	avatar_texture1.set_texture(load('res://Sprites/ships/' + Lobby.players[first][2]))
	avatar_texture2.set_texture(load('res://Sprites/ships/' + Lobby.players[second][2]))
	

	if Lobby.players.size() > 2:
		$MarginContainer/VSplitContainer/HBoxContainer/PlacementContainer3.set_visible(true)
		name_label3.set_text(str(Lobby.players[third][0]))
		wins_label3.set_text('Wins:' + str(Lobby.players[third][3]))
		orbs_label3.set_text('Orbs:' + str(Lobby.players[third][4]))
		avatar_texture3.set_texture(load('res://Sprites/ships/' + Lobby.players[third][2]))
		
	Lobby.reset_score()

func _on_LobbyButton_pressed():
	get_tree().change_scene('res://scenes/screens/LobbyScreen.tscn')

func _on_MenuButton_pressed():
	Lobby.exit_lobby(false)
