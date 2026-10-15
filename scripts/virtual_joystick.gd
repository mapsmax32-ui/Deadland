extends Control

signal direction_changed(direction: Vector2)

@export var radius := 68.0
@export var dead_zone := 0.14
var finger_id := -1
var direction := Vector2.ZERO
var knob_position := Vector2.ZERO
var active := false

func _ready() -> void:
    custom_minimum_size = Vector2(radius * 2.5, radius * 2.5)
    mouse_filter = Control.MOUSE_FILTER_STOP
    knob_position = size * 0.5
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and finger_id == -1:
            finger_id = event.index
            active = true
            _update_from_position(event.position)
            accept_event()
        elif not event.pressed and event.index == finger_id:
            finger_id = -1
            active = false
            direction = Vector2.ZERO
            knob_position = size * 0.5
            direction_changed.emit(direction)
            queue_redraw()
            accept_event()
    elif event is InputEventScreenDrag and event.index == finger_id:
        _update_from_position(event.position)
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            active = true
            _update_from_position(event.position)
        else:
            active = false
            direction = Vector2.ZERO
            knob_position = size * 0.5
            direction_changed.emit(direction)
            queue_redraw()
    elif event is InputEventMouseMotion and active:
        _update_from_position(event.position)

func _update_from_position(local_pos: Vector2) -> void:
    var center := size * 0.5
    var offset := local_pos - center
    if offset.length() > radius:
        offset = offset.normalized() * radius
    knob_position = center + offset
    direction = offset / radius
    if direction.length() < dead_zone:
        direction = Vector2.ZERO
    direction_changed.emit(direction)
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, radius, Color(0.08, 0.09, 0.08, 0.58))
    draw_arc(center, radius, 0, TAU, 64, Color(0.8, 0.82, 0.75, 0.7), 3.0)
    draw_circle(knob_position, radius * 0.42, Color(0.72, 0.74, 0.66, 0.82))
