extends "res://scripts/elements/Element.gd"
onready var animation = $Sprite/AnimationPlayer
func _on_SpeedUp_body_entered(body):
	if body.is_network_master():
		if body.has_method('speed_up'):
			rpc('animate')
			body.rpc('speed_up')
			start_timer(body)

func start_timer(body):
	var timer = Timer.new()
	timer.set_wait_time(0.3)
	timer.set_one_shot(true)
	timer.set_autostart(true)
	timer.connect("timeout", self, "speed_body_down",[body, timer])
	add_child(timer, true)

func speed_body_down(body, timer):
	if body.has_method('speed_down'):
		body.rpc('speed_down')
	timer.queue_free()

remotesync func animate():
	animation.play('Scale Animation')