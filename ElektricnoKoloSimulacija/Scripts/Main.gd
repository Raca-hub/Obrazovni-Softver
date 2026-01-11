extends Node2D
# Glavni kontroler simulacije električnih kola - 2D RADNA POVRŠINA

var current_view_mode = 0  # 0 = Schematic, 1 = 2D textures
var wire_start = null
var temp_wire = null
var components = []
var wires = []

var selected_component_type = null
var selected_component_value = 0.0
var is_placing_component = false

# Grid settings
var grid_size = 20
var show_grid = true

# Preload scene
var ComponentScene = preload("res://ElektricnoKoloSimulacija/Scenes/Component.tscn")
var WireScene = preload("res://ElektricnoKoloSimulacija/Scenes/Wire.tscn")

var component_panel
var info_label

func _ready():
	print("=== MAIN.GD (2D Radna površina) UČITANA ===")
	
	# Pronađi component panel
	component_panel = get_node_or_null("CanvasLayer/ComponentPanel")
	
	# Povezi signal iz component panela
	if component_panel:
		component_panel.component_selected.connect(_on_component_selected)
		print("✓ ComponentPanel povezan")
	else:
		print("✗ ComponentPanel nije pronađen!")
	
	# Setup info label
	info_label = get_node_or_null("CanvasLayer/InfoLabel")
	if not info_label:
		create_info_label()
	
	# Primoraj redraw da se vidi grid
	queue_redraw()

func create_info_label():
	# Kreiraj info label ako ne postoji
	var canvas = get_node_or_null("CanvasLayer")
	if not canvas:
		canvas = CanvasLayer.new()
		canvas.name = "CanvasLayer"
		add_child(canvas)
	
	info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "Shift+Klik za povezivanje žicama"
	info_label.position = Vector2(10, 10)
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color(1, 1, 0.5))
	canvas.add_child(info_label)

func _draw():
	# Nacrtaj grid pozadinu
	if show_grid:
		draw_grid()
	
	# Prikaži ghost preview kada postavljamo komponentu
	if is_placing_component:
		var mouse_pos = get_global_mouse_position()
		var snapped_pos = snap_to_grid(mouse_pos)
		draw_rect(Rect2(snapped_pos - Vector2(50, 30), Vector2(100, 60)), Color(0.5, 1.0, 0.5, 0.3))
		draw_rect(Rect2(snapped_pos - Vector2(50, 30), Vector2(100, 60)), Color(0.5, 1.0, 0.5, 0.8), false, 2.0)

func _process(delta):
	# Redraw za ghost preview
	if is_placing_component:
		queue_redraw()
	
	# Ažuriraj info label
	if info_label:
		if wire_start:
			info_label.text = "Kliknite na drugu komponentu da završite žicu (ESC za odustajanje)"
		elif is_placing_component:
			info_label.text = "Kliknite gde želite da postavite komponentu (ESC za odustajanje)"
		else:
			info_label.text = "Shift+Klik = Povežite žicama | Drag = Pomeri | Desni klik = Rotiraj"

func draw_grid():
	var viewport_size = get_viewport_rect().size
	var grid_color = Color(0.2, 0.2, 0.25, 1.0)
	
	# Vertikalne linije
	for x in range(0, int(viewport_size.x), grid_size):
		draw_line(Vector2(x, 0), Vector2(x, viewport_size.y), grid_color, 1.0)
	
	# Horizontalne linije
	for y in range(0, int(viewport_size.y), grid_size):
		draw_line(Vector2(0, y), Vector2(viewport_size.x, y), grid_color, 1.0)

func snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / grid_size) * grid_size,
		round(pos.y / grid_size) * grid_size
	)

func _on_component_selected(type, value):
	selected_component_type = type
	selected_component_value = value
	is_placing_component = true
	print("Selektovana komponenta: ", type, " vrednost: ", value)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Shift+Klik za povezivanje žicama
				if event.shift_pressed:
					print("Shift+Klik detektovan!")
					var clicked_component = get_component_at_position(event.position)
					if clicked_component:
						print("Kliknuta komponenta za žicu")
						if wire_start:
							finish_wire(event.position)
						else:
							start_wire(clicked_component, event.position)
				# Postavljanje komponente
				elif is_placing_component:
					add_component(selected_component_type, event.position)
					is_placing_component = false
	
	elif event is InputEventMouseMotion:
		# Ažuriraj privremenu žicu
		if wire_start and temp_wire:
			temp_wire.update_end_point(event.position)
	
	# ESC za cancel
	elif event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if is_placing_component:
				is_placing_component = false
				print("Otkazano dodavanje komponente")
			if wire_start:
				if temp_wire:
					temp_wire.queue_free()
					temp_wire = null
				wire_start = null
				print("Otkazano povezivanje")

func start_wire(component, pos):
	print("Započinjem žicu od komponente...")
	wire_start = {
		"component": component,
		"terminal": component.get_nearest_terminal(pos)
	}
	
	if not wire_start.terminal:
		print("ERROR: Terminal nije pronađen!")
		wire_start = null
		return
	
	# Kreiraj privremenu žicu
	temp_wire = WireScene.instantiate()
	var terminal_global_pos = component.global_position + wire_start.terminal.position
	temp_wire.set_start_point(terminal_global_pos)
	add_child(temp_wire)
	print("Privremena žica kreirana")

func finish_wire(pos):
	if not wire_start:
		return
	
	print("Završavam žicu...")
	
	var end_component = get_component_at_position(pos)
	if end_component and end_component != wire_start.component:
		var end_terminal = end_component.get_nearest_terminal(pos)
		
		if not end_terminal:
			print("ERROR: Krajnji terminal nije pronađen!")
			if temp_wire:
				temp_wire.queue_free()
			wire_start = null
			temp_wire = null
			return
		
		# Kreiraj finalnu žicu
		var wire = WireScene.instantiate()
		
		wire.start_terminal = wire_start.terminal
		wire.end_terminal = end_terminal
		wire.start_component = wire_start.component
		wire.end_component = end_component
		
		wire.start_terminal_index = wire_start.component.terminals.find(wire_start.terminal)
		wire.end_terminal_index = end_component.terminals.find(end_terminal)
		
		print("Start terminal index: ", wire.start_terminal_index)
		print("End terminal index: ", wire.end_terminal_index)
		
		var start_base = Vector2(-40, 0) if wire.start_terminal_index == 0 else Vector2(40, 0)
		var end_base = Vector2(-40, 0) if wire.end_terminal_index == 0 else Vector2(40, 0)
		
		var start_rotated = start_base.rotated(deg_to_rad(wire_start.component.rotation_degrees))
		var end_rotated = end_base.rotated(deg_to_rad(end_component.rotation_degrees))
		
		var start_global_pos = wire_start.component.global_position + start_rotated
		var end_global_pos = end_component.global_position + end_rotated
		
		wire.clear_points()
		wire.add_point(wire.to_local(start_global_pos))
		wire.add_point(wire.to_local(end_global_pos))
		
		add_child(wire)
		wires.append(wire)
		
		wire_start.component.connect_to(end_component, wire)
		
		print("Žica uspešno kreirana!")
	else:
		print("Nije kliknuta validna komponenta za završetak")
	
	if temp_wire:
		temp_wire.queue_free()
		temp_wire = null
	wire_start = null

func get_component_at_position(pos):
	for comp in components:
		var rect = Rect2(comp.position - Vector2(50, 30), Vector2(100, 60))
		if rect.has_point(pos):
			return comp
	return null

func add_component(type, position):
	var component = ComponentScene.instantiate()
	component.init(type, selected_component_value)
	component.position = snap_to_grid(position)
	component.draggable = true
	component.set_view_mode(current_view_mode)
	add_child(component)
	components.append(component)
	print("Dodata komponenta na poziciju: ", component.position)

func simulate():
	print("=== POKREĆEM SIMULACIJU ===")
	print("Broj komponenti: ", components.size())
	print("Broj žica: ", wires.size())
	
	if components.size() == 0:
		show_error("Nema komponenti!")
		return
	
	if wires.size() == 0:
		show_error("Nema žica! Povežite komponente.")
		return
	
	CircuitSolver.solve_circuit(components, wires)
	update_visuals()
	
	print("=== REZULTATI ===")
	for i in range(components.size()):
		var comp = components[i]
		print("Komponenta ", i, ": struja=", comp.current, "A, napon=", comp.voltage, "V")
	
	print("Simulacija završena!")

func reset_circuit():
	for comp in components:
		comp.queue_free()
	for wire in wires:
		wire.queue_free()
	
	components.clear()
	wires.clear()
	print("Kolo resetovano")

func update_visuals():
	for wire in wires:
		wire.update_current_animation()
	
	for comp in components:
		comp.update_visual_state()

func show_error(message: String):
	print("GREŠKA: ", message)
	# Prikaži vizuelnu notifikaciju
	if info_label:
		var original_text = info_label.text
		info_label.text = "❌ GREŠKA: " + message
		info_label.add_theme_color_override("font_color", Color.RED)
		
		await get_tree().create_timer(3.0).timeout
		
		info_label.text = original_text
		info_label.add_theme_color_override("font_color", Color(1, 1, 0.5))
