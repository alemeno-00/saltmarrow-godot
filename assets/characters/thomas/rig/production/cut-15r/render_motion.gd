extends SceneTree
func _initialize():
 var base := OS.get_cmdline_user_args()[0]+"/assets/characters/thomas/rig/"
 var sheet := Image.load_from_file(base+"s.png")
 var strip := Image.create(80*60,80,false,Image.FORMAT_RGBA8)
 var motion := RigMotion.new()
 for i in 240:
  var speed := 45.0 if i>=30 and i<150 else 0.0
  var pose := motion.step(1.0/60.0,Vector2(0,speed),Vector2(0,1))
  if i%4==0:
   var frame := Rig.compose(sheet,pose,Vector2(0,-1),Vector2(40,72))
   strip.blit_rect(frame,Rect2i(0,0,80,80),Vector2i((i/4)*80,0))
 strip.save_png(base+"production/cut-15r/previews/start-walk-stop-60.png")
 print("60 RigMotion samples rendered over four seconds: idle, accelerate, walk, stop, settle")
 quit()
