extends Camera2D
class_name HybridCamera

# ==================== FOLLOW MODE ====================
@export var ball_group: String = "ball"
@export var follow_speed: float = 5.0
@export var look_ahead_factor: float = 0.35
@export var min_distance_to_snap: float = 4.0

# ==================== FREE MODE ====================
@export_range(1, 20, 0.01) var maxZoom : float = 5.0
@export_range(0.01, 1, 0.01) var minZoom : float = 0.1
@export_range(0.01, 0.2, 0.01) var zoomStepRatio : float = 0.1
@export var baseKeyboardPanSpeed : float = 350

@export_group("Actions")
@export var panAction : String = "pan"
@export var zoomInAction : String = "zoom_in"
@export var zoomOutAction : String = "zoom_out"

@export_group("Mouse")
@export var zoomToCursor: bool = true
@export_enum("Auto", "Always", "Never") var useFallbackButtons: String = "Auto"
@export var panButton : MouseButton = MOUSE_BUTTON_MIDDLE
@export var zoomInButton : MouseButton = MOUSE_BUTTON_WHEEL_UP
@export var zoomOutButton : MouseButton = MOUSE_BUTTON_WHEEL_DOWN

@export_group("Smoothing")
@export_range(0, 0.99, 0.01) var panSmoothing : float = 0.5:
	set(new_value): panSmoothing = pow(new_value, slider_exponent)
	get: return panSmoothing
@export_range(0, 0.99, 0.01) var zoomSmoothing : float = 0.5:
	set(new_value): zoomSmoothing = pow(new_value, slider_exponent)
	get: return zoomSmoothing

const slider_exponent : float = 0.25
const referenceFPS : float = 120.0

# ==================== HYBRID SETTINGS ====================
@export var inactivity_timeout: float = 4.0
@export var snap_on_drag_start: bool = true
@export var tap_threshold_time: float = 0.25
@export var tap_threshold_dist: float = 12.0

# Internal
enum CameraMode { FREE, FOLLOW }
var current_mode: CameraMode = CameraMode.FREE

var target: Node2D = null
var drag_launcher = null

# Free-mode state
@onready var zoom_goal := zoom
@onready var position_goal := position
var fallback_mouse_pan := false
var fallback_mouse_zoom_in := false
var fallback_mouse_zoom_out := false
var last_mouse := Vector2.ZERO
var zoom_mouse := Vector2.ZERO

var inactivity_timer := 0.0

# Reset on death / level start
var initial_position: Vector2
var initial_zoom: Vector2
var was_launched_last_frame: bool = false

# Middle-click tap detection
var pan_press_time: float = 0.0
var pan_press_start_pos: Vector2

func _ready() -> void:
	make_current()
	find_ball()
	
	panSmoothing = panSmoothing
	zoomSmoothing = zoomSmoothing
	
	# === NEW: Start centered on the ball (and save this as the "reset" view) ===
	if target:
		position = target.global_position
		position_goal = position
	initial_position = position
	initial_zoom = zoom
	
	# Setup safe fallbacks
	var actions = InputMap.get_actions()
	var always = useFallbackButtons == "Always"
	var never = useFallbackButtons == "Never"
	fallback_mouse_pan = not never and (always or (panAction not in actions))
	fallback_mouse_zoom_in = not never and (always or (zoomInAction not in actions))
	fallback_mouse_zoom_out = not never and (always or (zoomOutAction not in actions))

func find_ball() -> void:
	var balls = get_tree().get_nodes_in_group(ball_group)
	if balls.size() > 0:
		target = balls[0] as Node2D
		if target:
			drag_launcher = target.get_node_or_null("DragLauncher")
			was_launched_last_frame = target.has_been_launched

func _process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		find_ball()
		return
	
	# Detect death/respawn
	if was_launched_last_frame and not target.has_been_launched:
		reset_to_start()
	was_launched_last_frame = target.has_been_launched
	
	var is_interacting = _is_user_interacting()
	
	if is_interacting:
		inactivity_timer = 0.0
		if current_mode == CameraMode.FOLLOW:
			current_mode = CameraMode.FREE
			position_goal = position
	
	# Drag-to-shoot snaps to follow
	if snap_on_drag_start and drag_launcher and drag_launcher.is_dragging and not is_interacting:
		if current_mode != CameraMode.FOLLOW:
			current_mode = CameraMode.FOLLOW
	
	# Inactivity timeout
	if current_mode == CameraMode.FREE:
		inactivity_timer += delta
		if inactivity_timer >= inactivity_timeout:
			current_mode = CameraMode.FOLLOW
			inactivity_timer = 0.0
	
	_update_zoom(delta)
	
	if current_mode == CameraMode.FOLLOW:
		_do_follow(delta)
	else:
		_do_free_pan(delta)

func reset_to_start() -> void:
	current_mode = CameraMode.FREE
	position_goal = initial_position
	zoom_goal = initial_zoom
	position = initial_position
	zoom = initial_zoom
	inactivity_timer = 0.0

func _update_zoom(delta: float) -> void:
	var k_zoom := pow(zoomSmoothing, referenceFPS * delta)
	var mouse_pre := to_local(get_canvas_transform().affine_inverse().basis_xform(zoom_mouse))
	zoom = zoom * k_zoom + (1.0 - k_zoom) * zoom_goal
	var mouse_post := to_local(get_canvas_transform().affine_inverse().basis_xform(zoom_mouse))
	
	var zoom_offset := (mouse_pre - mouse_post) if zoomToCursor else Vector2.ZERO
	if zoom_offset != Vector2.ZERO:
		position += zoom_offset

func _do_follow(delta: float) -> void:
	var ball_vel = target.velocity
	var ball_pos = target.global_position
	var lookahead = ball_vel.normalized() * ball_vel.length() * look_ahead_factor * 0.001
	var desired = ball_pos + lookahead
	
	if global_position.distance_to(desired) > min_distance_to_snap:
		global_position = global_position.lerp(desired, follow_speed * delta)
	else:
		global_position = global_position.lerp(desired, 0.8 * delta)

func _do_free_pan(delta: float) -> void:
	var k_pan := pow(panSmoothing, referenceFPS * delta)
	
	var pan_input := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	var effective_zoom = zoom_goal.x
	var pan_speed = baseKeyboardPanSpeed / effective_zoom * (2.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	position_goal += pan_input * pan_speed * delta
	
	position = position * k_pan + (1.0 - k_pan) * position_goal

func _is_user_interacting() -> bool:
	var pan_pressed = InputMap.has_action(panAction) and Input.is_action_pressed(panAction)
	var zoom_in_pressed = InputMap.has_action(zoomInAction) and Input.is_action_just_pressed(zoomInAction)
	var zoom_out_pressed = InputMap.has_action(zoomOutAction) and Input.is_action_just_pressed(zoomOutAction)
	
	return (
		pan_pressed or
		(fallback_mouse_pan and Input.is_mouse_button_pressed(panButton)) or
		zoom_in_pressed or
		zoom_out_pressed
	)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouse or event is InputEventAction):
		return
	
	var current_mouse := get_local_mouse_position()
	
	# Middle-click tap → FOLLOW mode
	if event is InputEventMouseButton and event.button_index == panButton:
		if event.pressed:
			pan_press_time = Time.get_ticks_msec() / 1000.0
			pan_press_start_pos = current_mouse
		else:
			var hold_time = (Time.get_ticks_msec() / 1000.0) - pan_press_time
			var move_dist = (current_mouse - pan_press_start_pos).length()
			if hold_time < tap_threshold_time and move_dist < tap_threshold_dist:
				current_mode = CameraMode.FOLLOW
	
	# Force FREE mode on any zoom input
	if (InputMap.has_action(zoomInAction) and Input.is_action_just_pressed(zoomInAction)) or \
	   (InputMap.has_action(zoomOutAction) and Input.is_action_just_pressed(zoomOutAction)):
		if current_mode == CameraMode.FOLLOW:
			current_mode = CameraMode.FREE
			position_goal = position
	
	# Normal pan (holding + dragging)
	if (InputMap.has_action(panAction) and Input.is_action_pressed(panAction)) or \
	   (fallback_mouse_pan and Input.is_mouse_button_pressed(panButton)):
		position_goal += (last_mouse - current_mouse)
	
	# Zoom input
	if Input.is_action_just_pressed(zoomInAction) or (fallback_mouse_zoom_in and Input.is_mouse_button_pressed(zoomInButton)):
		zoom_goal *= 1.0 / (1.0 - zoomStepRatio)
		zoom_mouse = get_viewport().get_mouse_position() - get_viewport_rect().size * 0.5
	
	if Input.is_action_just_pressed(zoomOutAction) or (fallback_mouse_zoom_out and Input.is_mouse_button_pressed(zoomOutButton)):
		zoom_goal *= (1.0 - zoomStepRatio)
		zoom_mouse = get_viewport().get_mouse_position() - get_viewport_rect().size * 0.5
	
	zoom_goal = zoom_goal.clamp(minZoom * Vector2.ONE, maxZoom * Vector2.ONE)
	last_mouse = current_mouse
