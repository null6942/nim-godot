class_name Pearl
extends Area3D

signal clicked
signal hover_changed(on: bool)

enum Phase { IDLE, REMOVING, REMOVED }

const RADIUS := 0.18
const GOLD := Color("e8c056")

var row := 0
var selected := false:
	set(v):
		selected = v
		_apply_visual()
var hovered := false
var dimmed := false:
	set(v):
		dimmed = v
		_apply_visual()
var hue_shift := 0.0
var phase: int = Phase.IDLE
var mesh_instance: MeshInstance3D
var ring: MeshInstance3D
var _mat: ShaderMaterial
var _ring_mat: StandardMaterial3D
var _shape: CollisionShape3D
var _fallback_mat: StandardMaterial3D

func _ready() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = RADIUS
	sphere.height = RADIUS * 2.0
	sphere.radial_segments = 48
	sphere.rings = 24
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere
	mesh_instance.scale = Vector3(1.0, 0.94, 1.0)
	add_child(mesh_instance)

	var shader: Shader = null
	if ResourceLoader.exists("res://pearl.gdshader"):
		shader = load("res://pearl.gdshader")
	if shader:
		_mat = ShaderMaterial.new()
		_mat.shader = shader
		_mat.set_shader_parameter("hue_shift", hue_shift)
		mesh_instance.material_override = _mat
	else:
		_fallback_mat = StandardMaterial3D.new()
		_fallback_mat.roughness = 0.08
		_fallback_mat.metallic = 0.30
		_fallback_mat.albedo_color = Color(0.94, 0.90, 0.84, 1.0)
		mesh_instance.material_override = _fallback_mat

	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.albedo_color = Color(GOLD, 0.0)
	_ring_mat.emission_enabled = true
	_ring_mat.emission = GOLD
	_ring_mat.emission_energy_multiplier = 1.35
	_ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS * 1.18
	torus.outer_radius = RADIUS * 1.40
	torus.rings = 18
	torus.ring_segments = 28
	ring = MeshInstance3D.new()
	ring.mesh = torus
	ring.material_override = _ring_mat
	ring.position = Vector3(0, -RADIUS * 0.94 + 0.014, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)

	var blob_mat := StandardMaterial3D.new()
	blob_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blob_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blob_mat.albedo_color = Color(0.02, 0.03, 0.02, 0.38)
	blob_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var blob_mesh := CylinderMesh.new()
	blob_mesh.top_radius = RADIUS * 0.92
	blob_mesh.bottom_radius = RADIUS * 0.92
	blob_mesh.height = 0.01
	blob_mesh.radial_segments = 20
	var blob := MeshInstance3D.new()
	blob.mesh = blob_mesh
	blob.material_override = blob_mat
	blob.position = Vector3(0, -RADIUS * 0.94 + 0.006, 0)
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(blob)

	_shape = CollisionShape3D.new()
	var ss := SphereShape3D.new()
	ss.radius = RADIUS * 1.08
	_shape.shape = ss
	add_child(_shape)
	collision_layer = 1
	collision_mask = 0
	monitoring = false
	monitorable = true
	input_ray_pickable = true
	mouse_entered.connect(func():
		hovered = true
		hover_changed.emit(true)
		_apply_visual()
	)
	mouse_exited.connect(func():
		hovered = false
		hover_changed.emit(false)
		_apply_visual()
	)
	input_event.connect(_on_input_event)
	_apply_visual()

func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if phase == Phase.IDLE:
			clicked.emit()

func set_pickable(on: bool) -> void:
	input_ray_pickable = on and phase == Phase.IDLE
	if _shape:
		_shape.disabled = not input_ray_pickable

func _apply_visual() -> void:
	if phase == Phase.REMOVED or phase == Phase.REMOVING:
		if ring:
			ring.visible = false
		return
	var sel := 1.0 if selected else 0.0
	var hov := 1.0 if hovered else 0.0
	var dim := 1.0 if dimmed else 0.0
	if _mat:
		_mat.set_shader_parameter("selected", sel)
		_mat.set_shader_parameter("hovered", hov)
		_mat.set_shader_parameter("dimmed", dim)
		_mat.set_shader_parameter("hue_shift", hue_shift)
	elif _fallback_mat:
		if selected:
			_fallback_mat.albedo_color = GOLD
			_fallback_mat.emission_enabled = true
			_fallback_mat.emission = GOLD
			_fallback_mat.emission_energy_multiplier = 0.48
		elif dimmed:
			_fallback_mat.albedo_color = Color(0.70, 0.68, 0.64, 1.0)
			_fallback_mat.emission_enabled = false
		else:
			_fallback_mat.albedo_color = Color(0.94, 0.90, 0.84, 1.0)
			_fallback_mat.emission_enabled = hovered
			if hovered:
				_fallback_mat.emission = GOLD
				_fallback_mat.emission_energy_multiplier = 0.20
	if ring and _ring_mat:
		var show_ring := selected or hovered
		ring.visible = show_ring
		var alpha := 0.92 if selected else 0.40
		_ring_mat.albedo_color = Color(GOLD, alpha)
		_ring_mat.emission = GOLD
		_ring_mat.emission_energy_multiplier = 1.85 if selected else 0.65
		ring.scale = Vector3(1.08, 1.0, 1.08) if selected else Vector3.ONE

func animate_select_pulse() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.08, 1.08, 1.08), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func animate_remove() -> Signal:
	phase = Phase.REMOVING
	selected = false
	hovered = false
	set_pickable(false)
	if ring:
		ring.visible = false
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector3(0.04, 0.04, 0.04), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position:y", position.y + 0.32, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func():
		visible = false
		phase = Phase.REMOVED
	)
	return tw.finished
