"""Mechanical preview of painted parts using the pinned Rig/RigPose equations.
Not an in-game lighting test. Does not repaint any part or invent animation poses.
"""
from pathlib import Path
from PIL import Image
import math,json
P=Path(__file__).resolve().parent;R=P.parent;N=Image.Resampling.NEAREST
PARTS=[('head','neck','head',-1),('torso','hip','neck',-1),('skirt','hip','hem',1),('upper_arm_l','l_shoulder','l_elbow',1),('forearm_l','l_elbow','l_hand',1),('upper_arm_r','r_shoulder','r_elbow',1),('forearm_r','r_elbow','r_hand',1),('thigh_l','l_hip','l_knee',1),('shin_l','l_knee','l_ankle',1),('thigh_r','r_hip','r_knee',1),('shin_r','r_knee','r_ankle',1)]

def add(a,b):return tuple(x+y for x,y in zip(a,b))
def foot(q):
    q%=1
    if q<.5:return 9*(1-4*q),0
    u=(q-.5)/.5;return -9+18*u*u*(3-2*u),5*math.sin(math.pi*u)
def knee(hip,ankle):
    forward,up=ankle[2]-hip[2],ankle[1]-hip[1]
    d=max(.01,min(28.99,math.hypot(forward,up)));a=math.acos(d/29);base=math.atan2(up,forward)
    k=(math.cos(base-a)*14.5,math.sin(base-a)*14.5)
    if k[0]<forward*14.5/d:k=(math.cos(base+a)*14.5,math.sin(base+a)*14.5)
    return (hip[0]+ankle[0])/2,hip[1]+k[1],hip[2]+k[0]
def pose(t,idle=False):
    left,right=((2.5,0),(-2.5,0)) if idle else (foot(t),foot(t+.5))
    hy=29.7 if idle else 30-1.5*math.cos(4*math.pi*(t-.125));lean=.5 if idle else 2;dy=hy-30
    p={'hip':(0,hy,0),'l_hip':(-5,hy,0),'r_hip':(5,hy,0),'l_ankle':(-4,2+left[1],left[0]),'r_ankle':(4,2+right[1],right[0]),'neck':(0,50+dy,lean),'head':(0,55+dy,lean+.5),'l_shoulder':(-7,47+dy,lean),'r_shoulder':(7,47+dy,lean),'hem':(0,hy-16,lean*.5-(left[0]+right[0])*.15)}
    for side,f,other in [('l',left,right),('r',right,left)]:
        p[side+'_knee']=knee(p[side+'_hip'],p[side+'_ankle']);swing=.6*other[0]
        p[side+'_elbow']=add(p[side+'_shoulder'],(-1 if side=='l' else 1,-9,swing*.45-.5))
        p[side+'_hand']=add(p[side+'_elbow'],(0,-8.5,swing*.55+1.5))
    if idle:
        for k in ['neck','head','l_shoulder','r_shoulder','l_elbow','r_elbow','l_hand','r_hand']:p[k]=add(p[k],(0,.6*math.sin(math.tau*t),0))
    return p
def project(p):return 40-p[0],72-p[1]*math.cos(math.pi/6)+p[2]*.5,-p[2]
def frame(sheet,p):
    placements=[];depth=project(p['hip'])[2]
    for i,(name,start,end,rest) in enumerate(PARTS):
        a,b=project(p[start]),project(p[end]);vx,vy=b[0]-a[0],b[1]-a[1]
        angle=math.atan2(-rest*vx,rest*vy) if math.hypot(vx,vy)>.5 else 0
        d=(a[2]+b[2])/2
        layer=0 if name.startswith(('thigh','shin')) else ((1 if d>depth else 5) if 'arm' in name else {'skirt':2,'torso':3,'head':6}[name])
        placements.append((layer*1000-d,i,a,angle))
    out=Image.new('RGBA',(80,80))
    for order,i,a,angle in sorted(placements):
        cell=sheet.crop((i*24,0,i*24+24,24));pivot=(12,22 if i<2 else 2);c,s=math.cos(angle),math.sin(angle)
        for y in range(80):
            for x in range(80):
                dx,dy=x+.5-a[0],y+.5-a[1];sx=c*dx+s*dy+pivot[0];sy=-s*dx+c*dy+pivot[1]
                if 0<=sx<24 and 0<=sy<24:
                    colour=cell.getpixel((int(sx),int(sy)))
                    if colour[3]>127:out.putpixel((x,y),colour)
    return out
def main():
    sheet=Image.open(R/'s.png').convert('RGBA');pre=R/'previews';pre.mkdir(exist_ok=True)
    standing=frame(sheet,pose(0,True));standing.save(pre/'assembled-s.png');standing.resize((640,640),N).save(pre/'assembled-s-8x.png')
    frames=[frame(sheet,pose(i/8)) for i in range(8)];strip=Image.new('RGBA',(640,80))
    for i,f in enumerate(frames):strip.paste(f,(80*i,0))
    strip.resize((1920,240),N).save(pre/'south-walk-parts-3x.png')
    loop=[]
    for f in frames:
        bg=Image.new('RGBA',(80,80),(96,97,92,255));bg.alpha_composite(f);loop.append(bg.convert('RGB').resize((320,320),N))
    loop[0].save(pre/'south-walk-parts.gif',save_all=True,append_images=loop[1:],duration=100,loop=0)
    room=Image.open(P.parents[4]/'assets/tiles/sewers/rooms/junction_a/1.png').convert('RGBA');room.alpha_composite(standing,(112,152));room.crop((64,96,256,288)).resize((768,768),N).save(pre/'south-room-4x.png')
    print('Mechanical rig preview:',standing.getbbox())
if __name__=='__main__':main()
