extends CharacterBody3D

const SPEED = 4.0
const JUMP = 4.5
const SENS = 0.002
@onready var cam = $Camera3D
@onready var ray = $Camera3D/RayCast3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ray.add_exception(self)  # never hit our own body
	add_to_group("player")

func _unhandled_input(e):
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-e.relative.x * SENS)
		cam.rotate_x(-e.relative.y * SENS)
		cam.rotation.x = clamp(cam.rotation.x, -1.4, 1.4)
	if e is InputEventMouseButton and e.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if e.keycode == KEY_E:
			use_target()

# Lab 2: the prop under the crosshair (nearest parent with an interact() method)
func looked_at():
	var hit = ray.get_collider()
	while hit and not hit.has_method("interact"):
		hit = hit.get_parent()
	return hit

func use_target():
	var target = looked_at()
	if target:
		target.interact()

func _process(_delta):
	var seq = get_tree().get_first_node_in_group("sequence")
	if seq:
		seq.set_hover(looked_at())

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP
	var input = Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	var dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	move_and_slide()
