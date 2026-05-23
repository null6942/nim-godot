extends Control

const START := [2, 3, 5, 7]
const ACCENT    := Color("f0c040")
const DIM       := Color("888888")
const MUTED     := Color("aaaaaa")
const FAINT     := Color("666666")
const FELT      := Color(0.08, 0.20, 0.14, 1.0)   # dark green baize
const FELT_EDGE := Color(0.05, 0.13, 0.09, 1.0)

enum Difficulty { EASY, MEDIUM, HARD }
const OPTIMAL_CHANCE := [0.25, 0.60, 1.0]  # indexed by Difficulty enum
const DIFF_COLORS := [Color("4caf50"), Color("f0c040"), Color("e53935")]  # green / yellow / red

var rows: Array[int] = []
var selected_row := -1
var selected_indices: Array = []
var game_over := false
var player_turn := true
var difficulty: int = Difficulty.MEDIUM
var game_started := false
var game_gen := 0  # incremented on each new game; AI move bails if this changes

var status_label: Label
var board_box: VBoxContainer
var confirm_btn: Button
var diff_btns: Array = []
var pearls: Array = []

func _ready() -> void:
	if not OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	_build_ui()
	_init_game()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("080c14")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_theme_constant_override("separation", 10)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(outer)

	var title := Label.new()
	title.text = "NIM"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Last pearl loses"
	subtitle.add_theme_color_override("font_color", MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(subtitle)

	var diff_row := HBoxContainer.new()
	diff_row.alignment = BoxContainer.ALIGNMENT_CENTER
	diff_row.add_theme_constant_override("separation", 8)
	outer.add_child(diff_row)
	var diff_labels: Array = ["Easy", "Medium", "Hard"]
	for d in [Difficulty.EASY, Difficulty.MEDIUM, Difficulty.HARD]:
		var lbl: String = diff_labels[d]
		var btn := Button.new()
		btn.text = lbl
		btn.toggle_mode = true
		btn.pressed.connect(func(): _set_difficulty(d))
		diff_row.add_child(btn)
		diff_btns.append(btn)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = FELT
	panel_style.border_color = FELT_EDGE
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	panel_style.shadow_size = 24
	panel_style.shadow_offset = Vector2(0, 6)
	panel_style.content_margin_left   = 24
	panel_style.content_margin_right  = 24
	panel_style.content_margin_top    = 20
	panel_style.content_margin_bottom = 20

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	outer.add_child(panel)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	panel.add_child(inner)

	status_label = Label.new()
	status_label.add_theme_color_override("font_color", ACCENT)
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size.y = 20
	inner.add_child(status_label)

	var board_wrap := HBoxContainer.new()
	board_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_child(board_wrap)
	board_box = VBoxContainer.new()
	board_box.add_theme_constant_override("separation", 12)
	board_wrap.add_child(board_box)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 12)
	inner.add_child(controls)

	confirm_btn = Button.new()
	confirm_btn.text = "Remove selected"
	confirm_btn.pressed.connect(_on_confirm)
	confirm_btn.visible = false
	controls.add_child(confirm_btn)

	var new_btn := Button.new()
	new_btn.text = "New game"
	new_btn.pressed.connect(func(): _init_game(true))
	controls.add_child(new_btn)

	var rules := Label.new()
	rules.text = "Click pearls in one row to select them. You must remove at least one.\nThe player forced to take the last pearl loses."
	rules.add_theme_color_override("font_color", FAINT)
	rules.add_theme_font_size_override("font_size", 12)
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(rules)

	_refresh_diff_buttons()

func _init_game(randomize_first: bool = false) -> void:
	rows.clear()
	for v in START:
		rows.append(v)
	selected_row = -1
	selected_indices.clear()
	game_over = false
	player_turn = not randomize_first or randi() % 2 == 0
	game_started = false
	game_gen += 1
	confirm_btn.visible = false
	_refresh_diff_buttons()
	_build_board()
	if player_turn:
		_set_status("Your turn — click pearls to select, then confirm.")
	else:
		_set_status("Computer goes first…")
		var gen := game_gen
		await get_tree().create_timer(0.7).timeout
		if game_gen == gen:
			_ai_move()

func _build_board() -> void:
	for c in board_box.get_children():
		c.queue_free()
	pearls.clear()
	for ri in rows.size():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		label.text = char(65 + ri)
		label.custom_minimum_size.x = 16
		label.add_theme_color_override("font_color", DIM)
		row.add_child(label)
		var row_pearls: Array = []
		var n: int = START[ri]
		for i in n:
			var p := Pearl.new()
			var ri_c: int = ri
			var i_c: int = i
			p.clicked.connect(func(): _on_pearl_clicked(ri_c, i_c))
			row.add_child(p)
			row_pearls.append(p)
		board_box.add_child(row)
		pearls.append(row_pearls)
	_refresh_pearls()

func _refresh_pearls() -> void:
	for ri in pearls.size():
		var count: int = rows[ri]
		var row_arr: Array = pearls[ri]
		for i in row_arr.size():
			var p: Pearl = row_arr[i]
			var is_removed: bool = i >= count
			var is_selected: bool = (ri == selected_row) and (i in selected_indices)
			if is_removed:
				p.state = Pearl.State.REMOVED
				p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				p.mouse_filter = Control.MOUSE_FILTER_STOP
				if game_over or not player_turn:
					p.state = Pearl.State.DISABLED
				elif is_selected:
					p.state = Pearl.State.SELECTED
				else:
					p.state = Pearl.State.ACTIVE

func _on_pearl_clicked(ri: int, slot_index: int) -> void:
	if not player_turn or game_over:
		return
	if slot_index >= rows[ri]:
		return
	if selected_row != -1 and selected_row != ri:
		selected_row = -1
		selected_indices.clear()
	selected_row = ri
	if slot_index in selected_indices:
		selected_indices.erase(slot_index)
	else:
		selected_indices.append(slot_index)
	if selected_indices.is_empty():
		_clear_selection()
		return
	confirm_btn.visible = true
	_set_status("Remove %d from row %s? Click confirm." % [selected_indices.size(), char(65 + ri)])
	_refresh_pearls()

func _clear_selection() -> void:
	selected_row = -1
	selected_indices.clear()
	confirm_btn.visible = false
	_set_status("Your turn — click pearls to select, then confirm.")
	_refresh_pearls()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and selected_row != -1 and player_turn and not game_over:
		_clear_selection()

func _on_confirm() -> void:
	if selected_row == -1 or selected_indices.is_empty():
		return
	rows[selected_row] -= selected_indices.size()
	selected_row = -1
	selected_indices.clear()
	confirm_btn.visible = false
	if not game_started:
		game_started = true
		_refresh_diff_buttons()
	if _check_game_over():
		return
	player_turn = false
	_set_status("Computer is thinking…")
	_refresh_pearls()
	var gen := game_gen
	await get_tree().create_timer(0.7).timeout
	if game_gen == gen:
		_ai_move()

func _check_game_over() -> bool:
	var total := 0
	for r in rows:
		total += r
	if total == 0:
		game_over = true
		var msg := ""
		if player_turn:
			msg = "You took the last pearl. Computer wins!"
		else:
			msg = "Computer took the last pearl. You win!"
		_set_status(msg)
		_refresh_pearls()
		return true
	return false

func _set_difficulty(d: int) -> void:
	difficulty = d
	_refresh_diff_buttons()

func _refresh_diff_buttons() -> void:
	for i in diff_btns.size():
		var btn: Button = diff_btns[i]
		btn.set_pressed_no_signal(i == difficulty)
		btn.disabled = game_started and not game_over
		if i == difficulty:
			var col: Color = DIFF_COLORS[i]
			btn.add_theme_color_override("font_color", col)
			btn.add_theme_color_override("font_pressed_color", col)
			btn.add_theme_color_override("font_hover_color", col)
		else:
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_color_override("font_pressed_color")
			btn.remove_theme_color_override("font_hover_color")

func _random_move() -> void:
	var available: Array = []
	for i in rows.size():
		if rows[i] > 0:
			available.append(i)
	var move_row: int = available[randi() % available.size()]
	var move_count: int = 1 + randi() % rows[move_row]
	rows[move_row] -= move_count
	if _check_game_over():
		return
	player_turn = true
	_set_status("Computer removed %d from row %s. Your turn!" % [move_count, char(65 + move_row)])
	_refresh_pearls()

# Misère Nim AI
# big>=2: play normal Nim (XOR to 0)
# big==1: reduce that heap to 0 or 1 so opponent faces odd count of 1-heaps
# big==0: take a 1 (only 1s left)
func _ai_move() -> void:
	if randf() > OPTIMAL_CHANCE[difficulty]:
		_random_move()
		return

	var big := 0
	var ones := 0
	for r in rows:
		if r > 1:
			big += 1
		elif r == 1:
			ones += 1

	var move_row := -1
	var move_count := 0

	if big >= 2:
		var ns := 0
		for r in rows:
			ns ^= r
		if ns == 0:
			move_row = _largest_row()
			move_count = 1
		else:
			for i in rows.size():
				var target: int = rows[i] ^ ns
				if target < rows[i]:
					move_row = i
					move_count = rows[i] - target
					break
	elif big == 1:
		var bi := -1
		for i in rows.size():
			if rows[i] > 1:
				bi = i
				break
		if (ones + 1) % 2 == 1:
			move_row = bi
			move_count = rows[bi] - 1
		else:
			move_row = bi
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

	rows[move_row] -= move_count
	if _check_game_over():
		return
	player_turn = true
	_set_status("Computer removed %d from row %s. Your turn!" % [move_count, char(65 + move_row)])
	_refresh_pearls()

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
