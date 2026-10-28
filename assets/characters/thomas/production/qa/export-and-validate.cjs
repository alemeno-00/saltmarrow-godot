// Art export/inspection only. Requires Node.js and sharp; no game code is touched.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');

async function binary(input) {
  const { data, info } = await sharp(input).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  for (let i = 0; i < data.length; i += 4) {
    data[i + 3] = data[i + 3] >= 128 ? 255 : 0;
    if (!data[i + 3]) data.fill(0, i, i + 4);
  }
  return sharp(data, { raw: info }).png().toBuffer();
}

async function inspect(input) {
  const { data, info } = await sharp(input).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const alpha = new Set(), colours = new Set();
  let left = info.width, top = info.height, right = -1, bottom = -1, opaque = 0;
  const soles = [];
  for (let y = 0; y < info.height; y++) for (let x = 0; x < info.width; x++) {
    const i = (y * info.width + x) * 4, a = data[i + 3]; alpha.add(a);
    if (a) {
      opaque++; colours.add(data.subarray(i, i + 3).toString('hex'));
      left = Math.min(left, x); right = Math.max(right, x);
      top = Math.min(top, y); bottom = Math.max(bottom, y);
      if (y === 55) soles.push(x);
    }
  }
  return { width: info.width, height: info.height, alphaValues: [...alpha].sort((a,b)=>a-b),
    opaquePixels: opaque, opaqueColours: colours.size, bbox: [left,top,right,bottom], solePixelsAtY55: soles,
    sha256: crypto.createHash('sha256').update(fs.readFileSync(input)).digest('hex') };
}

async function palette(input) {
  // Palette reduction is an export step, not a claim that generated detail is hand-pixelled.
  const {data,info}=await sharp(await binary(input)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const histogram=new Map();
  for(let i=0;i<data.length;i+=4)if(data[i+3]){
    const key=data.subarray(i,i+3).toString('hex');
    const c=histogram.get(key)||{rgb:[data[i],data[i+1],data[i+2]],n:0};c.n++;histogram.set(key,c);
  }
  let boxes=[[...histogram.values()]];
  const range=b=>[0,1,2].map(k=>Math.max(...b.map(c=>c.rgb[k]))-Math.min(...b.map(c=>c.rgb[k])));
  while(boxes.length<31){
    const options=boxes.map((b,i)=>({i,b,r:range(b)})).filter(o=>o.b.length>1)
      .sort((a,b)=>Math.max(...b.r)-Math.max(...a.r));
    if(!options.length)break;
    const {i,b,r}=options[0],axis=r.indexOf(Math.max(...r));b.sort((a,b)=>a.rgb[axis]-b.rgb[axis]);
    const half=b.reduce((s,c)=>s+c.n,0)/2;let total=0,cut=1;
    for(let j=0;j<b.length-1;j++){total+=b[j].n;cut=j+1;if(total>=half)break;}
    boxes.splice(i,1,b.slice(0,cut),b.slice(cut));
  }
  const colours=boxes.map(b=>[0,1,2].map(k=>Math.round(b.reduce((s,c)=>s+c.rgb[k]*c.n,0)/b.reduce((s,c)=>s+c.n,0))));
  for(let i=0;i<data.length;i+=4)if(data[i+3]){
    let best=colours[0],distance=Infinity;
    for(const c of colours){const d=c.reduce((s,v,k)=>s+(v-data[i+k])**2,0);if(d<distance){distance=d;best=c;}}
    for(let k=0;k<3;k++)data[i+k]=best[k];
  }
  return sharp(data,{raw:info}).png().toBuffer();
}

(async () => {
  const master = path.join(root, 'masters/standing-generated.png');
  const meta = await sharp(master).metadata();
  assert(meta.hasAlpha, 'Standing master must have real alpha');
  const solid = await binary(master);
  const trimmed = await sharp(solid).trim({ threshold: 0 }).png().toBuffer();
  const small = await sharp(trimmed).resize({ width: 30, height: 46, fit: 'inside', kernel: 'nearest' }).png().toBuffer();
  const size = await sharp(small).metadata();
  const left = 32 - Math.floor(size.width / 2), top = 56 - size.height;
  const placed = await sharp({ create: { width:64, height:64, channels:4, background:'#00000000' } })
    .composite([{ input:small, left, top }]).png().toBuffer();
  const spritePath = path.join(root, 'sprites/standing-candidate.png');
  await sharp(await palette(placed)).png().toFile(spritePath);

  const portraitMaster = path.join(root, 'masters/portrait-generated.png');
  assert((await sharp(portraitMaster).metadata()).hasAlpha, 'Portrait master must have real alpha');
  const portrait = await sharp(await binary(portraitMaster)).resize(120,120,{fit:'contain',kernel:'nearest',background:'#00000000'})
    .extend({top:4,bottom:4,left:4,right:4,background:'#00000000'}).png().toBuffer();
  const portraitPath = path.join(root,'sprites/steady-portrait-candidate.png');
  await sharp(await palette(portrait)).png().toFile(portraitPath);

  const results = {};
  for (const [name, file, expected] of [['standing',spritePath,64],['portrait',portraitPath,128]]) {
    const result = await inspect(file); results[name] = result;
    assert.equal(result.width,expected); assert.equal(result.height,expected);
    assert.deepEqual(result.alphaValues,[0,255]); assert(result.opaqueColours<=32);
    assert(result.opaquePixels>0); assert(result.bbox[0]>0 && result.bbox[2]<expected-1);
    assert(result.bbox[1]>0, 'Top must not be clipped');
    await sharp(file).resize(expected*4,expected*4,{kernel:'nearest'}).png().toFile(path.join(root,'qa',name+'-4x.png'));
  }
  assert.equal(results.standing.bbox[3],55);
  assert(results.standing.bbox[0]>=16 && results.standing.bbox[2]<=47);
  results.standing.root = [32,56];
  results.standing.animation = 'Single still; no animation validation or completion claimed';
  results.portrait.animation = 'Single portrait; no animation';

  // Native 64 px frame on a 32 px tile grid, enlarged with nearest-neighbour for inspection.
  const grid = Buffer.alloc(128*128*4);
  for(let y=0;y<128;y++)for(let x=0;x<128;x++){
    const i=(y*128+x)*4; const edge=x%32===0||y%32===0;
    grid[i]=edge?65:34;grid[i+1]=edge?73:43;grid[i+2]=edge?78:48;grid[i+3]=255;
  }
  const onGrid = await sharp(grid,{raw:{width:128,height:128,channels:4}})
    .composite([{input:spritePath,left:32,top:32}]).png().toBuffer();
  await sharp(onGrid).resize(512,512,{kernel:'nearest'}).png().toFile(path.join(root,'qa/standing-grid-4x.png'));
  fs.writeFileSync(path.join(root,'qa/validation.json'),JSON.stringify(results,null,2)+'\n');
  console.log(JSON.stringify(results,null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});
