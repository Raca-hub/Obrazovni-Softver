extends Control
# Task Manager - glavna scena za vežbanje sa zadacima

var task_panel  # Kreira se u setup_ui()
var circuit_2d  # Kreira se u create_circuit_views()
var circuit_3d  # Kreira se u create_circuit_views()

var task_system  # Reference na TaskSystems autoload
var current_view_mode = 0  # 0 = 2D, 1 = 3D

func _ready():
	print("=== TASK MANAGER POKRENUT ===")
	
	# Koristi TaskSystems autoload (globalni singleton)
	task_system = TaskSystems
	
	# Povezi signale
	task_system.task_completed.connect(_on_task_completed)
	task_system.all_tasks_completed.connect(_on_all_tasks_completed)
	
	# Setup UI (kreira task_panel, circuit_2d, circuit_3d)
	setup_ui()
	
	# Prikaži prvi zadatak (NAKON što je task_panel kreiran)
	# Koristi call_deferred da osiguramo da su svi node-ovi dodati u stablo
	call_deferred("update_task_display")
	
	# Postavi početni view mode
	set_view_mode(0)

func setup_ui():
	# Kreiraj pozadinu
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -1
	add_child(bg)
	
	# Task Panel (gore)
	create_task_panel()
	
	# View selector (desno gore)
	create_view_selector()
	
	# Circuit views (dinamički)
	create_circuit_views()
	
	# Control buttons (dole)
	create_control_buttons()

func create_task_panel():
	print("  → Kreiram Task Panel...")
	
	var panel = Panel.new()
	panel.name = "TaskPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.size = Vector2(0, 150)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Naslov zadatka
	var title = Label.new()
	title.name = "TaskTitle"
	title.text = "Zadatak učitavanje..."
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(title)
	
	# Opis zadatka
	var desc = Label.new()
	desc.name = "TaskDescription"
	desc.text = "Opis zadatka..."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 14)
	vbox.add_child(desc)
	
	# Hint
	var hint = Label.new()
	hint.name = "TaskHint"
	hint.text = "💡 Savet: ..."
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(hint)
	
	# Progress bar
	var progress = ProgressBar.new()
	progress.name = "TaskProgress"
	progress.min_value = 0
	progress.max_value = 100
	progress.value = 0
	progress.show_percentage = false
	vbox.add_child(progress)
	
	task_panel = panel
	print("  ✓ Task Panel kreiran!")

func create_view_selector():
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-220, 160)
	panel.size = Vector2(200, 100)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_all", 10)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 5)
	margin.add_child(inner_vbox)
	
	var label = Label.new()
	label.text = "PRIKAZ:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(label)
	
	var btn_2d = Button.new()
	btn_2d.text = "🖼 2D Radna Površina"
	btn_2d.pressed.connect(func(): set_view_mode(0))
	inner_vbox.add_child(btn_2d)
	
	var btn_3d = Button.new()
	btn_3d.text = "🎲 3D Pregled"
	btn_3d.pressed.connect(func(): set_view_mode(1))
	inner_vbox.add_child(btn_3d)

func create_circuit_views():
	# 2D Circuit View (Node2D based - radna površina)
	var view_2d = load("res://ElektricnoKoloSimulacija/Scenes/Main.tscn").instantiate()
	view_2d.name = "Circuit2DView"
	view_2d.position = Vector2(0, 170)
	add_child(view_2d)
	circuit_2d = view_2d
	
	# 3D Circuit View (3D orbit - samo pregled)
	var view_3d_container = SubViewportContainer.new()
	view_3d_container.name = "Circuit3DView"
	view_3d_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	view_3d_container.offset_top = 170
	view_3d_container.offset_bottom = -80
	view_3d_container.visible = false
	add_child(view_3d_container)
	
	var viewport_3d = SubViewport.new()
	viewport_3d.size = Vector2(1280, 720)
	view_3d_container.add_child(viewport_3d)
	
	var world_3d = load("res://ElektricnoKoloSimulacija/Scenes/World3D.tscn").instantiate()
	viewport_3d.add_child(world_3d)
	
	circuit_3d = view_3d_container

func create_control_buttons():
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.size = Vector2(0, 70)
	add_child(panel)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_all", 10)
	hbox.add_child(margin)
	
	var inner_hbox = HBoxContainer.new()
	inner_hbox.add_theme_constant_override("separation", 10)
	margin.add_child(inner_hbox)
	
	# Simulate button
	var simulate_btn = Button.new()
	simulate_btn.text = "▶ POKRENI SIMULACIJU"
	simulate_btn.custom_minimum_size = Vector2(200, 50)
	simulate_btn.pressed.connect(_on_simulate_pressed)
	inner_hbox.add_child(simulate_btn)
	
	# Check task button
	var check_btn = Button.new()
	check_btn.text = "✓ PROVERI ZADATAK"
	check_btn.custom_minimum_size = Vector2(200, 50)
	check_btn.pressed.connect(_on_check_task_pressed)
	inner_hbox.add_child(check_btn)
	
	# Reset button
	var reset_btn = Button.new()
	reset_btn.text = "🗑 OČISTI"
	reset_btn.custom_minimum_size = Vector2(150, 50)
	reset_btn.pressed.connect(_on_reset_pressed)
	inner_hbox.add_child(reset_btn)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_hbox.add_child(spacer)
	
	# Back to menu
	var menu_btn = Button.new()
	menu_btn.text = "← NAZAD NA MENI"
	menu_btn.custom_minimum_size = Vector2(200, 50)
	menu_btn.pressed.connect(_on_back_to_menu)
	inner_hbox.add_child(menu_btn)

func update_task_display():
	var task = task_system.get_current_task()
	if not task:
		print("UPOZORENJE: Nema trenutnog zadatka")
		return
	
	if not task_panel:
		print("UPOZORENJE: task_panel još ne postoji")
		return
	
	var title = task_panel.get_node_or_null("MarginContainer/VBoxContainer/TaskTitle")
	var desc = task_panel.get_node_or_null("MarginContainer/VBoxContainer/TaskDescription")
	var hint = task_panel.get_node_or_null("MarginContainer/VBoxContainer/TaskHint")
	var progress = task_panel.get_node_or_null("MarginContainer/VBoxContainer/TaskProgress")
	
	if not title or not desc or not hint or not progress:
		print("GREŠKA: Neki UI elementi nisu pronađeni!")
		print("  title=", title != null)
		print("  desc=", desc != null)
		print("  hint=", hint != null)
		print("  progress=", progress != null)
		return
	
	title.text = task.title
	desc.text = task.description
	hint.text = "💡 Savet: " + task.hint
	
	var prog = task_system.get_progress()
	progress.value = prog.percentage
	
	print("✓ Zadatak prikazan: ", task.title)

func set_view_mode(mode: int):
	current_view_mode = mode
	
	if mode == 0:  # 2D
		circuit_2d.visible = true
		circuit_3d.visible = false
		print("Prebačeno na 2D radnu površinu")
	else:  # 3D
		circuit_2d.visible = false
		circuit_3d.visible = true
		print("Prebačeno na 3D pregled")
		
		# Sinhronizuj komponente u 3D prikaz
		sync_components_to_3d()

func sync_components_to_3d():
	# Ažuriraj 3D prikaz sa komponentama iz 2D
	if circuit_2d and circuit_3d:
		var components = circuit_2d.components
		var wires = circuit_2d.wires
		
		# Postavi view mode za sve komponente
		for comp in components:
			comp.set_view_mode(2)  # 3D mode
		
		for wire in wires:
			wire.set_view_mode(2)

func _on_simulate_pressed():
	# Pokreni simulaciju na 2D view-u
	if circuit_2d:
		circuit_2d.simulate()
		
		# Ako smo u 3D modu, ažuriraj vizuale
		if current_view_mode == 1:
			sync_components_to_3d()

func _on_check_task_pressed():
	# Proveri da li je zadatak ispunjen
	if not circuit_2d:
		return
	
	var components = circuit_2d.components
	var wires = circuit_2d.wires
	
	var result = task_system.check_task_completion(components, wires)
	
	# Prikaži rezultat
	var dialog = AcceptDialog.new()
	dialog.title = "Provera Zadatka"
	dialog.dialog_text = result.message
	
	if result.has("details") and result.details.size() > 0:
		dialog.dialog_text += "\n\n" + "\n".join(result.details)
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Ako je uspešno, pređi na sledeći zadatak
	if result.success:
		task_system.complete_current_task()
		
		# Pričekaj pa ažuriraj prikaz
		await get_tree().create_timer(1.5).timeout
		update_task_display()

func _on_reset_pressed():
	if circuit_2d:
		circuit_2d.reset_circuit()

func _on_back_to_menu():
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_task_completed(task_id):
	print("✓ Zadatak ", task_id, " završen!")

func _on_all_tasks_completed():
	var dialog = AcceptDialog.new()
	dialog.title = "🎉 ČESTITAMO! 🎉"
	dialog.dialog_text = "Uspešno ste završili SVE zadatke iz električnih kola!\n\nOdlično poznavanje fizike!"
	add_child(dialog)
	dialog.popup_centered_ratio(0.4)
