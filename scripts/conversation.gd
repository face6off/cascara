extends PanelContainer
signal finished
var pages=[]
var choices=[]
var index=0
var words:Label
var prompt:Label
var options:HBoxContainer
var letter_clock=0.0
var done=false
func setup(speaker,lines,buttons=[]):
	pages=lines if not lines.is_empty() else ["..."];choices=buttons
	position=Vector2(36,568);size=Vector2(1208,196)
	var style=StyleBoxFlat.new();style.bg_color=Color("#f5f2df");style.border_color=Color("#355c58");style.set_border_width_all(5);style.set_corner_radius_all(12);style.content_margin_left=25;style.content_margin_right=25;style.content_margin_top=14;style.content_margin_bottom=12;add_theme_stylebox_override("panel",style)
	var col=VBoxContainer.new();col.add_theme_constant_override("separation",8);add_child(col)
	var nameplate=Label.new();nameplate.text=speaker;nameplate.add_theme_color_override("font_color",Color("#376562"));nameplate.add_theme_font_size_override("font_size",23);col.add_child(nameplate)
	words=Label.new();words.custom_minimum_size=Vector2(1148,62);words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_theme_color_override("font_color",Color("#263e3c"));words.add_theme_font_size_override("font_size",21);col.add_child(words)
	options=HBoxContainer.new();options.add_theme_constant_override("separation",16);col.add_child(options)
	prompt=Label.new();prompt.text="E / Space / click to continue  ▾";prompt.add_theme_color_override("font_color",Color("#607672"));prompt.add_theme_font_size_override("font_size",14);col.add_child(prompt)
	show_page();return self
func show_page():
	words.text=str(pages[index]);words.visible_characters=0;letter_clock=0
func _process(delta):
	letter_clock+=delta*52
	words.visible_characters=mini(words.text.length(),int(letter_clock))
	if words.visible_characters>=words.text.length() and index==pages.size()-1 and not choices.is_empty() and options.get_child_count()==0:
		prompt.text="Choose a response."
		for choice in choices:
			var button=Button.new();button.text=choice[0];button.custom_minimum_size=Vector2(180,36);options.add_child(button)
			var action=choice[1];button.pressed.connect(func():finish();action.call())
func advance():
	if done:return
	if words.visible_characters<words.text.length():letter_clock=words.text.length();words.visible_characters=-1;return
	if index<pages.size()-1:index+=1;show_page()
	elif choices.is_empty():finish()
func finish():
	if done:return
	done=true;finished.emit();queue_free()
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_E,KEY_SPACE,KEY_ENTER]:advance();get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and choices.is_empty():advance();get_viewport().set_input_as_handled()
