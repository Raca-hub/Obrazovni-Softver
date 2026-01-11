extends Control
# Glavni meni za izbor tipa simulacije

func _ready():
	setup_ui()

func setup_ui():
	# Kreiraj pozadinu
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Centrirani VBox container
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	center_container.add_child(vbox)
	
	# Naslov
	var title = Label.new()
	title.text = "⚡ FIZIKA SIMULACIJE ⚡"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(title)
	
	# Podnaslov
	var subtitle = Label.new()
	subtitle.text = "Izaberite tip simulacije"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(subtitle)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(spacer)
	
	# Dugme za ELEKTRIČNA KOLA
	var electric_btn = create_menu_button("⚡ ELEKTRIČNA KOLA", Color(1.0, 0.8, 0.2))
	electric_btn.pressed.connect(_on_electric_pressed)
	vbox.add_child(electric_btn)
	
	# Dugme za OSCILACIJE
	var oscillation_btn = create_menu_button("〜 OSCILACIJE", Color(0.3, 0.8, 1.0))
	oscillation_btn.pressed.connect(_on_oscillation_pressed)
	vbox.add_child(oscillation_btn)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(spacer2)
	
	# Exit dugme
	var exit_btn = create_menu_button("✕ IZLAZ", Color(0.8, 0.3, 0.3))
	exit_btn.custom_minimum_size = Vector2(300, 50)
	exit_btn.pressed.connect(_on_exit_pressed)
	vbox.add_child(exit_btn)

func create_menu_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(400, 80)
	btn.add_theme_font_size_override("font_size", 24)
	
	# Stilizuj dugme
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color.darkened(0.5)
	style_normal.corner_radius_top_left = 10
	style_normal.corner_radius_top_right = 10
	style_normal.corner_radius_bottom_left = 10
	style_normal.corner_radius_bottom_right = 10
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 3
	style_normal.border_color = color
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = color.darkened(0.3)
	style_hover.corner_radius_top_left = 10
	style_hover.corner_radius_top_right = 10
	style_hover.corner_radius_bottom_left = 10
	style_hover.corner_radius_bottom_right = 10
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 3
	style_hover.border_color = color.lightened(0.3)
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = color.darkened(0.2)
	style_pressed.corner_radius_top_left = 10
	style_pressed.corner_radius_top_right = 10
	style_pressed.corner_radius_bottom_left = 10
	style_pressed.corner_radius_bottom_right = 10
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 3
	style_pressed.border_width_bottom = 3
	style_pressed.border_color = color
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	
	return btn

func _on_electric_pressed():
	print("Učitavam ELEKTRIČNA KOLA simulaciju...")
	# Prebaci na scenu za električna kola
	get_tree().change_scene_to_file("res://ElektricnoKoloSimulacija/Scenes/TaskManager.tscn")

func _on_oscillation_pressed():
	print("Učitavam OSCILACIJE simulaciju...")
	# Ovo možeš implementirati kasnije
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Oscilacije simulacija još nije implementirana!"
	dialog.title = "U izradi"
	add_child(dialog)
	dialog.popup_centered()

func _on_exit_pressed():
	get_tree().quit()
