extends Panel

# Panel za prebacivanje između različitih načina prikaza

signal view_mode_changed(mode)

enum ViewMode {
	SCHEMATIC,  # Šematski prikaz (linije i simboli)
	VIEW_2D,    # 2D slike komponenti
	VIEW_3D     # 3D modeli komponenti
}

var current_mode = ViewMode.SCHEMATIC

func _ready():
	create_buttons()

func create_buttons():
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 5)
	add_child(hbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	hbox.add_child(margin)
	
	var inner_hbox = HBoxContainer.new()
	inner_hbox.add_theme_constant_override("separation", 8)
	margin.add_child(inner_hbox)
	
	# Schematic dugme
	var schematic_btn = Button.new()
	schematic_btn.text = "📐 Schematic"
	schematic_btn.custom_minimum_size = Vector2(120, 40)
	schematic_btn.pressed.connect(_on_mode_button_pressed.bind(ViewMode.SCHEMATIC))
	inner_hbox.add_child(schematic_btn)
	
	# 2D dugme
	var view_2d_btn = Button.new()
	view_2d_btn.text = "🖼 2D View"
	view_2d_btn.custom_minimum_size = Vector2(120, 40)
	view_2d_btn.pressed.connect(_on_mode_button_pressed.bind(ViewMode.VIEW_2D))
	inner_hbox.add_child(view_2d_btn)
	
	# 3D dugme
	var view_3d_btn = Button.new()
	view_3d_btn.text = "🎲 3D View"
	view_3d_btn.custom_minimum_size = Vector2(120, 40)
	view_3d_btn.pressed.connect(_on_mode_button_pressed.bind(ViewMode.VIEW_3D))
	inner_hbox.add_child(view_3d_btn)
	
	# Highlight trenutni mod
	update_button_states()

func _on_mode_button_pressed(mode):
	print("*** DUGME PRITISNUTO: ", get_mode_name(mode), " (mode=", mode, ") ***")
	
	if current_mode != mode:
		current_mode = mode
		print("*** EMITUJEM SIGNAL view_mode_changed sa modom: ", mode, " ***")
		view_mode_changed.emit(mode)
		update_button_states()
	else:
		print("*** Već je na modu: ", mode, " ***")

func update_button_states():
	# Highlight aktivno dugme
	var buttons = get_tree().get_nodes_in_group("view_mode_buttons")
	# Ovo možeš implementirati ako želiš da se dugmad bojе drugačije

func get_mode_name(mode):
	match mode:
		ViewMode.SCHEMATIC:
			return "Schematic"
		ViewMode.VIEW_2D:
			return "2D View"
		ViewMode.VIEW_3D:
			return "3D View"
	return "Unknown"
