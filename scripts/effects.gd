class_name Effects
## Lab 3: small factory for the particle effects and one-shot sounds.

static func _soft_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex

static func _draw_mesh(size: float) -> QuadMesh:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _soft_dot()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = m
	return q

## kind: dust, steam, drip, splash, water, mist, heat, confetti
static func particles(kind: String) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	var size := 0.05
	match kind:
		"dust":
			p.amount = 160; p.lifetime = 8.0; size = 0.02
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			pm.emission_box_extents = Vector3(3.5, 1.3, 3.5)
			pm.gravity = Vector3(0, -0.01, 0)
			pm.direction = Vector3(0, 1, 0); pm.spread = 180.0
			pm.initial_velocity_min = 0.02; pm.initial_velocity_max = 0.06
			pm.color = Color(1.0, 0.95, 0.85, 0.55)
			p.visibility_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 4, 8))
		"steam", "mist", "heat":
			p.amount = 40; p.lifetime = 2.5; size = 0.18
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 0.08
			pm.direction = Vector3(0, 1, 0); pm.spread = 12.0
			pm.initial_velocity_min = 0.2; pm.initial_velocity_max = 0.45
			pm.gravity = Vector3(0, 0.05, 0)
			pm.scale_min = 0.6; pm.scale_max = 1.4
			var curve := Curve.new(); curve.add_point(Vector2(0, 0.4)); curve.add_point(Vector2(1, 1.6))
			var ct := CurveTexture.new(); ct.curve = curve
			pm.scale_curve = ct
			var fade := Gradient.new()
			var c = {"steam": Color(1, 1, 1), "mist": Color(0.8, 0.92, 1.0), "heat": Color(1.0, 0.7, 0.4)}[kind]
			fade.set_color(0, Color(c, 0.35)); fade.set_color(1, Color(c, 0.0))
			var gt := GradientTexture1D.new(); gt.gradient = fade
			pm.color_ramp = gt
			if kind == "mist":
				pm.direction = Vector3(0, -0.3, 1); pm.gravity = Vector3(0, -0.15, 0)
		"drip":
			p.amount = 1; p.lifetime = 2.0; size = 0.025
			pm.gravity = Vector3(0, -9.8, 0)
			pm.color = Color(0.6, 0.8, 1.0, 0.9)
		"water":
			p.amount = 120; p.lifetime = 0.35; size = 0.045
			pm.direction = Vector3(0, -1, 0); pm.spread = 4.0
			pm.initial_velocity_min = 0.3; pm.initial_velocity_max = 0.5
			pm.gravity = Vector3(0, -9.8, 0)
			pm.color = Color(0.25, 0.5, 1.0, 0.95)
		"splash":
			p.amount = 45; p.lifetime = 0.9; size = 0.035; p.one_shot = true; p.explosiveness = 0.9
			pm.direction = Vector3(0, 1, 0); pm.spread = 55.0
			pm.initial_velocity_min = 1.0; pm.initial_velocity_max = 2.0
			pm.gravity = Vector3(0, -9.8, 0)
			pm.color = Color(0.95, 0.45, 0.6, 1.0)
		"confetti":
			p.amount = 160; p.lifetime = 2.5; size = 0.05; p.one_shot = true; p.explosiveness = 1.0
			pm.direction = Vector3(0, 1, 0); pm.spread = 70.0
			pm.initial_velocity_min = 2.5; pm.initial_velocity_max = 4.5
			pm.gravity = Vector3(0, -3.0, 0)
			var rainbow := Gradient.new()
			rainbow.set_color(0, Color(1, 0.3, 0.3)); rainbow.set_color(1, Color(0.3, 0.5, 1))
			rainbow.add_point(0.33, Color(1, 0.9, 0.2)); rainbow.add_point(0.66, Color(0.3, 1, 0.5))
			var rt := GradientTexture1D.new(); rt.gradient = rainbow
			pm.color_initial_ramp = rt
	p.process_material = pm
	p.draw_pass_1 = _draw_mesh(size)
	p.name = kind.capitalize() + "Particles"
	return p

## Plays a sound once at a world position, then frees itself.
static func play_at(parent: Node, stream: AudioStream, pos: Vector3, volume_db := 0.0):
	var a := AudioStreamPlayer3D.new()
	a.stream = stream
	a.volume_db = volume_db
	a.unit_size = 4.0
	parent.add_child(a)
	a.global_position = pos
	a.finished.connect(a.queue_free)
	a.play()

## Plays a non-positional (UI) sound once.
static func play_ui(parent: Node, stream: AudioStream, volume_db := 0.0):
	var a := AudioStreamPlayer.new()
	a.stream = stream
	a.volume_db = volume_db
	parent.add_child(a)
	a.finished.connect(a.queue_free)
	a.play()

## Emits a temporary particle effect at a world position for `secs` seconds.
static func burst(parent: Node, kind: String, pos: Vector3, secs := 1.5):
	var p := particles(kind)
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	await parent.get_tree().create_timer(secs).timeout
	p.emitting = false
	await parent.get_tree().create_timer(p.lifetime + 0.2).timeout
	p.queue_free()
