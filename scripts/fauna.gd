extends RefCounted

func shape(root,kind,color,pos,scale):
	var node = MeshInstance3D.new()
	var mesh
	if kind=="box": mesh=BoxMesh.new()
	elif kind=="cone": mesh=CylinderMesh.new();mesh.top_radius=0;mesh.bottom_radius=0.5;mesh.height=1
	else: mesh=SphereMesh.new();mesh.radius=0.5;mesh.height=1;mesh.radial_segments=12;mesh.rings=8
	node.mesh=mesh
	var mat = StandardMaterial3D.new();mat.albedo_color=Color(color);mat.roughness=0.85
	node.material_override=mat;node.position=pos;node.scale=scale;root.add_child(node)
	return node

func make(id,species,shiny=false):
	var model=build_model(id,species)
	if shiny:
		apply_shiny(model,int(id))
		model.set_meta("shiny",true)
		model.add_child(preload("res://scripts/shimmer.gd").new())
	return model

func build_model(id,species):
	id=int(id)
	var path = ("res://assets/rigged/" if int(id) in [1,4,7,10] else "res://assets/models/")+str(id)+".glb"
	if ResourceLoader.exists(path):
		var model=load(path).instantiate()
		if int(id) in [1,4,7,10]:return preload("res://scripts/creature_motion.gd").new().configure(model,id)
		return model
	var s = species[int(id)]; var root = Node3D.new()
	var color = Color({"Grass":"#799b61","Water":"#649caf","Fire":"#b86d48","Electric":"#d5be65","Ice":"#b3d9dd","Rock":"#9b9280","Steel":"#8c9ea0","Ghost":"#8c85a4","Poison":"#ab86b1","Dark":"#4f535e","Fairy":"#c9a1b6"}.get(s.types[0],"#9e947e"))
	var concept = s.concept.to_lower()
	var size = 1.0+(int(s.stage)-1)*0.18
	if s.legendary: size=1.8
	shape(root,"sphere",color,Vector3(0,0.65,0),Vector3(0.75,0.7,1.0))
	shape(root,"sphere",color.lightened(0.12),Vector3(0,1.02,0.42),Vector3(0.62,0.55,0.57))
	for x in [-0.15,0.15]:
		shape(root,"sphere","#eff3e1",Vector3(x,1.08,0.68),Vector3(0.12,0.14,0.08))
		shape(root,"sphere","#263632",Vector3(x,1.08,0.725),Vector3(0.07,0.09,0.04))
	for x in [-0.22,0.22]:
		for z in [-0.27,0.27]: shape(root,"sphere",color.darkened(0.18),Vector3(x,0.22,z),Vector3(0.13,0.44,0.15))
	if concept.contains("bird") or concept.contains("eagle") or concept.contains("raven") or concept.contains("bat") or concept.contains("moth"):
		for x in [-1,1]:
			var wing = shape(root,"sphere",color.lightened(0.1),Vector3(x*0.62,0.95,0),Vector3(1.0,0.12,0.6));wing.rotation.z=x*0.3
		shape(root,"cone","#d7bb77",Vector3(0,1.0,0.85),Vector3(0.18,0.4,0.18)).rotation.x=PI/2
	elif concept.contains("mushroom"):
		shape(root,"sphere",color.lightened(0.2),Vector3(0,1.42,0),Vector3(1.6,0.36,1.6))
	elif concept.contains("snake") or concept.contains("serpent") or concept.contains("worm") or concept.contains("dragon") or concept.contains("kelp"):
		for i in range(8): shape(root,"sphere",color,Vector3(sin(i*0.65)*0.32,0.25+i*0.09,-i*0.23),Vector3(0.48,0.4,0.5))
	elif concept.contains("jellyfish") or concept.contains("anemone") or concept.contains("octopus") or concept.contains("sea star"):
		for i in range(8):
			var angle = i*TAU/8
			shape(root,"sphere",color.lightened(0.13),Vector3(cos(angle)*0.5,0.35,sin(angle)*0.5),Vector3(0.21,0.6,0.21))
	elif concept.contains("geode") or concept.contains("crystal"):
		for i in range(6): shape(root,"cone","#aea3d8",Vector3(cos(i)*0.45,1.15,sin(i)*0.4),Vector3(0.3,0.8,0.3))
	elif concept.contains("cart") or concept.contains("locomotive"):
		shape(root,"box",color.darkened(0.12),Vector3(0,0.7,0),Vector3(1.1,0.65,1.4))
		for x in [-0.6,0.6]:
			for z in [-0.45,0.45]: shape(root,"sphere","#444b50",Vector3(x,0.25,z),Vector3(0.18,0.4,0.4))
	elif concept.contains("raincoat"):
		shape(root,"cone","#d5b54e",Vector3(0,0.7,0),Vector3(1.0,1.2,0.9));shape(root,"sphere","#d6bd63",Vector3(0,1.36,0.2),Vector3(0.7,0.75,0.7))
	elif concept.contains("chime"):
		for i in range(5): shape(root,"box","#bfccbc",Vector3((i-2)*0.23,1.0+sin(i)*0.15,0),Vector3(0.09,1.0,0.09))
	elif concept.contains("whale") or concept.contains("orca") or concept.contains("salmon"):
		root.scale=Vector3(1,0.8,1.5)
		for x in [-1,1]: shape(root,"sphere",color,Vector3(x*0.5,0.5,0),Vector3(0.7,0.13,0.45))
	elif concept.contains("mammoth"):
		for i in range(6): shape(root,"sphere",color,Vector3(0,0.85-i*0.1,0.75+i*0.09),Vector3(0.18,0.22,0.2))
		for x in [-1,1]: shape(root,"cone","#e5dfc9",Vector3(x*0.27,0.72,0.87),Vector3(0.15,0.8,0.15)).rotation.x=-0.9
	else:
		for x in [-1,1]: shape(root,"cone",color,Vector3(x*0.2,1.38,0.36),Vector3(0.22,0.47,0.23))
		shape(root,"sphere",color,Vector3(0,0.7,-0.7),Vector3(0.23,0.25,0.85))
	if concept.contains("sabertooth"):
		for x in [-1,1]: shape(root,"cone","#c1e2ec",Vector3(x*0.2,0.83,0.73),Vector3(0.11,0.6,0.11)).rotation.z=PI
	if s.types.has("Grass"):
		for i in range(5): shape(root,"sphere","#6b9652",Vector3((i-2)*0.15,1.0,-0.2),Vector3(0.35,0.12,0.65)).rotation.z=(i-2)*0.35
	if s.types.has("Rock") or s.types.has("Steel"):
		for i in range(3): shape(root,"cone",color.lightened(0.18),Vector3(0,1.1,-i*0.2),Vector3(0.35,0.55,0.35))
	root.scale*=size
	return root

func apply_shiny(node,id):
	if node is MeshInstance3D and node.mesh!=null:
		for surface in range(node.mesh.get_surface_count()):
			var original=node.material_override if node.material_override!=null else node.get_active_material(surface)
			if original is StandardMaterial3D:
				var mat=original.duplicate();var base=mat.albedo_color
				if base.s>0.12 and base.v>0.16:
					var shift={1:0.42,4:0.55,7:0.36,10:0.45,1001:0.08,1002:0.5}.get(id,0.32+float(id%5)*0.06)
					mat.albedo_color=Color.from_hsv(fmod(base.h+shift,1),clampf(base.s*1.1,0.3,0.85),clampf(base.v*1.12,0.3,1),base.a)
				node.set_surface_override_material(surface,mat)
		# Procedural meshes use an override, so move it into per-surface materials.
		node.material_override=null
	for child in node.get_children():apply_shiny(child,id)
