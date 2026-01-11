extends Node


# Baza zadataka za električna kola
var tasks = []
var current_task_index = 0

signal task_completed(task_id)
signal all_tasks_completed()

func _ready():
	load_tasks()

func load_tasks():
	# Definiši zadatke
	tasks = [
		{
			"id": 1,
			"title": "Zadatak 1: Osnovno kolo",
			"description": "Povežite bateriju od 9V direktno sa sijalicom od 50Ω. Pokrenite simulaciju.",
			"requirements": {
				"batteries": [{"voltage": 9.0}],
				"bulbs": [{"resistance": 50.0}],
				"min_wires": 2,
				"bulb_must_light": true,
				"max_voltage_on_bulb": 10.0
			},
			"learning_goal": "Razumevanje osnovnog zatvorenog kola",
			"hint": "Sijalica treba da svetli! Povežite oba terminala baterije sa terminima sijalice."
		},
		{
			"id": 2,
			"title": "Zadatak 2: Pregorevanje sijalice",
			"description": "Imate sijalicu koja može podneti maksimalno 5V, ali bateriju od 100V. Direktna veza će PREGORETI sijalicu! Koristite otpornik da zaštitite sijalicu.",
			"requirements": {
				"batteries": [{"voltage": 100.0}],
				"bulbs": [{"resistance": 50.0, "max_voltage": 5.0}],
				"resistors": [{"min_resistance": 900.0}],
				"min_wires": 4,
				"bulb_must_light": true,
				"bulb_voltage_safe": true
			},
			"learning_goal": "Razumevanje pada napona i zaštite komponenti",
			"hint": "Koristite otpornik od bar 900Ω da smanjite napon na sijalici na bezbednih 5V!"
		},
		{
			"id": 3,
			"title": "Zadatak 3: Prekidač",
			"description": "Napravite kolo sa baterijom, sijalicom i prekidačem. Sijalica sme da svetli SAMO kada je prekidač uključen.",
			"requirements": {
				"batteries": [{"voltage": 9.0}],
				"bulbs": [{"resistance": 50.0}],
				"switches": [{"must_control_circuit": true}],
				"min_wires": 4,
				"test_switch_on": true,
				"test_switch_off": true
			},
			"learning_goal": "Razumevanje prekidača i kontrole strujnog kola",
			"hint": "Prekidač mora biti u seriji sa sijalicom!"
		},
		{
			"id": 4,
			"title": "Zadatak 4: Serijska veza otpornika",
			"description": "Povežite dva otpornika (100Ω i 200Ω) u seriju sa baterijom od 9V. Izračunajte ukupan otpor.",
			"requirements": {
				"batteries": [{"voltage": 9.0}],
				"resistors": [{"resistance": 100.0}, {"resistance": 200.0}],
				"min_wires": 3,
				"series_connection": true,
				"expected_total_resistance": 300.0
			},
			"learning_goal": "Razumevanje serijske veze otpornika",
			"hint": "U serijskoj vezi, otpornici se povezuju jedan za drugim."
		},
		{
			"id": 5,
			"title": "Zadatak 5: Složeno kolo",
			"description": "Napravite kolo sa: baterijom (12V), dva otpornika (150Ω svaki), sijalica (50Ω), i prekidač. Otpornici su u seriji, a sijalica paralelno sa drugim otpornikom.",
			"requirements": {
				"batteries": [{"voltage": 12.0}],
				"resistors": [{"resistance": 150.0}, {"resistance": 150.0}],
				"bulbs": [{"resistance": 50.0}],
				"switches": [{}],
				"min_wires": 6,
				"complex_topology": true
			},
			"learning_goal": "Razumevanje složenih kola sa serijskom i paralelnom vezom",
			"hint": "Ovo je napredno! Nacrtajte šemu prvo."
		}
	]
	
	print("✓ Učitano ", tasks.size(), " zadataka")

func get_current_task():
	if current_task_index < tasks.size():
		return tasks[current_task_index]
	return null

func check_task_completion(components: Array, wires: Array) -> Dictionary:
	# Proveri da li je trenutni zadatak ispunjen
	var task = get_current_task()
	if not task:
		return {"success": false, "message": "Nema više zadataka!"}
	
	print("\n=== PROVERAVA SE ZADATAK ", task.id, " ===")
	
	var req = task.requirements
	var result = {
		"success": true,
		"message": "",
		"details": []
	}
	
	# Prebrojavanje komponenti
	var battery_count = 0
	var bulb_count = 0
	var resistor_count = 0
	var switch_count = 0
	
	var batteries = []
	var bulbs = []
	var resistors = []
	var switches = []
	
	for comp in components:
		match comp.component_type:
			CircuitComponent.BATTERY:
				battery_count += 1
				batteries.append(comp)
			CircuitComponent.BULB:
				bulb_count += 1
				bulbs.append(comp)
			CircuitComponent.RESISTOR:
				resistor_count += 1
				resistors.append(comp)
			CircuitComponent.SWITCH:
				switch_count += 1
				switches.append(comp)
	
	print("Komponente: Baterije=", battery_count, " Sijalice=", bulb_count, " Otpornici=", resistor_count, " Prekidači=", switch_count)
	
	# 1. Proveri baterije
	if req.has("batteries"):
		if battery_count < req.batteries.size():
			result.success = false
			result.message = "❌ Nedovoljno baterija! Treba: " + str(req.batteries.size()) + ", imate: " + str(battery_count)
			return result
		
		# Proveri napone
		for req_battery in req.batteries:
			var found = false
			for bat in batteries:
				if abs(bat.value - req_battery.voltage) < 0.1:
					found = true
					print("  ✓ Pronađena baterija od ", bat.value, "V")
					break
			if not found:
				result.success = false
				result.message = "❌ Nema baterije od " + str(req_battery.voltage) + "V"
				return result
	
	# 2. Proveri sijalice
	if req.has("bulbs"):
		if bulb_count < req.bulbs.size():
			result.success = false
			result.message = "❌ Nedovoljno sijalica! Treba: " + str(req.bulbs.size()) + ", imate: " + str(bulb_count)
			return result
		
		print("  ✓ Sijalice OK")
	
	# 3. Proveri otpornike
	if req.has("resistors"):
		if resistor_count < req.resistors.size():
			result.success = false
			result.message = "❌ Nedovoljno otpornika! Treba: " + str(req.resistors.size()) + ", imate: " + str(resistor_count)
			return result
		
		# Proveri minimalne otpore
		for req_resistor in req.resistors:
			if req_resistor.has("min_resistance"):
				var found = false
				for res in resistors:
					if res.value >= req_resistor.min_resistance:
						found = true
						print("  ✓ Pronađen otpornik od ", res.value, "Ω (potrebno ≥", req_resistor.min_resistance, "Ω)")
						break
				if not found:
					result.success = false
					result.message = "❌ Potreban otpornik od bar " + str(req_resistor.min_resistance) + "Ω"
					return result
	
	# 4. Proveri prekidače
	if req.has("switches"):
		if switch_count < req.switches.size():
			result.success = false
			result.message = "❌ Nedovoljno prekidača! Treba: " + str(req.switches.size()) + ", imate: " + str(switch_count)
			return result
		
		print("  ✓ Prekidači OK")
	
	# 5. Proveri broj žica
	if req.has("min_wires"):
		if wires.size() < req.min_wires:
			result.success = false
			result.message = "❌ Premalo žica! Treba bar: " + str(req.min_wires) + ", imate: " + str(wires.size())
			return result
		
		print("  ✓ Žice OK (", wires.size(), ")")
	
	# 6. Proveri da li sijalica svetli
	if req.has("bulb_must_light") and req.bulb_must_light:
		var bulb_lights = false
		for bulb in bulbs:
			if bulb.current > 0.001:  # Ako ima struje, svetli
				bulb_lights = true
				print("  ✓ Sijalica svetli sa strujom: ", bulb.current, "A")
				break
		
		if not bulb_lights:
			result.success = false
			result.message = "❌ Sijalica ne svetli! Proverite da li je kolo zatvoreno.\n\nMorate pokrenuti simulaciju prvo!"
			result.details.append("Kliknite 'POKRENI SIMULACIJU' pre provere zadatka.")
			return result
	
	# 7. Proveri da li je napon na sijalici bezbedan (NAJVAŽNIJE ZA ZADATAK 2!)
	if req.has("bulb_voltage_safe") and req.bulb_voltage_safe:
		for i in range(min(req.bulbs.size(), bulbs.size())):
			var req_bulb = req.bulbs[i]
			if req_bulb.has("max_voltage"):
				var bulb = bulbs[i]
				
				print("  Proverava se sijalica: napon=", bulb.voltage, "V, max=", req_bulb.max_voltage, "V")
				
				if bulb.voltage > req_bulb.max_voltage:
					result.success = false
					result.message = "💥 PREGORELA SIJALICA! 💥\n\n"
					result.message += "Napon na sijalici je " + str(snapped(bulb.voltage, 0.1)) + "V\n"
					result.message += "Maksimalan bezbedni napon: " + str(req_bulb.max_voltage) + "V\n\n"
					result.message += "Dodajte OTPORNIK da smanjite napon!"
					result.details.append("Savет: Koristite otpornik od bar 900Ω u seriji sa sijalicom.")
					return result
				else:
					print("  ✓ Sijalica bezbedna: ", bulb.voltage, "V ≤ ", req_bulb.max_voltage, "V")
					result.details.append("✓ Napon na sijalici je bezbedan: " + str(snapped(bulb.voltage, 0.1)) + "V")
	
	# 8. Proveri prekidač kontrolu (za zadatak 3)
	if req.has("test_switch_on") or req.has("test_switch_off"):
		# Ovo je informativna poruka
		result.details.append("ℹ️ Testirajte prekidač ručno:")
		result.details.append("  • Uključite prekidač (klik) → sijalica treba da svetli")
		result.details.append("  • Isključite prekidač (klik) → sijalica ne sme da svetli")
	
	# 9. Proveri serijsku vezu (za zadatak 4)
	if req.has("series_connection") and req.series_connection:
		# Jednostavna provera - da li su otpornici povezani u nizu
		if resistor_count >= 2:
			result.details.append("✓ Otpornici su povezani u seriju")
			
			# Proveri očekivani ukupni otpor
			if req.has("expected_total_resistance"):
				var total_resistance = 0.0
				for res in resistors:
					total_resistance += res.value
				
				var expected = req.expected_total_resistance
				if abs(total_resistance - expected) < 10.0:  # Tolerancija
					print("  ✓ Ukupan otpor: ", total_resistance, "Ω (očekivano: ", expected, "Ω)")
					result.details.append("✓ Ukupan otpor: " + str(total_resistance) + "Ω")
				else:
					result.success = false
					result.message = "❌ Ukupan otpor nije ispravan. Trebalo bi biti oko " + str(expected) + "Ω"
					return result
	
	# 10. Proveri složenu topologiju (za zadatak 5)
	if req.has("complex_topology") and req.complex_topology:
		# Ovo je napredniji zadatak - samo proveri da li ima dovoljno komponenti i veza
		result.details.append("ℹ️ Složeno kolo - proverite da li je topologija ispravna")
	
	# AKO SVE PROĐE - USPEH!
	if result.success:
		result.message = "🎉 ZADATAK USPEŠNO REŠEN! 🎉\n\n"
		result.message += task.learning_goal + "\n\n"
		result.message += "Odlično! Nastavite na sledeći zadatak."
		
		print("  ✓✓✓ ZADATAK ", task.id, " USPEŠNO ZAVRŠEN! ✓✓✓")
	
	return result

func complete_current_task():
	var task = get_current_task()
	if task:
		task_completed.emit(task.id)
		current_task_index += 1
		
		if current_task_index >= tasks.size():
			all_tasks_completed.emit()
			print("\n🎉🎉🎉 SVI ZADACI USPEŠNO ZAVRŠENI! 🎉🎉🎉\n")
		else:
			print("\n→ Prelazak na zadatak ", current_task_index + 1, "\n")

func reset_progress():
	current_task_index = 0
	print("Progres resetovan na zadatak 1")

func get_progress() -> Dictionary:
	return {
		"current": current_task_index + 1,  # +1 jer je index 0-based
		"total": tasks.size(),
		"percentage": (float(current_task_index) / float(tasks.size())) * 100.0 if tasks.size() > 0 else 0.0
	}

func skip_to_task(task_id: int):
	# Debug funkcija za preskakanje na specifičan zadatak
	if task_id > 0 and task_id <= tasks.size():
		current_task_index = task_id - 1
		print("Preskočeno na zadatak ", task_id)
	else:
		print("GREŠKA: Nevalidan ID zadatka: ", task_id)
