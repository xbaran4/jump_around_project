extends "res://scripts/elements/Element.gd"

func _on_Bonus_body_entered(body):
	if body.is_network_master():
		if body.has_method("add_coin"):
			body.rpc('add_coin')
			rpc('delete')