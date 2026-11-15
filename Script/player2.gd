extends CharacterBody2D

@export var action_prefix := "p2_"      # "" for player 1, "p2_" for player 2
@export var controlled := true       

@export var speed := 600.0
@export var acceleration := 4000.0
@export var friction := 5000.0
@export var air_control := 0.6

@export var gravity := 3000.0
@export var fall_gravity_multiplier := 1.6
@export var max_fall_speed := 1800.0

@export var jump_strength := 1000.0
@export var jump_cut := 0.4
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.1

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0


func _physics_process(delta: float) -> void:
	# Input only counts when this character is the controlled one
	var direction := 0.0
	var jump_held := false
	if controlled:
		direction = Input.get_axis(action_prefix + "left", action_prefix + "right")
		jump_held = Input.is_action_pressed(action_prefix + "jump")

	# movement
	var control := 1.0 if is_on_floor() else air_control
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)

	# gravity
	var g := gravity
	if velocity.y > 0.0:
		g *= fall_gravity_multiplier
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)

	# timers
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if jump_held:
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta

	# jump
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = -jump_strength
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	move_and_slide()
