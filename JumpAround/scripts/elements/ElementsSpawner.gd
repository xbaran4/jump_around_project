extends Node
const damager = preload("res://scenes/elements/Damager.tscn")
const orb = preload("res://scenes/elements/Orb.tscn")
const reverser = preload("res://scenes/elements/Reverser.tscn")
const speedup = preload("res://scenes/elements/SpeedUp.tscn")
var spawn_interval = 4
onready var viewport_size = get_viewport().get_visible_rect().size
onready var element_number = 0
var element

func start_spawn():
		var timer = Timer.new()
		timer.set_wait_time(spawn_interval)
		timer.set_autostart(true)
		timer.connect("timeout", self, "spawn")
		add_child(timer, true)
			
func spawn():
	randomize()
	var element_id = randi() % 4
	var element_orientation = bool(randi() % 2)
	var element_position = rand_range(20, viewport_size.x - 20)
	rpc('spawn_element', element_id, element_orientation, element_position)

remotesync func spawn_element(element_id, element_orientation, element_position):
	match element_id:
		0:
			element = damager.instance()
		1:
			element = orb.instance()
		2:
			element = reverser.instance()
		3:
			element = speedup.instance()
			
	if element_orientation:
		element.position.y = viewport_size.y + 10
	else:
		element.position.y = -10
	element.orientation = element_orientation
	element.position.x = element_position
	element.set_name(element.name + str(element_number))
	element_number = element_number + 1
	add_child(element)
			