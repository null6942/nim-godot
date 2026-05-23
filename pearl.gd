class_name Pearl
extends Control

signal clicked

enum State { ACTIVE, SELECTED, REMOVED, DISABLED }

const SIZE := 52.0

const CREAM     := Color(0.93, 0.90, 0.85, 1.0)
const MID       := Color(0.78, 0.75, 0.70, 1.0)
const BLUE_TINT := Color(0.80, 0.88, 0.96, 1.0)
const GOLD      := Color("f0c040")
const GOLD_DIM  := Color(0.94, 0.75, 0.10, 1.0)

var state: int = State.ACTIVE:
	set(v):
		state = v
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = MOUSE_FILTER_STOP

func _draw() -> void:
	var c := Vector2(SIZE * 0.5, SIZE * 0.5)
	var r := SIZE * 0.5 - 3.0

	if state == State.REMOVED:
		return

	var selected := state == State.SELECTED

	draw_circle(c + Vector2(1.5, 2.5), r, Color(0, 0, 0, 0.4))

	if selected:
		draw_arc(c, r + 6.0, 0.0, TAU, 64, Color(GOLD.r, GOLD.g, GOLD.b, 0.25), 5.0, true)
		draw_arc(c, r + 3.0, 0.0, TAU, 64, Color(GOLD.r, GOLD.g, GOLD.b, 0.55), 3.0, true)
		draw_circle(c, r, Color(0.95, 0.82, 0.45, 1.0))
	else:
		draw_circle(c, r, CREAM)

	draw_circle(c + Vector2(r * 0.12, r * 0.18), r * 0.88, Color(MID.r, MID.g, MID.b, 0.45))
	draw_circle(c + Vector2(r * 0.28, -r * 0.08), r * 0.58, Color(BLUE_TINT.r, BLUE_TINT.g, BLUE_TINT.b, 0.28))

	var h := c + Vector2(-r * 0.27, -r * 0.30)
	draw_circle(h, r * 0.46, Color(1, 1, 1, 0.72))
	draw_circle(h + Vector2(-r * 0.09, -r * 0.09), r * 0.16, Color(1, 1, 1, 1.0))

	if selected:
		draw_arc(c, r + 2.0, 0.0, TAU, 64, GOLD, 2.5, true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if state == State.ACTIVE or state == State.SELECTED:
			clicked.emit()
			accept_event()
