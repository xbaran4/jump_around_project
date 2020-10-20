extends Control
onready var connect_popup = $ConnectPopup
onready var disconnected_popup = $DisconnectedPopup
onready var about_popup = $AboutPopup
onready var ip_line = $ConnectPopup/MarginContainer/VBoxContainer/IPLineEdit
onready var con_label = $ConnectPopup/MarginContainer/VBoxContainer/ConnectionLabel
onready var ok_button = $ConnectPopup/MarginContainer/VBoxContainer/HSplitContainer/OKButton
onready var cancel_button = $ConnectPopup/MarginContainer/VBoxContainer/HSplitContainer/CancelButton

func _ready():
	Lobby.connect("connection_succeeded", self, "on_connection_success")
	Lobby.connect("connection_failed", self, "on_connection_failed")
	
func _on_JoinButton_pressed():
	$ConnectPopup/AnimationPlayer.play("PopupAnim")

func _on_CreateButton_pressed():
	Lobby.create_server()
	get_tree().change_scene("res://scenes/screens/LobbyScreen.tscn")
	
func _on_QuitButton_pressed():
	 get_tree().quit()

func _on_AboutButton_pressed():
	$AboutPopup/AnimationPlayer.play("AboutPopup")

func _on_CancelButton_pressed():
	connect_popup.hide()
	con_label.set_text('')
	con_label.set_visible(false)

func _on_OKButton_pressed():
	con_label.set_visible(true)
	if (not ip_line.get_text().is_valid_ip_address()):
		con_label.set_text('Invalid IP entered')
		return
	Lobby.connect_to_server(ip_line.get_text())
	ok_button.set_disabled(true)
	cancel_button.set_disabled(true)
	con_label.set_text('Connecting...')

func on_connection_success():
	get_tree().change_scene("res://scenes/screens/LobbyScreen.tscn")

func on_connection_failed():
	ok_button.set_disabled(false)
	cancel_button.set_disabled(false)
	con_label.set_text('Connection FAILED')

func popup_disconnect():
	$DisconnectedPopup/AnimationPlayer.play("DisconnectPopup")
