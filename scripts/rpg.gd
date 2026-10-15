extends RefCounted

var data = {}
var species = {}
var moves = {}
var state = {}
var active_slot = 0
var rng = RandomNumberGenerator.new()
const KEYS = ["hp", "attack", "defense", "special_attack", "special_defense", "speed"]
const COLORS = {"Grass":"#7eab68","Fire":"#ce7654","Water":"#6ca8bd","Electric":"#dec365","Ice":"#a7d6df","Fighting":"#b88372","Poison":"#a279b0","Ground":"#bba17c","Flying":"#9fb7c9","Psychic":"#d593b2","Bug":"#9ca966","Rock":"#a39376","Ghost":"#857caa","Dragon":"#718fae","Dark":"#645d70","Steel":"#94a6a8","Fairy":"#d7b0cd","Normal":"#b7ac96"}
const CHART = {"Normal":{"Rock":0.5,"Ghost":0.0,"Steel":0.5},"Fire":{"Fire":0.5,"Water":0.5,"Grass":2.0,"Ice":2.0,"Bug":2.0,"Rock":0.5,"Dragon":0.5,"Steel":2.0},"Water":{"Fire":2.0,"Water":0.5,"Grass":0.5,"Ground":2.0,"Rock":2.0,"Dragon":0.5},"Grass":{"Fire":0.5,"Water":2.0,"Grass":0.5,"Poison":0.5,"Ground":2.0,"Flying":0.5,"Bug":0.5,"Rock":2.0,"Dragon":0.5,"Steel":0.5},"Electric":{"Water":2.0,"Electric":0.5,"Grass":0.5,"Ground":0.0,"Flying":2.0,"Dragon":0.5},"Ice":{"Fire":0.5,"Water":0.5,"Grass":2.0,"Ice":0.5,"Ground":2.0,"Flying":2.0,"Dragon":2.0,"Steel":0.5},"Fighting":{"Normal":2.0,"Ice":2.0,"Poison":0.5,"Flying":0.5,"Psychic":0.5,"Bug":0.5,"Rock":2.0,"Ghost":0.0,"Dark":2.0,"Steel":2.0,"Fairy":0.5},"Poison":{"Grass":2.0,"Poison":0.5,"Ground":0.5,"Rock":0.5,"Ghost":0.5,"Steel":0.0,"Fairy":2.0},"Ground":{"Fire":2.0,"Electric":2.0,"Grass":0.5,"Poison":2.0,"Flying":0.0,"Bug":0.5,"Rock":2.0,"Steel":2.0},"Flying":{"Electric":0.5,"Grass":2.0,"Fighting":2.0,"Bug":2.0,"Rock":0.5,"Steel":0.5},"Psychic":{"Fighting":2.0,"Poison":2.0,"Psychic":0.5,"Dark":0.0,"Steel":0.5},"Bug":{"Fire":0.5,"Grass":2.0,"Fighting":0.5,"Poison":0.5,"Flying":0.5,"Psychic":2.0,"Ghost":0.5,"Dark":2.0,"Steel":0.5,"Fairy":0.5},"Rock":{"Fire":2.0,"Ice":2.0,"Fighting":0.5,"Ground":0.5,"Flying":2.0,"Bug":2.0,"Steel":0.5},"Ghost":{"Normal":0.0,"Psychic":2.0,"Ghost":2.0,"Dark":0.5},"Dragon":{"Dragon":2.0,"Steel":0.5,"Fairy":0.0},"Dark":{"Fighting":0.5,"Psychic":2.0,"Ghost":2.0,"Dark":0.5,"Fairy":0.5},"Steel":{"Fire":0.5,"Water":0.5,"Electric":0.5,"Ice":2.0,"Rock":2.0,"Steel":0.5,"Fairy":2.0},"Fairy":{"Fire":0.5,"Fighting":2.0,"Poison":0.5,"Dragon":2.0,"Dark":2.0,"Steel":0.5}}
const NATURES = {"Hardy":[],"Lonely":[1,2],"Brave":[1,5],"Adamant":[1,3],"Naughty":[1,4],"Bold":[2,1],"Docile":[],"Relaxed":[2,5],"Impish":[2,3],"Lax":[2,4],"Timid":[5,1],"Hasty":[5,2],"Serious":[],"Jolly":[5,3],"Naive":[5,4],"Modest":[3,1],"Mild":[3,2],"Quiet":[3,5],"Bashful":[],"Rash":[3,4],"Calm":[4,1],"Gentle":[4,2],"Sassy":[4,5],"Careful":[4,3],"Quirky":[]}

func setup():
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/cascara.json"))
	for s in data.species: species[int(s.id)] = s
	rng.randomize()
	for t in COLORS:
		moves[t.to_lower()+"_strike"] = {"name":t+" Strike","type":t,"power":50,"category":"physical","pp":25,"accuracy":100,"priority":0}
		moves[t.to_lower()+"_pulse"] = {"name":t+" Pulse","type":t,"power":80,"category":"special","pp":15,"accuracy":100,"priority":0}
	moves.merge({"tackle":{"name":"Tackle","type":"Normal","power":40,"category":"physical","pp":35,"accuracy":100},"quick":{"name":"Quick Attack","type":"Normal","power":40,"category":"physical","pp":25,"accuracy":100,"priority":1},"guard":{"name":"Guard Stance","type":"Normal","power":0,"effect":"guard","pp":20,"accuracy":100},"growl":{"name":"Growl","type":"Normal","power":0,"effect":"growl","pp":30,"accuracy":100},"recover":{"name":"Recover","type":"Normal","power":0,"effect":"recover","pp":5,"accuracy":100},"bite":{"name":"Bite","type":"Dark","power":60,"category":"physical","pp":25,"accuracy":100},"poison":{"name":"Poison Powder","type":"Poison","power":0,"effect":"poison","pp":20,"accuracy":90},"sleep":{"name":"Sleep Powder","type":"Grass","power":0,"effect":"sleep","pp":15,"accuracy":75},"burn":{"name":"Will-O-Wisp","type":"Fire","power":0,"effect":"burn","pp":15,"accuracy":85},"paralyze":{"name":"Thunder Wave","type":"Electric","power":0,"effect":"paralyze","pp":20,"accuracy":90},"protect":{"name":"Protect","type":"Normal","power":0,"effect":"protect","pp":10,"accuracy":100,"priority":4},"rain":{"name":"Rain Dance","type":"Water","power":0,"effect":"rain","pp":5,"accuracy":100},"sun":{"name":"Sunny Day","type":"Fire","power":0,"effect":"sun","pp":5,"accuracy":100},"snow":{"name":"Snowscape","type":"Ice","power":0,"effect":"snow","pp":5,"accuracy":100},"sand":{"name":"Sandstorm","type":"Rock","power":0,"effect":"sand","pp":5,"accuracy":100},"swords":{"name":"Swords Dance","type":"Normal","power":0,"effect":"swords","pp":20,"accuracy":100},"haze":{"name":"Haze","type":"Ice","power":0,"effect":"haze","pp":10,"accuracy":100},"struggle":{"name":"Struggle","type":"Normal","power":50,"category":"physical","pp":1,"accuracy":100}})
	for t in ["Fire","Water","Grass","Electric","Ice","Rock"]:
		moves[t.to_lower()+"_pulse"].status = {"Fire":"burn","Water":"","Grass":"","Electric":"paralyze","Ice":"freeze","Rock":""}[t]
	for a in data.abilities.abilities:
		if a.id in ["pressure","intimidate"]: continue
	for s in species.values():
		s.egg_group = egg_group(s)
		s.baby = int(s.family_id)

func egg_group(s):
	if s.legendary: return "Undiscovered"
	var concept = s.concept.to_lower()
	if s.types.has("Bug"): return "Bug"
	if s.types.has("Flying") or concept.contains("raven") or concept.contains("bird"): return "Flying"
	if concept.contains("geode") or concept.contains("cart") or concept.contains("chime"): return "Mineral"
	if s.types.has("Dragon"): return "Dragon"
	if s.types.has("Ghost") or concept.contains("slug") or concept.contains("mushroom"): return "Amorphous"
	if s.types.has("Water"): return "Water 1"
	return "Field"

func new_game(id):
	state = {"version":1,"map":"brackenbay","x":15,"z":15,"party":[make_mon(id,5)],"boxes":[],"eggs":[],"daycare":{"parents":[],"steps":0,"egg":{}},"bag":{"ball":15,"great":0,"ultra":0,"master":0,"potion":8,"revive":2,"candy":3,"patch":0,"capsule":0},"money":1500,"badges":0,"flags":{},"quests":{},"puzzles":{},"caught":[int(id)],"seen":[int(id)],"steps":0,"hall":[],"options":{"music":true,"volume":0.3}}
	return state

func make_mon(id,level):
	var s = species[int(id)]
	var iv = []; var ev = []
	for k in range(6): iv.append(rng.randi_range(0,31)); ev.append(0)
	var n = NATURES.keys()[rng.randi_range(0,24)]
	var gender = "female" if rng.randf() < (0.125 if int(id)<10 else 0.5) else "male"
	if s.legendary: gender = "unknown"
	var m = {"uid":str(Time.get_unix_time_from_system())+"-"+str(rng.randi()),"species":int(id),"level":int(level),"xp":0,"ivs":iv,"evs":ev,"nature":n,"gender":gender,"slot":"slot_1","status":"","hp":1,"friendship":70,"held":"","shiny":rng.randi_range(1,4096)==1,"stages":{"attack":0,"defense":0,"special_attack":0,"special_defense":0,"speed":0,"accuracy":0},"moves":[],"spent":{}}
	for mid in learnset(s,int(level)): m.moves.append({"id":mid,"pp":int(moves[mid].pp)})
	m.hp = stats(m)[0]
	return m

func learnset(s,level):
	var first = s.types[0].to_lower()+"_strike"
	var second = s.types[-1].to_lower()+"_pulse" if level>=20 else "quick"
	if level<12: return ["tackle",first,"growl","guard"]
	var support = "guard"
	if s.types.has("Poison"): support = "poison"
	elif s.types.has("Ghost"): support = "burn"
	elif s.types.has("Electric"): support = "paralyze"
	elif s.types.has("Grass"): support = "sleep"
	elif s.types.has("Ice"): support = "snow"
	return [first,second,support,"protect" if level>=30 else "guard"]

func ability(m): return species[int(m.species)].abilities.get(m.slot,"pressure")
func stats(m):
	var s = species[int(m.species)]; var result = []; var nature = NATURES.get(m.nature,[])
	for k in range(6):
		var q = int((2*float(s.base_stat_target[KEYS[k]])+m.ivs[k]+int(m.evs[k]/4))*m.level/100.0)
		var value = q+m.level+10 if k==0 else q+5
		if nature.size()==2 and k>0: value = int(value*(1.1 if nature[0]==k else 0.9 if nature[1]==k else 1.0))
		result.append(value)
	return result

func heal(m):
	m.hp = stats(m)[0]; m.status = ""; m.spent = {}
	for k in m.stages: m.stages[k]=0
	for v in m.moves: v.pp=int(moves[v.id].pp)

func heal_party():
	for m in state.party: heal(m)

func add_ev(m,k,amount):
	var total = 0
	for v in m.evs: total+=int(v)
	var change = maxi(0,mini(amount,mini(252-m.evs[k],510-total))) if amount>0 else maxi(amount,-m.evs[k])
	var old_hp = stats(m)[0]; m.evs[k]+=change
	if m.hp>0: m.hp = clampi(m.hp+stats(m)[0]-old_hp,1,stats(m)[0])
	return change

func gain(m,amount):
	var log = []; m.xp+=amount
	while m.level<100 and m.xp>=m.level*12:
		m.xp-=m.level*12; var hp = stats(m)[0]; m.level+=1
		m.hp = mini(stats(m)[0],m.hp+stats(m)[0]-hp)
		log.append(species[int(m.species)].name+" reached level "+str(m.level)+".")
		var s = species[int(m.species)]
		if s.evolution!=null and m.level>=int(s.evolution.level):
			var before = stats(m)[0]; m.species=int(s.evolution.to_id); m.hp+=stats(m)[0]-before
			log.append(s.name+" evolved into "+species[int(m.species)].name+"!")
			if not state.caught.has(m.species): state.caught.append(m.species)
			if not state.seen.has(m.species): state.seen.append(m.species)
		if m.level in [12,20,30,36]:
			m.moves.clear()
			for id in learnset(species[int(m.species)],m.level): m.moves.append({"id":id,"pp":int(moves[id].pp)})
	return log

func effective(t,types):
	var n = 1.0
	for d in types: n*=float(CHART.get(t,{}).get(d,1))
	return n
func stage(n): return (2.0+n)/2.0 if n>=0 else 2.0/(2.0-n)
func entry(m,opponents,weather):
	var log = []; m.spent.erase("protection"); m.spent.erase("ink"); m.spent.erase("furnace")
	for k in m.stages: m.stages[k]=0
	var ab = ability(m)
	if ab=="intimidate":
		for e in opponents:
			if ability(e) in ["hyper_cutter","inner_focus","own_tempo","oblivious","clear_body"]: continue
			if ability(e)=="defiant": e.stages.attack=mini(6,e.stages.attack+1)
			elif ability(e)=="competitive": e.stages.special_attack=mini(6,e.stages.special_attack+2)
			else: e.stages.attack=maxi(-6,e.stages.attack-1)
		log.append(species[int(m.species)].name+" used Intimidate.")
	if ab=="cold_instinct" and weather=="snow": m.stages.attack+=1
	if ab=="barometer" and weather!="": m.stages.special_defense+=1
	if ab=="living_canopy" and not m.spent.get("canopy",false): m.hp=mini(stats(m)[0],m.hp+maxi(1,int(stats(m)[0]/8)));m.spent.canopy=true
	return log

func hit(a,d,index,weather):
	var log = []; var slot = a.moves[index]; var move = moves[slot.id] if slot.pp>0 else moves.struggle
	if a.hp<=0 or d.hp<=0: return log
	if a.status=="sleep":
		if rng.randf()<0.45: a.status=""
		else: return [species[int(a.species)].name+" is asleep."]
	if a.status=="freeze":
		if rng.randf()<0.2: a.status=""
		else: return [species[int(a.species)].name+" is frozen."]
	if a.status=="paralyze" and rng.randf()<0.25: return [species[int(a.species)].name+" cannot move."]
	if slot.pp>0: slot.pp=maxi(0,slot.pp-(2 if ability(d)=="pressure" else 1))
	log.append(species[int(a.species)].name+" used "+move.name+".")
	if rng.randf()*100>move.accuracy*stage(a.stages.accuracy): return log+["The move missed."]
	if d.spent.get("protect",false): return log+["The target protected itself."]
	var ab = ability(a); var db = ability(d); var effect = move.get("effect","")
	if effect!="":
		match effect:
			"guard": a.stages.defense=mini(6,a.stages.defense+(2 if ab=="simple" else 1))
			"growl":
				if db=="defiant": d.stages.attack=mini(6,d.stages.attack+1)
				elif db=="competitive": d.stages.special_attack=mini(6,d.stages.special_attack+2)
				elif db not in ["hyper_cutter","clear_body"]: d.stages.attack=maxi(-6,d.stages.attack-1)
			"recover": a.hp=mini(stats(a)[0],a.hp+int(stats(a)[0]/2))
			"swords": a.stages.attack=mini(6,a.stages.attack+2)
			"protect": a.spent.protect=true
			"haze":
				for k in d.stages:
					if db!="quiet_witness" or d.stages[k]<0: d.stages[k]=0
			_:
				if effect in ["burn","poison","sleep","paralyze"]: inflict(d,effect)
		return log
	var type = move.type; var immune = {"Fire":["flash_fire"],"Water":["water_absorb","storm_drain"],"Electric":["volt_absorb","lightning_rod"],"Grass":["sap_sipper"],"Ground":["levitate"]}
	if immune.get(type,[]).has(db):
		if db in ["volt_absorb","water_absorb"]: d.hp=mini(stats(d)[0],d.hp+int(stats(d)[0]/4))
		if db in ["lightning_rod","storm_drain"]: d.stages.special_attack=mini(6,d.stages.special_attack+1)
		if db=="sap_sipper": d.stages.attack=mini(6,d.stages.attack+1)
		return log+["The ability absorbed the attack."]
	var eff = effective(type,species[int(d.species)].types)
	if eff==0: return log+["It had no effect."]
	var physical = move.get("category","physical")=="physical"
	var atk = stats(a)[1 if physical else 3]*stage(a.stages.attack if physical else a.stages.special_attack)
	var defense = stats(d)[2 if physical else 4]*stage(d.stages.defense if physical else d.stages.special_defense)
	if a.status=="burn" and physical: atk*=0.5
	var mod = eff*(1.5 if species[int(a.species)].types.has(type) else 1.0)*rng.randf_range(0.85,1.0)
	if ab=="adaptability" and species[int(a.species)].types.has(type): mod*=4.0/3.0
	if ab=="strong_jaw" and move.name=="Bite": mod*=1.5
	if a.hp<=stats(a)[0]/3 and {"overgrow":"Grass","blaze":"Fire","torrent":"Water"}.get(ab,"")==type: mod*=1.5
	if db=="thick_fat" and type in ["Fire","Ice"]: mod*=0.5
	if db=="multiscale" and d.hp==stats(d)[0]: mod*=0.5
	if db=="solid_rock" and eff>1: mod*=0.75
	if weather=="rain": mod*=1.5 if type=="Water" else 0.5 if type=="Fire" else 1.0
	if weather=="sun": mod*=1.5 if type=="Fire" else 0.5 if type=="Water" else 1.0
	if weather=="snow" and physical and species[int(d.species)].types.has("Ice"): defense*=1.5
	if not d.spent.get("protection",false) and eff>1 and (db=="deep_time" or db=="herd_shelter" and weather=="snow" or db=="furnace_burrow" and type=="Water"):
		mod*=0.75; d.spent.protection=true
	if db=="rain_shelter" and type=="Fire" and weather=="rain" and not d.spent.get("rain_shelter",false): mod*=0.5;d.spent.rain_shelter=true
	var damage = maxi(1,int(((2*a.level/5.0+2)*move.power*atk/maxf(1,defense)/50+2)*mod))
	if damage>=d.hp and d.hp==stats(d)[0] and (db=="sturdy" or d.held=="Focus Sash"): damage=d.hp-1;d.held="" if d.held=="Focus Sash" else d.held
	d.hp=maxi(0,d.hp-damage)
	if eff>1: log.append("It is super effective!")
	if eff<1: log.append("It is not very effective.")
	if move.get("status","")!="" and db!="shield_dust" and rng.randf()<0.1: inflict(d,move.status)
	if db=="ink_decoy" and physical and d.hp>0 and not d.spent.get("ink",false): a.stages.accuracy=maxi(-6,a.stages.accuracy-1);d.spent.ink=true
	if db=="furnace_plates" and physical and not d.spent.get("furnace",false):
		d.spent.furnace=true
		if rng.randf()<0.3: inflict(a,"burn")
	if d.hp==0:
		log.append(species[int(d.species)].name+" fainted.")
		if ab=="root_wrestler" and physical and type in ["Grass","Fighting"]: a.stages.defense=mini(6,a.stages.defense+1)
	return log

func inflict(m,status):
	if m.status!="" or m.hp<=0: return
	var types = species[int(m.species)].types; var ab = ability(m)
	if status=="burn" and (types.has("Fire") or ab in ["water_veil","furnace_plates"]): return
	if status=="poison" and (types.has("Poison") or types.has("Steel")): return
	if status=="paralyze" and types.has("Electric"): return
	if status=="freeze" and (types.has("Ice") or ab in ["cold_instinct","herd_shelter"]): return
	if status=="sleep" and ab=="vital_spirit": return
	m.status=status

func residual(m,weather):
	m.spent.erase("protect")
	if m.hp<=0: return
	if m.status in ["burn","poison"]: m.hp=maxi(0,m.hp-maxi(1,int(stats(m)[0]/(16 if m.status=="burn" else 8))))
	var ab = ability(m)
	if ab=="shed_skin" and rng.randf()<0.33 or ab=="hydration" and weather=="rain": m.status=""
	if ab=="rain_dish" and weather=="rain" or ab=="ice_body" and weather=="snow" or m.held=="Leftovers": m.hp=mini(stats(m)[0],m.hp+maxi(1,int(stats(m)[0]/16)))
	if m.held in ["Oran Berry","Sitrus Berry"] and m.hp<=stats(m)[0]/2: m.hp=mini(stats(m)[0],m.hp+(10 if m.held=="Oran Berry" else int(stats(m)[0]/4)));m.held=""

func can_breed(a,b):
	return a.gender!="unknown" and b.gender!="unknown" and a.gender!=b.gender and species[int(a.species)].egg_group==species[int(b.species)].egg_group
func egg(a,b):
	if not can_breed(a,b): return {}
	var mother = a if a.gender=="female" else b
	var m = make_mon(species[int(mother.species)].baby,1)
	var count = 5 if a.held=="Destiny Knot" or b.held=="Destiny Knot" else 3
	var keys = [0,1,2,3,4,5]; keys.shuffle()
	for k in keys.slice(0,count): m.ivs[k]=(a if rng.randf()<0.5 else b).ivs[k]
	if a.held=="Everstone": m.nature=a.nature
	elif b.held=="Everstone": m.nature=b.nature
	if mother.slot=="hidden" and rng.randf()<0.6: m.slot="hidden"
	m.egg_steps=256;m.hp=stats(m)[0]
	return m
func walk_daycare():
	var log = []; var d = state.daycare
	for m in d.parents: log.append_array(gain(m,1))
	if d.parents.size()==2 and d.egg.is_empty() and can_breed(d.parents[0],d.parents[1]):
		d.steps+=1
		if d.steps>=128: d.egg=egg(d.parents[0],d.parents[1]);d.steps=0;log.append("An Egg is ready at the daycare.")
	for m in state.eggs.duplicate():
		m.egg_steps-=1
		if m.egg_steps<=0 and (state.party.size()<6 or state.boxes.size()<300):
			m.erase("egg_steps");state.eggs.erase(m);(state.party if state.party.size()<6 else state.boxes).append(m);heal(m)
			if not state.caught.has(m.species): state.caught.append(m.species)
			log.append("An Egg hatched into "+species[int(m.species)].name+"!")
	return log

func save_game(slot=-1):
	if slot<0: slot=active_slot
	else: active_slot=slot
	var path = "user://save_"+str(slot)+".json"
	var f = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f==null: return false
	f.store_string(JSON.stringify(state));f.close()
	if FileAccess.file_exists(path): DirAccess.copy_absolute(path,path+".bak")
	return DirAccess.rename_absolute(path+".tmp",path)==OK
func load_game(slot=0):
	var p = "user://save_"+str(slot)+".json"
	for path in [p,p+".bak"]:
		if FileAccess.file_exists(path):
			var s = JSON.parse_string(FileAccess.get_file_as_string(path))
			if validate(s): state=normalise_save(s);active_slot=slot;return true
	return false
func validate(s):
	if not s is Dictionary or s.get("version",0)!=1: return false
	for k in ["party","boxes","eggs","flags","daycare","map","badges","bag","money","quests","puzzles","caught","seen","x","z","hall","options"]:
		if not s.has(k): return false
	if not (s.x is int or s.x is float) or not (s.z is int or s.z is float) or not is_finite(float(s.x)) or not is_finite(float(s.z)):return false
	if not s.party is Array or s.party.size()<1 or s.party.size()>6 or s.boxes.size()>300 or s.eggs.size()>12 or s.daycare.parents.size()>2: return false
	var seen_uids = {}
	var all = s.party+s.boxes+s.eggs+s.daycare.parents
	if not s.daycare.egg.is_empty(): all.append(s.daycare.egg)
	for m in all:
		if not m is Dictionary: return false
		for k in ["species","uid","level","ivs","evs","nature","moves","hp","xp","gender","slot","status","stages","held","spent","friendship","shiny"]:
			if not m.has(k): return false
		if not species.has(int(m.species)) or seen_uids.has(m.uid) or m.level<1 or m.level>100 or not NATURES.has(m.nature) or m.ivs.size()!=6 or m.evs.size()!=6: return false
		seen_uids[m.uid]=true
		var total = 0
		for k in range(6):
			if m.ivs[k]<0 or m.ivs[k]>31 or m.evs[k]<0 or m.evs[k]>252: return false
			total+=int(m.evs[k])
		if total>510 or m.hp<0 or m.hp>stats(m)[0] or m.moves.size()>4 or m.moves.size()<1: return false
		for v in m.moves:
			if not moves.has(v.id) or v.pp<0 or v.pp>moves[v.id].pp: return false
	return s.badges>=0 and s.badges<=8 and s.money>=0

func normalise_save(s):
	for key in ["version","badges","money","steps"]:s[key]=int(s.get(key,0))
	for key in s.bag:s.bag[key]=int(s.bag[key])
	for key in s.quests:s.quests[key]=int(s.quests[key])
	for key in ["seen","caught"]:s[key]=s[key].map(func(v):return int(v))
	var all=s.party+s.boxes+s.eggs+s.daycare.parents
	if not s.daycare.egg.is_empty():all.append(s.daycare.egg)
	for mon in all:
		for key in ["species","level","hp","xp","friendship"]:mon[key]=int(mon[key])
		mon.ivs=mon.ivs.map(func(v):return int(v));mon.evs=mon.evs.map(func(v):return int(v))
		for move in mon.moves:move.pp=int(move.pp)
		for key in mon.stages:mon.stages[key]=int(mon.stages[key])
	return s
