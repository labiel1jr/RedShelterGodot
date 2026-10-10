extends SceneTree
## Tambores: cada malha do FBX vira um .glb na origem (base no chão),
## 0,9 m de altura, com a textura própria da variante.
const NAMES := {"Barril1": "rust", "Barril2": "blue", "barril3": "hazard", "Barril4": "green", "Barril5": "red"}
func _initialize():
	await process_frame
	var s: Node3D = load("res://barris.fbx").instantiate()
	root.add_child(s)
	var cam := Camera3D.new(); root.add_child(cam)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.5,0.5,0.55); env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color.WHITE; root.add_child(env)
	var preview := Node3D.new(); root.add_child(preview)
	var i := 0
	for mi: MeshInstance3D in s.find_children("*", "MeshInstance3D"):
		var variant: String = NAMES[mi.name]
		var a: AABB = mi.global_transform * mi.mesh.get_aabb()
		var k := 0.9 / a.size.y
		var base := Vector3(a.get_center().x, a.position.y, a.get_center().z)
		var b := Basis().scaled(Vector3.ONE * k)
		var xform: Transform3D = Transform3D(b, -(b * base)) * mi.global_transform
		var out := Node3D.new(); out.name = "prop_barrels_" + variant
		var m := MeshInstance3D.new(); m.name = out.name + "_mesh"
		var mat := StandardMaterial3D.new(); mat.resource_name = out.name
		mat.albedo_texture = load("res://tex/%s.png" % out.name)
		var mesh: ArrayMesh = mi.mesh.duplicate()
		mesh.surface_set_material(0, mat)
		m.mesh = mesh; m.transform = xform
		out.add_child(m); m.owner = out
		var doc := GLTFDocument.new(); var st := GLTFState.new()
		doc.append_from_scene(out, st)
		print(out.name, " ", doc.write_to_filesystem(st, "res://out/%s.glb" % out.name), " ", xform * mi.mesh.get_aabb())
		out.position.x = i * 0.9; i += 1
		preview.add_child(out)
	s.queue_free()
	cam.look_at_from_position(Vector3(1.8, 1.4, 3.2), Vector3(1.8, 0.4, 0))
	var l := DirectionalLight3D.new(); root.add_child(l); l.rotation = Vector3(-0.7, 0.5, 0)
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview.png")
	quit()
