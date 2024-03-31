@tool
extends PanelContainer
#---UV---#
@onready var b_reload = $VBoxContainer/Buttons/Reload
@onready var b_settings = $VBoxContainer/Buttons/Settings
@onready var b_apply = $VBoxContainer/Buttons/Apply
@onready var search = $VBoxContainer/Search
@onready var settings = $VBoxContainer/Settings
@onready var b_material = $VBoxContainer/Materials/VBoxContainer2/Material
@onready var text_edit = $VBoxContainer/HBoxContainer/TextEdit
@onready var alert_ui = $Alert
#---CheckBox---#
@onready var shader_material: CheckBox = $VBoxContainer/Settings/shader_material
@onready var standart_material_3d: CheckBox = $VBoxContainer/Settings/standart_material_3d
@onready var visual_shader: CheckBox = $VBoxContainer/Settings/visual_shader
#---Buttons---#
@onready var help = $VBoxContainer/Settings/HBoxContainer/Help
@onready var bug_report = $"VBoxContainer/Settings/HBoxContainer/Bug Report"
#---Slider---#
@onready var size_slider = $VBoxContainer/Settings/HBoxContainer2/Size_Slider
#---Icons---#
const SHADER_MATERIAL = preload("res://addons/material_viewer/icons/godot/ShaderMaterial.svg")
const STANDARD_MATERIAL_3D = preload("res://addons/material_viewer/icons/godot/StandardMaterial3D.svg")
const VISUAL_SHADER = preload("res://addons/material_viewer/icons/godot/VisualShader.svg")
#---Signals---#
signal reload
signal apply
#---Array---#
var Buttons : Array[Button]
var Buttons_shader_materials : Array[Button]
var Buttons_standart_materials : Array[Button]
var Buttons_visual_shaders : Array[Button]
var Shaders : Array
#---Other---#
var preview : EditorResourcePreview = EditorInterface.get_resource_previewer()

func _ready():
	b_reload.button_down.connect(_reload)
	b_settings.button_down.connect(_settings)
	b_apply.button_down.connect(_apply)
	search.text_changed.connect(_text_changed)
	shader_material.toggled.connect(_filter_shader_material)
	standart_material_3d.toggled.connect(_filter_standart_material_3d)
	visual_shader.toggled.connect(_filter_visual_shader)
	help.pressed.connect(_help)
	bug_report.pressed.connect(_bug_report)
	size_slider.value_changed.connect(_size_slider)

func _reload():
	reload.emit()

func _apply():
	apply.emit()

func _update(shaders):
	b_material.visible = true
	for i in Buttons.size():
		Buttons[i].free()
	Buttons = []
	Buttons_shader_materials = []
	Buttons_standart_materials = []
	Buttons_visual_shaders = []
	Shaders = shaders
	for i in shaders.size():
		var shader = shaders[i]
		var new_button : Button = b_material.duplicate(8)
		b_material.get_parent().add_child(new_button)
		var sh_name = shader.resource_path.get_basename().get_slice("/", shader.resource_path.get_slice_count("/")-1)
		new_button.text = sh_name
		if shader.get_class() == "ShaderMaterial":
			preview.queue_resource_preview(shader.resource_path, self, "_set_preview", new_button)
			Buttons_shader_materials.append(new_button)
		elif shader.get_class() == "StandardMaterial3D":
			preview.queue_resource_preview(shader.resource_path, self, "_set_preview", new_button)
			Buttons_standart_materials.append(new_button)
		elif shader.get_class() == "VisualShader":
			new_button.icon = VISUAL_SHADER
			Buttons_visual_shaders.append(new_button)
		new_button.button_down.connect(_k.bind(new_button))
		Buttons.append(new_button)
	_filter()
	b_material.visible = false

func _set_preview(path: String, preview: Texture2D, thumbnail: Texture2D, button : Button):
	button.icon = preview

func _k(m_button):
	var i = Buttons.find(m_button)
	text_edit.text = Shaders[i].resource_path.get_base_dir()
	EditorInterface.select_file(Shaders[i].resource_path)

#---Filters---#

func _filter():
	_filter_shader_material(shader_material.button_pressed)
	_filter_standart_material_3d(standart_material_3d.button_pressed)
	_filter_visual_shader(visual_shader.button_pressed)

func _filter_shader_material(toggle: bool):
	for i in Buttons_shader_materials.size():
		Buttons_shader_materials[i].visible = toggle

func _filter_standart_material_3d(toggle: bool):
	for i in Buttons_standart_materials.size():
		Buttons_standart_materials[i].visible = toggle

func _filter_visual_shader(toggle: bool):
	for i in Buttons_visual_shaders.size():
		Buttons_visual_shaders[i].visible = toggle

func _settings():
	if settings.visible == true:
		settings.visible = false
	else:
		settings.visible = true

func _text_changed(text):
	var filtre_buttons: Array[Button]
	
	var toggle_filter_shader_material: bool = shader_material.button_pressed
	var toggle_filter_standart_material_3d: bool = standart_material_3d.button_pressed
	var toggle_filter_visual_shader: bool = visual_shader.button_pressed
	
	if toggle_filter_shader_material:
		for i in Buttons_shader_materials.size():
			filtre_buttons.append(Buttons_shader_materials[i])
	if toggle_filter_standart_material_3d:
		for i in Buttons_standart_materials.size():
			filtre_buttons.append(Buttons_standart_materials[i])
	if toggle_filter_visual_shader:
		for i in Buttons_visual_shaders.size():
			filtre_buttons.append(Buttons_visual_shaders[i])
	
	if text == "":
		for i in filtre_buttons.size():
			filtre_buttons[i].visible = true
	else:
		for i in filtre_buttons.size():
			if filtre_buttons[i].text.contains(text):
				filtre_buttons[i].visible = true
			else:
				filtre_buttons[i].visible = false

#---Setting-Buttons---#

func _size_slider(value):
	var y = 30 * (1 - value) + 60 * value
	for i in Buttons.size():
		Buttons[i].custom_minimum_size = Vector2(0, y)

func _help():
	OS.shell_open("https://github.com/3Dvachevsky/MaterialViewer")

func _bug_report():
	OS.shell_open("https://github.com/3Dvachevsky/MaterialViewer/issues")

func alert():
	alert_ui.show()
