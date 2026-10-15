extends Node3D

# A small articulated character. Gait follows distance travelled, so pauses
# and turns do not leave the feet cycling while the character stands still.
var hips: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var phase = 0.0
var motion = 0.0
var last_position = Vector3.ZERO
var clock = 0.0
var initialized = false

func piece(parent, mesh, color, pos, size=Vector3.ONE):
	var n=MeshInstance3D.new();n.mesh=mesh;n.position=pos;n.scale=size
	var m=StandardMaterial3D.new();m.albedo_color=Color(color);m.roughness=1.0
	n.material_override=m;parent.add_child(n);return n
func ball(parent,color,pos,size):
	var s=SphereMesh.new();s.radius=0.5;s.height=1.0;s.radial_segments=16;s.rings=8
	return piece(parent,s,color,pos,size)
func limb(x,y,length,color):
	var pivot=Node3D.new();pivot.position=Vector3(x,y,0);hips.add_child(pivot)
	var c=CapsuleMesh.new();c.radius=0.12;c.height=length
	piece(pivot,c,color,Vector3(0,-length/2,0));return pivot
func build(coat="#e1ab43",traveller=true):
	hips=Node3D.new();add_child(hips)
	ball(hips,coat,Vector3(0,0.96,0),Vector3(0.65,0.69,0.44))
	ball(hips,"#efc5a4",Vector3(0,1.52,0),Vector3(0.53,0.56,0.5))
	ball(hips,"#343941",Vector3(0,1.72,-0.045),Vector3(0.58,0.28,0.5))
	ball(hips,coat,Vector3(0,1.78,0),Vector3(0.62,0.2,0.57))
	ball(hips,coat,Vector3(0,1.74,0.31),Vector3(0.57,0.055,0.31))
	for x in [-0.105,0.105]:
		ball(hips,"#fbf4de",Vector3(x,1.55,0.233),Vector3(0.105,0.13,0.04))
		ball(hips,"#263c3b",Vector3(x,1.54,0.258),Vector3(0.055,0.08,0.025))
	ball(hips,"#d39a82",Vector3(0,1.45,0.27),Vector3(0.07,0.06,0.06))
	left_leg=limb(-0.17,0.69,0.55,"#354f61");right_leg=limb(0.17,0.69,0.55,"#354f61")
	for leg in [left_leg,right_leg]: ball(leg,"#293936",Vector3(0,-0.54,0.08),Vector3(0.27,0.18,0.4))
	left_arm=limb(-0.38,1.19,0.51,coat);right_arm=limb(0.38,1.19,0.51,coat)
	for arm in [left_arm,right_arm]: ball(arm,"#efc5a4",Vector3(0,-0.53,0),Vector3(0.18,0.21,0.19))
	if traveller:
		ball(hips,"#57746b",Vector3(0,1.05,-0.29),Vector3(0.54,0.63,0.26))
		for x in [-0.2,0.2]: ball(hips,"#b8cdad",Vector3(x,1.08,0.21),Vector3(0.055,0.53,0.035))
	return self
func _process(delta):
	if hips==null:return
	if not initialized:last_position=global_position;initialized=true
	var distance=global_position.distance_to(last_position)
	motion=lerpf(motion,clampf(distance/maxf(delta,0.001)/6.0,0,1),minf(1,delta*16))
	phase+=distance*5.8;clock+=delta
	var swing=sin(phase)*0.65*motion
	left_leg.rotation.x=swing;right_leg.rotation.x=-swing
	left_arm.rotation.x=-swing*0.8;right_arm.rotation.x=swing*0.8
	hips.position.y=absf(sin(phase))*0.06*motion+sin(clock*2)*0.008*(1-motion)
	var direction=global_position-last_position
	if direction.length()>0.002: rotation.y=lerp_angle(rotation.y,atan2(direction.x,direction.z),minf(1,delta*18))
	last_position=global_position
