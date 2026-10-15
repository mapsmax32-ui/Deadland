extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var status_label: Label
var message_label: Label
var choice_panel: PanelContainer
var stranger_saved := false
var supplies_taken := false
var health := 100
var stamina := 100.0
var interact_target: StaticBody3D
var zombie: CharacterBody3D
var zombie_speed := 1.5
var game_over := false

func _ready() -> void:
    _make_world()
    _make_player()
    _make_zombie()
    _make_npc()
    _make_hud()
    _update_status()
    message_label.text = "День 12. Найди припасы и реши, что делать с незнакомцем."

func _process(delta: float) -> void:
    if game_over:
        return
    _update_camera()
    _update_zombie(delta)
    _update_status()
    if Input.is_action_just_pressed("interact"):
        _interact()
    if Input.is_action_just_pressed("attack"):
        _attack()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_E:
            _interact()
        elif event.keycode == KEY_SPACE:
            _attack()

func _make_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.07, 0.085, 0.075)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.7, 0.75, 0.68)
    environment.ambient_light_energy = 0.8
    env.environment = environment
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.light_energy = 1.1
    add_child(sun)
    _box("Ground", Vector3(0, -0.25, 0), Vector3(30, 0.5, 30), Color(0.22, 0.25, 0.20))
    _box("Road", Vector3(0, 0.015, -4), Vector3(26, 0.04, 4.0), Color(0.12, 0.13, 0.12))
    for x in range(-11, 12, 4):
        _box("RoadMarking", Vector3(float(x), 0.04, -4), Vector3(1.5, 0.025, 0.08), Color(0.7, 0.65, 0.43))
    _box("AbandonedShop", Vector3(-6, 1.2, 2), Vector3(5, 2.4, 4), Color(0.35, 0.30, 0.24))
    _box("ShopRoof", Vector3(-6, 2.48, 2), Vector3(5.3, 0.18, 4.3), Color(0.17, 0.19, 0.17))
    _box("Motel", Vector3(7, 1.0, 5), Vector3(4, 2, 5), Color(0.38, 0.34, 0.29))
    _box("MotelRoof", Vector3(7, 2.08, 5), Vector3(4.3, 0.18, 5.3), Color(0.2, 0.18, 0.16))
    _box("CarA", Vector3(-2.0, 0.35, -3.0), Vector3(2.1, 0.7, 1.0), Color(0.28, 0.19, 0.16))
    _box("CarB", Vector3(3.0, 0.35, -4.8), Vector3(2.1, 0.7, 1.0), Color(0.16, 0.22, 0.24))
    _box("SupplyCrate", Vector3(4.8, 0.35, 1.2), Vector3(0.8, 0.7, 0.8), Color(0.43, 0.29, 0.14))
    _box("SupplyCrate2", Vector3(5.6, 0.25, 1.5), Vector3(0.65, 0.5, 0.65), Color(0.36, 0.25, 0.13))
    for p in [Vector3(-10,0,-1), Vector3(-10,0,5), Vector3(11,0,-1), Vector3(11,0,2), Vector3(0,0,8), Vector3(-3,0,9)]:
        _make_tree(p)

func _make_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 0.9, 2)
    player.set_script(load("res://scripts/player_controller.gd"))
    add_child(player)
    var model_path := "res://assets/models/characters/survivor.glb"
    var model_resource := load(model_path) as PackedScene if ResourceLoader.exists(model_path) else null
    if model_resource != null:
        var character_model := model_resource.instantiate() as Node3D
        if character_model != null:
            character_model.name = "SurvivorVisual"
            # The GLB stores its mesh at centimeter scale; compensate while keeping the scene's axis conversion.
            character_model.position = Vector3(0, -0.8, 0)
            character_model.scale = Vector3(100, 100, 100)
            player.add_child(character_model)
        else:
            _make_fallback_player_visual()
    else:
        _make_fallback_player_visual()
    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.32
    shape.height = 1.6
    col.shape = shape
    player.add_child(col)
    camera = Camera3D.new()
    camera.name = "ThirdPersonCamera"
    camera.projection = Camera3D.PROJECTION_PERSPECTIVE
    camera.fov = 68.0
    add_child(camera)
    camera.current = true
    _update_camera()

func _make_fallback_player_visual() -> void:
    # Temporary placeholder until assets/models/characters/survivor.glb is copied into the project.
    var body := _make_mesh_box(Vector3(0.65, 1.2, 0.45), Color(0.23, 0.38, 0.32))
    body.position.y = 0.1
    player.add_child(body)
    var head := _make_mesh_sphere(0.25, Color(0.72, 0.57, 0.43))
    head.position.y = 0.88
    player.add_child(head)
    _add_limb(player, Vector3(-0.43, 0.12, 0), Vector3(0.18, 0.72, 0.18), Color(0.20, 0.31, 0.27), Vector3(0, 0, -0.22))
    _add_limb(player, Vector3(0.43, 0.12, 0), Vector3(0.18, 0.72, 0.18), Color(0.20, 0.31, 0.27), Vector3(0, 0, 0.22))
    _add_limb(player, Vector3(-0.20, -0.58, 0), Vector3(0.20, 0.72, 0.20), Color(0.16, 0.19, 0.18), Vector3(0, 0, -0.04))
    _add_limb(player, Vector3(0.20, -0.58, 0), Vector3(0.20, 0.72, 0.20), Color(0.16, 0.19, 0.18), Vector3(0, 0, 0.04))

func _make_zombie() -> void:
    zombie = CharacterBody3D.new()
    zombie.name = "Zombie"
    zombie.position = Vector3(5.5, 0.8, -1)
    add_child(zombie)
    var torso := _make_mesh_box(Vector3(0.65, 1.25, 0.45), Color(0.38, 0.42, 0.27))
    torso.position.y = 0.05
    zombie.add_child(torso)
    var head := _make_mesh_sphere(0.24, Color(0.43, 0.55, 0.34))
    head.position.y = 0.82
    zombie.add_child(head)
    _add_limb(zombie, Vector3(-0.42, 0.08, 0), Vector3(0.18, 0.78, 0.18), Color(0.32, 0.36, 0.22), Vector3(0, 0, -0.45))
    _add_limb(zombie, Vector3(0.42, 0.08, 0), Vector3(0.18, 0.78, 0.18), Color(0.32, 0.36, 0.22), Vector3(0, 0, 0.45))
    _add_limb(zombie, Vector3(-0.20, -0.57, 0), Vector3(0.20, 0.72, 0.20), Color(0.23, 0.27, 0.19), Vector3(0, 0, -0.12))
    _add_limb(zombie, Vector3(0.20, -0.57, 0), Vector3(0.20, 0.72, 0.20), Color(0.23, 0.27, 0.19), Vector3(0, 0, 0.12))
    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.32
    shape.height = 1.5
    col.shape = shape
    zombie.add_child(col)

func _make_npc() -> void:
    interact_target = StaticBody3D.new()
    interact_target.name = "Stranger"
    interact_target.position = Vector3(-2.2, 0.6, 2.0)
    add_child(interact_target)
    var torso := _make_mesh_box(Vector3(0.6, 1.1, 0.45), Color(0.45, 0.25, 0.2))
    torso.position.y = 0.1
    interact_target.add_child(torso)
    var head := _make_mesh_sphere(0.23, Color(0.7, 0.54, 0.4))
    head.position.y = 0.83
    interact_target.add_child(head)
    _add_limb(interact_target, Vector3(-0.40, 0.10, 0), Vector3(0.17, 0.68, 0.17), Color(0.38, 0.20, 0.16), Vector3(0, 0, -0.2))
    _add_limb(interact_target, Vector3(0.40, 0.10, 0), Vector3(0.17, 0.68, 0.17), Color(0.38, 0.20, 0.16), Vector3(0, 0, 0.2))
    _add_limb(interact_target, Vector3(-0.19, -0.54, 0), Vector3(0.19, 0.68, 0.19), Color(0.22, 0.18, 0.16), Vector3(0, 0, -0.03))
    _add_limb(interact_target, Vector3(0.19, -0.54, 0), Vector3(0.19, 0.68, 0.19), Color(0.22, 0.18, 0.16), Vector3(0, 0, 0.03))

func _make_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    hud.add_child(root)
    var top := PanelContainer.new()
    top.position = Vector2(18, 18)
    top.custom_minimum_size = Vector2(360, 95)
    root.add_child(top)
    var vbox := VBoxContainer.new()
    top.add_child(vbox)
    var title := Label.new()
    title.text = "DEADLAND  |  ДЕНЬ 12"
    title.add_theme_font_size_override("font_size", 22)
    vbox.add_child(title)
    status_label = Label.new()
    vbox.add_child(status_label)
    message_label = Label.new()
    message_label.position = Vector2(18, 128)
    message_label.custom_minimum_size = Vector2(600, 58)
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_label.add_theme_font_size_override("font_size", 18)
    root.add_child(message_label)
    var hint := Label.new()
    hint.text = "ПК: WASD / стрелки · E — действие · Space — удар"
    hint.position = Vector2(18, 670)
    hint.add_theme_font_size_override("font_size", 15)
    root.add_child(hint)
    choice_panel = PanelContainer.new()
    choice_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
    choice_panel.position = Vector2(-470, -125)
    choice_panel.custom_minimum_size = Vector2(440, 240)
    choice_panel.visible = false
    root.add_child(choice_panel)
    var joystick_control := Control.new()
    joystick_control.name = "VirtualJoystick"
    joystick_control.set_script(load("res://scripts/virtual_joystick.gd"))
    joystick_control.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    joystick_control.position = Vector2(28, -205)
    joystick_control.size = Vector2(180, 180)
    root.add_child(joystick_control)
    joystick_control.direction_changed.connect(func(direction: Vector2):
        if is_instance_valid(player) and player.has_method("set_touch_direction"):
            player.set_touch_direction(direction)
    )
    var interact_button := Button.new()
    interact_button.text = "ДЕЙСТВИЕ"
    interact_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    interact_button.position = Vector2(-320, -105)
    interact_button.size = Vector2(170, 66)
    interact_button.add_theme_font_size_override("font_size", 18)
    interact_button.pressed.connect(_interact)
    root.add_child(interact_button)
    var attack_button := Button.new()
    attack_button.text = "УДАР"
    attack_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    attack_button.position = Vector2(-155, -185)
    attack_button.size = Vector2(130, 66)
    attack_button.add_theme_font_size_override("font_size", 18)
    attack_button.pressed.connect(_attack)
    root.add_child(attack_button)

func _update_camera() -> void:
    if not is_instance_valid(player) or not is_instance_valid(camera):
        return
    var target := player.global_position + Vector3(0, 1.0, 0)
    var desired := player.global_position + Vector3(0, 3.2, 6.5)
    camera.global_position = camera.global_position.lerp(desired, 0.14)
    camera.look_at(target, Vector3.UP)

func _update_zombie(delta: float) -> void:
    if not is_instance_valid(zombie) or not is_instance_valid(player):
        return
    var d: Vector3 = player.global_position - zombie.global_position
    d.y = 0
    if d.length() < 7.5 and d.length() > 1.0:
        zombie.velocity = d.normalized() * zombie_speed
        zombie.move_and_slide()
    elif d.length() <= 1.0:
        if randf() < delta * 0.65:
            health = max(0, health - 5)
            message_label.text = "Зомби наносит удар! Отойди от него."
            if health <= 0:
                game_over = true
                message_label.text = "ТЫ ПОГИБ. Перезапусти сцену, чтобы попробовать снова."

func _update_status() -> void:
    if is_instance_valid(status_label):
        status_label.text = "Здоровье: %d   Выносливость: %d   Припасы: %s" % [health, int(stamina), "получены" if supplies_taken else "0"]

func _interact() -> void:
    if player.global_position.distance_to(interact_target.global_position) > 3.0:
        message_label.text = "Подойди ближе к незнакомцу (коричневая фигура)."
        return
    _show_choices()

func _show_choices() -> void:
    for child in choice_panel.get_children():
        child.queue_free()
    var v := VBoxContainer.new()
    choice_panel.add_child(v)
    var label := Label.new()
    label.text = "Незнакомец: «Помоги мне. У меня есть лекарства, но вокруг заражённые»"
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.custom_minimum_size = Vector2(400, 60)
    v.add_child(label)
    var save_btn := Button.new()
    save_btn.text = "Помочь незнакомцу"
    save_btn.pressed.connect(func():
        stranger_saved = true
        health = min(100, health + 10)
        message_label.text = "Ты помог незнакомцу. Он отдаёт тебе бинты. Решение запомнено."
        choice_panel.visible = false
        _update_status()
    )
    v.add_child(save_btn)
    var take_btn := Button.new()
    take_btn.text = "Забрать припасы и уйти"
    take_btn.pressed.connect(func():
        supplies_taken = true
        message_label.text = "Ты забрал припасы. Незнакомец остался позади. Решение запомнено."
        choice_panel.visible = false
        _update_status()
    )
    v.add_child(take_btn)
    var leave_btn := Button.new()
    leave_btn.text = "Отказаться и уйти"
    leave_btn.pressed.connect(func():
        message_label.text = "Ты ушёл. В следующий раз последствия могут быть другими."
        choice_panel.visible = false
    )
    v.add_child(leave_btn)
    choice_panel.visible = true

func _attack() -> void:
    if is_instance_valid(zombie) and player.global_position.distance_to(zombie.global_position) < 2.0:
        zombie.queue_free()
        message_label.text = "Ты отбросил зомби. Пока путь свободен."
    else:
        message_label.text = "Удар в пустоту. Подойди к зомби ближе."

func _box(label: String, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = label
    body.position = pos
    add_child(body)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mesh.material_override = mat
    body.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body

func _make_mesh_box(size: Vector3, color: Color) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mesh.material_override = mat
    return mesh

func _make_mesh_sphere(radius: float, color: Color) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    mesh.mesh = sphere
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mesh.material_override = mat
    return mesh

func _add_limb(parent: Node3D, pos: Vector3, size: Vector3, color: Color, rot: Vector3) -> void:
    var limb := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = min(size.x, size.z) * 0.5
    capsule.height = size.y
    limb.mesh = capsule
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    limb.material_override = mat
    limb.position = pos
    limb.rotation = rot
    parent.add_child(limb)

func _make_tree(pos: Vector3) -> void:
    _box("TreeTrunk", pos + Vector3(0, 0.7, 0), Vector3(0.35, 1.4, 0.35), Color(0.25, 0.18, 0.12))
    var crown := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 1.0
    sphere.height = 2.0
    crown.mesh = sphere
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.15, 0.24, 0.15)
    crown.material_override = mat
    crown.position = pos + Vector3(0, 1.8, 0)
    add_child(crown)
