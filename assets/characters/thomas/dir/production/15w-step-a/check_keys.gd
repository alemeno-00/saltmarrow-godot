extends SceneTree
const W=preload("res://walk_guides.gd")
func _initialize():
 var repo:=OS.get_cmdline_user_args()[0]
 var out:=repo+"/assets/characters/thomas/dir/production/15w-step-a/"
 var keys:=Image.load_from_file(out+"keys-1x.png")
 var guide:=Image.load_from_file(repo+"/design/art-briefs/animation/walk-s/guide_walk_s.png")
 var model:=Image.load_from_file(repo+"/assets/characters/thomas/rig/production/model-s.png")
 var sheet:=Image.create(640,160,false,Image.FORMAT_RGBA8)
 for i in 6:sheet.blit_rect(model,Rect2i(0,0,80,80),Vector2i(i*80,0))
 sheet.blit_rect(guide,Rect2i(0,0,640,80),Vector2i(0,80))
 for j in 4:
  var n:=1+j*2
  var frame:=keys.get_region(Rect2i(j*80,0,80,80))
  frame.save_png(out+"key-%02d-1x.png"%n)
  sheet.blit_rect(frame,Rect2i(0,0,80,80),Vector2i((n-1)*80,80))
 sheet.save_png("/tmp/saltmarrow-15w/qa-only-guide-placeholders.png")
 var report:=W.check(sheet)
 var lines=[]
 for i in [0,2,4,6]:
  lines.append(report.lines[i]);print(report.lines[i])
 var result={"checker":"unchanged tools/pose_guides/walk_guides.gd check", "scope":"Only keys1,3,5,7 painted; QA-only temporary sheet uses unchanged supplied guides for2,4,6,8. No runtime sheet delivered.","key_lines":lines,"keys_pass":report.ok,"engine":Engine.get_version_info().string}
 FileAccess.open(out+"guide-check.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
 print("KEYS PASS" if report.ok else "KEYS FAIL")
 quit(0 if report.ok else 1)
