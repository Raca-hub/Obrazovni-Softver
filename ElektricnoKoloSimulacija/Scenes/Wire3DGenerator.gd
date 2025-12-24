extends Node3D
class_name Wire3DGenerator

# Generiše 3D žicu između dve 3D komponente

var mesh_instance: MeshInstance3D
var wire_material: StandardMaterial3D
var start_pos: Vector3
var end_pos: Vector3
var wire_thickness = 0.05

func _ready():
	setup_wire()

func setup_wire():
	# Kreiraj MeshInstance3D za žicu
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Kreiraj materijal
	wire_material = StandardMaterial3D.new()
	wire_material.albedo_color = Color(0.4, 0.4, 0.4)  # Siva
	wire_material.metallic = 0.8
	wire_material.roughness = 0.3

func generate_wire(from: Vector3, to: Vector3):
	start_pos = from
	end_pos = to
	
	# Kreiraj mesh za žicu (cilindar između dve tačke)
	var wire_mesh = create_cylinder_between_points(from, to)
	mesh_instance.mesh = wire_mesh
	mesh_instance.material_override = wire_material

func create_cylinder_between_points(from: Vector3, to: Vector3) -> CylinderMesh:
	# Kreiraj cilindar koji ide od 'from' do 'to'
	var cylinder = CylinderMesh.new()
	
	var direction = to - from
	var length = direction.length()
	
	cylinder.height = length
	cylinder.top_radius = wire_thickness
	cylinder.bottom_radius = wire_thickness
	
	# Pozicioniraj mesh na sredinu
	var midpoint = (from + to) / 2.0
	mesh_instance.global_position = midpoint
	
	# Rotiraj cilindar da pokazuje od from ka to
	var up = Vector3.UP
	var forward = direction.normalized()
	
	if abs(forward.dot(up)) < 0.99:
		var right = up.cross(forward).normalized()
		up = forward.cross(right).normalized()
		
		var basis = Basis(right, up, forward)
		mesh_instance.global_transform.basis = basis
	else:
		# Handle vertical wires
		mesh_instance.global_transform.basis = Basis()
		mesh_instance.rotate_x(PI / 2.0)
	
	return cylinder

func set_wire_color(color: Color):
	wire_material.albedo_color = color

func update_wire_position(from: Vector3, to: Vector3):
	# Ažuriraj poziciju žice
	generate_wire(from, to)
