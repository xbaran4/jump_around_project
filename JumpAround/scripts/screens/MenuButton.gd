extends TextureButton
onready var label = $Label

func _on_MenuButton_button_down():
	label.add_color_override('font_color', Color('FFD311'))


func _on_MenuButton_button_up():
	label.add_color_override('font_color', Color('ffffff'))