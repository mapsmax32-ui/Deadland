extends CharacterBody3D

@export var move_speed := 4.0
@export var acceleration := 18.0
var touch_direction := Vector2.ZERO

func set_touch_direction(direction: Vector2) -> void:
    touch_direction = direction

func _physics_process(delta: float) -> void:
    var keyboard := Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    )
    var input_dir := keyboard
    if touch_direction.length() > 0.05:
        input_dir = touch_direction
    if input_dir.length() > 1.0:
        input_dir = input_dir.normalized()
    var direction := Vector3(input_dir.x, 0, input_dir.y)
    velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
    velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
    if not is_on_floor():
        velocity.y -= 20.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func _ready() -> void:
    _ensure_key_action("move_up", KEY_W)
    _ensure_key_action("move_down", KEY_S)
    _ensure_key_action("move_left", KEY_A)
    _ensure_key_action("move_right", KEY_D)
    _ensure_key_action("move_up", KEY_UP)
    _ensure_key_action("move_down", KEY_DOWN)
    _ensure_key_action("move_left", KEY_LEFT)
    _ensure_key_action("move_right", KEY_RIGHT)
    _ensure_key_action("interact", KEY_E)
    _ensure_key_action("attack", KEY_SPACE)

func _ensure_key_action(action: String, keycode: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var ev := InputEventKey.new()
    ev.physical_keycode = keycode
    if not InputMap.action_has_event(action, ev):
        InputMap.action_add_event(action, ev)
