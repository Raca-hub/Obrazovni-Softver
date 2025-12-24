extends Panel

# UI panel za dodavanje komponenti u kolo

signal component_selected(type, value)

var buttons = []

func _ready():
	# Kreiraj dugmad za svaku komponentu
	create_component_buttons()

func create_component_buttons():
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	add_child(vbox)
	
	# Dodaj margin container za padding
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(inner_vbox)
	
	# Dodaj naslov
	var title = Label.new()
	title.text = "⚡ KOMPONENTE ⚡"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	inner_vbox.add_child(title)
	
	inner_vbox.add_child(HSeparator.new())
	
	# Baterija
	var battery_btn = create_button("🔋 Baterija (9V)", CircuitComponent.BATTERY, 9.0)
	inner_vbox.add_child(battery_btn)
	
	# Otpornik
	var resistor_btn = create_button("⚡ Otpornik (100Ω)", CircuitComponent.RESISTOR, 100.0)
	inner_vbox.add_child(resistor_btn)
	
	# Sijalica
	var bulb_btn = create_button("💡 Sijalica (50Ω)", CircuitComponent.BULB, 50.0)
	inner_vbox.add_child(bulb_btn)
	
	# Prekidač
	var switch_btn = create_button("🔘 Prekidač", CircuitComponent.SWITCH, 0.0)
	inner_vbox.add_child(switch_btn)
	
	inner_vbox.add_child(HSeparator.new())
	
	# Uputstva
	var help = Label.new()
	help.text = "KONTROLE:\n• Klik: Dodaj komponentu\n• Drag: Pomeri\n• Desni klik: Rotiraj\n• Shift+Klik: Povezi žicom"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD
	help.add_theme_font_size_override("font_size", 10)
	inner_vbox.add_child(help)
	
	inner_vbox.add_child(HSeparator.new())
	
	# Dugme za simulaciju
	var simulate_btn = Button.new()
	simulate_btn.text = "▶ SIMULIRAJ"
	simulate_btn.pressed.connect(_on_simulate_pressed)
	inner_vbox.add_child(simulate_btn)
	
	# Dugme za reset
	var reset_btn = Button.new()
	reset_btn.text = "🗑 OČISTI SVE"
	reset_btn.pressed.connect(_on_reset_pressed)
	inner_vbox.add_child(reset_btn)

func create_button(text: String, type, value: float) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(150, 40)
	btn.pressed.connect(_on_component_button_pressed.bind(type, value))
	buttons.append(btn)
	return btn

func _on_component_button_pressed(type, value):
	component_selected.emit(type, value)

func _on_simulate_pressed():
	get_parent().get_parent().simulate()

func _on_reset_pressed():
	get_parent().get_parent().reset_circuit()
