extends RefCounted

var root: Node3D
var blocked = {}
var grass = {}
var rng = RandomNumberGenerator.new()
var materials = {}

func material(color):
	if not materials.has(color):
		var m=StandardMaterial3D.new();m.albedo_color=Color(color);m.roughness=1.0
		materials[color]=m
	return materials[color]
func shape(mesh,color,pos,size=Vector3.ONE):
	var n=MeshInstance3D.new();n.mesh=mesh;n.material_override=material(color);n.position=pos;n.scale=size;root.add_child(n);return n
func box(color,pos,size):return shape(BoxMesh.new(),color,pos,size)
func sphere(color,pos,size):
	var s=SphereMesh.new();s.radius=0.5;s.height=1;s.radial_segments=10;s.rings=6
	return shape(s,color,pos,size)
func cone(color,pos,radius,height):
	var c=CylinderMesh.new();c.top_radius=0;c.bottom_radius=radius;c.height=height;c.radial_segments=10
	return shape(c,color,pos)
func tree(x,z,snow=false):
	box("#7c6350",Vector3(x,0.7,z),Vector3(0.28,1.4,0.28))
	for i in range(3):cone("#bdcec5" if snow and i==2 else ["#326b58","#43846a","#62a27b"][i],Vector3(x,1.3+i*0.55,z),1.05-i*0.17,1.7-i*0.15)
	blocked[Vector2i(x,z)]=true
func house(x,z,roof,sign):
	box("#e5d6b5",Vector3(x,1.25,z),Vector3(4,2.5,3.8))
	box("#b99066",Vector3(x,0.2,z),Vector3(4.25,0.4,4.05))
	for side in [-1,1]:
		var n=box(roof,Vector3(x+side*1.0,2.85,z),Vector3(2.7,0.2,4.5));n.rotation.z=side*-0.4
	box("#4c6868",Vector3(x,0.88,z+1.92),Vector3(0.84,1.7,0.08))
	box("#c7c9a6",Vector3(x,0.18,z+2.25),Vector3(1.3,0.25,0.6))
	for side in [-1,1]:
		box("#7ba9ad",Vector3(x+side*1.32,1.38,z+1.92),Vector3(0.65,0.75,0.08))
		box("#f9e8bc",Vector3(x+side*1.32,1.38,z+1.98),Vector3(0.055,0.77,0.03))
	box("#ac8268",Vector3(x+1.2,3.2,z-0.5),Vector3(0.44,1.1,0.5))
	var label=Label3D.new();label.text=sign;label.position=Vector3(x,2.05,z+2);label.font_size=28;label.pixel_size=0.011;label.modulate=Color("#fff1cd");root.add_child(label)
	for a in range(x-2,x+3):
		for b in range(z-2,z+2):blocked[Vector2i(a,b)]=true
func patch(x,z):
	grass[Vector2i(x,z)]=true
	box("#609e66",Vector3(x,0.03,z),Vector3(1.02,0.05,1.02))
	for i in range(5):
		var a=x+rng.randf_range(-0.4,0.4);var b=z+rng.randf_range(-0.4,0.4)
		for j in [-1,1]:
			var blade=box("#8dc573" if i%2 else "#427e58",Vector3(a,0.18,b),Vector3(0.07,0.34,0.12));blade.rotation.z=j*0.28
func build(target,map,id):
	root=target;blocked={};grass={};rng.seed=abs(id.hash())
	if id in ["brackenbay","r01"]:
		opening(id)
		return {"blocked":blocked,"grass":grass}
	var snow=id in ["frostford","whitevault_glacier","herdrest_basin","r14","r15","r16"]
	var volcanic=id in ["calderpost","caldera_furnace","r12","r13"]
	var color="#b9cfc6" if snow else "#9c927f" if volcanic else "#74996f"
	box(color,Vector3(15,-0.22,13),Vector3(33,0.4,29))
	box("#b8a98a",Vector3(15,0.015,15),Vector3(31,0.06,2.7))
	box("#b8a98a",Vector3(15,0.02,13),Vector3(2.7,0.07,27))
	# Continuous border hills frame the playable trail rather than an empty plane.
	for i in range(12):
		var x=i*3-2
		sphere("#809f91" if snow else "#588773",Vector3(x,1.4,-3),Vector3(5,4+rng.randf()*3,5))
		cone("#e6e8d9" if snow else "#86ae94",Vector3(x,3.3,-3),1.4,2.2)
	for x in [-2,32]:
		for z in range(0,28,3):tree(x,z,snow)
	if map.kind=="town":
		house(7,5,["#af6b52","#558a80","#7484a1"][abs(id.hash())%3],"TRAIL HOUSE")
		house(23,5,"#577c72","FIELD STATION")
		house(4,22,"#bc8958","REST & SUPPLIES")
		house(26,22,"#647e9e","RESIDENTS")
		for x in range(10,22,3):
			box("#cdb892",Vector3(x,0.15,11),Vector3(1.5,0.2,1.5))
			for i in range(3):sphere("#dbba83",Vector3(x+(i-1)*0.35,0.37,11),Vector3(0.22,0.3,0.22))
		for x in [3,27]:
			box("#617467",Vector3(x,1.2,12),Vector3(0.12,2.4,0.12))
			sphere("#f3d893",Vector3(x,2.4,12),Vector3(0.35,0.45,0.35))
		for x in [10,20]:
			for z in [19,23]:
				box("#846c53",Vector3(x,0.45,z),Vector3(1.5,0.15,0.45));box("#846c53",Vector3(x,0.78,z-0.2),Vector3(1.5,0.5,0.1))
				for side in [-1,1]:box("#4a5c51",Vector3(x+side*0.6,0.22,z),Vector3(0.12,0.45,0.3))
		for x in range(3,29,2):
			for z in [9,18]:
				if abs(x-15)<3:continue
				box("#496d57",Vector3(x,0.23,z),Vector3(0.4,0.4,0.4))
				for side in [-1,1]:sphere("#d9aa78" if z==9 else "#c28fa6",Vector3(x+side*0.15,0.55,z),Vector3(0.25,0.25,0.25))
		for x in [2,28]:
			for z in range(3,13,2):
				box("#c2ae85",Vector3(x,0.6,z),Vector3(0.13,1.2,0.13));box("#c2ae85",Vector3(x,0.8,z+1),Vector3(0.08,0.14,2))
	elif map.kind=="gym":
		gym(map.gym)
	else:
		for x in range(3,28):
			for z in range(3,24):
				if x>=17 and x<=26 and z>=17 and z<=22:patch(x,z)
		for i in range(32):
			var x=rng.randi_range(3,28);var z=rng.randi_range(3,23)
			if abs(x-15)<3 or abs(z-15)<3 or (abs(x-21)<2 and abs(z-7)<2) or grass.has(Vector2i(x,z)) or z>=20:continue
			tree(x,z,snow)
		if map.kind=="dungeon":
			for x in [3,27]:
				for z in range(3,24,4):
					cone("#a5b1b9" if snow else "#818b8b",Vector3(x,1,z),1.5,2.6)
					cone("#ad9cd0",Vector3(x+0.5,1.4,z),0.3,1.5)
		# A stream, footbridge and bank live outside the main horizontal path.
		for x in range(2,13):
			box("#589daf",Vector3(x,0.04,24),Vector3(1.1,0.04,2.4))
			box("#94c7c3",Vector3(x,0.066,23.6+sin(x)*0.2),Vector3(0.7,0.01,0.06))
			blocked[Vector2i(x,24)]=true;blocked[Vector2i(x,25)]=true
		for x in range(6,10):
			box("#ac8f6b",Vector3(x,0.16,24),Vector3(0.25,0.12,3))
			blocked.erase(Vector2i(x,24));blocked.erase(Vector2i(x,25))
	return {"blocked":blocked,"grass":grass}
func gym(g):
	var palettes=["#7cad72","#629ea9","#9c8f56","#a78bc2","#7378a9","#ac947f","#c4825b","#94b6be"]
	var accent=palettes[int(g.number)-1]
	box("#9ba58f",Vector3(15,0.07,13),Vector3(29,0.1,25))
	var tiles=MultiMesh.new();tiles.transform_format=MultiMesh.TRANSFORM_3D;tiles.use_colors=true;tiles.mesh=BoxMesh.new();tiles.mesh.size=Vector3(0.97,0.025,0.97);tiles.instance_count=29*25
	for x in range(29):
		for z in range(25):
			var index=x*25+z;tiles.set_instance_transform(index,Transform3D(Basis.IDENTITY,Vector3(x+1,0.14,z+1)))
			tiles.set_instance_color(index,Color(accent).lerp(Color("#c2bfaa"),0.75 if (x+z)%2 else 0.65))
	var tile_node=MultiMeshInstance3D.new();tile_node.multimesh=tiles
	var tile_mat=StandardMaterial3D.new();tile_mat.vertex_color_use_as_albedo=true;tile_mat.roughness=1;tile_node.material_override=tile_mat;root.add_child(tile_node)
	for x in [1,29]:box(accent,Vector3(x,1.0,13),Vector3(0.7,2,26))
	box(accent,Vector3(15,1.0,0),Vector3(29,2,0.7))
	box(accent,Vector3(15,0.18,5),Vector3(8,0.22,6))
	for z in range(9,23,3):box(accent,Vector3(15,0.14,z),Vector3(1.5,0.07,1.4))
	for x in [5,10,20,25]:
		for z in [5,11,20]:
			match int(g.number):
				1:
					box("#927755",Vector3(x,0.35,z),Vector3(2.3,0.65,1.8));box("#4c6650",Vector3(x,0.69,z),Vector3(2.1,0.06,1.6))
					for i in range(3):sphere("#659963",Vector3(x+(i-1)*0.6,1.0,z),Vector3(0.8,0.75,0.6));cone("#9fbd6d",Vector3(x+(i-1)*0.6,1.4,z),0.2,0.5)
					for side in [-1,1]:box("#9c8761",Vector3(x+side*1.1,1.3,z),Vector3(0.08,2.3,0.08))
					box("#7da984",Vector3(x,2.45,z),Vector3(2.6,0.15,2.1)).rotation.z=0.12
				2:
					box("#7c9da0",Vector3(x,0.25,z),Vector3(2.8,0.4,2.6));box("#538f9c",Vector3(x,0.47,z),Vector3(2.5,0.04,2.3))
					box("#b09865",Vector3(x,0.56,z),Vector3(1.2,0.12,0.8));sphere("#9bc185",Vector3(x,0.8,z),Vector3(0.8,0.4,0.7))
					for i in range(3):box("#a9cec1",Vector3(x-0.8+i*0.65,0.52,z-0.5),Vector3(0.4,0.03,0.07))
				3:
					for side in [-1,1]:box("#4b5c59",Vector3(x+side*0.55,0.2,z),Vector3(0.08,0.1,3))
					for i in range(5):box("#8c7857",Vector3(x,0.18,z+(i-2)*0.5),Vector3(1.6,0.08,0.15))
					box("#b9ad69",Vector3(x,0.6,z),Vector3(1.35,0.8,1.6));box("#8ac2c6",Vector3(x,1.27,z),Vector3(1.05,0.7,1.25));box("#5a736a",Vector3(x,1.68,z),Vector3(1.4,0.1,1.7))
				4:
					var pool=CylinderMesh.new();pool.top_radius=1;pool.bottom_radius=1;pool.height=0.7;shape(pool,"#787e92",Vector3(x,0.5,z))
					var water=CylinderMesh.new();water.top_radius=0.87;water.bottom_radius=0.87;water.height=0.02;shape(water,"#a881b5",Vector3(x,0.87,z))
					cone("#bda2cc",Vector3(x,1.15,z),0.35,0.9);box("#657887",Vector3(x+1.2,1.1,z),Vector3(0.16,1.8,0.16))
				5:
					box("#647183",Vector3(x,0.3,z),Vector3(1.8,0.5,1.3))
					for side in [-1,1]:box("#8e9e9b",Vector3(x+side*0.7,1.3,z),Vector3(0.12,2.1,0.12))
					box("#8e9e9b",Vector3(x,2.3,z),Vector3(1.6,0.12,0.12))
					for i in range(5):box("#b8bbcc",Vector3(x+(i-2)*0.24,1.65+sin(i)*0.15,z),Vector3(0.09,1.1,0.12))
				6:
					cone("#8c877d",Vector3(x,0.9,z),1.1,2.1);cone("#beb397",Vector3(x-0.6,0.5,z+0.8),0.6,1.1)
					for side in [-1,1]:box("#544f4b",Vector3(x+side*0.4,0.18,z-1.3),Vector3(0.06,0.1,3))
					box("#9e7758",Vector3(x,0.45,z-1),Vector3(1.2,0.6,1.2))
				7:
					box("#9b7b59",Vector3(x,0.4,z),Vector3(2,0.7,1.7));cone("#699665",Vector3(x,1.0,z),0.4,0.9)
					for side in [-1,1]:box("#5f8b85",Vector3(x+side*0.85,1.3,z),Vector3(0.09,2.1,1.9))
					box("#8dbbb1",Vector3(x,2.35,z),Vector3(2.1,0.1,2.1))
					box("#b48055",Vector3(x+1.1,0.5,z),Vector3(0.12,0.12,3));sphere("#cd9d62",Vector3(x+1.1,0.7,z+0.7),Vector3(0.3,0.5,0.3))
				8:
					cone("#b6d0c6",Vector3(x,0.8,z),0.7,1.8);cone("#86afb2",Vector3(x+0.5,0.5,z+0.5),0.5,1.2)
					box("#846d59",Vector3(x-0.6,1.1,z),Vector3(0.08,2.2,0.08));box("#b78460",Vector3(x-0.3,1.9,z),Vector3(0.7,0.35,0.04))

			for a in range(x-1,x+2):
				for b in range(z-1,z+2):blocked[Vector2i(a,b)]=true

func trail(a:Vector2,b:Vector2,width=2.4):
	var middle=(a+b)*0.5
	box("#c7b68e",Vector3(middle.x,0.018,middle.y),Vector3(abs(a.x-b.x)+width,0.06,abs(a.y-b.y)+width))
func bridge(z):
	for x in range(13,19):
		box("#ad8b62",Vector3(x,0.14,z),Vector3(0.94,0.22,3.0))
		for side in [-1,1]:
			box("#816748",Vector3(x,0.65,z+side*1.4),Vector3(0.12,1.15,0.12))
			box("#c8ab77",Vector3(x,0.98,z+side*1.4),Vector3(1.05,0.12,0.12))
		for dz in [-1,0,1]:blocked.erase(Vector2i(x,z+dz))
func bench(x,z):
	box("#967855",Vector3(x,0.5,z),Vector3(1.7,0.15,0.6))
	box("#967855",Vector3(x,0.9,z-0.28),Vector3(1.7,0.65,0.12))
	for dx in [-0.65,0.65]:box("#4e6154",Vector3(x+dx,0.25,z),Vector3(0.12,0.5,0.5))
	blocked[Vector2i(x,z)]=true
func opening(id):
	box("#7b9c69",Vector3(15,-0.23,13),Vector3(34,0.4,30))
	for x in range(-2,34,3):
		sphere("#5e8b70",Vector3(x,1,-3),Vector3(6,4,5))
		tree(x,0)
	for x in [-1,31]:
		for z in range(3,28,3):tree(x,z)
	if id=="brackenbay":
		# A coastal promenade, field station and working harbour.
		box("#639fa8",Vector3(15,-0.07,26),Vector3(34,0.08,9))
		box("#d3c394",Vector3(15,-0.03,21.5),Vector3(32,0.1,1.3))
		for x in range(1,30):
			for z in range(22,26):blocked[Vector2i(x,z)]=true
		trail(Vector2(1,15),Vector2(29,15),3.0)
		trail(Vector2(15,6),Vector2(15,21),3.2)
		trail(Vector2(6,10),Vector2(24,10))
		house(6,5,"#667f9c","HEMLOCK FIELD STATION")
		house(24,6,"#b9795f","BRACKENBAY POST")
		house(5,19,"#618b7b","SEABREEZE COTTAGE")
		for x in range(13,18):
			for z in range(21,27):
				box("#aa8b62",Vector3(x,0.1,z),Vector3(0.96,0.2,0.96));blocked.erase(Vector2i(x,z))
		for x in [12,18]:
			for z in [22,25]:box("#806649",Vector3(x,0.7,z),Vector3(0.25,1.4,0.25))
		for x in [10,20]:bench(x,18)
		for x in [3,9,21,28]:
			tree(x,11)
			for z in [12,13]:sphere("#d6ac79",Vector3(x,0.28,z),Vector3(0.45,0.5,0.5))
		# Lighthouse marks the harbour from the town square.
		var tower=CylinderMesh.new();tower.top_radius=0.8;tower.bottom_radius=1.2;tower.height=4.8
		shape(tower,"#e7dcc0",Vector3(26,2.4,20))
		var stripe=CylinderMesh.new();stripe.top_radius=1.02;stripe.bottom_radius=1.12;stripe.height=0.8
		shape(stripe,"#af7261",Vector3(26,1.4,20))
		sphere("#f3d995",Vector3(26,5.0,20),Vector3(1.4,1.0,1.4));cone("#647e8a",Vector3(26,5.8,20),1.3,0.8)
		for x in range(25,28):
			for z in range(19,22):blocked[Vector2i(x,z)]=true
		for i in range(16):box("#a4d0ca",Vector3(i*2,0.0,23+(i%3)),Vector3(0.8,0.02,0.06))
	else:
		# Saltwind Walk bends across a river and loops through two meadows.
		trail(Vector2(1,15),Vector2(8,15));trail(Vector2(8,15),Vector2(8,11))
		trail(Vector2(8,11),Vector2(23,11));trail(Vector2(23,11),Vector2(23,15));trail(Vector2(23,15),Vector2(29,15))
		trail(Vector2(8,15),Vector2(8,21),1.8);trail(Vector2(8,21),Vector2(23,21),1.8);trail(Vector2(23,15),Vector2(23,21),1.8)
		box("#5b9da9",Vector3(15.5,0.02,13),Vector3(4,0.05,27))
		for x in range(14,18):
			for z in range(1,26):blocked[Vector2i(x,z)]=true
		for z in range(2,26,2):box("#add1c7",Vector3(15.5+sin(z),0.054,z),Vector3(1.1,0.01,0.07))
		bridge(11);bridge(21)
		for x in range(19,23):
			for z in range(18,21):patch(x,z)
		for x in range(9,13):
			for z in range(6,10):patch(x,z)
		for x in range(25,29):
			for z in range(6,10):patch(x,z)
		for pos in [Vector2i(3,4),Vector2i(4,5),Vector2i(7,3),Vector2i(12,3),Vector2i(19,3),Vector2i(23,4),Vector2i(27,3),Vector2i(3,19),Vector2i(4,22),Vector2i(10,24),Vector2i(21,24),Vector2i(28,21)]:tree(pos.x,pos.y)
		bench(5,11);bench(26,18)
		for x in [4,5,6]:
			box("#c3aa7d",Vector3(x,0.65,17),Vector3(0.12,1.3,0.12));box("#c3aa7d",Vector3(x,0.9,17),Vector3(1.0,0.12,0.1));blocked[Vector2i(x,17)]=true
		for x in [19,20,21]:sphere("#aaa894",Vector3(x,0.3,5),Vector3(0.7,0.6,0.9));blocked[Vector2i(x,5)]=true
