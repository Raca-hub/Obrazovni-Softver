extends Node
class_name CircuitSolver

# Ovaj skript implementira rešavanje električnih kola koristeći
# nodal analysis (analizu čvorova) - primena Kirchhoffovih zakona

static func solve_circuit(components: Array, wires: Array):
	# Glavna funkcija za rešavanje kola
	
	print("CircuitSolver: Identifikujem čvorove...")
	
	# 1. Identifikuj sve čvorove
	var nodes = identify_nodes(components, wires)
	
	print("CircuitSolver: Pronađeno ", nodes.size(), " čvorova")
	
	if nodes.size() == 0:
		print("GREŠKA: Nema čvorova!")
		return false
	
	# 2. Nađi referencni čvor (ground)
	var ground_node = find_ground_node(nodes)
	
	print("CircuitSolver: Ground čvor postavljen")
	
	# 3. Kreiraj mapiranje node_id -> equation_index
	var non_ground_nodes = nodes.filter(func(n): return n != ground_node)
	var node_to_eq_index = {}
	for i in range(non_ground_nodes.size()):
		node_to_eq_index[non_ground_nodes[i].id] = i
	
	print("CircuitSolver: Node-to-equation mapping: ", node_to_eq_index)
	
	# 4. Primeni Kirchhoffov zakon struje (KCL) na svaki čvor
	var equations = build_nodal_equations(nodes, ground_node, components, node_to_eq_index)
	
	print("CircuitSolver: Kreirano ", equations.size(), " jednačina")
	
	# 5. Reši sistem linearnih jednačina
	var voltages = solve_equations(equations, non_ground_nodes.size())
	
	print("CircuitSolver: Rešeni naponi: ", voltages)
	
	# 6. Izračunaj struje kroz komponente
	calculate_currents(components, wires, voltages, nodes, node_to_eq_index, ground_node)
	
	print("CircuitSolver: Struje izračunate")
	
	return true

static func identify_nodes(components: Array, wires: Array) -> Array:
	# Pronađi sve čvorove u kolu
	# Čvor je tačka gde se susreću 2 ili više komponenti
	
	var nodes = []
	var terminal_to_node = {}  # Mapira terminal (kao string key) na čvor
	var next_node_id = 0
	
	# Kreiraj početne čvorove za svaki terminal svake komponente
	for comp in components:
		for i in range(comp.terminals.size()):
			var terminal = comp.terminals[i]
			# Kreiraj jedinstveni key za terminal (komponenta + index terminala)
			var term_key = str(comp.get_instance_id()) + "_" + str(i)
			
			if not terminal_to_node.has(term_key):
				var node = {
					"id": next_node_id,
					"terminals": [terminal],
					"components": [comp],
					"terminal_keys": [term_key],
					"voltage": 0.0
				}
				nodes.append(node)
				terminal_to_node[term_key] = node
				next_node_id += 1
	
	print("  Kreirano ", nodes.size(), " početnih čvorova")
	
	# Spoji čvorove koji su povezani žicama
	for wire in wires:
		if wire.start_component and wire.end_component and wire.start_terminal and wire.end_terminal:
			# Pronađi indekse terminala
			var start_term_idx = wire.start_component.terminals.find(wire.start_terminal)
			var end_term_idx = wire.end_component.terminals.find(wire.end_terminal)
			
			if start_term_idx == -1 or end_term_idx == -1:
				print("  UPOZORENJE: Žica ima nevalidne terminale!")
				continue
			
			var start_key = str(wire.start_component.get_instance_id()) + "_" + str(start_term_idx)
			var end_key = str(wire.end_component.get_instance_id()) + "_" + str(end_term_idx)
			
			if terminal_to_node.has(start_key) and terminal_to_node.has(end_key):
				var node1 = terminal_to_node[start_key]
				var node2 = terminal_to_node[end_key]
				
				if node1 != node2:
					# Spoji ova dva čvora u jedan
					print("  Spajam čvorove ", node1.id, " i ", node2.id)
					merge_nodes(node1, node2, nodes, terminal_to_node)
	
	print("  Konačan broj čvorova: ", nodes.size())
	
	return nodes

static func merge_nodes(node1, node2, nodes: Array, terminal_to_node: Dictionary):
	# Spoji dva čvora u jedan
	for terminal in node2.terminals:
		node1.terminals.append(terminal)
	
	for comp in node2.components:
		if not node1.components.has(comp):
			node1.components.append(comp)
	
	for key in node2.terminal_keys:
		node1.terminal_keys.append(key)
		terminal_to_node[key] = node1
	
	nodes.erase(node2)

static func find_ground_node(nodes: Array):
	# Pronađi ili označi referencni čvor (ground = 0V)
	# Za jednostavnost, biramo prvi čvor
	if nodes.size() > 0:
		nodes[0].voltage = 0.0
		nodes[0].is_ground = true
		return nodes[0]
	return null

static func build_nodal_equations(nodes: Array, ground: Dictionary, components: Array, node_to_eq_index: Dictionary) -> Array:
	# Izgraditi sistem jednačina za svaki čvor (osim ground-a)
	# KCL: suma struja koja ulazi u čvor = suma struja koja izlazi
	
	var equations = []
	var non_ground_nodes = nodes.filter(func(n): return n != ground)
	
	print("  Gradim jednačine za ", non_ground_nodes.size(), " čvorova")
	print("  Ground čvor ID: ", ground.id)
	
	for node in non_ground_nodes:
		print("  Obrađujem čvor ID: ", node.id, " -> eq_index: ", node_to_eq_index[node.id])
		
		var eq_index = node_to_eq_index[node.id]
		
		var equation = {
			"coefficients": {},  # Koeficijenti po INDEKSU jednačine (ne po node ID)
			"constant": 0.0
		}
		
		# Za svaku komponentu u čvoru
		for comp in node.components:
			print("    Komponenta: tip=", comp.component_type, " vrednost=", comp.value)
			
			# Pronađi koji terminal ove komponente je u ovom čvoru
			var terminal_in_node = null
			var terminal_idx = -1
			
			for i in range(comp.terminals.size()):
				if node.terminals.has(comp.terminals[i]):
					terminal_in_node = comp.terminals[i]
					terminal_idx = i
					break
			
			if terminal_idx == -1:
				print("    UPOZORENJE: Terminal nije pronađen u čvoru!")
				continue
			
			print("    Terminal index: ", terminal_idx)
			
			# Pronađi drugi terminal
			var other_idx = 1 - terminal_idx  # 0->1 ili 1->0
			if other_idx >= comp.terminals.size():
				continue
			
			var other_terminal = comp.terminals[other_idx]
			var other_node = get_node_for_terminal(other_terminal, nodes)
			
			if not other_node:
				print("    UPOZORENJE: Drugi čvor nije pronađen!")
				continue
			
			print("    Drugi čvor ID: ", other_node.id)
			
			# Primeni Ohmov zakon: I = V / R
			match comp.component_type:
				CircuitComponent.RESISTOR, CircuitComponent.BULB:
					# (V_node - V_other) / R = I
					var conductance = 1.0 / comp.value if comp.value > 0 else 0.001
					
					if not equation.coefficients.has(eq_index):
						equation.coefficients[eq_index] = 0.0
					equation.coefficients[eq_index] += conductance
					
					if other_node != ground:
						var other_eq_index = node_to_eq_index[other_node.id]
						if not equation.coefficients.has(other_eq_index):
							equation.coefficients[other_eq_index] = 0.0
						equation.coefficients[other_eq_index] -= conductance
					
					print("    Dodao otpor/sijalicu: conductance=", conductance)
				
				CircuitComponent.BATTERY:
					# Baterija generiše napon
					var voltage_source = comp.value
					var conductance = 1.0 / 0.1  # Mali unutrašnji otpor
					
					if not equation.coefficients.has(eq_index):
						equation.coefficients[eq_index] = 0.0
					equation.coefficients[eq_index] += conductance
					
					if other_node != ground:
						var other_eq_index = node_to_eq_index[other_node.id]
						if not equation.coefficients.has(other_eq_index):
							equation.coefficients[other_eq_index] = 0.0
						equation.coefficients[other_eq_index] -= conductance
					
					# Dodaj napon u konstantu - proveri polaritet
					if terminal_idx == 0:  # Terminal 0 je negativan
						equation.constant += conductance * voltage_source
						print("    Dodao bateriju: +", conductance * voltage_source, "V")
					else:  # Terminal 1 je pozitivan
						equation.constant -= conductance * voltage_source
						print("    Dodao bateriju: -", conductance * voltage_source, "V")
				
				CircuitComponent.SWITCH:
					if comp.is_on:
						# Zatvoren prekidač = žica (mali otpor)
						var conductance = 1.0 / 0.01
						
						if not equation.coefficients.has(eq_index):
							equation.coefficients[eq_index] = 0.0
						equation.coefficients[eq_index] += conductance
						
						if other_node != ground:
							var other_eq_index = node_to_eq_index[other_node.id]
							if not equation.coefficients.has(other_eq_index):
								equation.coefficients[other_eq_index] = 0.0
							equation.coefficients[other_eq_index] -= conductance
		
		print("  Jednačina: koef=", equation.coefficients, " const=", equation.constant)
		equations.append(equation)
	
	return equations

static func solve_equations(equations: Array, num_unknowns: int) -> Array:
	# Reši sistem linearnih jednačina koristeći Gaussovu eliminaciju
	
	if equations.size() == 0 or num_unknowns == 0:
		print("  UPOZORENJE: Nema jednačina za rešavanje!")
		return []
	
	print("  Rešavam ", equations.size(), " jednačina sa ", num_unknowns, " nepoznatih")
	
	# Poseban slučaj: samo jedna jednačina
	if equations.size() == 1 and num_unknowns == 1:
		var eq = equations[0]
		print("  Jednačina: ", eq)
		
		# Pronađi koeficijent (može biti bilo koji ID)
		var coef = 0.0
		for key in eq.coefficients.keys():
			coef = eq.coefficients[key]
			break
		
		if abs(coef) < 0.0001:
			print("  GREŠKA: Koeficijent je ~0!")
			return [0.0]
		
		var solution = eq.constant / coef
		print("  Rešenje: V = ", solution)
		return [solution]
	
	# Konvertuj u matricu (opšti slučaj)
	var matrix = []
	for eq in equations:
		var row = []
		for i in range(num_unknowns):
			row.append(eq.coefficients.get(i, 0.0))
		row.append(eq.constant)
		matrix.append(row)
	
	# Gaussova eliminacija sa parcijalnim pivotovanjem
	var n = matrix.size()
	
	for i in range(min(n, num_unknowns)):
		# Nađi pivot
		var max_row = i
		for k in range(i + 1, n):
			if abs(matrix[k][i]) > abs(matrix[max_row][i]):
				max_row = k
		
		# Zameni redove
		var temp = matrix[i]
		matrix[i] = matrix[max_row]
		matrix[max_row] = temp
		
		# Eliminacija
		for k in range(i + 1, n):
			if abs(matrix[i][i]) > 0.0001:
				var factor = matrix[k][i] / matrix[i][i]
				for j in range(i, num_unknowns + 1):
					matrix[k][j] -= factor * matrix[i][j]
	
	# Unazadna supstitucija
	var solution = []
	solution.resize(num_unknowns)
	
	for i in range(num_unknowns - 1, -1, -1):
		if i < matrix.size() and abs(matrix[i][i]) > 0.0001:
			solution[i] = matrix[i][num_unknowns]
			for j in range(i + 1, num_unknowns):
				solution[i] -= matrix[i][j] * solution[j]
			solution[i] /= matrix[i][i]
		else:
			solution[i] = 0.0
	
	return solution

static func calculate_currents(components: Array, wires: Array, voltages: Array, nodes: Array, node_to_eq_index: Dictionary, ground_node: Dictionary):
	# Izračunaj struje kroz svaku komponentu na osnovu napona na čvorovima
	
	for comp in components:
		if comp.terminals.size() < 2:
			continue
		
		var node1 = get_node_for_terminal(comp.terminals[0], nodes)
		var node2 = get_node_for_terminal(comp.terminals[1], nodes)
		
		if not node1 or not node2:
			continue
		
		var v1 = 0.0
		var v2 = 0.0
		
		if node1 == ground_node:
			v1 = 0.0
		elif node_to_eq_index.has(node1.id):
			var idx = node_to_eq_index[node1.id]
			v1 = voltages[idx] if idx < voltages.size() else 0.0
		
		if node2 == ground_node:
			v2 = 0.0
		elif node_to_eq_index.has(node2.id):
			var idx = node_to_eq_index[node2.id]
			v2 = voltages[idx] if idx < voltages.size() else 0.0
		
		var voltage_diff = v1 - v2
		
		# Primeni Ohmov zakon
		match comp.component_type:
			CircuitComponent.RESISTOR, CircuitComponent.BULB:
				comp.current = voltage_diff / comp.value if comp.value > 0 else 0.0
				comp.voltage = abs(voltage_diff)
			
			CircuitComponent.BATTERY:
				# Za bateriju, struja zavisi od celog kola
				comp.current = voltage_diff / 0.1  # Unutrašnji otpor
				comp.voltage = comp.value
			
			CircuitComponent.SWITCH:
				if comp.is_on:
					comp.current = voltage_diff / 0.01
				else:
					comp.current = 0.0
				comp.voltage = abs(voltage_diff)
	
	# Postavi struje u žicama
	for wire in wires:
		# Pronađi komponentu povezanu sa ovom žicom
		if wire.start_component:
			wire.set_current(abs(wire.start_component.current))
		elif wire.end_component:
			wire.set_current(abs(wire.end_component.current))

static func get_component_for_terminal(terminal, components: Array):
	for comp in components:
		if comp.terminals.has(terminal):
			return comp
	return null

static func get_other_terminal(comp, terminal):
	for t in comp.terminals:
		if t != terminal:
			return t
	return null

static func get_node_for_terminal(terminal, nodes: Array):
	for node in nodes:
		if node.terminals.has(terminal):
			return node
	return null
