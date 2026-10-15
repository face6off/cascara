extends Node3D
var age=0.0
func _ready():
	for i in range(6):
		var star=MeshInstance3D.new();var diamond=PrismMesh.new();diamond.size=Vector3(0.08,0.16,0.08);star.mesh=diamond
		var mat=StandardMaterial3D.new();mat.albedo_color=Color("#f9e8a3");mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;star.material_override=mat;add_child(star)
func _process(delta):
	age+=delta
	for i in range(get_child_count()):
		var star=get_child(i);var angle=float(i)*TAU/6+age*0.55
		star.position=Vector3(cos(angle)*0.55,0.8+sin(angle*2+age)*0.4,sin(angle)*0.55)
		star.rotation.z=age+float(i);star.scale=Vector3.ONE*(0.4+0.6*absf(sin(age*2+i)))
