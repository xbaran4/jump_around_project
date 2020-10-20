extends Area2D
var orientation
const MOTION = 0.5
onready var viewport_size = get_viewport().get_visible_rect().size
#puppet var puppet_position = Vector2()

func _physics_process(delta):
	if orientation:
#		rset_unreliable('puppet_position', position)
		position.y = position.y - MOTION
		if position.y < -50:
			queue_free()
	else:
#		rset_unreliable('puppet_position', position)
		position.y = position.y + MOTION
		if position.y > viewport_size.y + 50:
			queue_free()
		
remotesync func delete():
	queue_free()
