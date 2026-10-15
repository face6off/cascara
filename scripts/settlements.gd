extends "res://scripts/scenery.gd"

const DOORS={"centre":Vector2i(7,8),"mart":Vector2i(23,8),"home":Vector2i(7,23),"house":Vector2i(23,23),"station":Vector2i(15,12),"hall":Vector2i(23,14)}
const LABELS={"centre":"POKÉMON CENTRE","mart":"POKÉ MART","home":"RESIDENT'S HOME","house":"TRAIL HOUSE","station":"FIELD STATION","hall":"COMMUNITY HALL"}
const THEMES={"brackenbay":["#7da991","#8abac5","#bf805f"],"alderwick":["#6b9265","#a7bb7f","#6d8b6d"],"millford":["#85ac89","#84b5c3","#b39a67"],"rainhaven":["#7d9394","#a9b9bd","#718caa"],"fogbell":["#8b9d96","#b6c7c3","#7a8c9d"],"tideglass":["#9cbe9d","#83c9c9","#d7a26f"],"mossmere":["#668d75","#9db2a0","#8877a1"],"ironvale":["#939482","#b5b3a1","#9c7f65"],"calderpost":["#9d997b","#c0bca1","#b57d56"],"highmere":["#98b5a0","#b6cfca","#7789a0"],"frostford":["#c1d5cf","#e1e4d5","#8faab7"],"crownstation":["#98aa99","#c3c6ad","#9b805c"]}
func build(target,map,id):
	root=target;blocked={};grass={};rng.seed=abs(id.hash())
	if map.kind=="indoor":interior(map)
	else:city(map,id)
	return {"blocked":blocked,"grass":grass}
func city(map,id):
	var palette=THEMES.get(id,["#859d7d","#bcc6a5","#8c8c76"])
	box(palette[0],Vector3(15,-0.22,13),Vector3(33,0.4,29))
	trail(Vector2(1,15),Vector2(29,15),3.0);trail(Vector2(15,1),Vector2(15,25),3.0)
	trail(Vector2(7,9),Vector2(23,9),2.0);trail(Vector2(7,9),Vector2(7,16),2.0);trail(Vector2(23,9),Vector2(23,16),2.0)
	trail(Vector2(4,24),Vector2(26,24),2.0);trail(Vector2(4,15),Vector2(4,24),2.0);trail(Vector2(26,15),Vector2(26,24),2.0)
	for kind in DOORS:
		if kind=="hall" and map.get("city_gym","")!="":continue
		var door=DOORS[kind];var x=door.x;var z=door.y-3
		var roof="#c46d6c" if kind=="centre" else "#5e91ba" if kind=="mart" else palette[2]
		house(x,z,roof,LABELS[kind]);box(roof,Vector3(x,0.06,door.y),Vector3(1.5,0.1,1.0))
		if kind in ["centre","mart"]:
			box("#eee9cf",Vector3(x,3.25,z+0.2),Vector3(1.5,0.9,0.12))
			box(roof,Vector3(x,3.25,z+0.28),Vector3(0.8,0.18,0.05))
			if kind=="centre":box(roof,Vector3(x,3.25,z+0.28),Vector3(0.18,0.7,0.05))
	if map.get("city_gym","")!="":house(23,11,palette[2],"GYM")
	for x in [2,29]:
		for z in [3,6,20,23]:tree(x,z,id=="frostford")
	for pos in [Vector2i(10,12),Vector2i(18,12),Vector2i(11,19),Vector2i(19,19)]:
		box("#d1c49d",Vector3(pos.x,0.16,pos.y),Vector3(1.5,0.3,1.5));sphere(palette[0],Vector3(pos.x,0.65,pos.y),Vector3(1.2,0.8,1.2));blocked[pos]=true
		for side in [-1,1]:sphere("#e5b685",Vector3(pos.x+side*0.3,1.0,pos.y),Vector3(0.3,0.3,0.3))
	bench(11,16);bench(19,16)
	for x in [5,25]:
		box("#526e67",Vector3(x,1.3,16),Vector3(0.1,2.6,0.1));sphere("#f5de9d",Vector3(x,2.6,16),Vector3(0.35,0.5,0.35));blocked[Vector2i(x,16)]=true
	if id in ["brackenbay","fogbell","tideglass","millford"]:
		box(palette[1],Vector3(15,-0.05,28),Vector3(34,0.08,4))
		for x in range(1,30,2):box("#b8d8cb",Vector3(x,0.01,27.0+sin(x)*0.2),Vector3(0.7,0.02,0.06))
	if id=="rainhaven":
		for x in [2,29]:box("#718a90",Vector3(x,2.4,11),Vector3(2,4.8,3));box("#b7d3ce",Vector3(x,3,12.55),Vector3(1.2,1.6,0.05))
func furniture(x,z,color,size=Vector3(1,1,1)):
	box(color,Vector3(x,size.y*0.5,z),size);blocked[Vector2i(x,z)]=true
func interior(map):
	var service=map.service;var accent="#b87275" if service=="centre" else "#638fae" if service=="mart" else "#8fa17a"
	box("#6a817b",Vector3(15,-0.3,13),Vector3(34,0.4,30))
	box("#e6dcc0",Vector3(15,-0.04,13),Vector3(15,0.14,16))
	for x in range(1,30):
		for z in range(1,26):
			if x<=7 or x>=23 or z<=5 or z>=21:blocked[Vector2i(x,z)]=true
	blocked.erase(Vector2i(15,21))
	box("#e0d9be",Vector3(15,1.5,5.5),Vector3(16,3,0.4))
	for x in [7.5,22.5]:box("#d0c9b0",Vector3(x,0.65,13),Vector3(0.35,1.3,15))
	box(accent,Vector3(15,0.03,19.5),Vector3(2.4,0.04,3))
	for x in range(9,22,2):
		for z in range(7,20,2):box("#d6d0b8",Vector3(x,0.04,z),Vector3(1.9,0.02,1.9))
	if service in ["centre","mart"]:
		for x in range(12,19):furniture(x,9,accent,Vector3(1,0.9,0.9))
		if service=="centre":
			furniture(15,7,"#b9c7bc",Vector3(3,1.2,1.4))
			for x in [14.3,15.0,15.7]:sphere("#d97979",Vector3(x,1.3,7),Vector3(0.35,0.35,0.35))
			box("#b97076",Vector3(15,2.3,5.75),Vector3(1.4,0.25,0.1));box("#b97076",Vector3(15,2.3,5.75),Vector3(0.25,1.2,0.1))
			for x in [10,20]:bench(x,17)
		else:
			for x in [9,21]:
				for z in [8,12,16]:
					furniture(x,z,"#9c8569",Vector3(1,1.6,1.5))
					for h in [0.6,1.2,1.75]:
						for dz in [-0.35,0.35]:sphere("#82b5ab" if h<1 else "#e6c07b",Vector3(x,h,z+dz),Vector3(0.35,0.4,0.35))
	else:
		furniture(10,8,"#9e8568",Vector3(2,1.5,1))
		furniture(20,8,"#9b876b",Vector3(2,0.6,3));box("#839faa",Vector3(20,0.65,8),Vector3(1.9,0.15,2.2))
		furniture(15,13,"#b69b73",Vector3(2.2,0.8,1.3))
		bench(12,15);bench(18,15)
