"""Run in Blender. Leaves the user's active scene, selection and file intact."""
import bpy
import bmesh
import json
import math
from pathlib import Path
from mathutils import Vector

ASSET = Path(r"C:\Users\evans\Documents\Codex\2026-09-19\i-x20\Mistborn\assets\tutorial-wall")
original_scene = bpy.context.window.scene
original_selection = list(bpy.context.selected_objects)
original_active = bpy.context.view_layer.objects.active
previous = bpy.data.scenes.get("TutorialWallAsset")
if previous and previous != original_scene:
    for obj in list(previous.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.scenes.remove(previous)
scene = bpy.data.scenes.new("TutorialWallAsset")
try:
    bpy.context.window.scene = scene
    bpy.ops.import_scene.gltf(filepath=str(ASSET / "tutorial-wall-source.glb"))
    meshes = [obj for obj in scene.objects if obj.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    wall = bpy.context.object
    wall.name = "TutorialMedievalStoneWall"
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # Put the finalized mesh pivot at ground level under the wall center.
    scene.cursor.location = (0, 80, 0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    wall.location = (0, 0, 0)
    for obj in list(scene.objects):
        if obj.type == 'EMPTY':
            bpy.data.objects.remove(obj, do_unlink=True)
    bm = bmesh.new()
    bm.from_mesh(wall.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.00001)
    bmesh.ops.dissolve_degenerate(bm, edges=list(bm.edges), dist=0.00001)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(wall.data)
    bm.free()
    wall.data.validate()
    wall.data.update()
    for polygon in wall.data.polygons:
        polygon.use_smooth = False
    # Existing GLTF box UVs survive joining; keep hard stone edges and eight PBR colors.
    for mat in wall.data.materials:
        if mat and mat.use_nodes:
            shader = next((node for node in mat.node_tree.nodes if node.type == 'BSDF_PRINCIPLED'), None)
            if shader:
                shader.inputs['Roughness'].default_value = .96
                shader.inputs['Metallic'].default_value = 0
    bpy.ops.export_scene.gltf(filepath=str(ASSET / "tutorial-wall-final.glb"),
        export_format='GLB', use_selection=True, use_active_scene=True, export_texcoords=True,
        export_normals=True, export_materials='EXPORT', export_yup=True)
    wall.data.calc_loop_triangles()
    report = {'blenderVersion': bpy.app.version_string, 'meshObjects': 1,
        'vertices': len(wall.data.vertices), 'triangles': len(wall.data.loop_triangles),
        'materials': len(wall.data.materials), 'uvLayers': len(wall.data.uv_layers),
        'dimensionsStuds': list(wall.dimensions), 'pivot': list(wall.location),
        'sourcePartCount': len(meshes), 'originalScenePreserved': original_scene.name,
        'finalGlbBytes': (ASSET / 'tutorial-wall-final.glb').stat().st_size}
    # A scene library is a valid .blend, without saving over the user's current file.
    bpy.data.libraries.write(str(ASSET / 'tutorial-wall.blend'), {scene}, fake_user=True)
    report['blendBytes'] = (ASSET / 'tutorial-wall.blend').stat().st_size
    (ASSET / 'blender-result.json').write_text(json.dumps(report, indent=2) + '\n')
    # Review render objects are not saved into the asset library or GLB.
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = 1120
    scene.render.resolution_y = 700
    scene.render.resolution_percentage = 100
    scene.world = bpy.data.worlds.new('TutorialWallReviewWorld')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes.get('Background').inputs[0].default_value = (.38,.42,.46,1)
    scene.world.node_tree.nodes.get('Background').inputs[1].default_value = .7
    camera_data = bpy.data.cameras.new('TutorialWallReviewCamera')
    camera = bpy.data.objects.new('TutorialWallReviewCamera', camera_data)
    scene.collection.objects.link(camera)
    camera.location = (240,-410,180)
    camera.rotation_euler = (Vector((0,0,44)) - camera.location).to_track_quat('-Z','Y').to_euler()
    camera_data.type = 'ORTHO'
    camera_data.ortho_scale = 350
    scene.camera = camera
    light_data = bpy.data.lights.new('TutorialWallReviewSun', 'SUN')
    light_data.energy = 3
    light_data.angle = .15
    light = bpy.data.objects.new('TutorialWallReviewSun', light_data)
    scene.collection.objects.link(light)
    light.rotation_euler = (math.radians(25),math.radians(-35),math.radians(-20))
    scene.render.image_settings.file_format = 'PNG'
    scene.render.filepath = str(ASSET / 'wall-preview.png')
    bpy.ops.render.render(write_still=True)
    print(json.dumps(report))
finally:
    bpy.context.window.scene = original_scene
    bpy.ops.object.select_all(action='DESELECT')
    for obj in original_selection:
        if obj.name in bpy.context.view_layer.objects:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = original_active
