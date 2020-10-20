extends KinematicBody2D
const SPEED = 320
const GRAVITY = 35
const JUMP_HEIGHT = 900
const DOWN_TIME = 3
const STAT_TIME = 1
const IMMORTAL_TIME = 1
var jump_index = JUMP_HEIGHT
var motion = Vector2()
var can_jump = true
var is_down = false
var direction = true
var health = 3
var orbs = 0
onready var down_timer = get_node("Timers/DownTimer")
onready var stat_timer = get_node("Timers/StatTimer")
onready var shield_timer = get_node("Timers/ShieldTimer")
onready var immortal_timer = get_node("Timers/ImmortalTimer")
onready var ship_sprite = get_node("ShipSprite")
onready var engine_particles = get_node('ShipSprite/Particles/EngineParticles')
onready var jump_particles = get_node('ShipSprite/Particles/JumpParticles')
onready var hit_particles = get_node('ShipSprite/Particles/HitParticles')
onready var shield_sprite = get_node('ShipSprite/ShieldSprite')
onready var stat_sprite = get_node('ShipSprite/StatSprite')
onready var knockout_area = get_node('KockoutArea')
onready var tween = get_node('Tween')
var delta_counter = 0

func _ready():
	connect('tree_exited',get_node("/root/Lobby"),'check_end_round')
	motion.x = SPEED
	
	down_timer.set_wait_time(DOWN_TIME)
	down_timer.connect("timeout",self,"on_down_timer_timeout")
	stat_timer.set_wait_time(STAT_TIME)
	stat_timer.connect("timeout",self,"on_stat_timer_timeout")
	shield_timer.set_wait_time(IMMORTAL_TIME)
	shield_timer.connect("timeout",self,"on_shield_timer_timeout")
	immortal_timer.set_wait_time(IMMORTAL_TIME)
	immortal_timer.connect("timeout",self,"on_immortal_timer_timeout")

remotesync func add_coin():
	orbs = orbs + 1
	if orbs >= 3:
		health = health + 1
		orbs = 0
	set_stat_visible()
	Lobby.players[self.get_network_master()][4] += 1


remotesync func hit():
	if is_down:
		return
	set_collision_mask_bit(2, false)
	health = health - 1
	motion.x = 0
	if health < 1:	
		rpc('knock_out')
	is_down = true
	can_jump = false
	engine_particles.emitting = false
	hit_particles.set_emitting(true)
	set_immortal()
	set_stat_visible()
	down_timer.start()
	
remotesync func initial_jump():
	motion.x = SPEED if direction else -SPEED
	is_down = false
	set_collision_mask_bit(2, true)
	engine_particles.emitting = true
	enable_shield()
	set_immortal()
	
remotesync func jump():
	jump_particles.emitting = true
	jump_particles.restart()
	motion.y = -jump_index
	jump_index += JUMP_HEIGHT
	motion = move_and_slide(motion, Vector2(0,-1))

remotesync func bounce():
	motion.y = -JUMP_HEIGHT / 2
		
remotesync func flip():
	ship_sprite.set_flip_h(direction)
	direction = !direction
	engine_particles.rotation_degrees = 180 if direction else 0
	engine_particles.position.x *= -1  
	
	if !is_down:
		motion.x = SPEED if direction else -SPEED
		
remotesync func speed_up():
	if !is_down:
		motion.x = SPEED * 2 if direction else - SPEED * 2
		engine_particles.set_speed_scale(15.0)

remotesync func speed_down():
	if !is_down:
		motion.x = SPEED if direction else -SPEED
		engine_particles.set_speed_scale(1.0)

func on_down_timer_timeout():
	can_jump = true
	hit_particles.set_emitting(false)

func _input(event):
	if is_network_master():
		if event is InputEventScreenTouch and event.is_pressed():
			if can_jump:
				if is_down:
					rpc('initial_jump')
				rpc('jump')
			else:
				rpc('flip')

func _physics_process(delta):
	delta_counter += delta
	motion.y += GRAVITY
	if is_network_master():
		if is_on_wall():
			rpc('flip')
		elif (is_on_ceiling() or is_on_floor()) and !is_down:
			rpc('hit')
			
		motion = move_and_slide(motion, Vector2(0,-1))	
		
		if delta_counter > 0.032:
			rpc_unreliable('update_pos', position)
			delta_counter = 0
			
	if jump_index > JUMP_HEIGHT:
		jump_index -= 70
	if motion.x == 0 and !is_down:
		motion.x = SPEED if direction else -SPEED
		
	if motion.x > 1:
		ship_sprite.set_rotation_degrees(motion.y / 80)
	elif motion.x < -1:
		ship_sprite.set_rotation_degrees(-motion.y / 80)
	else:
		ship_sprite.set_rotation_degrees(0)
		

remote func update_pos(updated_position):
	tween.interpolate_property(self,'position', null, updated_position, 0.035,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	tween.start()
	
remotesync func knock_out():
	queue_free()
	
func set_stat_visible():
	stat_sprite.get_node("StatLabel").set_text(str(health))
	stat_sprite.set_visible(true)
	stat_timer.start()
	
func on_stat_timer_timeout():
	stat_sprite.set_visible(false)
	
func enable_shield():
	set_collision_mask_bit(4, false)
	shield_sprite.set_visible(true)
	shield_timer.start()
	
func on_shield_timer_timeout():
	set_collision_mask_bit(4, true)
	shield_sprite.set_visible(false)
	
func set_immortal():
	knockout_area.set_collision_layer_bit(9, false)
	knockout_area.set_collision_mask_bit(9, false)
	immortal_timer.start()
	
func on_immortal_timer_timeout():
	knockout_area.set_collision_layer_bit(9, true)
	knockout_area.set_collision_mask_bit(9, true)

func set_winner():
	$WinningLabel.set_visible(true)
	$ShipSprite/Particles/WinningParticles.set_emitting(true)
	
func _on_KockoutArea_area_entered(area):
	if is_down:
		return
	if is_network_master():
		if area.get_parent().position.y > self.position.y:
			rpc('bounce')
			if area.get_parent().is_down:
				area.get_parent().rpc('knock_out')
			else:
				area.get_parent().rpc('hit')
