extends Node3D

var joints=[]
var clock=0.0
var phase=0.0
var previous=Vector3.ZERO
var moving=0.0
func _ready():previous=global_position
func gather(node,parts):
	if node.name.begins_with("Part_"):parts[int(str(node.name).trim_prefix("Part_"))]=node
	for child in node.get_children():gather(child,parts)
func joint(parts,indices,pivot,kind,offset=0.0):
	var bone=Node3D.new();bone.name=kind+str(joints.size());bone.position=pivot;add_child(bone)
	for index in indices:
		if not parts.has(index):continue
		var part=parts[index];part.owner=null;var old=part.transform;part.get_parent().remove_child(part);bone.add_child(part);part.transform=old;part.position-=pivot
	joints.append({"bone":bone,"kind":kind,"phase":offset})
func configure(model,id):
	add_child(model)
	var parts={};gather(model,parts)
	assert(parts.size()>10,"Rig parts missing")
	match int(id):
		1:
			joint(parts,[1,2],Vector3(-0.22,0.43,-0.23),"leg",0)
			joint(parts,[3,4],Vector3(-0.22,0.43,0.23),"leg",PI)
			joint(parts,[5,6],Vector3(0.22,0.43,-0.23),"leg",PI)
			joint(parts,[7,8],Vector3(0.22,0.43,0.23),"leg",0)
			joint(parts,range(12,25),Vector3(0,0.85,0.35),"head")
			joint(parts,[25],Vector3(0,0.71,-0.3),"tail")
		4:
			joint(parts,[7],Vector3(-0.2,0.3,0.14),"leg")
			joint(parts,[12],Vector3(0.2,0.3,0.14),"leg",PI)
			joint(parts,[6],Vector3(-0.28,0.62,0.14),"arm",PI)
			joint(parts,[11],Vector3(0.28,0.62,0.14),"arm")
			joint(parts,[3,4,5,8,9,10,13,14,15,16,17,18,19,20,21],Vector3(0,0.68,0.05),"head")
			joint(parts,[22],Vector3(0,0.28,-0.25),"tail")
		7:
			joint(parts,[6],Vector3(-0.19,0.3,0.08),"leg")
			joint(parts,[10],Vector3(0.19,0.3,0.08),"leg",PI)
			joint(parts,[7],Vector3(-0.25,0.6,0.1),"arm",PI)
			joint(parts,[11],Vector3(0.25,0.6,0.1),"arm")
			joint(parts,[3,4,5,8,9,12,13,14,15,16,17,18,19,22],Vector3(0,0.68,0.04),"head")
			joint(parts,[20],Vector3(0,0.22,-0.26),"tail")
		10:
			joint(parts,[1,2],Vector3(-0.12,0.32,0.03),"leg")
			joint(parts,[3,4],Vector3(0.12,0.32,0.03),"leg",PI)
			joint(parts,[15,16],Vector3(-0.2,0.58,-0.01),"wing")
			joint(parts,[17,18],Vector3(0.2,0.58,-0.01),"wing",PI)
			joint(parts,range(7,15),Vector3(0,0.65,0.13),"head")
			joint(parts,[19],Vector3(0,0.55,-0.25),"tail")
	return self
func _process(delta):
	clock+=delta
	var distance=global_position.distance_to(previous);previous=global_position
	moving=lerpf(moving,minf(distance/maxf(delta,0.001)/4.0,1),minf(1,delta*10));phase+=distance*5.5
	for j in joints:
		match j.kind:
			"leg","arm":j.bone.rotation.x=sin(phase+j.phase)*moving*0.6+sin(clock*2+j.phase)*0.025
			"head":j.bone.rotation.y=sin(clock*1.3)*0.08;j.bone.rotation.x=sin(clock*2.2)*0.035
			"tail":j.bone.rotation.y=sin(clock*3)*0.22
			"wing":j.bone.rotation.z=sin(clock*3+j.phase)*(0.12+moving*0.3)
