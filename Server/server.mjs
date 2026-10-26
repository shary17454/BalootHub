import {createServer as httpServer} from 'node:http';
import {spawn} from 'node:child_process';
import {createInterface} from 'node:readline';
import {randomBytes,timingSafeEqual} from 'node:crypto';
import {fileURLToPath} from 'node:url';
const invalid=(status,code)=>Object.assign(new Error(code),{status,code});
export class Engine {
 constructor(binary=process.env.BALOOT_ENGINE_WORKER || fileURLToPath(new URL('EngineWorker/.build/release/BalootWorker',import.meta.url))){
  this.queue=[];this.closed=false;this.child=spawn(binary,[],{stdio:['pipe','pipe','ignore']});
  createInterface({input:this.child.stdout}).on('line',line=>{const next=this.queue.shift();if(next){clearTimeout(next.timer);try{next.resolve(JSON.parse(line));}catch{next.reject(invalid(503,'engine_unavailable'));}}});
  const ended=()=>{this.closed=true;for(const p of this.queue){clearTimeout(p.timer);p.reject(invalid(503,'engine_unavailable'));}this.queue=[];};
  this.child.on('error',ended);this.child.on('exit',ended);
 }
 call(value){return new Promise((resolve,reject)=>{if(this.closed)return reject(invalid(503,'engine_unavailable'));const timer=setTimeout(()=>this.child.kill(),10000);this.queue.push({resolve,reject,timer});this.child.stdin.write(JSON.stringify(value)+'\n');});}
 close(){this.child.kill();}
}
export function createServer(engine=new Engine()){
 const rooms=new Map(),limits=new Map();let accepting=true;
 const maintenance=setInterval(()=>{const now=Date.now();for(const[k,v]of limits)if(v.until<now)limits.delete(k);for(const[k,r]of rooms)if(r.updated<now-30*60000||r.created<now-4*3600000)rooms.delete(k);},30000);maintenance.unref();
 async function json(req){let size=0;const chunks=[];for await(const c of req){size+=c.length;if(size>4096)throw invalid(413,'too_large');chunks.push(c);}try{return JSON.parse(Buffer.concat(chunks).toString()||'{}');}catch{throw invalid(400,'invalid_json');}}
 const cleanName=n=>typeof n==='string'?n.replace(/[\x00-\x1f\x7f]/g,'').trim().slice(0,24):'';
 const auth=(r,header)=>{const token=/^Bearer ([A-Za-z0-9_-]{43})$/.exec(header||'')?.[1];if(!token)throw invalid(401,'unauthorized');const seat=r.seats.findIndex(s=>s&&timingSafeEqual(Buffer.from(s.token),Buffer.from(token)));if(seat<0)throw invalid(401,'unauthorized');return seat;};
 async function snapshot(r,seat){let game=null;if(r.state){const reply=await engine.call({op:'view',state:r.state,seat});if(!reply.ok)throw invalid(503,'engine_unavailable');game=reply.view;}return{code:r.code,revision:r.revision,seat,started:!!r.state,host:seat===0,players:r.seats.map((s,i)=>({seat:i,name:s?.name||'',ready:s?.ready||false})),game};}
 const server=httpServer(async(req,res)=>{
  const send=(status,body)=>{res.writeHead(status,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});res.end(JSON.stringify(body));};
  try{
   const url=new URL(req.url,'http://localhost');
   if(req.method==='GET'&&url.pathname==='/health'){if(engine.closed)throw invalid(503,'engine_unavailable');return send(200,{ok:true,service:'Baloot online rooms',protocol:1,authoritativeEngine:'BalootEngine',voice:false,accounts:false});}
   if(!accepting)throw invalid(503,'shutting_down');
   if(req.method==='GET'&&url.pathname==='/'){res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});return res.end('<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8"><title>بلوت | خدمة الغرف</title><h1>خادم غرف البلوت</h1><p>خدمة مباريات لأربعة لاعبين بمحرك البلوت الأصلي والتحقق من الأدوار وحجب أوراق الخصوم</p><p>الدخول من واجهة اللعب عبر الإنترنت في بناء التطبيق الداعم لهذه الخدمة</p></html>');}
   const ip=req.socket.remoteAddress||'unknown',now=Date.now();let lim=limits.get(ip);if(!lim||lim.until<now){if(limits.size>=5000)throw invalid(503,'busy');lim={n:0,creates:0,until:now+60000};limits.set(ip,lim);}if(++lim.n>1000)throw invalid(429,'rate_limited');
   if(req.method==='POST'&&url.pathname==='/v1/rooms'){
    if(++lim.creates>8||rooms.size>=100)throw invalid(429,'room_limit');const b=await json(req),name=cleanName(b.name);if(!name)throw invalid(400,'invalid_name');
    let code;do{code=randomBytes(5).toString('hex').slice(0,8).toUpperCase();}while(rooms.has(code));const token=randomBytes(32).toString('base64url');
    const r={code,seats:[{name,token,ready:false},null,null,null],revision:0,state:null,created:now,updated:now,queue:Promise.resolve()};rooms.set(code,r);return send(201,{token,...await snapshot(r,0)});
   }
   const match=/^\/v1\/rooms\/([A-F0-9]{8})(?:\/(join|ready|start|action|next|leave))?$/.exec(url.pathname);if(!match)throw invalid(404,'not_found');
   const room=rooms.get(match[1]);if(!room)throw invalid(404,'room_not_found');const op=match[2];
   // Serialize each room: a revision is checked inside its transaction, not before waiting.
   const previous=room.queue;let unlock;room.queue=new Promise(r=>{unlock=r;});await previous;
   try{
    if(rooms.get(room.code)!==room)throw invalid(410,'room_closed');room.updated=Date.now();
    if(req.method==='POST'&&op==='join'){
     if(room.state)throw invalid(409,'match_started');const b=await json(req),name=cleanName(b.name);if(!name)throw invalid(400,'invalid_name');const seat=room.seats.indexOf(null);if(seat<0)throw invalid(409,'room_full');
     const token=randomBytes(32).toString('base64url');room.seats[seat]={name,token,ready:false};room.revision++;return send(200,{token,...await snapshot(room,seat)});
    }
    const seat=auth(room,req.headers.authorization);
    if(req.method==='GET'&&!op)return send(200,await snapshot(room,seat));
    if(req.method!=='POST')throw invalid(405,'method_not_allowed');const b=await json(req);
    if(op==='ready'){
     if(room.state||typeof b.ready!=='boolean')throw invalid(400,'invalid_state');room.seats[seat].ready=b.ready;
    }else if(op==='start'){
     if(seat!==0)throw invalid(403,'host_only');if(room.state||room.seats.some(s=>!s?.ready))throw invalid(409,'not_ready');
     const r=await engine.call({op:'new',names:room.seats.map(s=>s.name),seat});if(!r.ok)throw invalid(503,'engine_unavailable');room.state=r.state;
    }else if(op==='action'){
     if(!room.state)throw invalid(409,'not_started');if(b.revision!==room.revision)throw invalid(409,'stale_revision');if(!Number.isInteger(b.index)||b.index<0||b.index>100)throw invalid(400,'invalid_action');
     const r=await engine.call({op:'apply',state:room.state,seat,index:b.index});if(!r.ok)throw invalid(400,'illegal_action');room.state=r.state;
    }else if(op==='next'){
     if(seat!==0)throw invalid(403,'host_only');if(!room.state||b.revision!==room.revision)throw invalid(409,'stale_revision');
     const r=await engine.call({op:'next',state:room.state,seat});if(!r.ok)throw invalid(400,'round_not_finished');room.state=r.state;
    }else if(op==='leave'){
     if(seat===0||room.state){rooms.delete(room.code);return send(200,{closed:true});}room.seats[seat]=null;
    }else throw invalid(404,'not_found');
    room.revision++;return send(200,await snapshot(room,seat));
   }finally{unlock();}
  }catch(error){return send(error.status||500,{error:error.code||'internal_error'});}
 });
 server.headersTimeout=10000;server.requestTimeout=15000;
 server.on('close',()=>{accepting=false;clearInterval(maintenance);engine.close();});
 return server;
}
if(process.argv[1]===fileURLToPath(import.meta.url)){const server=createServer();server.listen(Number(process.env.PORT||8080),'0.0.0.0');process.on('SIGTERM',()=>server.close(()=>process.exit(0)));}
