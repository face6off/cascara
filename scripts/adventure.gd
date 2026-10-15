extends Node3D

const Rules = preload("res://scripts/rpg.gd")
const Art = preload("res://scripts/fauna.gd")
const Walker = preload("res://scripts/walker.gd")
const Cities = preload("res://scripts/settlements.gd")
const Conversation = preload("res://scripts/conversation.gd")
const Scenery = preload("res://scripts/scenery.gd")
var rpg = Rules.new()
var art = Art.new()
var maps = {}
var nodes = []
var terrain: Node3D
var actors: Node3D
var player: Node3D
var camera: Camera3D
var ui: Control
var panel: PanelContainer
var body: VBoxContainer
var hud: Label
var objective: Label
var battle = {}
var message = ""
var step_timer = 0.0
var music: AudioStreamPlayer
var music_kind = "town"
var title_screen = true
var log_lines = []
var file_dialog: FileDialog
var known_maps = []
var busy = false
var fast_mode = false
var blocked = {}
var grass_tiles = {}
var exits = []
var transition: ColorRect
var chapter: Label
var arena: Node3D
var models = {}
var battle_cards: Control
var cinematic = false
var elapsed = 0.0
var exit_cooldown = 0.0
var footstep: AudioStreamPlayer
var last_foot = 0.0
var message_timer = 0.0
var navigation: HBoxContainer
var health_bars = {}
var approached = {}
var dialogue = null
var distance_walked=0.0
var side_jobs=[]
var move_direction=Vector2.ZERO

func _ready():
	fast_mode="--self-test" in OS.get_cmdline_user_args()
	rpg.setup()
	build_maps()
	var environment = WorldEnvironment.new()
	var env = Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("#adc6bf");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("#d2e4d4");env.ambient_light_energy=0.18;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.environment=env;add_child(environment)
	var sun = DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-35,0);sun.light_color=Color("#fff0d2");sun.light_energy=0.38;sun.shadow_enabled=true;add_child(sun)
	camera=Camera3D.new();camera.fov=43;camera.current=true;add_child(camera)
	var canvas=CanvasLayer.new();add_child(canvas);ui=Control.new();ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.add_child(ui)
	var theme=Theme.new();theme.default_font_size=17
	for state in ["normal","hover","pressed","focus"]:
		var st=StyleBoxFlat.new();st.bg_color=Color("#28584e" if state=="normal" else "#3e7d66");st.set_corner_radius_all(8);st.content_margin_left=14;st.content_margin_right=14;st.content_margin_top=8;st.content_margin_bottom=8;theme.set_stylebox(state,"Button",st)
	theme.set_color("font_color","Button",Color("#f4eed5"));theme.set_color("font_hover_color","Button",Color.WHITE);ui.theme=theme
	var header=Panel.new();header.position=Vector2(12,10);header.size=Vector2(1256,85);header.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var hs=StyleBoxFlat.new();hs.bg_color=Color(0.08,0.17,0.16,0.9);hs.set_corner_radius_all(12);header.add_theme_stylebox_override("panel",hs);ui.add_child(header)
	hud=Label.new();hud.position=Vector2(22,18);hud.add_theme_color_override("font_color",Color("#eff3df"));ui.add_child(hud)
	objective=Label.new();objective.position=Vector2(22,52);objective.add_theme_color_override("font_color",Color("#e5e7bc"));ui.add_child(objective)
	var bar=HBoxContainer.new();navigation=bar;bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);bar.position=Vector2(20,-56);ui.add_child(bar)
	for pair in [["Party",party_menu],["Bag",bag_menu],["Guide",guide_menu],["Map",travel_menu],["Save",save_menu],["Settings",settings_menu],["Journal",quest_journal]]:
		var b=Button.new();b.text=pair[0];b.custom_minimum_size=Vector2(112,38);b.pressed.connect(func():if not busy and dialogue==null:pair[1].call());bar.add_child(b)
	file_dialog=FileDialog.new();file_dialog.access=FileDialog.ACCESS_FILESYSTEM;file_dialog.filters=PackedStringArray(["*.json ; Cascara save"]);ui.add_child(file_dialog)
	music=AudioStreamPlayer.new();music.volume_db=-14;add_child(music)
	var overlay=CanvasLayer.new();overlay.layer=20;add_child(overlay)
	transition=ColorRect.new();transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);transition.color=Color(0.025,0.07,0.08,0);transition.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(transition)
	chapter=Label.new();chapter.set_anchors_and_offsets_preset(Control.PRESET_CENTER);chapter.position=Vector2(-500,-40);chapter.size=Vector2(1000,80);chapter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;chapter.add_theme_font_size_override("font_size",34);chapter.modulate.a=0;overlay.add_child(chapter)
	footstep=AudioStreamPlayer.new();footstep.volume_db=-22;add_child(footstep);create_footstep()
	show_title()
	if "--self-test" in OS.get_cmdline_user_args(): run_tests()
	if "--presentation-test" in OS.get_cmdline_user_args() or "--city-test" in OS.get_cmdline_user_args():call_deferred("city_test")

func build_maps():
	for town in rpg.data.world.towns: maps[town.id]={"id":town.id,"name":town.name,"kind":"town","level":5,"links":[],"encounters":[]}
	for landmark in rpg.data.world.landmarks: maps[landmark.id]={"id":landmark.id,"name":landmark.name,"kind":"town","level":60,"links":[],"encounters":[]}
	for route in rpg.data.world.routes:
		maps[route.id]={"id":route.id,"name":route.name,"kind":"route","level":int(route.level_range[0]),"links":[route.start,route.end],"encounters":route.encounters.map(func(e):return int(e.species_id))}
	for d in rpg.data.world.dungeons: maps[d.id]={"id":d.id,"name":d.name,"kind":"dungeon","level":30,"links":[],"encounters":[]}
	for route in rpg.data.world.routes:
		for endpoint in [route.start,route.end]:
			if maps.has(endpoint) and not maps[endpoint].links.has(route.id): maps[endpoint].links.append(route.id)
	for d in rpg.data.world.dungeons:
		if maps.has(d.entry) and not maps[d.entry].links.has(d.id): maps[d.entry].links.append(d.id);maps[d.id].links.append(d.entry)
	for g in rpg.data.characters.gyms:
		var id = g.id+"_interior"
		maps[id]={"id":id,"name":g.title,"kind":"gym","level":int(g.ace_level)-4,"links":[g.town],"encounters":[],"gym":g}
		maps[g.town].links.append(id)
	for s in rpg.species.values():
		if int(s.id)>9 and not s.legendary and int(s.stage)==1:
			var habitat = s.get("primary_habitat","r01")
			if maps.has(habitat) and not maps[habitat].encounters.has(int(s.id)): maps[habitat].encounters.append(int(s.id))
	for s in rpg.species.values():
		if int(s.id)>=1000: maps["r01" if int(s.id)%2 else "r02"].encounters.append(int(s.id))
	for d in maps.values():
		if d.encounters.is_empty() and d.kind=="dungeon": d.encounters=[39,51,63,65]
	build_city_maps()
	known_maps=maps.keys()

func allowed(id):
	var badges = int(rpg.state.get("badges",0));var flags=rpg.state.get("flags",{})
	if id.begins_with("gym"): return badges>=int(maps[id].gym.number)-1
	if id.begins_with("r") and id.length()==3:
		var n=int(id.substr(1));var need={3:1,5:2,6:3,7:3,8:3,9:4,10:5,11:5,12:6,13:7,14:7,15:8,16:8,17:8,18:8,19:8}
		if n>=20: return flags.get("champion",false)
		if n==16: return flags.get("whitevault_shutdown",false)
		if n in [17,18,19]: return flags.get("main_story_resolved",false)
		return badges>=need.get(n,0)
	if id=="league_summit": return badges==8 and flags.get("main_story_resolved",false)
	return true

func add_button(text,call,target=null):
	var b=Button.new();b.text=text;b.custom_minimum_size=Vector2(0,40);b.pressed.connect(func():if not busy:call.call());(body if target==null else target).add_child(b);return b
func text(line):
	var label=Label.new();label.text=str(line);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_color_override("font_color",Color("#46604e"));body.add_child(label);return label
func show_panel(title):
	if panel!=null: panel.queue_free()
	panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER);panel.position=Vector2(-310,-275);panel.size=Vector2(620,550);ui.add_child(panel)
	var style=StyleBoxFlat.new();style.bg_color=Color("#f0f0e0");style.set_corner_radius_all(14);style.content_margin_left=22;style.content_margin_right=22;style.content_margin_top=18;style.content_margin_bottom=18;panel.add_theme_stylebox_override("panel",style)
	var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(576,510);panel.add_child(scroll);body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",9);scroll.add_child(body)
	var heading=text(title);heading.add_theme_font_size_override("font_size",27);heading.add_theme_color_override("font_color",Color("#24493d"))
func close_panel():
	if busy:return
	if panel!=null: panel.queue_free();panel=null
	if not battle.is_empty(): battle_menu()
func show_title():
	title_screen=true;rpg.new_game(1);load_map("brackenbay");show_panel("CASCARA\nPaths Beneath the Ice")
	text("A rain-soaked coastal journey through forests, islands, and mountain passes.")
	text("Explore Cascara. Meet your partner, follow the coast, and train for eight distinct Gyms.")
	for i in range(3):
		var slot=i;var exists=FileAccess.file_exists("user://save_"+str(slot)+".json")
		if exists: add_button("Continue slot "+str(slot+1),func():if rpg.load_game(slot):title_screen=false;load_map(rpg.state.map,Vector2(rpg.state.x,rpg.state.z));close_panel())
	add_button("New adventure",choose_starter)
	add_button("Import save",func():file_dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE;file_dialog.file_selected.connect(import_save,CONNECT_ONE_SHOT);file_dialog.popup_centered_ratio(0.7))
	add_button("Quit",func():get_tree().quit())
func choose_starter():
	show_panel("Choose your first partner")
	text("Fernawn steadied the muddy dock, Embermot freed a frozen winch, and Rillip found the missing rope. Which one will travel with you?")
	for id in [1,4,7]:
		var sid=id;add_button(rpg.species[sid].name+" / "+str(rpg.species[sid].types[0]),func():rpg.new_game(sid);title_screen=false;load_map("brackenbay");close_panel();notice("Hemlock: Follow Saltwind Walk east to Alderwick. Your Field Guide will record the journey."))

func mesh_node(mesh,color,pos,scale=Vector3.ONE):
	var n=MeshInstance3D.new();n.mesh=mesh;n.position=pos;n.scale=scale
	var mat=StandardMaterial3D.new();mat.albedo_color=Color(color);mat.roughness=0.9;n.material_override=mat;return n
func label3d(line,pos):
	var n=Label3D.new();n.text=line;n.position=pos;n.font_size=28;n.pixel_size=0.012;n.no_depth_test=true;n.billboard=BaseMaterial3D.BILLBOARD_ENABLED;n.modulate=Color("#f7eed0");actors.add_child(n);return n
func marker(node):
	nodes.append(node)
	var m=Node3D.new();m.position=Vector3(node.x,0,node.z);actors.add_child(m);node.visual=m
	if node.role in ["legend","rare","climax"]:
		var sid=int(node.legend.species_id) if node.role=="legend" else int(node.species) if node.role=="rare" else 93
		var creature=art.make(sid,rpg.species);m.add_child(creature)
	elif node.role=="lost_item":
		var parcel=BoxMesh.new();parcel.size=Vector3(0.6,0.5,0.5);m.add_child(mesh_node(parcel,"#d5ad63",Vector3(0,0.3,0)))
		var ribbon=BoxMesh.new();ribbon.size=Vector3(0.12,0.52,0.52);m.add_child(mesh_node(ribbon,"#f3e7c5",Vector3(0,0.3,0)))
	elif node.role in ["puzzle","shutdown","storage","journal"]:
		var console=BoxMesh.new();console.size=Vector3(0.8,1,0.6);m.add_child(mesh_node(console,"#5d7874",Vector3(0,0.5,0)))
		var screen=BoxMesh.new();screen.size=Vector3(0.6,0.4,0.04);m.add_child(mesh_node(screen,"#b4d2a4",Vector3(0,0.9,0.33)))
	else:
		var person=Walker.new().build("#d58d9b" if node.role=="heal" else "#769db3" if node.role=="shop" else ["#c18272","#688e9f","#927aac","#97a663"][nodes.size()%4],false);m.add_child(person);person.rotation.y=0 if node.get("facing",Vector2i(0,-1)).y==1 else PI
	node.label=label3d(node.name,Vector3(node.x,2.3,node.z))
func load_map(id,spawn=Vector2(15,16)):
	if not maps.has(id): id="brackenbay"
	if id=="r01" and Vector2(spawn)==Vector2(15,16):spawn=Vector2(2,15)
	rpg.state.map=id;rpg.state.x=spawn.x;rpg.state.z=spawn.y
	rpg.state.flags["visited_"+id]=true
	if terrain!=null: terrain.queue_free()
	if actors!=null: actors.queue_free()
	terrain=Node3D.new();actors=Node3D.new();add_child(terrain);add_child(actors);nodes.clear();approached.clear()
	var map=maps[id]
	var scenery=Cities.new() if map.kind in ["town","indoor"] else Scenery.new();var geometry=scenery.build(terrain,map,id);blocked=geometry.blocked;grass_tiles=geometry.grass
	player=Walker.new().build();actors.add_child(player);player.position=Vector3(rpg.state.x,0,rpg.state.z);distance_walked=0.0;fixed_camera()
	exits=map_exits(id)
	for gate in exits:
		if gate.get("door",false):continue
		var pos=gate.tile;var post=BoxMesh.new();post.size=Vector3(0.12,1.1,0.12);terrain.add_child(mesh_node(post,"#826b51",Vector3(pos.x,0.55,pos.y)))
		label3d("→ "+maps[gate.dest].name,Vector3(pos.x,2.2,pos.y));blocked.erase(pos)
	if not map.kind in ["town","indoor"]:marker({"name":"Rest shelter","x":20 if id=="r01" else 15,"z":23,"role":"heal"})
	if map.kind=="town":
		marker({"name":"Town noticeboard","x":13,"z":16,"role":"journal"})
		if id=="millford":marker({"name":"Nursery gifts","x":19,"z":10,"role":"starter_gift"})
		if id=="crownstation":marker({"name":"Battle Lodge","x":21,"z":15,"role":"lodge"})
	if map.kind=="indoor":populate_interior(map)
	if map.kind=="route":
		var positions=[[7,13],[11,6],[23,18],[26,8]] if id=="r01" else [[8,15],[15,7],[23,15],[15,21]];var i=0
		for trainer in rpg.data.trainers:
			if trainer.map_id==id:
				marker({"name":trainer.name,"x":positions[i][0],"z":positions[i][1],"role":"trainer","trainer":trainer,"facing":Vector2i(0,1) if i<2 else Vector2i(0,-1)});i+=1
	if map.kind=="gym":
		var g=map.gym
		marker({"name":"Puzzle console","x":7,"z":15,"role":"puzzle","gym":g})
		marker({"name":g.leader,"x":15,"z":4,"role":"leader","gym":g})
		var i=0
		for trainer in rpg.data.trainers:
			if trainer.map_id==id: marker({"name":trainer.name,"x":23,"z":8+i*5,"role":"trainer","trainer":trainer});i+=1
	var quest_index=0
	for q in rpg.data.quests:
		if q.location==id:
			marker({"name":q.name,"x":6,"z":8+quest_index*4,"role":"quest","quest":q})
			quest_index+=1
	if id=="whitevault_glacier": marker({"name":"Whitevault control core","x":15,"z":7,"role":"shutdown"})
	if id=="herdrest_basin": marker({"name":"The ancient corridor","x":15,"z":7,"role":"climax"})
	if id=="league_summit": marker({"name":"League registration","x":15,"z":7,"role":"league"})
	for l in rpg.data.legendaries:
		if l.location==id: marker({"name":rpg.species[int(l.species_id)].name,"x":21,"z":7,"role":"legend","legend":l})
	for sid in [88,90,91]:
		var habitat=rpg.species[sid].get("primary_habitat","")
		if habitat==id: marker({"name":rpg.species[sid].name,"x":21,"z":7,"role":"rare","species":sid})
	spawn_side_items(id)
	ensure_safe_spawn()
	set_music("battle" if not battle.is_empty() else "town" if map.kind in ["town","indoor"] else "route")
	update_hud()
	if not title_screen:rpg.save_game()

func _process(delta):
	elapsed+=delta;exit_cooldown-=delta;message_timer-=delta
	if player==null or not is_instance_valid(player):return
	if not cinematic:fixed_camera()
	if actors!=null and is_instance_valid(actors):
		for n in actors.get_children():
			if n is Label3D:n.visible=n.position.distance_to(player.position)<4.5
	if not battle.is_empty() and arena!=null:
		for model in models.values():
			if is_instance_valid(model) and not model.get_meta("acting",false):model.position.y=sin(elapsed*2.8+float(model.get_instance_id()%7))*0.035
	if title_screen or panel!=null or dialogue!=null or not battle.is_empty() or busy:return
	var nearby=nearest_interaction()
	if nearby!=null:objective.text="E / "+nearby.name
	elif message_timer>0:objective.text=message
	else:objective.text="WASD / arrows: walk freely. E: talk or examine. Walk through a door to enter."
	if scan_trainers():return
	var direction=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	if direction==Vector2.ZERO:return
	move_world(direction,delta)
func fixed_camera():
	var focus=player.position+Vector3(0,0.75,0)
	camera.position=focus+Vector3(0,13,12);camera.look_at(focus)
func can_stand(pos):
	if pos.x<1 or pos.x>29 or pos.y<1 or pos.y>25:return false
	var radius=0.27
	for x in range(int(floor(pos.x-radius+0.5)),int(floor(pos.x+radius+0.5))+1):
		for z in range(int(floor(pos.y-radius+0.5)),int(floor(pos.y+radius+0.5))+1):
			if blocked.has(Vector2i(x,z)):return false
	for n in nodes:
		if Vector2(n.x,n.z).distance_to(pos)<0.65:return false
	return true
func move_world(direction,delta):
	move_direction=direction.normalized()
	var distance=4.8*minf(delta,0.1)
	# Short collision steps avoid tunnelling at low frame rates.
	var parts=maxi(1,int(ceil(distance/0.12)))
	for i in range(parts):
		var old=Vector2(player.position.x,player.position.z);var pos=old;var step=move_direction*distance/parts
		if can_stand(pos+Vector2(step.x,0)):pos.x+=step.x
		if can_stand(pos+Vector2(0,step.y)):pos.y+=step.y
		player.position=Vector3(pos.x,0,pos.y);rpg.state.x=pos.x;rpg.state.z=pos.y
		distance_walked+=old.distance_to(pos)
	fixed_camera()
	if distance_walked>=1.0:
		distance_walked-=1.0;rpg.state.steps+=1
		for line in rpg.walk_daycare():notice(line)
		if elapsed-last_foot>0.22:footstep.play();last_foot=elapsed
		var tile=Vector2i(roundi(rpg.state.x),roundi(rpg.state.z))
		if grass_tiles.has(tile) and rpg.rng.randf()<0.10:encounter();return
		if int(rpg.state.steps)%50==0:rpg.save_game()
	for gate in exits:
		if Vector2(gate.tile).distance_to(Vector2(rpg.state.x,rpg.state.z))<0.6 and exit_cooldown<=0:
			if allowed(gate.dest):travel_to(gate.dest);return
			notice("The trail ahead opens as your journey progresses.");exit_cooldown=1.5
func nearest_interaction():
	var result=null;var distance=1.65
	for n in nodes:
		var d=Vector2(n.x,n.z).distance_to(Vector2(rpg.state.x,rpg.state.z))
		if d<distance:distance=d;result=n
	return result
func _unhandled_key_input(event):
	if not event.pressed or event.echo or busy or dialogue!=null: return
	if event.keycode==KEY_ESCAPE and not title_screen: close_panel()
	if event.keycode in [KEY_E,KEY_ENTER,KEY_SPACE] and panel==null and not title_screen: interact()
	if event.keycode==KEY_P and not title_screen and battle.is_empty(): party_menu()
func notice(line):
	message=line;message_timer=6.0;update_hud()
func update_hud():
	if rpg.state.is_empty(): return
	hud.text=maps[rpg.state.map].name+"   |   "+str(int(rpg.state.badges))+" / 8 badges   |   "+str(int(rpg.state.money))+" money   |   "+str(rpg.state.caught.size())+" species"
	objective.text=message if message!="" else "WASD / arrows move. E interacts. P opens Party. Your progress saves at each map and milestone."
func interact():
	if dialogue!=null:return
	var nearest=nearest_interaction()
	for n in nodes:
		if n==nearest:
			match n.role:
				"travel": travel_menu()
				"heal": heal_conversation()
				"shop": shop_menu()
				"storage": storage_menu()
				"daycare": daycare_menu()
				"training": training_menu()
				"trainer": trainer_challenge(n.trainer)
				"leader": leader_challenge(n.gym)
				"puzzle": puzzle_menu(n.gym)
				"quest": quest_menu(n.quest)
				"legend": legend_challenge(n.legend)
				"rare": start_battle("",[{"species_id":n.species,"level":maxi(20,rpg.state.badges*7)}],"rare",true)
				"shutdown": shutdown_menu()
				"climax": climax_menu()
				"league": league_menu()
				"starter_gift": gift_menu()
				"lodge": lodge_menu()
				"lore": talk(n.npc.name,[n.npc.history,n.npc.sample_line])
				"resident": talk(n.name,n.lines)
				"side_quest": side_conversation(n.job)
				"lost_item": collect_side_item(n.job)
				"journal": quest_journal()
			return

func travel_menu():
	if title_screen or not battle.is_empty() or busy or dialogue!=null:return
	show_panel("Trail guide / "+maps[rpg.state.map].name)
	text("Walk to the marked entrance at the edge of the area. The next trail starts where this one ends.")
	for gate in exits:
		var id=gate.dest;var tile=gate.tile;var direction="West" if tile.x==1 else "East" if tile.x==29 else "North" if tile.y==1 else "South"
		text(direction+": "+maps[id].name+(" / not open yet" if not allowed(id) else ""))
	if rpg.state.badges>=2:
		text("Ferry and railway return service")
		for town in rpg.data.world.towns:
			var id=town.id
			if rpg.state.flags.get("visited_"+id,false): add_button(town.name,func():close_panel();travel_to(id))
	add_button("Return",close_panel)

func encounter():
	var map=maps[rpg.state.map]
	if map.encounters.is_empty(): return
	var id=map.encounters[rpg.rng.randi_range(0,map.encounters.size()-1)]
	start_battle("",[{"species_id":id,"level":maxi(3,map.level+rpg.rng.randi_range(0,3))}],"wild",true)

func trainer_challenge(tr):
	if rpg.state.flags.get("defeated_"+tr.id,false):talk(tr.name,["You won our battle. I will keep training here."]);return
	var line={"r01_trainer_2":"My partner loves the tall grass. Let us show you what we have practised!","r01_trainer_3":"The river is quiet today. How about a battle while we wait for a bite?","r01_trainer_4":"One last stop before Alderwick. Have you got time for a quick battle?"}.get(tr.id,tr.get("dialogue",{}).get("before","Ready for a friendly battle?"))
	talk(tr.name,[line],[["Let's battle",func():start_battle(tr.name,tr.team,tr.id,false,tr.get("format","singles"))],["Maybe later",func():pass]])

func leader_challenge(g):
	if int(rpg.state.badges)>=int(g.number):talk(g.leader,["Your badge belongs to the team that got you here."]);return
	if not rpg.state.flags.get(g.id+"_puzzle_complete",false):talk(g.leader,["Finish the three stages of our Gym puzzle first. I will be waiting here."]);return
	for index in [1,3]:
		if not rpg.state.flags.get("defeated_"+g.id+"_trainer_"+str(index),false):talk(g.leader,["Train with the first and third Gym staff before you challenge me."]);return
	if int(g.number)==3 and rpg.state.party.filter(func(m):return m.hp>0).size()<2:talk(g.leader,["This is a doubles battle. Bring two conscious partners."]);return
	talk(g.leader,[g.detailed_design.tactic,"Are you ready to challenge me for the "+g.badge+"?"],[["Challenge",func():start_battle(g.leader,g.team,g.id,false,g.detailed_design.leader_format)],["Not yet",func():pass]])

func puzzle_menu(g):
	var id=g.id;var p=rpg.state.puzzles.get(id,{"stage":0,"values":[0,0,0],"sequence":[]})
	rpg.state.puzzles[id]=p
	show_panel(g.title+" / puzzle")
	if rpg.state.flags.get(id+"_puzzle_complete",false): text("All three stages are complete. Your checkpoint is saved.");add_button("Return",close_panel);return
	text("Stage "+str(int(p.stage)+1)+" / 3. "+g.detailed_design.stages[int(p.stage)])
	match int(g.number):
		1:
			text("Point the three leaf roofs East, West, North to keep each bed dry.")
			for i in range(3):
				var k=i;add_button("Roof "+str(k+1)+": "+["North","East","West"][int(p.values[k])],func():p.values[k]=(int(p.values[k])+1)%3;puzzle_menu(g))
			add_button("Check shelter",func():puzzle_check(g,p.values==[1,2,0]))
		2:
			text("Keep all three nursery channels supplied. Target flow: "+str([2+int(p.stage),3,4-int(p.stage)])+". Total flow stays 9.")
			if p.values==[0,0,0]: p.values=[3,3,3]
			for i in range(3):
				var k=i;add_button("Transfer one unit to channel "+str(k+1)+" ("+str(p.values[k])+")",func():var from=(k+1)%3;if p.values[from]>1:p.values[from]-=1;p.values[k]+=1;puzzle_menu(g))
			add_button("Launch raft",func():puzzle_check(g,p.values==[2+int(p.stage),3,4-int(p.stage)]))
		3:
			var target=["Fuse","Battery","Signal"] if p.stage==0 else ["Battery","Signal","Fuse"] if p.stage==1 else ["Signal","Fuse","Battery"]
			text("Dispatch itinerary: "+", ".join(target)+". Current: "+", ".join(p.sequence))
			for stop in ["Fuse","Battery","Signal","Closed track"]:
				var name=stop
				add_button(name,func():
					p.sequence.append(name)
					if p.sequence.size()==3:
						puzzle_check(g,p.sequence==target)
					else:
						puzzle_menu(g)
				)
		4:
			text("Sample key: SAFE means clear, neutral, no alarm. Choose the safe pool.")
			var safe=(int(p.stage)+1)%3
			for i in range(3):
				var k=i;add_button("Pool "+str(k+1)+(" / clear, neutral, no alarm" if k==safe else " / cloudy, acidic, alarm"),func():puzzle_check(g,k==safe))
		5:
			var target=["Arrival","Bell","Tools"] if p.stage==0 else ["Lunch","Coat","Letter"] if p.stage==1 else ["Letter","Tools","Bell"]
			text("Witness memory: "+", ".join(target)+". Reconstruct the sequence: "+", ".join(p.sequence))
			for item in target:
				var name=item
				add_button(name,func():
					p.sequence.append(name)
					if p.sequence.size()==3:
						puzzle_check(g,p.sequence==target)
					else:
						puzzle_menu(g)
				)
		6:
			text("The loaded cart weighs "+str(2+int(p.stage))+" units. Pick the first track rated for its weight.")
			for rating in [1,2,3,4]:
				var capacity=rating;add_button("Track capacity "+str(capacity),func():puzzle_check(g,capacity==2+int(p.stage)))
		7:
			text("Adjust heat while the three greenhouses share one budget. Target: "+str([2+int(p.stage),4,3-int(p.stage)])+".")
			if p.values==[0,0,0]: p.values=[3,3,3]
			for i in range(3):
				var k=i;add_button("Shift heat to chamber "+str(k+1)+" ("+str(p.values[k])+")",func():var from=(k+1)%3;if p.values[from]>0:p.values[from]-=1;p.values[k]+=1;puzzle_menu(g))
			add_button("Stabilize",func():puzzle_check(g,p.values==[2+int(p.stage),4,3-int(p.stage)]))
		8:
			var target=["Shelter","Anchor","Cross"] if p.stage==0 else ["Anchor","Shelter","Cross"] if p.stage==1 else ["Shelter","Cross","Anchor"]
			text("Dispatch briefing: "+", ".join(target)+". Choose the convoy's safe order. "+", ".join(p.sequence))
			for task in ["Shelter","Anchor","Cross"]:
				var name=task
				add_button(name,func():
					p.sequence.append(name)
					if p.sequence.size()==3:
						puzzle_check(g,p.sequence==target)
					else:
						puzzle_menu(g)
				)
	add_button("Reset current stage",func():p.values=[0,0,0];p.sequence=[];puzzle_menu(g))
	add_button("Leave with checkpoint",func():rpg.save_game();close_panel())
func puzzle_check(g,correct):
	var p=rpg.state.puzzles[g.id]
	if correct:
		p.stage+=1;p.values=[0,0,0];p.sequence=[]
		if p.stage==3: rpg.state.flags[g.id+"_puzzle_complete"]=true;rpg.heal_party()
	else: p.sequence=[];message="That arrangement did not work. No progress or items were lost."
	rpg.save_game();puzzle_menu(g)

func start_battle(name,roster,id,catchable,format="singles"):
	if not rpg.state.party.any(func(m):return m.hp>0): rpg.heal_party()
	battle={"name":name,"id":id,"enemies":[],"enemy_active":[],"active":[],"format":format,"catchable":catchable,"choices":[],"weather":"","weather_turns":0,"log":[],"turn":0}
	for spec in roster:
		var sid=int(spec.get("species_id",spec.get("species",1)));var m=rpg.make_mon(sid,int(spec.level));
		if spec.has("shiny"):m.shiny=spec.shiny
		battle.enemies.append(m)
		if not rpg.state.seen.has(sid): rpg.state.seen.append(sid)
	var count=2 if format=="doubles" else 1
	for i in range(battle.enemies.size()):
		if battle.enemy_active.size()<count: battle.enemy_active.append(i)
	for i in range(rpg.state.party.size()):
		if rpg.state.party[i].hp>0 and battle.active.size()<count: battle.active.append(i)
	for i in battle.active: battle.log.append_array(rpg.entry(rpg.state.party[i],battle.enemies,battle.weather))
	for i in battle.enemy_active: battle.log.append_array(rpg.entry(battle.enemies[i],rpg.state.party,battle.weather))
	battle.log.append(name+" wants to battle." if name!="" else "A wild "+rpg.species[int(battle.enemies[0].species)].name+" appeared.")
	set_music("battle");navigation.visible=false
	if fast_mode:build_arena();battle_menu()
	else:battle_intro()

func battle_menu():
	if busy or battle.is_empty():return
	show_panel("Choose your move")
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT);panel.position=Vector2(20,566);panel.size=Vector2(1240,214)
	panel.get_child(0).custom_minimum_size=Vector2(1196,176)
	if battle_cards!=null:battle_cards.queue_free()
	health_bars={};battle_cards=Control.new();battle_cards.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(battle_cards)
	for j in range(battle.enemy_active.size()):health_card(battle.enemies[battle.enemy_active[j]],"FOE",Vector2(920-j*350,108))
	for j in range(battle.active.size()):health_card(rpg.state.party[battle.active[j]],"PARTNER",Vector2(20+j*350,460))
	text("\n".join(battle.log.slice(maxi(0,battle.log.size()-1))))
	var actor=int(battle.choices.size())
	if actor>=battle.active.size():resolve_turn();return
	var pi=battle.active[actor];var mon=rpg.state.party[pi]
	body.get_child(0).text=rpg.species[int(mon.species)].name+" / choose an action"
	var grid=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",8);body.add_child(grid)
	for i in range(mon.moves.size()):
		var k=i;var v=mon.moves[k];var b=add_button(rpg.moves[v.id].name+" / "+str(v.pp)+" PP",func():choose_target(pi,k),grid);b.custom_minimum_size.x=275;b.disabled=v.pp<=0
	if mon.moves.all(func(v):return v.pp<=0):add_button("Struggle",func():choose_target(pi,0),grid)
	add_button("Potion",func():battle.choices.append({"kind":"potion","actor":pi});battle_menu(),grid)
	add_button("Switch",func():switch_menu(pi),grid)
	if battle.catchable:
		add_button("Capture Ball",func():capture(),grid)
		add_button("Run",func():battle.log=["You got away safely."];end_battle(false,true),grid)
	show_battle_models()
func choose_target(actor,move):
	if battle.enemy_active.size()==1: battle.choices.append({"kind":"move","actor":actor,"move":move,"target":battle.enemy_active[0]});battle_menu();return
	show_panel("Choose the target")
	for index in battle.enemy_active:
		var target=index;add_button(rpg.species[int(battle.enemies[target].species)].name,func():battle.choices.append({"kind":"move","actor":actor,"move":move,"target":target});battle_menu())
func switch_menu(actor):
	show_panel("Switch partner")
	for i in range(rpg.state.party.size()):
		if rpg.state.party[i].hp<=0 or battle.active.has(i): continue
		var index=i;add_button(rpg.species[int(rpg.state.party[i].species)].name,func():battle.choices.append({"kind":"switch","actor":actor,"target":index});battle_menu())
	add_button("Back",battle_menu)
func resolve_turn():
	busy=true
	if not fast_mode and panel!=null:panel.queue_free();panel=null
	var choices=battle.choices.duplicate();battle.choices=[];battle.turn+=1;battle.log=[]
	for i in battle.enemy_active:
		var e=battle.enemies[i];var best=0;var power=-1.0
		for k in range(e.moves.size()):
			var v=e.moves[k];var score=float(rpg.moves[v.id].get("power",10))*rpg.rng.randf_range(0.7,1.1)
			if v.pp>0 and score>power: best=k;power=score
		choices.append({"kind":"move","enemy":true,"actor":i,"move":best,"target":battle.active[rpg.rng.randi_range(0,battle.active.size()-1)]})
	for c in choices:
		var m=battle.enemies[c.actor] if c.get("enemy",false) else rpg.state.party[c.actor]
		var speed=rpg.stats(m)[5]*rpg.stage(m.stages.speed)*(0.5 if m.status=="paralyze" else 1.0)
		var priority=6 if c.kind in ["switch","potion","wait"] else rpg.moves[m.moves[c.move].id].get("priority",0)
		if c.kind=="move" and rpg.ability(m)=="prankster" and rpg.moves[m.moves[c.move].id].get("power",0)==0: priority+=1
		c.order=priority*10000+speed+rpg.rng.randf()
	choices.sort_custom(func(a,b):return a.order>b.order)
	for c in choices:
		var m=battle.enemies[c.actor] if c.get("enemy",false) else rpg.state.party[c.actor]
		if m.hp<=0: continue
		if c.kind=="wait":
			continue
		elif c.kind=="potion":
			if rpg.state.bag.potion>0 and m.hp<rpg.stats(m)[0]:rpg.state.bag.potion-=1;m.hp=mini(rpg.stats(m)[0],m.hp+60);battle.log.append("A Potion restored HP.")
		elif c.kind=="switch":
			if rpg.ability(m)=="natural_cure": m.status=""
			if rpg.ability(m)=="regenerator":m.hp=mini(rpg.stats(m)[0],m.hp+int(rpg.stats(m)[0]/3))
			battle.active[battle.active.find(c.actor)]=c.target;battle.log.append_array(rpg.entry(rpg.state.party[c.target],battle.enemies,battle.weather))
		else:
			if c.get("enemy",false) and not battle.active.has(c.target):c.target=battle.active[0]
			var target=battle.enemies[c.target] if not c.get("enemy",false) else rpg.state.party[c.target]
			var effect=rpg.moves[m.moves[c.move].id].get("effect","")
			if effect in ["rain","sun","snow","sand"]:battle.weather=effect;battle.weather_turns=5;battle.log.append("The weather became "+effect+".")
			else:
				var before=target.hp
				if not fast_mode:await animate_action(c,m,target)
				var result=rpg.hit(m,target,c.move,battle.weather);battle.log.append_array(result)
				if not fast_mode:await narrate("Battle",result)
				if not fast_mode:await animate_hit(c,target,before)
	for m in rpg.state.party+battle.enemies: rpg.residual(m,battle.weather)
	if battle.weather_turns>0:battle.weather_turns-=1
	if battle.weather_turns==0:battle.weather=""
	var defeated=[]
	for i in battle.enemy_active:
		if battle.enemies[i].hp<=0:defeated.append(i)
	for i in defeated:
		var foe=battle.enemies[i];var xp=int(foe.level)*16
		for p in rpg.state.party:
			if p.hp>0:rpg.gain(p,xp);rpg.add_ev(p,rpg.species[int(foe.species)].base_stat_target.values().find(rpg.species[int(foe.species)].base_stat_target.values().max()),1)
		battle.enemy_active.erase(i)
		for k in range(battle.enemies.size()):
			if battle.enemies[k].hp>0 and not battle.enemy_active.has(k):battle.enemy_active.append(k);break
	if battle.enemy_active.is_empty():end_battle(true);return
	for index in battle.active.duplicate():
		if rpg.state.party[index].hp<=0:
			battle.active.erase(index)
			for k in range(rpg.state.party.size()):
				if rpg.state.party[k].hp>0 and not battle.active.has(k):battle.active.append(k);break
	if battle.active.is_empty():end_battle(false,false,true);return
	busy=false;battle_menu()
func capture():
	var enemy=battle.enemies[battle.enemy_active[0]]
	if rpg.state.party.size()==6 and rpg.state.boxes.size()>=300:notice("Make room in storage before catching.");return
	var ball="ultra" if rpg.state.bag.ultra>0 else "great" if rpg.state.bag.great>0 else "ball"
	if rpg.state.bag[ball]<=0:notice("You have no Capture Balls left.");return
	if not fast_mode:await capture_animation()
	rpg.state.bag[ball]-=1
	var mod=2.0 if ball=="ultra" else 1.5 if ball=="great" else 1.0
	var chance=clampf((0.28+0.55*(1.0-float(enemy.hp)/rpg.stats(enemy)[0]))*mod,0.05,0.95)
	if rpg.species[int(enemy.species)].legendary:chance*=0.35
	if enemy.status!="":chance*=1.3
	if rpg.rng.randf()<chance:
		(rpg.state.party if rpg.state.party.size()<6 else rpg.state.boxes).append(enemy)
		if not rpg.state.caught.has(enemy.species):rpg.state.caught.append(enemy.species)
		if rpg.species[int(enemy.species)].legendary:rpg.state.flags["caught_"+str(enemy.species)]=true
		battle.log=["Caught "+rpg.species[int(enemy.species)].name+"!"];end_battle(false,true)
	else:
		battle.choices.append({"kind":"wait","actor":battle.active[0]});battle.log=["The Pokémon broke free."];resolve_turn()
func show_battle_models():
	if arena==null:return
	var active_keys=[]
	for side in [0,1]:
		var indices=battle.active if side==0 else battle.enemy_active
		for j in range(indices.size()):
			var key=("p" if side==0 else "e")+str(indices[j]);active_keys.append(key)
			if models.has(key):continue
			var m=rpg.state.party[indices[j]] if side==0 else battle.enemies[indices[j]]
			var model=art.make(m.species,rpg.species,m.get("shiny",false));model.position=Vector3(-2.8 if side==0 else 2.8,0,1.8-j*2.0 if side==0 else -1.8+j*2.0)
			model.rotation.y=atan2(5.6 if side==0 else -5.6,-3.6 if side==0 else 3.6)
			model.scale*=2.1 if int(rpg.species[int(m.species)].stage)==1 and not rpg.species[int(m.species)].legendary else 1.4 if not rpg.species[int(m.species)].legendary else 1.0
			model.set_meta("rest_scale",model.scale);arena.add_child(model);models[key]=model
	for key in models.keys():
		if not active_keys.has(key):models[key].queue_free();models.erase(key)
func end_battle(won,escaped=false,lost=false):
	busy=true
	var id=battle.id;var log=battle.log.duplicate()
	if won:
		if id=="lodge" or not rpg.state.flags.get("defeated_"+id,false):rpg.state.money+=maxi(200,maps[rpg.state.map].level*70)
		rpg.state.flags["defeated_"+id]=true
		if id.begins_with("gym") and id.length()==4:
			rpg.state.badges=maxi(int(rpg.state.badges),int(id.substr(3)));rpg.state.bag.candy+=3;rpg.state.bag.great+=5
			log.append("You earned badge "+str(rpg.state.badges)+"!")
		if id=="climax":rpg.state.flags.main_story_resolved=true;log.append("The final tower falls silent. The migration corridor is safe. The League awaits.")
		if id.begins_with("league_"):
			rpg.state.flags[id]=true;rpg.heal_party()
			if id=="league_5":rpg.state.flags.champion=true;rpg.state.hall.append(rpg.state.party.duplicate(true));rpg.state.bag.patch+=3;log.append("You are Cascara's Champion! The postgame expeditions are open.")
		if id.begins_with("trial_"):rpg.state.flags[id]=true
	if lost:rpg.heal_party();log.append("The rescue station restored your team. You can retry.")
	for p in rpg.state.party:
		for k in p.stages:p.stages[k]=0
		p.spent={}
	if not fast_mode:await fade_to(1.0,0.3)
	battle={}
	if arena!=null:arena.queue_free();arena=null
	models={}
	if battle_cards!=null:battle_cards.queue_free();battle_cards=null
	terrain.visible=true;actors.visible=true;cinematic=false;navigation.visible=true
	camera.position=Vector3(player.position.x,13,player.position.z+12);camera.look_at(player.position+Vector3(0,0,-1))
	set_music("town" if maps[rpg.state.map].kind=="town" else "route");rpg.save_game()
	await fade_to(0.0,0.3);busy=false;exit_cooldown=1.0
	talk("Battle results",log.slice(maxi(0,log.size()-6)) if not log.is_empty() else ["You returned to your adventure."]);update_hud()

func party_menu():
	if title_screen or not battle.is_empty() or busy or dialogue!=null:return
	show_panel("Your travelling party")
	for i in range(rpg.state.party.size()):
		var k=i;var m=rpg.state.party[k];text(mon_name(m)+" / Lv "+str(m.level)+" / "+str(m.hp)+" / "+str(rpg.stats(m)[0])+" HP")
		add_button("Summary / "+rpg.species[int(m.species)].name,func():summary_menu(k))
		add_button("Make lead",func():var first=rpg.state.party[0];rpg.state.party[0]=rpg.state.party[k];rpg.state.party[k]=first;rpg.save_game();party_menu())
	add_button("Return",close_panel)
func summary_menu(index):
	var m=rpg.state.party[index];var s=rpg.species[int(m.species)]
	show_panel(mon_name(m)+" / Summary");creature_portrait(m);text("Level "+str(m.level)+" / "+m.gender+" / "+m.nature+" / "+rpg.ability(m).capitalize())
	for k in range(6):text(Rules.KEYS[k].capitalize()+": "+str(rpg.stats(m)[k])+"   IV "+str(m.ivs[k])+"   EV "+str(m.evs[k])+" / 252")
	text("Total EVs: "+str(m.evs.reduce(func(a,b):return a+b,0))+" / 510. Held: "+m.held)
	for held in ["Destiny Knot","Everstone","Oran Berry","Leftovers","Focus Sash",""]:
		var item=held;add_button("Hold "+(item if item!="" else "nothing"),func():m.held=item;rpg.save_game();summary_menu(index))
	if rpg.state.bag.patch>0:add_button("Use Ability Patch",func():m.slot="slot_1" if m.slot=="hidden" else "hidden";rpg.state.bag.patch-=1;rpg.save_game();summary_menu(index))
	add_button("Party",party_menu)
func bag_menu():
	if title_screen or not battle.is_empty() or busy or dialogue!=null:return
	show_panel("Field bag")
	for k in rpg.state.bag:text(k.capitalize()+" x "+str(rpg.state.bag[k]))
	for i in range(rpg.state.party.size()):
		var index=i;var m=rpg.state.party[index]
		add_button("Potion / "+rpg.species[int(m.species)].name,func():if rpg.state.bag.potion>0 and m.hp>0 and m.hp<rpg.stats(m)[0]:rpg.state.bag.potion-=1;m.hp=mini(rpg.stats(m)[0],m.hp+60);rpg.save_game();bag_menu())
		add_button("Rare Candy / "+rpg.species[int(m.species)].name,func():if rpg.state.bag.candy>0 and m.level<100:rpg.state.bag.candy-=1;rpg.gain(m,m.level*12-m.xp);rpg.save_game();bag_menu())
		add_button("Revive / "+rpg.species[int(m.species)].name,func():if rpg.state.bag.revive>0 and m.hp==0:rpg.state.bag.revive-=1;m.hp=maxi(1,int(rpg.stats(m)[0]/2));rpg.save_game();bag_menu())
	add_button("Return",close_panel)
func shop_menu():
	show_panel("Trail supplies / "+str(int(rpg.state.money))+" money")
	for pair in [["ball",200],["great",600],["ultra",1200],["potion",300],["revive",800],["candy",3500]]:
		var item=pair[0];var cost=int(pair[1]);add_button(item.capitalize()+" / "+str(cost),func():if rpg.state.money>=cost:rpg.state.money-=cost;rpg.state.bag[item]+=1;rpg.save_game();shop_menu())
	add_button("Return",close_panel)
func storage_menu():
	show_panel("Storage / "+str(rpg.state.boxes.size())+" partners")
	for i in range(rpg.state.boxes.size()):
		var k=i;var m=rpg.state.boxes[k];add_button("Withdraw "+mon_name(m)+" Lv "+str(m.level),func():if rpg.state.party.size()<6:rpg.state.party.append(rpg.state.boxes.pop_at(k));rpg.save_game();storage_menu())
	text("Leave a partner in storage. At least one conscious partner stays with you.")
	for i in range(rpg.state.party.size()):
		var k=i;add_button("Deposit "+mon_name(rpg.state.party[k]),func():if rpg.state.party.size()>1 and rpg.state.party.filter(func(m):return m.hp>0).size()>(1 if rpg.state.party[k].hp>0 else 0):rpg.state.boxes.append(rpg.state.party.pop_at(k));rpg.save_game();storage_menu())
	add_button("Return",close_panel)
func daycare_menu():
	show_panel("Noor's daycare")
	text("Parents gain experience while you walk. Compatible parents make an Egg after 128 steps. Eggs hatch after 256 travel steps. These are Cascara's travel timings.")
	var d=rpg.state.daycare
	for i in range(d.parents.size()):
		var k=i;var m=d.parents[k];add_button("Collect "+rpg.species[int(m.species)].name+" Lv "+str(m.level),func():if rpg.state.party.size()<6 or rpg.state.boxes.size()<300:(rpg.state.party if rpg.state.party.size()<6 else rpg.state.boxes).append(d.parents.pop_at(k));rpg.save_game();daycare_menu())
	if d.parents.size()==2:text("Compatible parents" if rpg.can_breed(d.parents[0],d.parents[1]) else "These parents cannot breed together.")
	if not d.egg.is_empty():add_button("Collect Egg",func():if rpg.state.eggs.size()<12:rpg.state.eggs.append(d.egg);d.egg={};rpg.save_game();daycare_menu())
	for egg in rpg.state.eggs:text("Carried Egg: "+str(egg.egg_steps)+" steps left")
	for i in range(rpg.state.party.size()):
		var k=i;var m=rpg.state.party[k];add_button("Leave "+rpg.species[int(m.species)].name+" / "+m.gender,func():if d.parents.size()<2 and rpg.state.party.size()>1 and rpg.state.party.filter(func(p):return p.hp>0).size()>(1 if m.hp>0 else 0):d.parents.append(rpg.state.party.pop_at(k));d.steps=0;rpg.save_game();daycare_menu())
	add_button("Return",close_panel)
func training_menu():
	show_panel("Elin's training field")
	text("Each session adds up to 10 EVs and costs 100 money. Berries remove 10 EVs. One stat caps at 252, and the full total caps at 510.")
	for i in range(rpg.state.party.size()):
		var index=i;var m=rpg.state.party[index];text(rpg.species[int(m.species)].name)
		for k in range(6):
			var stat=k;add_button(Rules.KEYS[stat]+" / "+str(m.evs[stat])+" EV / train",func():if rpg.state.money>=100 and rpg.add_ev(m,stat,10)>0:rpg.state.money-=100;rpg.save_game();training_menu())
			add_button("Berry / "+Rules.KEYS[stat],func():rpg.add_ev(m,stat,-10);rpg.save_game();training_menu())
	add_button("Return",close_panel)
func guide_menu():
	if title_screen:return
	show_panel("Cascara Field Guide")
	text("Caught: "+str(rpg.state.caught.size())+" / "+str(rpg.species.size())+". Seen: "+str(rpg.state.seen.size()))
	for sid in rpg.state.seen:text(("Owned / " if rpg.state.caught.has(sid) else "Seen / ")+rpg.species[int(sid)].name+" / "+", ".join(rpg.species[int(sid)].types))
	text("Journal")
	for q in rpg.data.quests:text(q.name+" / "+str(rpg.state.quests.get(q.id,0))+" / "+str(q.steps.size())+" steps")
	add_button("Return",close_panel)
func save_menu():
	if title_screen or not battle.is_empty() or busy or dialogue!=null:return
	show_panel("Save your adventure")
	for i in range(3):
		var slot=i;add_button("Save to slot "+str(slot+1),func():notice("Adventure saved." if rpg.save_game(slot) else "The save could not be written.");close_panel())
	add_button("Export backup",func():file_dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE;file_dialog.current_file="cascara-save.json";file_dialog.file_selected.connect(export_save,CONNECT_ONE_SHOT);file_dialog.popup_centered_ratio(0.7))
	add_button("Return",close_panel)
func export_save(path):
	var f=FileAccess.open(path,FileAccess.WRITE)
	if f!=null:f.store_string(JSON.stringify(rpg.state));f.close();notice("Backup exported.")
func import_save(path):
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
	if rpg.validate(parsed) and maps.has(parsed.map):rpg.state=rpg.normalise_save(parsed);title_screen=false;load_map(parsed.map,Vector2(parsed.x,parsed.z));close_panel();notice("Backup imported.")
	else:notice("That file is not a valid native Cascara save. Your existing save was not changed.")
func settings_menu():
	if title_screen or not battle.is_empty() or busy or dialogue!=null:return
	show_panel("Settings")
	add_button("Music on / off",func():rpg.state.options.music=not rpg.state.options.music;music.playing=rpg.state.options.music;rpg.save_game();settings_menu())
	text("Saves are stored in "+OS.get_user_data_dir())
	add_button("Return to title",func():rpg.save_game();show_title())
	add_button("Return",close_panel)
func set_music(kind):
	if music==null:return
	if kind==music_kind and music.playing:return
	music_kind=kind
	var path="res://assets/audio/"+kind+".wav"
	if ResourceLoader.exists(path):
		var stream=load(path)
		if stream is AudioStreamWAV:stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		music.stream=stream;music.play()
	if not rpg.state.is_empty() and not rpg.state.options.music:music.stop()

func quest_menu(q):
	show_panel(q.name)
	var index=int(rpg.state.quests.get(q.id,0))
	if index>=q.steps.size():text("This investigation is complete.");add_button("Return",close_panel);return
	var requirements={"quiet_keeper":5,"cloud_garden":3,"unused_starters":6,"main_legend_pair":8}
	if rpg.state.badges<requirements.get(q.id,0):text("Return after reaching the next stage of your Gym journey.");add_button("Return",close_panel);return
	if q.id in ["sky_guardian","sea_guardian","deep_guardian","mist_guardian","strata_guardian"] and not rpg.state.flags.get("champion",false):text("This expedition begins after the League.");add_button("Return",close_panel);return
	text("Step "+str(index+1)+": "+q.steps[index])
	text("Investigate this site, check the local evidence, and speak to the people nearby.")
	add_button("Investigate and continue",func():
		rpg.state.quests[q.id]=index+1
		if index+1==q.steps.size():
			for flag in q.flags:
				if not str(flag).contains("caught") and flag!="main_story_resolved": rpg.state.flags[flag]=true
			rpg.state.money+=700
			rpg.state.bag.ball+=3
		rpg.save_game()
		quest_menu(q)
	)
	add_button("Return",close_panel)
func shutdown_menu():
	show_panel("Whitevault / evacuation control")
	text("Jun refuses to seal the tunnel while the convoy is inside. Ellis finds the railway exit and Ada gives you the safe shutdown order: open the exit, release the pressure, then stop the tower.")
	var p=rpg.state.puzzles.get("shutdown",0)
	text("Completed rescue steps: "+str(p)+" / 3")
	for i in range(3):
		var k=i;add_button(["Open the railway exit","Release pressure","Stop the tower"][k],func():if k==int(p):rpg.state.puzzles.shutdown=k+1;if k==2:rpg.state.flags.whitevault_shutdown=true;rpg.save_game();shutdown_menu())
	add_button("Return",close_panel)
func climax_menu():
	show_panel("Paths beneath the ice")
	if rpg.state.flags.get("main_story_resolved",false):text("The convoy is safe. Dreadmoth's remembered path is open, and Rimefang has returned to the ancient trail.");add_button("Return",close_panel);return
	text("Dreadmoth opens a migration corridor under the glacier. Rimefang intercepts the convoy. Hold the passage while Ada and Ellis shut down the last core.")
	add_button("Hold the passage",func():start_battle("Rimefang / story encounter",[{"species_id":93,"level":60}],"climax",false))
	add_button("Prepare first",close_panel)
func legend_challenge(l):
	var id=int(l.species_id);show_panel(rpg.species[id].name)
	if rpg.state.flags.get("caught_"+str(id),false):text("This legendary is already part of your adventure.");add_button("Return",close_panel);return
	if id<95 and not rpg.state.flags.get("main_story_resolved",false):text("The ancient corridor must be made safe before this encounter.");add_button("Return",close_panel);return
	if id>=95 and not rpg.state.flags.get("champion",false):text("Return after completing the League.");add_button("Return",close_panel);return
	if id==99 and not [95,96,97].all(func(s):return rpg.state.flags.get("trial_"+str(s),false)):text("Complete the sky, sea, and furnace trials first. Capturing their guardians is optional.");add_button("Return",close_panel);return
	text(l.lore)
	if id>=95 and not rpg.state.flags.get("trial_"+str(id),false):add_button("Guardian trial",func():start_battle(rpg.species[id].name,[{"species_id":id,"level":int(l.level)}],"trial_"+str(id),false))
	else:add_button("Approach / capture encounter",func():start_battle("",[{"species_id":id,"level":int(l.level)}],"legend_"+str(id),true))
	add_button("Return",close_panel)
func league_menu():
	show_panel("Cascara League")
	if rpg.state.badges<8 or not rpg.state.flags.get("main_story_resolved",false):text("Eight badges and a safe migration corridor are required.");add_button("Return",close_panel);return
	var names=["Orin","Sable","Rhea","Kellan","Champion June"]
	var teams=[[12,52,36,70,82],[25,3,59,45,55],[36,38,64,82,22],[20,59,9,82,50],[48,45,50,80,34,87]]
	var index=0
	while index<5 and rpg.state.flags.get("league_"+str(index+1),false):index+=1
	if index==5:text("Your team is in the Hall of Fame. The guardian expeditions, rematches, and Battle Lodge are open.");add_button("Return",close_panel);return
	var roster=[]
	for sid in teams[index]:roster.append({"species_id":sid,"level":62+index+(4 if index==4 else 0)})
	text("Next opponent: "+names[index]+". Free rest between League battles is available.")
	add_button("Challenge "+names[index],func():start_battle(names[index],roster,"league_"+str(index+1),false))
	add_button("Rest and prepare",func():rpg.heal_party();close_panel())
func gift_menu():
	show_panel("Noor's nursery / partner gifts")
	text("The other starter species are available after six badges, then after the Champion title.")
	if rpg.state.badges>=6:
		for sid in [1,4,7]:
			var id=sid
			if not rpg.state.caught.has(id):add_button("Welcome "+rpg.species[id].name,func():var mon=rpg.make_mon(id,5);(rpg.state.party if rpg.state.party.size()<6 else rpg.state.boxes).append(mon);rpg.state.caught.append(id);rpg.state.seen.append(id);rpg.save_game();gift_menu())
	add_button("Return",close_panel)
func lodge_menu():
	show_panel("Battle Lodge")
	if not rpg.state.flags.get("champion",false):text("Complete the League to enter the postgame ladder.");add_button("Return",close_panel);return
	text("Repeatable battles fund training and Ability Patches.")
	add_button("Battle a visiting trainer",func():
		var roster=[]
		for i in range(4): roster.append({"species_id":rpg.rng.randi_range(10,92),"level":70})
		start_battle("Lodge visitor",roster,"lodge",false)
	)
	add_button("Ability Patch / 2500 money",func():if rpg.state.money>=2500:rpg.state.money-=2500;rpg.state.bag.patch+=1;rpg.save_game();lodge_menu())
	add_button("Return",close_panel)

func run_tests():
	rpg.new_game(1)
	assert(rpg.species.size()==109)
	assert(maps.size()>=58)
	assert(rpg.effective("Water",["Fire","Ground"])==4.0)
	assert(rpg.effective("Normal",["Ghost"])==0.0)
	var m=rpg.make_mon(1,100);m.nature="Hardy";m.ivs=[31,31,31,31,31,31];m.evs=[0,0,0,0,0,0]
	assert(rpg.stats(m)[0]==229)
	m.nature="Adamant";assert(rpg.stats(m)[1]==200);m.nature="Hardy"
	assert(rpg.add_ev(m,1,300)==252);assert(rpg.add_ev(m,5,300)==252);assert(rpg.add_ev(m,0,300)==6);assert(rpg.add_ev(m,2,10)==0)
	var a=rpg.make_mon(1,5);var b=rpg.make_mon(4,5);a.gender="female";b.gender="male";a.held="Destiny Knot"
	assert(rpg.can_breed(a,b));assert(not rpg.egg(a,b).is_empty())
	a.ivs=[31,31,31,31,31,31];b.ivs=[31,31,31,31,31,31];b.held="Everstone";b.nature="Jolly"
	var child=rpg.egg(a,b);assert(child.ivs.filter(func(v):return v==31).size()>=5);assert(child.nature=="Jolly")
	assert(rpg.validate(rpg.state))
	assert(rpg.save_game(2));assert(rpg.load_game(2))
	for id in maps:
		for dest in maps[id].links:assert(maps.has(dest))
	var available={}
	for map in maps.values():
		for sid in map.encounters:available[int(sid)]=true
	for sid in [1,4,7,88,90,91,93,94,95,96,97,98,99]:available[sid]=true
	var changed=true
	while changed:
		changed=false
		for sid in available.keys():
			var evolution=rpg.species[int(sid)].evolution
			if evolution!=null and not available.has(int(evolution.to_id)):available[int(evolution.to_id)]=true;changed=true
	for sid in rpg.species:assert(available.has(sid),"Missing acquisition path: "+str(sid))
	rpg.state.party=[]
	for sid in [3,6,9,87,80,99]:rpg.state.party.append(rpg.make_mon(sid,100))
	for g in rpg.data.characters.gyms:
		load_map(g.id+"_interior")
		rpg.heal_party()
		start_battle(g.leader,g.team,g.id,false,g.detailed_design.leader_format)
		var limit=0
		while not battle.is_empty() and limit<200:
			var choices=[]
			for actor in battle.active:
				var mon=rpg.state.party[actor];var target=battle.enemies[battle.enemy_active[0]];var best=0;var best_score=-1.0
				for k in range(mon.moves.size()):
					var move=rpg.moves[mon.moves[k].id];var score=move.get("power",0)*rpg.effective(move.type,rpg.species[int(target.species)].types)
					if mon.moves[k].pp>0 and score>best_score:best=k;best_score=score
				choices.append({"kind":"move","actor":actor,"move":best,"target":battle.enemy_active[0]})
			battle.choices=choices;resolve_turn();limit+=1
		assert(limit<200,"Battle stalled")
		assert(int(rpg.state.badges)>=int(g.number),"Gym reward missing")
	assert(rpg.state.badges==8)
	assert(not allowed("r17"))
	rpg.state.flags.main_story_resolved=true
	assert(allowed("r17"));assert(allowed("league_summit"));assert(not allowed("r20"))
	rpg.state.flags.champion=true
	assert(allowed("r20"));assert(allowed("r24"))
	assert(rpg.validate(rpg.state))
	for sid in rpg.species:
		var model=art.make(sid,rpg.species);assert(model!=null);model.free()
	print("PASS: native project, 109 species with acquisition paths, complete world graph, elemental rules, individual stats, EV limits, breeding, save round trip, eight Gym battle rewards including doubles, story/postgame gates, and all models.")
	get_tree().quit()



func create_footstep():
	var wave=AudioStreamWAV.new();wave.format=AudioStreamWAV.FORMAT_16_BITS;wave.mix_rate=22050
	var samples=PackedByteArray();samples.resize(1323*2);var noise=RandomNumberGenerator.new();noise.seed=123
	for i in range(1323):
		var amplitude=1.0-float(i)/1323.0;samples.encode_s16(i*2,int((noise.randf_range(-1,1)*0.35+sin(i*0.08)*0.4)*amplitude*amplitude*10000))
	wave.data=samples;footstep.stream=wave
func fade_to(alpha,duration):
	if fast_mode:transition.color.a=alpha;return
	var t=create_tween();t.tween_property(transition,"color:a",alpha,duration);await t.finished
func travel_to(id):
	if busy or not allowed(id):return
	var origin=rpg.state.map;busy=true
	if not fast_mode:await get_tree().create_timer(0.18).timeout
	cinematic=true
	if panel!=null:panel.queue_free();panel=null
	await fade_to(1.0,0.32);chapter.text=maps[id].name;chapter.modulate.a=1
	var entry=Vector2(15,16)
	for gate in map_exits(id):
		if gate.dest==origin:
			entry=Vector2(gate.tile)
			if gate.get("door",false):entry.y+=1
			if entry.x==1:entry.x=2
			elif entry.x==29:entry.x=28
			if entry.y==1:entry.y=2
			elif entry.y==25:entry.y=24
			break
	if maps[id].kind=="indoor":entry=Vector2(15,19)
	load_map(id,entry);camera.position=Vector3(player.position.x,13,player.position.z+12);camera.look_at(player.position+Vector3(0,0,-1))
	if not fast_mode:await get_tree().create_timer(0.45).timeout
	await fade_to(0.0,0.5);chapter.modulate.a=0;busy=false;cinematic=false;exit_cooldown=1.2
	notice("Arrived at "+maps[id].name+". Follow the trail signs to continue.")
func build_arena():
	terrain.visible=false;actors.visible=false;cinematic=true;arena=Node3D.new();add_child(arena);models={}
	var disc=CylinderMesh.new();disc.top_radius=13;disc.bottom_radius=13;disc.height=0.22;disc.radial_segments=64;arena.add_child(mesh_node(disc,"#88a879",Vector3(0,-0.18,0)))
	var field=CylinderMesh.new();field.top_radius=6;field.bottom_radius=6;field.height=0.035;field.radial_segments=64;arena.add_child(mesh_node(field,"#d8ccaa",Vector3(0,-0.025,0)))
	var dressing=Scenery.new();dressing.root=arena
	for i in range(22):
		var angle=i*TAU/22;dressing.tree(int(cos(angle)*11),int(sin(angle)*11))
	for i in range(16):
		var angle=i*TAU/16;dressing.sphere("#9ba58d",Vector3(cos(angle)*7.2,0.25,sin(angle)*7.2),Vector3(0.7,0.5,0.65))
	camera.position=Vector3(7,4.5,10);camera.look_at(Vector3(0,0.7,0));show_battle_models()
func battle_intro():
	busy=true
	if battle.catchable:
		chapter.text="The grass is moving...";chapter.modulate.a=1
		var rustle=create_tween();rustle.tween_property(camera,"fov",38.0,0.25);rustle.tween_interval(0.2);await rustle.finished;camera.fov=43;chapter.modulate.a=0
	if panel!=null:panel.queue_free();panel=null
	await fade_to(1.0,0.22);build_arena()
	for key in models:models[key].scale=Vector3.ONE*0.001
	await fade_to(0.0,0.28);chapter.text=battle.name+" challenges you!" if battle.name!="" else "Something stirs in the grass...";chapter.modulate.a=1
	for key in models:
		if key.begins_with("e"):
			var appear=create_tween();appear.tween_property(models[key],"scale",models[key].get_meta("rest_scale"),0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);await appear.finished
	await get_tree().create_timer(0.65).timeout;chapter.text="Go, "+rpg.species[int(rpg.state.party[battle.active[0]].species)].name+"!"
	for key in models:
		if not key.begins_with("p"):continue
		var model=models[key];var release=SphereMesh.new();release.radius=0.15;release.height=0.3;var ball=mesh_node(release,"#f3d9a0",Vector3(-7,1,5));arena.add_child(ball)
		var toss=create_tween();toss.tween_property(ball,"position",model.position+Vector3(0,1.5,0),0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);await toss.finished;ball.queue_free()
		var deploy=create_tween();deploy.tween_property(model,"scale",model.get_meta("rest_scale"),0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);await deploy.finished
	var shot=create_tween();shot.tween_property(camera,"position",Vector3(6,4.2,8.5),0.5).set_trans(Tween.TRANS_SINE);await shot.finished
	camera.look_at(Vector3(0,0.7,0));chapter.modulate.a=0;busy=false;battle_menu()
func health_card(mon,title,pos):
	var card=PanelContainer.new();card.position=pos;card.size=Vector2(330,90);battle_cards.add_child(card)
	var st=StyleBoxFlat.new();st.bg_color=Color(0.08,0.19,0.18,0.94);st.set_corner_radius_all(10);st.content_margin_left=16;st.content_margin_right=16;st.content_margin_top=10;st.content_margin_bottom=10;card.add_theme_stylebox_override("panel",st)
	var col=VBoxContainer.new();card.add_child(col);var name=Label.new();name.text=title+"  "+mon_name(mon)+"  Lv "+str(mon.level);col.add_child(name)
	var hp=ProgressBar.new();hp.custom_minimum_size=Vector2(290,16);hp.max_value=rpg.stats(mon)[0];hp.value=mon.hp;hp.show_percentage=false
	var fill=StyleBoxFlat.new();fill.bg_color=Color("#83c481" if float(mon.hp)/hp.max_value>0.3 else "#e7b55c");fill.set_corner_radius_all(5);hp.add_theme_stylebox_override("fill",fill);col.add_child(hp);health_bars[str(mon.uid)]=hp
	var detail=Label.new();detail.text=str(mon.hp)+" / "+str(rpg.stats(mon)[0])+" HP  "+mon.status;detail.add_theme_font_size_override("font_size",14);col.add_child(detail)
func animate_action(c,m,target):
	var key=("e" if c.get("enemy",false) else "p")+str(c.actor);var target_key=("p" if c.get("enemy",false) else "e")+str(c.target)
	if not models.has(key):return
	var model=models[key];model.set_meta("acting",true);var start=model.position;var goal=models[target_key].position if models.has(target_key) else start+Vector3(1,0,0)
	await narrate(mon_name(m),[mon_name(m)+" used "+rpg.moves[m.moves[c.move].id].name+"!"])
	move_effect(rpg.moves[m.moves[c.move].id].type,start,goal)
	var t=create_tween();t.tween_property(model,"position",start+(goal-start).normalized()*1.1+Vector3(0,0.2,0),0.16).set_trans(Tween.TRANS_QUAD);t.tween_property(model,"position",start,0.22);await t.finished;model.set_meta("acting",false)
func animate_hit(c,target,before):
	if health_bars.has(str(target.uid)):
		var hp_tween=create_tween();hp_tween.tween_property(health_bars[str(target.uid)],"value",target.hp,0.3)
	var key=("p" if c.get("enemy",false) else "e")+str(c.target)
	if not models.has(key):return
	var model=models[key]
	if target.hp<before:
		model.set_meta("acting",true);var start=model.position;var t=create_tween();t.tween_property(model,"position:x",start.x+0.18,0.055);t.tween_property(model,"position:x",start.x-0.16,0.055);t.tween_property(model,"position:x",start.x,0.055);await t.finished
		if target.hp<=0:
			chapter.text=rpg.species[int(target.species)].name+" fainted.";var faint=create_tween();faint.tween_property(model,"scale",Vector3.ONE*0.001,0.4);await faint.finished
		model.set_meta("acting",false)
	await get_tree().create_timer(0.2).timeout;chapter.modulate.a=0
func capture_animation():
	busy=true
	if panel!=null:panel.queue_free();panel=null
	var enemy=models.get("e"+str(battle.enemy_active[0]))
	if enemy==null:busy=false;return
	var sphere=SphereMesh.new();sphere.radius=0.24;sphere.height=0.48;var ball=mesh_node(sphere,"#eacb87",Vector3(-5,1.8,3));arena.add_child(ball);chapter.text="The Capture Ball opens...";chapter.modulate.a=1
	var t=create_tween();t.tween_property(ball,"position",enemy.position+Vector3(0,1,0),0.4);t.tween_property(enemy,"scale",Vector3.ONE*0.001,0.22);t.tween_property(ball,"position:y",0.24,0.25);await t.finished
	for i in range(3):
		var shake=create_tween();shake.tween_property(ball,"rotation:z",0.35,0.12);shake.tween_property(ball,"rotation:z",-0.35,0.12);shake.tween_property(ball,"rotation:z",0.0,0.12);await shake.finished;await get_tree().create_timer(0.18).timeout
	ball.queue_free();enemy.scale=enemy.get_meta("rest_scale");chapter.modulate.a=0;busy=false
func capture_frame(filename):
	await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png("user://"+filename+".png")
func map_exits(id):
	if maps[id].kind=="indoor":return [{"dest":maps[id].town,"tile":Vector2i(15,21),"door":true}]
	var result=[];var used=[];var alternatives=[Vector2i(15,1),Vector2i(15,25),Vector2i(1,10),Vector2i(29,10),Vector2i(10,1),Vector2i(20,1),Vector2i(1,20),Vector2i(29,20)]
	for i in range(maps[id].links.size()):
		var dest=maps[id].links[i];var tile=Vector2i(15,1)
		if maps[dest].kind=="indoor":result.append({"dest":dest,"tile":Cities.DOORS[maps[dest].service],"door":true});continue
		if maps[id].kind=="town" and maps[dest].kind=="gym":result.append({"dest":dest,"tile":Vector2i(23,14),"door":true});continue
		if maps[id].kind=="route":tile=Vector2i(1,15) if i==0 else Vector2i(29,15) if i==1 else Vector2i(15,1)
		elif maps[id].kind in ["gym","dungeon"]:tile=Vector2i(15,25)
		elif maps[dest].kind=="route":tile=Vector2i(29,15) if maps[dest].links[0]==id else Vector2i(1,15)
		if used.has(tile):
			for alternate in alternatives:
				if not used.has(alternate):tile=alternate;break
		used.append(tile);result.append({"dest":dest,"tile":tile})
	return result

func trainer_sees(n):
	if n.role!="trainer" or n.trainer.get("trigger","")!="line_of_sight":return false
	if rpg.state.flags.get("defeated_"+n.trainer.id,false):return false
	var delta=Vector2i(roundi(rpg.state.x)-int(n.x),roundi(rpg.state.z)-int(n.z))
	var facing=n.get("facing",Vector2i(0,-1))
	var distance=absi(delta.x)+absi(delta.y)
	if distance<1 or distance>int(n.trainer.get("sight_tiles",3)) or delta!=facing*distance:return false
	for i in range(1,distance):
		var tile=Vector2i(n.x,n.z)+facing*i
		if blocked.has(tile) or nodes.any(func(other):return other!=n and Vector2i(other.x,other.z)==tile):return false
	return true
func scan_trainers():
	if fast_mode:return false
	for n in nodes:
		if not trainer_sees(n):continue
		if approached.has(n.trainer.id):continue
		approached[n.trainer.id]=true;trainer_approach(n);return true
	return false
func trainer_approach(n):
	busy=true
	var alert=Label3D.new();alert.text="!";alert.font_size=80;alert.modulate=Color("#ffd685");alert.position=Vector3(0,2.5,0);alert.billboard=BaseMaterial3D.BILLBOARD_ENABLED;n.visual.add_child(alert)
	await get_tree().create_timer(0.65).timeout
	alert.queue_free()
	while absi(int(n.x)-roundi(rpg.state.x))+absi(int(n.z)-roundi(rpg.state.z))>1:
		var next=Vector2i(n.x,n.z)+n.get("facing",Vector2i(0,-1))
		if blocked.has(next) or nodes.any(func(other):return other!=n and Vector2i(other.x,other.z)==next):break
		n.x=next.x;n.z=next.y
		var walk=create_tween().set_parallel(true);walk.tween_property(n.visual,"position",Vector3(n.x,0,n.z),0.24);walk.tween_property(n.label,"position",Vector3(n.x,2.3,n.z),0.24);await walk.finished
	busy=false;trainer_challenge(n.trainer)

func move_effect(kind,start,goal):
	var colors={"Grass":"#9fd36e","Fire":"#efac64","Water":"#84d3dc","Electric":"#f7df85","Ice":"#c0e8e5","Poison":"#be8acb","Psychic":"#e2a1cd","Ghost":"#b4a5db","Fighting":"#e6b18a"}
	for i in range(9):
		var mesh=SphereMesh.new();mesh.radius=0.09;mesh.height=0.18;mesh.radial_segments=8;mesh.rings=4
		var particle=mesh_node(mesh,colors.get(kind,"#f1e8c8"),start+Vector3(0,0.8,0));arena.add_child(particle)
		if kind=="Grass":particle.scale=Vector3(0.55,1.8,0.35)
		elif kind=="Electric":particle.scale=Vector3(0.4,2.7,0.4)
		var offset=Vector3(sin(i*2.4),cos(i*1.8)*0.5,sin(i*1.3))*0.6
		var fx=create_tween();fx.tween_interval(i*0.018);fx.tween_property(particle,"position",goal+Vector3(0,0.8,0)+offset,0.25);fx.tween_property(particle,"scale",Vector3.ONE*0.001,0.18);fx.tween_callback(particle.queue_free)
func build_city_maps():
	var index=0
	var items=["weather notebook","ranger's compass","hatchery parcel","tram pass","brass bell","shell case","old photograph","workshop key","greenhouse ledger","climbing strap","wool scarf","station watch"]
	var people=["Mara","Ellis","June","Theo","Nell","Sora","Ada","Bram","Lena","Ivo","Wren","Otis"]
	for town in rpg.data.world.towns:
		for kind in Cities.DOORS:
			if kind=="hall" and rpg.data.characters.gyms.any(func(g):return g.town==town.id):continue
			var id=town.id+"__"+kind
			maps[id]={"id":id,"name":town.name+" / "+Cities.LABELS[kind].capitalize(),"kind":"indoor","service":kind,"town":town.id,"level":5,"links":[town.id],"encounters":[]}
			maps[town.id].links.append(id)
		var route="r01"
		for road in rpg.data.world.routes:
			if road.start==town.id:route=road.id;break
		var job={"id":"town_errand_"+town.id,"town":town.id,"person":people[index],"item":items[index],"route":route,"name":people[index]+"'s missing "+items[index],"reward_species":{0:1002,2:1005,6:1009}.get(index,0),"reward_item":"great" if index%2 else "potion","reward_count":3,"x":10+index%2,"z":15}
		side_jobs.append(job);index+=1
	for g in rpg.data.characters.gyms:maps[g.town].city_gym=g.id+"_interior"
func populate_interior(map):
	match map.service:
		"centre":
			marker({"name":"Nurse","x":15,"z":10,"role":"heal"})
			marker({"name":"Storage PC","x":20,"z":11,"role":"storage"})
			marker({"name":"Resting trainer","x":10,"z":15,"role":"resident","lines":["The nurse heals your whole team for free, including their move PP.","That computer on the right stores your Pokémon. You can withdraw or deposit them there."]})
		"mart":
			marker({"name":"Shopkeeper","x":15,"z":10,"role":"shop"})
			marker({"name":"Local shopper","x":18,"z":15,"role":"resident","lines":["I always buy a few spare balls before leaving town. You never know what you might find in the grass."]})
		"home":
			for job in side_jobs:
				if job.town==map.town:marker({"name":job.person,"x":12,"z":11,"role":"side_quest","job":job})
			marker({"name":"Family member","x":18,"z":16,"role":"resident","lines":["A town is more than its Gym. Stop by the houses and talk to people. Some of us could use a hand."]})
		"house":
			if map.town=="alderwick":
				marker({"name":"Noor / Daycare","x":12,"z":11,"role":"daycare"});marker({"name":"Elin / Training","x":18,"z":16,"role":"training"})
			else:marker({"name":"Neighbour","x":12,"z":11,"role":"resident","lines":["Welcome to "+maps[map.town].name+"! The red roof marks the Pokémon Centre. The blue one is the Mart.","Some Pokémon have unusual colours. Their sparkle makes them easy to recognise, but it does not change their stats."]})
		"hall":
			marker({"name":"Town coordinator","x":12,"z":11,"role":"resident","lines":["This hall is open to everyone. The noticeboard outside lists errands you have accepted.","Visit the homes around the square if you are looking for someone to help."]})
		"station":
			var found=false
			for npc in rpg.data.characters.npcs:
				if npc.home==map.town:marker({"name":npc.name,"x":12,"z":11,"role":"lore","npc":npc});found=true;break
			if not found:marker({"name":"Field researcher","x":12,"z":11,"role":"resident","lines":["Our field stations keep notes on the local wildlife. Your Field Guide records the Pokémon you meet."]})
			marker({"name":"Quest journal","x":20,"z":16,"role":"journal"})
func talk(speaker,lines,choices=[]):
	if dialogue!=null:dialogue.queue_free()
	if panel!=null:panel.queue_free();panel=null
	dialogue=Conversation.new().setup(speaker,lines,choices);ui.add_child(dialogue);navigation.visible=false
	dialogue.finished.connect(func():dialogue=null;navigation.visible=battle.is_empty())
	return dialogue
func narrate(speaker,lines):
	if fast_mode:return
	var box=talk(speaker,lines)
	if "--city-test" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.12).timeout;box.finish();return
	await box.finished
func heal_conversation():
	talk("Nurse",["Welcome to the Pokémon Centre. Would you like me to care for your team?"],[["Heal my team",func():heal_at_centre()],["No, thank you",func():pass]])
func heal_at_centre():
	busy=true
	await narrate("Nurse",["Let me take your Pokémon for a moment."])
	await fade_to(0.35,0.25);rpg.heal_party();rpg.save_game();await fade_to(0,0.25);busy=false
	talk("Nurse",["Your Pokémon are fully rested. Their HP, status, and move PP are restored. We hope to see you again!"])
func side_stage(job):return int(rpg.state.quests.get(job.id,0))
func reward_text(job):
	if job.reward_species>0:return "a level 8 "+rpg.species[int(job.reward_species)].name
	return str(job.reward_count)+" "+("Great Balls" if job.reward_item=="great" else "Potions")
func side_conversation(job):
	match side_stage(job):
		0:
			talk(job.person,["I lost my "+job.item+" on "+maps[job.route].name+". Would you look for it?","Look for a small parcel beside the trail. Bring it back here and I will give you "+reward_text(job)+"."],[["I'll look for it",func():rpg.state.quests[job.id]=1;rpg.save_game();notice("Quest started: "+job.name)],["Not right now",func():pass]])
		1:talk(job.person,["My "+job.item+" is still somewhere on "+maps[job.route].name+". Your journal has the details."])
		2:
			if claim_side_reward(job):talk(job.person,["You found it! Thank you for bringing my "+job.item+" home.","You received "+reward_text(job)+"."])
			else:talk(job.person,["Please make some space in your party or storage first. Your reward will be waiting here."])
		_:talk(job.person,["Thanks again. That "+job.item+" means a lot to me. Take care on the trail!"])
func spawn_side_items(id):
	for job in side_jobs:
		if job.route==id and side_stage(job)<2:
			for x in range(job.x-1,job.x+2):
				for z in range(job.z-1,job.z+2):blocked.erase(Vector2i(x,z))
			marker({"name":"Lost parcel","x":job.x,"z":job.z,"role":"lost_item","job":job})
func collect_side_item(job):
	if side_stage(job)==0:talk("Lost parcel",["A name is written on the tag: "+job.person+" from "+maps[job.town].name+". You should ask them about it first."]);return
	if side_stage(job)!=1:return
	rpg.state.quests[job.id]=2;rpg.save_game()
	for i in range(nodes.size()-1,-1,-1):
		var n=nodes[i]
		if n.role=="lost_item" and n.job.id==job.id:n.visual.queue_free();n.label.queue_free();nodes.remove_at(i)
	talk("Found it!",["You found the "+job.item+". Return it to "+job.person+" at home in "+maps[job.town].name+"."])
func claim_side_reward(job):
	if side_stage(job)!=2:return false
	if job.reward_species>0:
		if rpg.state.party.size()>=6 and rpg.state.boxes.size()>=300:return false
		var m=rpg.make_mon(job.reward_species,8)
		(rpg.state.party if rpg.state.party.size()<6 else rpg.state.boxes).append(m)
		if not rpg.state.caught.has(m.species):rpg.state.caught.append(m.species)
		if not rpg.state.seen.has(m.species):rpg.state.seen.append(m.species)
	else:rpg.state.bag[job.reward_item]+=job.reward_count
	rpg.state.quests[job.id]=3;rpg.save_game();return true
func quest_journal():
	show_panel("Town errands")
	for job in side_jobs:
		var stage=side_stage(job)
		if stage==0:continue
		text(job.name+" / "+["","Search "+maps[job.route].name,"Return to "+job.person+" in "+maps[job.town].name,"Complete"][stage])
		text("Reward: "+reward_text(job))
	text("Visit the resident's home in each town to find more errands.");add_button("Return",close_panel)
func mon_name(mon):return ("★ " if mon.get("shiny",false) else "")+rpg.species[int(mon.species)].name

func ensure_safe_spawn():
	var pos=Vector2(rpg.state.x,rpg.state.z)
	if can_stand(pos):return
	for radius in range(1,32):
		for dx in range(-radius,radius+1):
			for dz in [-radius,radius]:
				var candidate=pos+Vector2(dx,dz)
				if can_stand(candidate):
					player.position=Vector3(candidate.x,0,candidate.y);rpg.state.x=candidate.x;rpg.state.z=candidate.y;fixed_camera();return
func creature_portrait(mon):
	var viewport=SubViewport.new();viewport.size=Vector2i(320,220);viewport.transparent_bg=true;viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var picture=TextureRect.new();picture.custom_minimum_size=Vector2(320,220);picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.add_child(viewport);body.add_child(picture);picture.texture=viewport.get_texture()
	var model=art.make(mon.species,rpg.species,mon.get("shiny",false));viewport.add_child(model)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=0.7;viewport.add_child(light)
	var view=Camera3D.new();view.position=Vector3(2.5,1.8,3.2);viewport.add_child(view);view.look_at(Vector3(0,0.8,0));view.projection=Camera3D.PROJECTION_ORTHOGONAL;view.size=2.8
	text("★ Shiny colour variant" if mon.get("shiny",false) else "Standard colour variant")

func dismiss_talk():
	if dialogue!=null:dialogue.finish()
func city_test():
	close_panel();title_screen=false;rpg.new_game(1);fast_mode=true
	# Reachability includes every service door and every interior interaction.
	for town in rpg.data.world.towns:
		load_map(town.id);assert(not nodes.any(func(n):return n.role in ["storage","shop","heal"]))
		check_access(town.id)
		for kind in Cities.DOORS:
			if not maps.has(town.id+"__"+kind):continue
			load_map(town.id+"__"+kind,Vector2(15,19));check_access(rpg.state.map)
			if kind=="centre":assert(nodes.any(func(n):return n.role=="storage"));assert(nodes.any(func(n):return n.role=="heal"))
	print("PASS: 12 towns, 64 interiors, service doors and interaction reachability.")
	load_map("brackenbay",Vector2(15,16));var before=player.position;var camera_rotation=camera.rotation
	move_world(Vector2(1,1),0.05);assert(player.position.x>before.x and player.position.z>before.z)
	assert(absf(player.position.x-roundf(player.position.x))>0.01);assert(camera.rotation.distance_to(camera_rotation)<0.001)
	var screen=camera.unproject_position(player.position+Vector3(0,0.75,0));assert(screen.distance_to(Vector2(640,400))<2)
	var saved=Vector2(rpg.state.x,rpg.state.z);rpg.save_game(2);assert(rpg.load_game(2));assert(Vector2(rpg.state.x,rpg.state.z).distance_to(saved)<0.001)
	load_map("brackenbay",Vector2(7,9));exit_cooldown=0;move_world(Vector2.UP,0.1)
	while busy:await get_tree().process_frame
	assert(rpg.state.map=="brackenbay__centre");assert(can_stand(Vector2(rpg.state.x,rpg.state.z)))
	rpg.state.party[0].hp=1;rpg.heal_party();assert(rpg.state.party[0].hp==rpg.stats(rpg.state.party[0])[0])
	await get_tree().create_timer(0.2).timeout;await capture_frame("centre06")
	travel_to("brackenbay")
	while busy:await get_tree().process_frame
	assert(rpg.state.map=="brackenbay" and absf(rpg.state.x-7)<0.01 and absf(rpg.state.z-9)<0.01)
	assert(not can_stand(Vector2(7,5)))
	load_map("brackenbay",Vector2(15,16));await get_tree().create_timer(0.2).timeout;await capture_frame("city06")
	load_map("brackenbay__mart",Vector2(15,16));await get_tree().create_timer(0.2).timeout;await capture_frame("mart06")
	var job=side_jobs[0];rpg.state.quests[job.id]=1;load_map(job.route);collect_side_item(job);assert(side_stage(job)==2);dismiss_talk()
	assert(rpg.save_game(2) and rpg.load_game(2));assert(side_stage(job)==2)
	var amount=rpg.state.party.size();assert(claim_side_reward(job));assert(rpg.state.party.size()==amount+1 and side_stage(job)==3);assert(not claim_side_reward(job))
	var item_job=side_jobs[1];rpg.state.quests[item_job.id]=2;var items=rpg.state.bag[item_job.reward_item];assert(claim_side_reward(item_job));assert(rpg.state.bag[item_job.reward_item]==items+3);assert(not claim_side_reward(item_job))
	load_map("brackenbay__home",Vector2(12,12));side_conversation(job);await get_tree().create_timer(1.4).timeout;await capture_frame("dialogue06");dismiss_talk()
	print("PASS: free diagonal movement, fixed centred camera, exact-position saves, door round trip, item and creature quests, repeat-reward prevention.")
	for sid in rpg.species:
		var model=art.make(sid,rpg.species,true);assert(model.get_meta("shiny",false));model.free()
	rpg.state.party[0].shiny=true;rpg.save_game(2);assert(rpg.load_game(2) and rpg.state.party[0].shiny)
	fast_mode=false;load_map("r01",Vector2(20,19));start_battle("",[{"species_id":10,"level":4,"shiny":true}],"wild",true)
	while busy:await get_tree().process_frame
	assert(models["p0"].get_meta("shiny",false) and models["e0"].get_meta("shiny",false));await capture_frame("shiny06")
	battle.choices=[{"kind":"move","actor":0,"move":0,"target":0}];resolve_turn()
	while busy:await get_tree().process_frame
	if not battle.is_empty():end_battle(false,true)
	while busy:await get_tree().process_frame
	dismiss_talk();close_panel();summary_menu(0);await get_tree().create_timer(0.3).timeout;await capture_frame("portrait06")
	print("PASS: 109 shiny model variants, shiny save persistence, shiny battle models, battle dialogue and portrait rendering.");get_tree().quit()
func check_access(id):
	var start=Vector2i(roundi(rpg.state.x),roundi(rpg.state.z));var visited={start:true};var pending=[start]
	while not pending.is_empty():
		var tile=pending.pop_front()
		for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next=tile+dir
			if visited.has(next) or not can_stand(Vector2(next)):continue
			visited[next]=true;pending.append(next)
	for gate in exits:assert(visited.has(gate.tile),"Unreachable door: "+id+" to "+gate.dest)
	for n in nodes:
		var pos=Vector2i(n.x,n.z)
		assert([Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN].any(func(d):return visited.has(pos+d)),"Unreachable NPC: "+id+" / "+n.name)
