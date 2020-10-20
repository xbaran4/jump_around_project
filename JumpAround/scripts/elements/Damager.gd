extends "res://scripts/elements/Element.gd"
onready var sprite = get_node('Sprite') 

func _physics_process(delta):
	sprite.rotation += 0.5 * delta


func _on_Damager_body_entered(body):
	if body.is_network_master():
		if body.has_method("hit"):
				body.rpc('hit')