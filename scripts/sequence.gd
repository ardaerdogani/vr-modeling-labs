extends Node
## Lab 2: an ordered task ("Make breakfast"). Each step names the prop to use,
## an optional moving part inside it and the animation to play.
## Lab 3: each step also has a sound and (for some) a particle or light effect.

const SND = {
	"door_open": preload("res://assets/audio/door_open.wav"),
	"door_close": preload("res://assets/audio/door_close.wav"),
	"drawer": preload("res://assets/audio/drawer.wav"),
	"blender": preload("res://assets/audio/blender.wav"),
	"coffee": preload("res://assets/audio/coffee.wav"),
	"microwave": preload("res://assets/audio/microwave.wav"),
	"water": preload("res://assets/audio/water.wav"),
	"step_done": preload("res://assets/audio/step_done.wav"),
	"wrong": preload("res://assets/audio/wrong.wav"),
	"complete": preload("res://assets/audio/complete.wav"),
}

const STEPS = [
	{"target": "Fridge", "part": "kitchenFridge(Clone)/doorFridge", "action": "swing_open", "sound": "door_open", "fx": "mist", "text": "Open the fridge"},
	{"target": "Fridge", "part": "kitchenFridge(Clone)/doorFridge", "action": "swing_close", "sound": "door_close", "fx": "", "text": "Close the fridge"},
	{"target": "UpperCabinet", "part": "kitchenCabinetUpper(Clone)/door", "action": "swing_open", "sound": "door_open", "fx": "", "text": "Open the wall cabinet"},
	{"target": "UpperCabinet", "part": "kitchenCabinetUpper(Clone)/door", "action": "swing_close", "sound": "door_close", "fx": "", "text": "Close the wall cabinet"},
	{"target": "CabinetDrawer", "part": "kitchenCabinetDrawer(Clone)/drawer", "action": "slide_out", "sound": "drawer", "fx": "", "text": "Open the drawer"},
	{"target": "CabinetDrawer", "part": "kitchenCabinetDrawer(Clone)/drawer", "action": "slide_in", "sound": "drawer", "fx": "", "text": "Close the drawer"},
	{"target": "Blender", "part": "", "action": "shake", "sound": "blender", "fx": "splash", "text": "Make a smoothie in the blender"},
	{"target": "CoffeeMachine", "part": "kitchenCoffeeMachine(Clone)/mug", "action": "slide_out", "sound": "coffee", "fx": "steam", "text": "Brew coffee and take the mug"},
	{"target": "Microwave", "part": "kitchenMicrowave(Clone)/Group", "action": "swing_open_close", "sound": "microwave", "fx": "glow", "text": "Heat food in the microwave"},
	{"target": "Stove", "part": "kitchenStove(Clone)/door", "action": "drop_open", "sound": "door_open", "fx": "heat", "text": "Open the oven"},
	{"target": "Stove", "part": "kitchenStove(Clone)/door", "action": "drop_close", "sound": "door_close", "fx": "", "text": "Close the oven"},
	{"target": "Sink", "part": "", "action": "shake", "sound": "water", "fx": "water", "text": "Wash your hands at the sink"},
]

var current := 0
var busy := false
var step_label: Label
var prompt_label: Label
var feedback_label: Label

func _ready():
	add_to_group("sequence")
	_build_hud()
	_update_hud()

func try_interact(prop: Node3D):
	if busy or current >= STEPS.size():
		return
	var s = STEPS[current]
	if prop.name != s.target:
		Effects.play_ui(self, SND.wrong, -6.0)
		_flash("Not yet! Next: " + s.text)
		return
	busy = true
	_play_feedback(prop, s)
	await _do_action(prop, s)
	busy = false
	current += 1
	_update_hud()
	if current >= STEPS.size():
		Effects.play_ui(self, SND.complete)
		_confetti()
		_flash("Breakfast is ready! All %d steps done." % STEPS.size(), 6.0)
	else:
		Effects.play_ui(self, SND.step_done, -10.0)
		_flash("Done: " + s.text)

## Called by the player every frame with what the crosshair is on (or null).
func set_hover(prop):
	if prop == null or current >= STEPS.size():
		prompt_label.text = ""
		return
	var n = prop.get_display_name() if prop.has_method("get_display_name") else String(prop.name)
	prompt_label.text = "[E] " + n

# ---------- Lab 3: sound + visual feedback ----------

func _play_feedback(prop: Node3D, s: Dictionary):
	var box := _main_box(prop)
	var c := box.get_center()
	Effects.play_at(self, SND[s.sound], c)
	match s.fx:
		"mist":
			Effects.burst(self, "mist", Vector3(c.x, c.y + 0.2, box.end.z), 1.0)
		"splash":
			Effects.burst(self, "splash", Vector3(c.x, box.end.y + 0.3, c.z), 0.3)
		"steam":
			var mug: Node3D = prop.get_node(s.part)
			Effects.burst(self, "steam", mug.global_position + Vector3(0, 0.12, 0.1), 2.0)
		"heat":
			Effects.burst(self, "heat", Vector3(c.x, c.y, box.end.z + 0.1), 1.5)
		"water":
			# faucet spout, in the sink model's own coordinates
			Effects.burst(self, "water", prop.global_transform * Vector3(0.218, 0.47, -0.3), 1.5)
		"glow":
			var light := OmniLight3D.new()
			light.light_color = Color(1.0, 0.6, 0.2)
			light.omni_range = 1.2
			add_child(light)
			light.global_position = c + Vector3(0, 0, 0.15)
			var t = create_tween()
			t.tween_property(light, "light_energy", 3.0, 0.3).from(0.0)
			t.tween_interval(0.8)
			t.tween_property(light, "light_energy", 0.0, 0.3)
			t.tween_callback(light.queue_free)

func _confetti():
	var player = get_tree().get_first_node_in_group("player")
	var pos = Vector3(0, 1, 0)
	if player:
		pos = player.global_position - player.global_basis.z * 1.5
	Effects.burst(self, "confetti", pos, 0.2)

## World-space box of the prop's main mesh (used to place effects).
func _main_box(prop: Node3D) -> AABB:
	var mi := prop.get_child(0) as MeshInstance3D
	if mi == null:
		return AABB(prop.global_position, Vector3.ONE * 0.2)
	return mi.global_transform * mi.get_aabb()

# ---------- Lab 2: animations ----------

func _do_action(prop: Node3D, s: Dictionary):
	var part: Node3D = prop.get_node(s.part) if s.part != "" else prop
	var t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	match s.action:
		"swing_open":
			t.tween_property(part, "rotation_degrees:y", -100.0, 0.6)
		"swing_close":
			t.tween_property(part, "rotation_degrees:y", 0.0, 0.6)
		"swing_open_close":
			t.tween_property(part, "rotation_degrees:y", -100.0, 0.5)
			t.tween_interval(0.8)
			t.tween_property(part, "rotation_degrees:y", 0.0, 0.5)
		"drop_open":
			t.tween_property(part, "rotation_degrees:x", 80.0, 0.6)
		"drop_close":
			t.tween_property(part, "rotation_degrees:x", 0.0, 0.6)
		"slide_out":
			t.tween_property(part, "position:z", part.position.z + 0.15, 0.5)
		"slide_in":
			t.tween_property(part, "position:z", part.position.z - 0.15, 0.5)
		"shake":
			var p0 = part.position
			for i in 12:
				t.tween_property(part, "position", p0 + Vector3(randf_range(-0.01, 0.01), 0, randf_range(-0.01, 0.01)), 0.06)
			t.tween_property(part, "position", p0, 0.06)
	await t.finished

# ---------- HUD ----------

func _update_hud():
	if current >= STEPS.size():
		step_label.text = "Make breakfast: complete!"
	else:
		step_label.text = "Make breakfast, step %d/%d: %s" % [current + 1, STEPS.size(), STEPS[current].text]

func _flash(msg: String, secs := 2.0):
	feedback_label.text = msg
	var my = msg
	await get_tree().create_timer(secs).timeout
	if feedback_label.text == my:
		feedback_label.text = ""

func _build_hud():
	var layer := CanvasLayer.new()
	add_child(layer)
	step_label = _label(layer, 0.0, 16, 26, false)
	var cross = _label(layer, 0.5, -20, 28, true)
	cross.text = "+"
	prompt_label = _label(layer, 0.5, 30, 22, true)
	feedback_label = _label(layer, 1.0, -80, 24, true)

## Label anchored at a vertical fraction of the screen (0 = top, 0.5 = middle, 1 = bottom).
func _label(parent: Node, anchor_y: float, offset_y: float, size: int, centered: bool) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.anchor_top = anchor_y
	l.anchor_bottom = anchor_y
	l.offset_left = 20
	l.offset_right = -20
	l.offset_top = offset_y
	l.offset_bottom = offset_y + 40
	if centered:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l
