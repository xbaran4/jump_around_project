extends "res://scripts/elements/Element.gd"
var latest_bodies = []
onready var animation = $Sprite/AnimationPlayer
func _on_Reverse_body_entered(body):
	if body in latest_bodies:
		return
	if body.is_network_master():
		if body.has_method('flip'):
			rpc('animate')
			body.rpc('flip')
			start_timer(body)
			
func start_timer(body):
	latest_bodies.append(body)
	var timer = Timer.new()
	timer.set_wait_time(0.5)
	timer.set_one_shot(true)
	timer.set_autostart(true)
	timer.connect("timeout", self, "reverse_cooldown_timout",[body, timer])
	add_child(timer, true)

func reverse_cooldown_timout(body, timer):
	if body in latest_bodies:
		latest_bodies.erase(body)
	timer.queue_free()

remotesync func animate():
	animation.play('Scale Animation')
