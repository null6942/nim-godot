extends Node

const START := [1, 3, 5, 7] # Marienbad tableau: four unequal heaps
const PEARL_GAP := 0.78
const ROW_Z := [-1.95, -0.65, 0.65, 1.95]
const FELT_TOP := 0.06

const GOLD := Color("e8c056")
const GOLD_DIM := Color("c9a24a")
const INK := Color("1a140c")
const MUTED := Color(0.78, 0.74, 0.66, 1.0)
const FAINT := Color(0.55, 0.52, 0.46, 1.0)
const ROOM := Color(0.035, 0.032, 0.03, 1.0)
const BTN_BG := Color(0.10, 0.12, 0.11, 0.92)
const BTN_HOVER := Color(0.16, 0.18, 0.16, 0.95)

enum Difficulty { EASY, MEDIUM, HARD }
enum PlayMode { CLASSIC, MISERE }

const OPTIMAL_CHANCE := [0.25, 0.60, 1.0]
const DIFF_LABELS := ["Easy", "Medium", "Hard"]
const DIFF_COLORS := [Color("7dcea0"), Color("e8c056"), Color("e07070")]
const MODE_LABELS := ["Classic", "Misère"]

var rows: Array[int] = []
var game_over := false
var player_turn := true
var difficulty: int = Difficulty.MEDIUM
var play_mode: int = PlayMode.MISERE
var game_started := false
var game_gen := 0
var busy := false
var player_took_last := false
var last_select_row := -1
var last_select_index := -1

var font_title: Font
var font_ui: Font
var font_ui_bold: Font

var world: Node3D
var pearls_root: Node3D
var table_viewport: SubViewport
var table_wrap: Control
var status_label: Label
var subtitle: Label
var rules_label: Label
var result_card: PanelContainer
var result_box: VBoxContainer
var result_title: Label
var result_sub: Label
var result_dim: ColorRect
var take_btn: Button
var new_btn: Button
var mode_btns: Array = []
var diff_btns: Array = []
var pearls: Array = []
var sfx_click: AudioStreamPlayer
var sfx_take: AudioStreamPlayer

func _ready() -> void:
	_load_fonts()
	_build_ui()
	_build_world()
	_enter_setup()

func _input(event: InputEvent) -> void:
	if event.is_echo() or not (event is InputEventKey) or not event.pressed:
		return
	var key: int = event.keycode
	if key == KEY_ESCAPE:
		if _selected_count() > 0:
			_clear_selection()
			get_viewport().set_input_as_handled()
	elif key == KEY_ENTER or key == KEY_KP_ENTER or key == KEY_SPACE:
		if _selected_count() > 0:
			_try_take_selected()
			get_viewport().set_input_as_handled()

func _load_fonts() -> void:
	font_title = _font("res://fonts/Fraunces-SemiBold.ttf")
	font_ui = _font("res://fonts/Figtree-Regular.ttf")
	font_ui_bold = _font("res://fonts/Figtree-SemiBold.ttf")

func _tracked_font(font: Font, spacing: int) -> Font:
	if font == null:
		return null
	var fv := FontVariation.new()
	fv.base_font = font
	fv.spacing_glyph = spacing
	return fv

func _font(path: String) -> Font:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Font:
			return res
	var ff := FontFile.new()
	if ff.load_dynamic_font(path) == OK:
		return ff
	return null

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _apply_font(ctrl: Control, font: Font, size: int, color: Color, outline := false) -> void:
	if font:
		ctrl.add_theme_font_override("font", font)
	ctrl.add_theme_font_size_override("font_size", size)
	ctrl.add_theme_color_override("font_color", color)
	if outline:
		ctrl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
		ctrl.add_theme_constant_override("outline_size", 3)

func _box(bg: Color, border: Color, width: int, radius: int, pad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.55
	s.content_margin_bottom = pad * 0.55
	return s

func _glow(s: StyleBoxFlat) -> StyleBoxFlat:
	s.shadow_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.28)
	s.shadow_size = 5
	s.shadow_offset = Vector2(0, 1)
	return s

func _plaque(pad: int) -> StyleBoxFlat:
	var s := _box(Color(INK.r, INK.g, INK.b, 0.78), Color(GOLD.r, GOLD.g, GOLD.b, 0.40), 1, 12, pad)
	s.shadow_color = Color(0, 0, 0, 0.32)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 2)
	return s

func _style_button(btn: Button, selected: bool, locked := false) -> void:
	var radius := 8
	var pad := 14
	var muted_box := _box(BTN_BG.darkened(0.2), Color(0.22, 0.20, 0.16, 1), 1, radius, pad)
	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var pressed: StyleBoxFlat
	var disabled: StyleBoxFlat
	if locked:
		var fill := BTN_BG.darkened(0.12)
		fill.a = 0.82
		var border := Color(0.22, 0.20, 0.16, 1)
		if selected:
			fill = BTN_BG.lightened(0.06)
			fill.a = 0.88
			border = Color(GOLD_DIM.r, GOLD_DIM.g, GOLD_DIM.b, 0.45)
		var box := _box(fill, border, 1, radius, pad)
		normal = box
		hover = box
		pressed = box
		disabled = box
		btn.add_theme_color_override("font_color", FAINT)
		btn.add_theme_color_override("font_hover_color", FAINT)
		btn.add_theme_color_override("font_pressed_color", FAINT)
		btn.add_theme_color_override("font_disabled_color", FAINT)
	elif selected:
		pressed = _glow(_box(GOLD, GOLD, 1, radius, pad))
		normal = pressed
		hover = _glow(_box(GOLD.lightened(0.08), GOLD, 1, radius, pad))
		disabled = muted_box
		btn.add_theme_color_override("font_color", INK)
		btn.add_theme_color_override("font_hover_color", INK)
		btn.add_theme_color_override("font_pressed_color", INK)
		btn.add_theme_color_override("font_disabled_color", FAINT)
	else:
		normal = _box(BTN_BG, Color(0.33, 0.20, 0.10, 1), 1, radius, pad)
		hover = _box(BTN_HOVER, GOLD_DIM, 1, radius, pad)
		pressed = _box(GOLD, GOLD, 1, radius, pad)
		disabled = muted_box
		btn.add_theme_color_override("font_color", MUTED)
		btn.add_theme_color_override("font_hover_color", GOLD)
		btn.add_theme_color_override("font_pressed_color", INK)
		btn.add_theme_color_override("font_disabled_color", FAINT)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	if font_ui_bold:
		btn.add_theme_font_override("font", font_ui_bold)
	btn.add_theme_font_size_override("font_size", 15)
	btn.mouse_default_cursor_shape = Control.CURSOR_ARROW if locked or btn.disabled else Control.CURSOR_POINTING_HAND
	btn.focus_mode = Control.FOCUS_NONE

func _mk_btn(text: String, toggle: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.toggle_mode = toggle
	btn.custom_minimum_size = Vector2(100, 36)
	_style_button(btn, false)
	return btn

func _tex_mat(path: String, color: Color, roughness: float, metallic: float, uv: Vector3, triplanar := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	var tex := _load_tex(path)
	if tex:
		m.albedo_texture = tex
	m.roughness = roughness
	m.metallic = metallic
	m.uv1_scale = uv
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if triplanar:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_triplanar_sharpness = 6.0
	return m

func _mesh_box(size: Vector3, mat: Material) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.material_override = mat
	return mi

func _add_click_body(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 2
	body.collision_mask = 0
	body.input_ray_pickable = true
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	body.input_event.connect(func(_c, event, _p, _n, _s):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_board_clicked()
	)
	parent.add_child(body)

func _build_world() -> void:
	world = Node3D.new()
	world.name = "World"
	table_viewport.add_child(world)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = ROOM
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.28, 0.22, 0.16)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.85
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.04
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.035, 0.03)
	env.fog_density = 0.012
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 28, 0)
	sun.light_energy = 0.55
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 22.0
	world.add_child(sun)

	var lamp := SpotLight3D.new()
	lamp.position = Vector3(0.0, 5.6, 0.15)
	lamp.rotation_degrees = Vector3(-90, 0, 0)
	lamp.light_energy = 2.55
	lamp.light_color = Color(1.0, 0.91, 0.74)
	lamp.spot_range = 12.0
	lamp.spot_angle = 36.0
	lamp.spot_attenuation = 0.6
	lamp.shadow_enabled = true
	world.add_child(lamp)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.8, 3.4, 2.6)
	fill.light_energy = 0.42
	fill.light_color = Color(0.55, 0.68, 1.0)
	fill.omni_range = 12.0
	world.add_child(fill)

	var rim_l := OmniLight3D.new()
	rim_l.position = Vector3(2.4, 2.2, -2.2)
	rim_l.light_energy = 0.38
	rim_l.light_color = Color(1.0, 0.72, 0.38)
	rim_l.omni_range = 9.0
	world.add_child(rim_l)

	_build_table()

	pearls_root = Node3D.new()
	pearls_root.name = "Pearls"
	world.add_child(pearls_root)

	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 7.5, 5.5)
	cam.look_at_from_position(cam.position, Vector3(0, 0.05, 0.12), Vector3.UP)
	cam.fov = 38.0
	cam.current = true
	world.add_child(cam)

func _build_table() -> void:
	var walnut := _tex_mat("res://textures/walnut.png", Color(0.98, 0.93, 0.86), 0.40, 0.05, Vector3(0.36, 0.36, 0.36), true)
	var felt := _tex_mat("res://textures/felt.png", Color(0.98, 1.0, 0.98), 0.90, 0.0, Vector3(1, 1, 1), false)
	var floor_m := _tex_mat("res://textures/floor.png", Color(0.90, 0.86, 0.80), 0.64, 0.03, Vector3(0.16, 0.16, 0.16), true)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = GOLD
	gold.metallic = 0.90
	gold.roughness = 0.20
	gold.emission_enabled = true
	gold.emission = GOLD_DIM
	gold.emission_energy_multiplier = 0.28

	var floor_mi := _mesh_box(Vector3(22.0, 0.08, 18.0), floor_m)
	floor_mi.position = Vector3(0, -0.72, 0)
	world.add_child(floor_mi)
	_add_click_body(world, Vector3(22.0, 0.08, 18.0), Vector3(0, -0.72, 0))

	var apron := _mesh_box(Vector3(6.7, 0.46, 5.5), walnut)
	apron.position = Vector3(0, -0.28, 0)
	world.add_child(apron)

	var rail_h := 0.20
	var rail_t := 0.34
	var rail_y := 0.08
	var inner_w := 6.02
	var inner_d := 4.82
	var outer_w := inner_w + rail_t * 2.0
	var outer_d := inner_d + rail_t * 2.0
	var n_rail := _mesh_box(Vector3(outer_w, rail_h, rail_t), walnut)
	n_rail.position = Vector3(0, rail_y, -(inner_d + rail_t) * 0.5)
	world.add_child(n_rail)
	var s_rail := _mesh_box(Vector3(outer_w, rail_h, rail_t), walnut)
	s_rail.position = Vector3(0, rail_y, (inner_d + rail_t) * 0.5)
	world.add_child(s_rail)
	var w_rail := _mesh_box(Vector3(rail_t, rail_h, inner_d), walnut)
	w_rail.position = Vector3(-(inner_w + rail_t) * 0.5, rail_y, 0)
	world.add_child(w_rail)
	var e_rail := _mesh_box(Vector3(rail_t, rail_h, inner_d), walnut)
	e_rail.position = Vector3((inner_w + rail_t) * 0.5, rail_y, 0)
	world.add_child(e_rail)

	var felt_mi := _mesh_box(Vector3(inner_w, 0.045, inner_d), felt)
	felt_mi.position = Vector3(0, FELT_TOP - 0.02, 0)
	world.add_child(felt_mi)
	_add_click_body(world, Vector3(inner_w, 0.08, inner_d), Vector3(0, FELT_TOP, 0))

	var inlay_t := 0.045
	var inlay_y := FELT_TOP + 0.012
	var n_in := _mesh_box(Vector3(inner_w + 0.02, 0.02, inlay_t), gold)
	n_in.position = Vector3(0, inlay_y, -inner_d * 0.5 + 0.03)
	world.add_child(n_in)
	var s_in := _mesh_box(Vector3(inner_w + 0.02, 0.02, inlay_t), gold)
	s_in.position = Vector3(0, inlay_y, inner_d * 0.5 - 0.03)
	world.add_child(s_in)
	var w_in := _mesh_box(Vector3(inlay_t, 0.02, inner_d - 0.04), gold)
	w_in.position = Vector3(-inner_w * 0.5 + 0.03, inlay_y, 0)
	world.add_child(w_in)
	var e_in := _mesh_box(Vector3(inlay_t, 0.02, inner_d - 0.04), gold)
	e_in.position = Vector3(inner_w * 0.5 - 0.03, inlay_y, 0)
	world.add_child(e_in)



func _row_origin_x() -> float:
	return -((START[START.size() - 1] - 1) * PEARL_GAP) * 0.5

func _pearl_pos(_ri: int, i: int) -> Vector3:
	return Vector3(_row_origin_x() + float(i) * PEARL_GAP, Pearl.RADIUS * 0.94 + FELT_TOP, ROW_Z[_ri])

func _build_ui() -> void:
	sfx_click = AudioStreamPlayer.new()
	sfx_take = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://sfx/click.wav"):
		sfx_click.stream = load("res://sfx/click.wav")
	if ResourceLoader.exists("res://sfx/take.wav"):
		sfx_take.stream = load("res://sfx/take.wav")
	add_child(sfx_click)
	add_child(sfx_take)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var bg := ColorRect.new()
	bg.color = ROOM
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 16
	col.offset_right = -16
	col.offset_top = 14
	col.offset_bottom = -16
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(col)

	var top_plaque := PanelContainer.new()
	top_plaque.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_plaque.mouse_filter = Control.MOUSE_FILTER_STOP
	top_plaque.add_theme_stylebox_override("panel", _plaque(12))
	col.add_child(top_plaque)

	var top := VBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 7)
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	top_plaque.add_child(top)

	var title := Label.new()
	title.text = "NIM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(title, _tracked_font(font_title, 10), 52, GOLD, true)
	top.add_child(title)

	var rule_wrap := CenterContainer.new()
	rule_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(88, 2)
	rule.color = Color(GOLD.r, GOLD.g, GOLD.b, 0.88)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule_wrap.add_child(rule)
	top.add_child(rule_wrap)

	subtitle = Label.new()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(subtitle, font_ui, 14, MUTED)
	top.add_child(subtitle)

	var mode_row := HBoxContainer.new()
	mode_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mode_row.add_theme_constant_override("separation", 8)
	mode_row.mouse_filter = Control.MOUSE_FILTER_STOP
	top.add_child(mode_row)
	for m in [PlayMode.CLASSIC, PlayMode.MISERE]:
		var btn := _mk_btn(MODE_LABELS[m], false)
		btn.custom_minimum_size = Vector2(118, 34)
		var captured: int = m
		btn.pressed.connect(func(): _set_play_mode(captured))
		mode_row.add_child(btn)
		mode_btns.append(btn)

	var diff_row := HBoxContainer.new()
	diff_row.alignment = BoxContainer.ALIGNMENT_CENTER
	diff_row.add_theme_constant_override("separation", 8)
	diff_row.mouse_filter = Control.MOUSE_FILTER_STOP
	top.add_child(diff_row)
	for d in [Difficulty.EASY, Difficulty.MEDIUM, Difficulty.HARD]:
		var btn := _mk_btn(DIFF_LABELS[d], false)
		var captured_d: int = d
		btn.pressed.connect(func(): _set_difficulty(captured_d))
		diff_row.add_child(btn)
		diff_btns.append(btn)

	table_wrap = Control.new()
	table_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	col.add_child(table_wrap)

	var svc := SubViewportContainer.new()
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_STOP
	table_wrap.add_child(svc)

	table_viewport = SubViewport.new()
	table_viewport.transparent_bg = false
	table_viewport.handle_input_locally = true
	table_viewport.physics_object_picking = true
	table_viewport.own_world_3d = true
	table_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	table_viewport.msaa_3d = Viewport.MSAA_4X
	table_viewport.scaling_3d_scale = 1.35
	svc.add_child(table_viewport)

	result_dim = ColorRect.new()
	result_dim.color = Color(ROOM.r, ROOM.g, ROOM.b, 0.55)
	result_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_dim.visible = false
	result_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	table_wrap.add_child(result_dim)

	result_card = PanelContainer.new()
	result_card.set_anchors_preset(Control.PRESET_CENTER)
	result_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	result_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	result_card.visible = false
	result_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_card.custom_minimum_size = Vector2(280, 0)
	var card_style := _box(Color(INK, 0.96), GOLD, 1, 12, 26)
	card_style.content_margin_top = 24
	card_style.content_margin_bottom = 24
	card_style.shadow_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.18)
	card_style.shadow_size = 10
	result_card.add_theme_stylebox_override("panel", card_style)
	table_wrap.add_child(result_card)
	result_box = VBoxContainer.new()
	result_box.alignment = BoxContainer.ALIGNMENT_CENTER
	result_box.add_theme_constant_override("separation", 8)
	result_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_card.add_child(result_box)
	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(result_title, font_title, 40, GOLD, true)
	result_box.add_child(result_title)
	var result_rule_wrap := CenterContainer.new()
	result_rule_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var result_rule := ColorRect.new()
	result_rule.custom_minimum_size = Vector2(72, 1)
	result_rule.color = Color(GOLD.r, GOLD.g, GOLD.b, 0.70)
	result_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_rule_wrap.add_child(result_rule)
	result_box.add_child(result_rule_wrap)
	result_sub = Label.new()
	result_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(result_sub, font_ui, 16, MUTED)
	result_box.add_child(result_sub)

	var bottom_plaque := PanelContainer.new()
	bottom_plaque.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_plaque.mouse_filter = Control.MOUSE_FILTER_STOP
	bottom_plaque.add_theme_stylebox_override("panel", _plaque(12))
	col.add_child(bottom_plaque)

	var bottom := VBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 6)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_plaque.add_child(bottom)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(status_label, font_ui, 14, FAINT)
	bottom.add_child(status_label)

	rules_label = Label.new()
	rules_label.visible = false
	rules_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(rules_label)

	var new_row := HBoxContainer.new()
	new_row.alignment = BoxContainer.ALIGNMENT_CENTER
	new_row.add_theme_constant_override("separation", 12)
	bottom.add_child(new_row)
	take_btn = _mk_btn("Take selected", false)
	take_btn.custom_minimum_size = Vector2(156, 40)
	take_btn.pressed.connect(_try_take_selected)
	new_row.add_child(take_btn)
	new_btn = _mk_btn("New game", false)
	new_btn.custom_minimum_size = Vector2(158, 42)
	_style_button(new_btn, true)
	new_btn.pressed.connect(_on_new_game)
	new_row.add_child(new_btn)

	_refresh_mode_buttons()
	_refresh_diff_buttons()
	_refresh_take_button()
	_refresh_copy()

func _options_locked() -> bool:
	return game_started and not game_over

func _is_setup() -> bool:
	return not game_started and not game_over

func _setup_status() -> String:
	return "Choose Classic or Misere and a difficulty, then press New game."

func _your_turn_status() -> String:
	return "Your turn - select pearls in one row, then Take."

func _refresh_copy() -> void:
	if play_mode == PlayMode.CLASSIC:
		subtitle.text = "Last pearl wins"
	else:
		subtitle.text = "Last pearl loses"
	rules_label.visible = false
	rules_label.text = ""

func _reset_board_state() -> void:
	game_gen += 1
	busy = false
	rows.clear()
	for v in START:
		rows.append(v)
	game_over = false
	player_took_last = false
	last_select_row = -1
	last_select_index = -1
	result_card.visible = false
	result_dim.visible = false
	status_label.visible = true
	rules_label.visible = false

func _on_new_game() -> void:
	_play_click()
	if _is_setup():
		_start_match()
	else:
		_enter_setup()

func _enter_setup() -> void:
	_reset_board_state()
	game_started = false
	player_turn = false
	_refresh_mode_buttons()
	_refresh_diff_buttons()
	_refresh_copy()
	_build_board()
	_refresh_take_button()
	_set_status(_setup_status())

func _start_match() -> void:
	_reset_board_state()
	game_started = true
	player_turn = randi() % 2 == 0
	_refresh_mode_buttons()
	_refresh_diff_buttons()
	_refresh_copy()
	_build_board()
	_refresh_take_button()
	if player_turn:
		_set_status(_your_turn_status())
		return
	_set_status("Computer goes first...")
	_refresh_pearls()
	var gen := game_gen
	await get_tree().create_timer(0.7).timeout
	if game_gen == gen:
		await _ai_move()

func _build_board() -> void:
	for c in pearls_root.get_children():
		c.queue_free()
	pearls.clear()
	var label_x: float = _row_origin_x() - 0.46
	for ri in START.size():
		var tag := Label3D.new()
		tag.text = char(65 + ri)
		if font_title:
			tag.font = font_title
		tag.font_size = 42
		tag.pixel_size = 0.0045
		tag.modulate = GOLD
		tag.outline_modulate = Color(0, 0, 0, 0.55)
		tag.outline_size = 8
		tag.position = Vector3(label_x, FELT_TOP + 0.10, ROW_Z[ri])
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		pearls_root.add_child(tag)
		var row_pearls: Array = []
		for i in START[ri]:
			var p := Pearl.new()
			p.row = ri
			p.hue_shift = randf_range(-0.045, 0.045)
			p.position = _pearl_pos(ri, i)
			p.clicked.connect(func(): _on_pearl_clicked(p))
			pearls_root.add_child(p)
			row_pearls.append(p)
		pearls.append(row_pearls)
	_refresh_pearls()

func _refresh_pearls() -> void:
	var sel_row := _selected_row()
	for ri in pearls.size():
		var count: int = rows[ri]
		var row_arr: Array = pearls[ri]
		for i in row_arr.size():
			var p: Pearl = row_arr[i]
			if p.phase == Pearl.Phase.REMOVING:
				continue
			if i >= count:
				p.phase = Pearl.Phase.REMOVED
				p.visible = false
				p.set_pickable(false)
				continue
			p.visible = true
			var playable := game_started and player_turn and not game_over and not busy
			p.dimmed = not playable or (sel_row >= 0 and ri != sel_row)
			p.set_pickable(playable)
			p._apply_visual()

func _selected_row() -> int:
	for ri in pearls.size():
		var count: int = rows[ri] if ri < rows.size() else 0
		for i in mini(count, pearls[ri].size()):
			var p: Pearl = pearls[ri][i]
			if p.selected and p.phase == Pearl.Phase.IDLE:
				return ri
	return -1

func _selected_count() -> int:
	var n := 0
	for ri in pearls.size():
		var count: int = rows[ri] if ri < rows.size() else 0
		for i in mini(count, pearls[ri].size()):
			var p: Pearl = pearls[ri][i]
			if p.selected and p.phase == Pearl.Phase.IDLE:
				n += 1
	return n

func _clear_selection() -> void:
	for row_arr in pearls:
		for p in row_arr:
			var pearl: Pearl = p
			pearl.selected = false
	last_select_row = -1
	last_select_index = -1
	_refresh_pearls()
	_refresh_take_button()
	if player_turn and not game_over and not busy:
		_set_status(_setup_status() if _is_setup() else _your_turn_status())

func _refresh_take_button() -> void:
	if take_btn == null:
		return
	var n := _selected_count()
	var can := n > 0 and game_started and player_turn and not game_over and not busy
	take_btn.disabled = not can
	take_btn.text = "Take selected" if n == 0 else ("Take %d" % n)
	_style_button(take_btn, can)

func _on_board_clicked() -> void:
	if player_turn and not busy and not game_over and _selected_count() > 0:
		_play_click()
		_clear_selection()

func _on_pearl_clicked(p: Pearl) -> void:
	if not game_started or not player_turn or game_over or busy:
		return
	if p.phase != Pearl.Phase.IDLE:
		return
	var ri: int = p.row
	var idx: int = pearls[ri].find(p)
	if idx < 0 or idx >= rows[ri]:
		return
	var current_row := _selected_row()
	if current_row >= 0 and current_row != ri:
		for row_arr in pearls:
			for q in row_arr:
				var other: Pearl = q
				other.selected = false
		last_select_row = -1
		last_select_index = -1
	var shift := Input.is_key_pressed(KEY_SHIFT)
	if shift and last_select_row == ri and last_select_index >= 0:
		var a: int = mini(last_select_index, idx)
		var b: int = maxi(last_select_index, idx)
		for i in range(a, b + 1):
			if i < rows[ri]:
				var q: Pearl = pearls[ri][i]
				q.selected = true
	else:
		p.selected = not p.selected
		if p.selected:
			p.animate_select_pulse()
	last_select_row = ri
	last_select_index = idx
	_play_click()
	_refresh_pearls()
	_refresh_take_button()
	var n := _selected_count()
	if n == 0:
		_set_status(_setup_status() if _is_setup() else _your_turn_status())
	else:
		_set_status("Row %s - %d selected. Take, or pick more." % [char(65 + ri), n])

func _try_take_selected() -> void:
	if not game_started or not player_turn or game_over or busy:
		return
	var ri := _selected_row()
	if ri < 0:
		return
	var indices: Array = []
	for i in range(rows[ri]):
		var p: Pearl = pearls[ri][i]
		if p.selected:
			indices.append(i)
	if indices.is_empty():
		return
	await _take_indices(ri, indices, true)

func _take(ri: int, n: int, is_player: bool) -> void:
	var from_i: int = rows[ri] - n
	var indices: Array = []
	for i in range(from_i, rows[ri]):
		indices.append(i)
	await _take_indices(ri, indices, is_player)

func _take_indices(ri: int, indices: Array, is_player: bool) -> void:
	busy = true
	for row_arr in pearls:
		for q in row_arr:
			var pearl: Pearl = q
			pearl.selected = false
	last_select_row = -1
	last_select_index = -1
	_refresh_take_button()
	if not game_started:
		game_started = true
		rules_label.visible = false
		_refresh_mode_buttons()
		_refresh_diff_buttons()
	indices.sort()
	var n: int = indices.size()
	_play_take()
	var last_tw: Signal
	var has_tw := false
	for i in indices:
		var p: Pearl = pearls[ri][i]
		last_tw = p.animate_remove()
		has_tw = true
	if has_tw:
		await last_tw
	var alive: Array = []
	var dead: Array = []
	for p in pearls[ri]:
		var pearl: Pearl = p
		if pearl.phase == Pearl.Phase.REMOVING or pearl.phase == Pearl.Phase.REMOVED:
			dead.append(pearl)
		else:
			alive.append(pearl)
	pearls[ri] = alive + dead
	if not alive.is_empty():
		var tw := create_tween()
		tw.set_parallel(true)
		for i in alive.size():
			var pearl: Pearl = alive[i]
			tw.tween_property(pearl, "position", _pearl_pos(ri, i), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw.finished
	rows[ri] = alive.size()
	player_took_last = is_player
	if _check_game_over():
		busy = false
		_refresh_take_button()
		return
	if is_player:
		player_turn = false
		_set_status("Computer is thinking…")
		_refresh_pearls()
		_refresh_take_button()
		var gen := game_gen
		await get_tree().create_timer(0.55).timeout
		if game_gen == gen:
			await _ai_move()
		else:
			busy = false
	else:
		player_turn = true
		busy = false
		_set_status("Computer took %d from row %s. Your turn." % [n, char(65 + ri)])
		_refresh_pearls()
		_refresh_take_button()

func _check_game_over() -> bool:
	var total := 0
	for r in rows:
		total += r
	if total != 0:
		return false
	game_over = true
	busy = false
	_refresh_pearls()
	_refresh_mode_buttons()
	_refresh_diff_buttons()
	_refresh_take_button()
	var player_won: bool
	if play_mode == PlayMode.CLASSIC:
		player_won = player_took_last
	else:
		player_won = not player_took_last
	status_label.visible = false
	result_dim.visible = true
	result_card.visible = true
	if player_won:
		result_title.text = "You win"
		result_sub.text = "You took the last pearl." if play_mode == PlayMode.CLASSIC else "The computer took the last pearl."
	else:
		result_title.text = "Computer wins"
		result_sub.text = "The computer took the last pearl." if play_mode == PlayMode.CLASSIC else "You took the last pearl."
	return true

func _set_play_mode(m: int) -> void:
	if _options_locked():
		_refresh_mode_buttons()
		return
	if play_mode == m:
		_refresh_mode_buttons()
		_refresh_copy()
		return
	play_mode = m
	_play_click()
	_refresh_mode_buttons()
	_refresh_copy()

func _set_difficulty(d: int) -> void:
	if _options_locked():
		_refresh_diff_buttons()
		return
	if difficulty == d:
		_refresh_diff_buttons()
		return
	difficulty = d
	_play_click()
	_refresh_diff_buttons()

func _refresh_mode_buttons() -> void:
	var locked := _options_locked()
	for i in mode_btns.size():
		var btn: Button = mode_btns[i]
		btn.disabled = locked
		btn.set_pressed_no_signal(i == play_mode)
		_style_button(btn, i == play_mode, locked)

func _refresh_diff_buttons() -> void:
	var locked := _options_locked()
	for i in diff_btns.size():
		var btn: Button = diff_btns[i]
		btn.disabled = locked
		btn.set_pressed_no_signal(i == difficulty)
		_style_button(btn, i == difficulty, locked)
		if i != difficulty and not locked:
			btn.add_theme_color_override("font_color", DIFF_COLORS[i])
			btn.add_theme_color_override("font_hover_color", DIFF_COLORS[i].lightened(0.15))

func _play_click() -> void:
	if sfx_click.stream:
		sfx_click.pitch_scale = randf_range(0.96, 1.05)
		sfx_click.play()

func _play_take() -> void:
	if sfx_take.stream:
		sfx_take.pitch_scale = randf_range(0.94, 1.06)
		sfx_take.play()

func _random_move() -> void:
	var available: Array = []
	for i in rows.size():
		if rows[i] > 0:
			available.append(i)
	var move_row: int = available[randi() % available.size()]
	var move_count: int = 1 + randi() % rows[move_row]
	await _take(move_row, move_count, false)

func _ai_move() -> void:
	if randf() > OPTIMAL_CHANCE[difficulty]:
		await _random_move()
		return
	var move_row := -1
	var move_count := 0
	if play_mode == PlayMode.CLASSIC:
		var pick: Array = _normal_nim_move()
		move_row = pick[0]
		move_count = pick[1]
	else:
		var big := 0
		var ones := 0
		for r in rows:
			if r > 1:
				big += 1
			elif r == 1:
				ones += 1
		if big >= 2:
			var pick2: Array = _normal_nim_move()
			move_row = pick2[0]
			move_count = pick2[1]
		elif big == 1:
			var bi := -1
			for i in rows.size():
				if rows[i] > 1:
					bi = i
					break
			move_row = bi
			if (ones + 1) % 2 == 1:
				move_count = rows[bi] - 1
			else:
				move_count = rows[bi]
		else:
			for i in rows.size():
				if rows[i] == 1:
					move_row = i
					move_count = 1
					break
	if move_row == -1 or move_count <= 0:
		move_row = _largest_row()
		move_count = 1
	await _take(move_row, move_count, false)

func _normal_nim_move() -> Array:
	var ns := 0
	for r in rows:
		ns ^= r
	if ns == 0:
		return [_largest_row(), 1]
	for i in rows.size():
		var target: int = rows[i] ^ ns
		if target < rows[i]:
			return [i, rows[i] - target]
	return [_largest_row(), 1]

func _largest_row() -> int:
	var idx := 0
	var best := -1
	for i in rows.size():
		if rows[i] > best:
			best = rows[i]
			idx = i
	return idx

func _set_status(msg: String) -> void:
	status_label.text = msg
