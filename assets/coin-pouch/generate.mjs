import {createRequire} from 'node:module';
import {pathToFileURL} from 'node:url';
import {writeFile} from 'node:fs/promises';
const root='C:/Users/evans/Documents/Codex/2026-09-13/im/work/threejs';
const req=createRequire(root+'/package.json');
const T=req('three');
await import(pathToFileURL(root+'/src/node-file-reader.mjs'));
const {GLTFExporter}=await import(pathToFileURL(root+'/node_modules/three/examples/jsm/exporters/GLTFExporter.js'));
const scene=new T.Scene(),parts=[];
function add(name,shape,size,pos,color,rot=[0,0,0],coin=0){
 const g=shape==='Sphere'?new T.SphereGeometry(.5,16,12):shape==='Cylinder'?new T.CylinderGeometry(.5,.5,1,16):new T.BoxGeometry(1,1,1);
 const m=new T.Mesh(g,new T.MeshStandardMaterial({color,roughness:coin?.35:.92,metalness:coin?.65:0}));
 m.name=name;m.scale.set(...size);m.position.set(...pos);m.rotation.set(...rot);scene.add(m);
 parts.push({name,shape,size,pos,color,rot,coin});
}
add('LeatherBody','Sphere',[.95,1.12,.64],[0,-.12,0],'#493024');
add('DarkOpening','Sphere',[.8,.09,.53],[0,.37,0],'#160e0a');
for(let i=0;i<20;i++){
 const a=i*Math.PI*2/20;
 add('RolledRim'+i,'Sphere',[.18,.13,.13],[.43*Math.cos(a),.4,.27*Math.sin(a)],'#624332');
}
for(const x of [-.29,.29]){
 add('BeltLoop','Block',[.13,.48,.1],[x,.55,.25],'#493024');
 add('Rivet','Sphere',[.06,.06,.035],[x,.39,.195],'#ab8644');
 for(let i=0;i<10;i++)add('Stitch','Sphere',[.022,.042,.021],[x,-.48+i*.075,-.29],'#9e8057');
}
for(let i=0;i<15;i++){
 const a=i*2.39996,rad=.05+.25*Math.sqrt(i/15);
 add('PouchCoin'+(i+1),'Cylinder',[.24,.045,.24],[Math.cos(a)*rad,.39+i*.003,Math.sin(a)*rad*.6],'#c69836',[.1*Math.sin(i),0,.15*Math.cos(i)],i+1);
}
const out=new URL('./',import.meta.url);
await writeFile(new URL('pouch-parts.json',out),JSON.stringify(parts,null,2));
await writeFile(new URL('coin-pouch-source.glb',out),new Uint8Array(await new GLTFExporter().parseAsync(scene,{binary:true})));
console.log(JSON.stringify({parts:parts.length}));
