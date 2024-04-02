@tool
extends EditorPlugin

var dock
#var filesystem = EditorInterface.get_resource_filesystem()

func _enter_tree():
	dock = preload("res://addons/material_viewer/material_viewer.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)

func _ready():
	dock.reload.connect(_reload)
	dock.apply.connect(get_all_glb)
	get_all_materials()

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()

func _reload():
	get_all_materials()

func get_all_glb():
	var objects : Array[PackedScene]
	var selected_folder = EditorInterface.get_current_directory()
	var dir = DirAccess.open(selected_folder)
	for file in dir.get_files():
		if file.ends_with(".glb"):
			var scene = load(selected_folder + "/" + file)
			if scene is PackedScene:
				objects.append(scene)
				apply_material(scene)#Вынести вызов из цикла!
	return objects

func apply_material(mesh):
	var scene = mesh.instantiate()
	var childs = scene.get_children()
	var surfaces = get_all_surfaces(scene)
	var materials = get_all_materials()
	var find_result = find_material(surfaces, materials)
	
	var config = ConfigFile.new()
	config.load(mesh.resource_path + ".import")
	var subresources : Dictionary = config.get_value("params", "_subresources")
	var subresourcesmats : Dictionary
	if subresources.has("materials"):
		subresourcesmats = subresources["materials"].duplicate()
	
	if find_result != []:
		for child in childs:
			if child.get_class() == "MeshInstance3D":
				var mi : MeshInstance3D = child
				for i in mi.mesh.get_surface_count():
					subresourcesmats[surfaces[i]] = { "use_external/enabled": true, "use_external/path": find_result[i].resource_path }
	else:
		dock.alert()
		return

	if !subresources.has("materials"):
		subresources["materials"] = {}

	subresources["materials"].clear()
	subresources["materials"] = subresourcesmats

	config.set_value("params", "_subresources", subresources)
	config.save(mesh.resource_path + ".import")
			
	EditorInterface.get_resource_filesystem().reimport_files([mesh.resource_path])

func get_all_surfaces(scene : Node3D):
	var childs = scene.get_children()
	var surfaces : Array[String]
	for child in childs:
		if child.get_class() == "MeshInstance3D":
			var mi : MeshInstance3D = child
			for i in mi.mesh.get_surface_count():
				var matName = mi.mesh.get("surface_" + str(i) + "/name")
				surfaces.append(matName)
	return surfaces

func find_material(surfaces : Array[String], materials : Array):
	var find_result : Array
	for i in surfaces.size():
		var surface = surfaces[i]
		for n in materials.size():
			var material = materials[n]
			if surface == material.resource_path.get_basename().get_slice("/", material.resource_path.get_slice_count("/")-1):
				if find_result == []:
					find_result.append(material)
				else:
					for g in find_result.size():
						var result = find_result[g]
						if material != result or find_result == []:
							find_result.append(material)
	return find_result

func get_all_materials():
	var materials : Array
	var folders = get_all_folders()
	for folder in folders:
		var dir = DirAccess.open(folder)
		for file in dir.get_files():
			if file.ends_with(".tres"):
				var shader = load(folder + file)
				shader.resource_path.get_basename()
				if shader.get_class() == "ShaderMaterial" or shader.get_class() == "StandardMaterial3D" or shader.get_class() == "VisualShader":
					materials.append(shader)
	dock._update(materials)
	return materials

func get_all_folders(path : String = "res://"):
	var folders_path : Array[String]
	for dir in DirAccess.get_directories_at(path):
		if dir.begins_with("."):
			continue
		var p = path + dir + "/"
		folders_path.append(p)
		folders_path.append_array(get_all_folders(p))
	return folders_path
