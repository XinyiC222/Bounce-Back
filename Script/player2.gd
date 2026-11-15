extends CharacterBody2D

@export var action_prefix := "p2_"      # "" for player 1, "p2_" for player 2
@export var controlled := true

@export var speed := 400.0
@export var acceleration := 4000.0
@export var friction := 5000.0
@export var air_control := 0.6

@export var gravity := 3000.0
@export var fall_gravity_multiplier := 1.6
@export var max_fall_speed := 1800.0

@export var jump_strength := 800.0
@export var jump_cut := 0.4
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.1

@export var ability_item := "lasso"
@export var grapple_speed := 1200.0

@export var anim_prefix := "p2_"   # "" = knight, "p2_" = cowboy
@onready var _anim: AnimatedSprite2D = %AnimatedSprite2D


@export var hold_repeat_delay := 0.25   # seconds on the ground before holding repeats the jump
var _grounded_hold := 0.0

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0

var _grappling := false
var _grapple_target := Vector2.ZERO
var _grapple_time := 0.0

func _ready() -> void:
	add_to_group("player")

func can_use_ability() -> bool:
	return ability_item != "" and Inventory.has(ability_item)


func _physics_process(delta: float) -> void:
	# While grappling, only the grapple moves us
	if _grappling:
		_do_grapple(delta)
		return

	# Use the tool (lasso)
	if controlled and Input.is_action_just_pressed(action_prefix + "use"):
		_try_grapple()

	# Input only counts when this character is the controlled one
	var direction := 0.0
	var jump_held := false
	var jump_pressed := false
	if controlled:
		direction = Input.get_axis(action_prefix + "left", action_prefix + "right")
		jump_held = Input.is_action_pressed(action_prefix + "jump")
		jump_pressed = Input.is_action_just_pressed(action_prefix + "jump")

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
	if is_on_floor() or _touching_hook():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if is_on_floor() and jump_held:
		_grounded_hold += delta
	else:
		_grounded_hold = 0.0

	# a fresh press always counts; holding only repeats after the delay
	if jump_pressed or (jump_held and _grounded_hold >= hold_repeat_delay):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta
	# jump
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = -jump_strength
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	move_and_slide()
	_update_animation()


func _try_grapple() -> void:
	if not can_use_ability():
		print("can't use: item missing or wrong character")
		return
	var hook := _find_hook()
	if hook == null:
		print("no hook in reach")
		return
	print("grapple started")
	_grappling = true
	_grapple_time = 0.0
	_grapple_target = hook.global_position


func _find_hook() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for h in get_tree().get_nodes_in_group("hook"):
		if h.required_item != ability_item:
			continue
		var d := global_position.distance_to(h.global_position)
		if d <= h.reach and d < best_dist:
			best = h
			best_dist = d
	return best


func _do_grapple(delta: float) -> void:
	_anim.play(anim_prefix + "jump")
	_grapple_time += delta
	var to_target := _grapple_target - global_position
	var step := grapple_speed * delta
	if to_target.length() <= step or _grapple_time > 1.5:
		global_position = _grapple_target
		_grappling = false
		velocity = Vector2(0, -jump_strength * 0.5)   # small hop on arrival
		return
	global_position += to_target.normalized() * step

func _touching_hook() -> bool:
	for h in get_tree().get_nodes_in_group("hook"):
		if global_position.distance_to(h.global_position) <= h.touch_radius:
			return true
	return false

func _update_animation() -> void:
	if absf(velocity.x) > 10.0:
		_anim.flip_h = velocity.x < 0.0

	var state := "idle"
	if not is_on_floor():
		state = "jump"
	elif absf(velocity.x) > 10.0:
		state = "run"

	var anim_name := anim_prefix + state
	if _anim.animation != anim_name:
		_anim.play(anim_name)
