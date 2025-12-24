extends Node2D

# Glavni kontroler simulacije električnih kola
var current_view_mode=0
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

# Preload scena
var ComponentScene = preload("res://ElektricnoKoloSimulacija/Scenes/Component.tscn")
var WireScene = preload("res://ElektricnoKoloSimulacija/Scenes/Wire.tscn")
@onready var component_panel = $CanvasLayer/ComponentPanel
@onready var view_mode_panel = $CanvasLayer/ViewModePanel
@onready var world_3d = $SubViewportContainer/SubViewport/World3D
@onready var viewport_container = $SubViewportContainer


func _ready():
	print("=== MAIN.GD UČITAN ===")
	
	# Povezi signal iz component panela
	if component_panel:
		component_panel.component_selected.connect(_on_component_selected)
		print("✓ ComponentPanel povezan")
	else:
		print("✗ ComponentPanel nije pronađen!")
	
	# Povezi signal iz view mode panela
	if view_mode_panel:
		view_mode_panel.view_mode_changed.connect(_on_view_mode_changed)
		print("✓ ViewModePanel povezan")
	else:
		print("✗ ViewModePanel nije pronađen!")
	
	# Proveri 3D komponente
	if viewport_container:
		print("✓ SubViewportContainer pronađen")
		viewport_container.visible = false  # Sakrij na početku
	else:
		print("✗ SubViewportContainer nije pronađen!")
	
	if world_3d:
		print("✓ World3D pronađen")
	else:
		print("✗ World3D nije pronađen!")
	
	# Primoraj redraw da se vidi grid
	queue_redraw()

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

func draw_grid():
	var viewport_size = get_viewport_rect().size
	var grid_color = Color(0.8, 0.8, 0.8, 1.0)  # Svetlija siva
	
	# Vertikalne linije
	for x in range(0, int(viewport_size.x), grid_size):
		draw_line(Vector2(x, 0), Vector2(x, viewport_size.y), grid_color, 1.0)
	
	# Horizontalne linije
	for y in range(0, int(viewport_size.y), grid_size):
		draw_line(Vector2(0, y), Vector2(viewport_size.x, y), grid_color, 1.0)

func snap_to_grid(pos: Vector2) -> Vector2:
	# Zaokruži poziciju na najbliži grid
	return Vector2(
		round(pos.x / grid_size) * grid_size,
		round(pos.y / grid_size) * grid_size
	)

func _on_component_selected(type, value):
	# Kada korisnik klikne dugme za komponentu
	selected_component_type = type
	selected_component_value = value
	is_placing_component = true
	print("Selektovana komponenta: ", type)

func _on_view_mode_changed(mode):
	# Promeni view mode za sve komponente i žice
	current_view_mode = mode
	print("")
	print("╔════════════════════════════════════════╗")
	print("║ VIEW MODE PROMENJEN NA: ", mode, "         ║")
	print("╚════════════════════════════════════════╝")
	print("Broj komponenti: ", components.size())
	print("Broj žica: ", wires.size())
	
	# Prikaži/sakrij 3D viewport
	if viewport_container:
		print(">>> Postavljam viewport_container.visible = ", (mode == 2))
		viewport_container.visible = (mode == 2)
		print(">>> viewport_container.visible je sada: ", viewport_container.visible)
	else:
		print("!!! GREŠKA: viewport_container je NULL!")
	
	# Ažuriraj komponente
	for i in range(components.size()):
		var comp = components[i]
		print("  Ažuriram komponentu ", i, " (tip: ", comp.component_type, ")")
		comp.set_view_mode(mode)
		comp.queue_redraw()
	
	# Ažuriraj žice
	for i in range(wires.size()):
		var wire = wires[i]
		print("  Ažuriram žicu ", i)
		wire.set_view_mode(mode)
	
	print("✓ Ažurirano ", components.size(), " komponenti i ", wires.size(), " žica")
	print("")
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Da li držimo Shift za povezivanje žicama?
				if event.shift_pressed:
					print("Shift+Klik detektovan!")
					# Mod za povezivanje žicama
					var clicked_component = get_component_at_position(event.position)
					if clicked_component:
						print("Kliknuta komponenta za žicu")
						if wire_start:
							# Završi žicu
							finish_wire(event.position)
						else:
							# Započni žicu
							start_wire(clicked_component, event.position)
				# Da li postavljamo komponentu?
				elif is_placing_component:
					add_component(selected_component_type, event.position)
					is_placing_component = false
			else:
				# Puštamo klik - završavamo žicu samo ako je bila započeta
				if wire_start and not event.shift_pressed:
					# Ne završavaj automatski, čekaj drugi Shift+Klik
					pass
	
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
	
	# Proveri da li smo kliknuli na drugu komponentu
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
		
		# Postavi reference na terminale i komponente
		wire.start_terminal = wire_start.terminal
		wire.end_terminal = end_terminal
		wire.start_component = wire_start.component
		wire.end_component = end_component
		
		# Nađi indekse terminala
		wire.start_terminal_index = wire_start.component.terminals.find(wire_start.terminal)
		wire.end_terminal_index = end_component.terminals.find(end_terminal)
		
		print("Start terminal index: ", wire.start_terminal_index)
		print("End terminal index: ", wire.end_terminal_index)
		
		# Postavi vizuelne tačke
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
		
		# Poveži komponente u električnom smislu
		wire_start.component.connect_to(end_component, wire)
		
		print("Žica uspešno kreirana!")
	else:
		print("Nije kliknuta validna komponenta za završetak")
	
	# Očisti privremenu žicu
	if temp_wire:
		temp_wire.queue_free()
		temp_wire = null
	wire_start = null

func get_component_at_position(pos):
	# Pronađi komponentu na datoj poziciji
	for comp in components:
		var rect = Rect2(comp.position - Vector2(50, 30), Vector2(100, 60))
		if rect.has_point(pos):
			return comp
	return null

func add_component(type, position):
	# Dodaj novu komponentu
	var component = ComponentScene.instantiate()
	component.init(type, selected_component_value)
	component.position = snap_to_grid(position)
	component.draggable = true
	component.set_view_mode(current_view_mode)  # Postavi trenutni view mode
	add_child(component)
	components.append(component)
	print("Dodata komponenta na poziciju: ", component.position)

func simulate():
	# Glavna simulacija - reši Kirchhoffove zakone
	print("=== POKREĆEM SIMULACIJU ===")
	print("Broj komponenti: ", components.size())
	print("Broj žica: ", wires.size())
	
	# Debug info o komponentama
	for i in range(components.size()):
		var comp = components[i]
		print("Komponenta ", i, ": tip=", comp.component_type, " vrednost=", comp.value)
	
	# Debug info o žicama
	for i in range(wires.size()):
		var wire = wires[i]
		print("Žica ", i, ": start_comp=", wire.start_component != null, " end_comp=", wire.end_component != null)
	
	if components.size() == 0:
		print("GREŠKA: Nema komponenti!")
		return
	
	if wires.size() == 0:
		print("GREŠKA: Nema žica!")
		return
	
	CircuitSolver.solve_circuit(components, wires)
	update_visuals()
	
	# Debug struje nakon simulacije
	print("=== REZULTATI ===")
	for i in range(components.size()):
		var comp = components[i]
		print("Komponenta ", i, ": struja=", comp.current, "A, napon=", comp.voltage, "V")
	
	print("Simulacija završena!")

func reset_circuit():
	# Obriši sve komponente i žice
	for comp in components:
		comp.queue_free()
	for wire in wires:
		wire.queue_free()
	
	components.clear()
	wires.clear()
	print("Kolo resetovano")

func update_visuals():
	# Ažuriraj vizuelni prikaz (animacija struje, boja žica, itd.)
	for wire in wires:
		wire.update_current_animation()
	
	for comp in components:
		comp.update_visual_state()
