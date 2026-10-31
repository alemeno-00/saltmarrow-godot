extends SceneTree
## Run in a temporary project containing unchanged Rig and RigPose from main.
## User argument: absolute path to the repo. Outputs are art-review composites only.
func _initialize():
 var repo := OS.get_cmdline_user_args()[0]
 var base := repo + "/assets/characters/thomas/rig/"
 var out := base + "production/cut-15r/previews/"
 var diffuse := Image.load_from_file(base + "s.png")
 var normal := Image.load_from_file(base + "s_n.png")
 var model := Image.load_from_file(base + "production/model-s.png")
 var model_n := Image.load_from_file(base + "production/model-s_n.png")
 var rebuilt := Rig.compose(diffuse,RigPose.bind(),Vector2(0,-1),Vector2(40,72))
 var rebuilt_n := Rig.compose(normal,RigPose.bind(),Vector2(0,-1),Vector2(40,72))
 rebuilt.save_png(out + "bind.png")
 rebuilt_n.save_png(out + "bind_n.png")
 var differences := 0
 var normal_differences := 0
 for y in 80:
  for x in 80:
   if rebuilt.get_pixel(x,y) != model.get_pixel(x,y): differences += 1
   if rebuilt_n.get_pixel(x,y) != model_n.get_pixel(x,y): normal_differences += 1
 var modes := ["idle","walk","sneak","limp"]
 var placements := {}
 for mode in modes:
  var strip := Image.create(80*16,80,false,Image.FORMAT_RGBA8)
  var positions := []
  for i in 16:
   var phase := i / 16.0
   var pose := RigPose.idle(phase) if mode=="idle" else RigPose.walk(phase, mode if mode!="walk" else "walk")
   var frame := Rig.compose(diffuse,pose,Vector2(0,-1),Vector2(40,72))
   strip.blit_rect(frame,Rect2i(0,0,80,80),Vector2i(i*80,0))
   var parts := []
   for p in Rig.placements(pose,Vector2(0,-1),Vector2(40,72)):
    parts.append({"part":p.part,"at":[p.at.x,p.at.y],"angle":p.angle,"order":p.order})
   positions.append(parts)
  strip.save_png(out + mode + "-16.png")
  placements[mode]=positions
 FileAccess.open(base+"production/cut-15r/motion-placements.json",FileAccess.WRITE).store_string(JSON.stringify(placements))
 var checks := {"engine":Engine.get_version_info().string,"diffuse_bind_differing_pixels":differences,"normal_bind_differing_pixels":normal_differences,"samples_per_motion":16,"motions":modes,"implementation":"unchanged main Rig.compose / RigPose; isolated temporary project; no game lighting or RigMotion spring simulation"}
 FileAccess.open(base+"production/cut-15r/godot-check.json",FileAccess.WRITE).store_string(JSON.stringify(checks,"  "))
 print(JSON.stringify(checks))
 quit(0 if differences==0 and normal_differences==0 else 1)
