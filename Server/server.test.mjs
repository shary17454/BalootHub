import test from 'node:test';
import assert from 'node:assert/strict';
import {once} from 'node:events';
import {createServer,Engine} from './server.mjs';
const server=process.env.BALOOT_TEST_BASE?null:createServer(new Engine());
if(server){server.listen(0,'127.0.0.1');await once(server,'listening');}
const base=process.env.BALOOT_TEST_BASE||`http://127.0.0.1:${server.address().port}`;
test.after(async()=>{if(server)await new Promise(r=>server.close(r));});
async function call(path,body,token){const res=await fetch(base+path,{method:body===undefined?'GET':'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:body===undefined?undefined:JSON.stringify(body)});return{status:res.status,...await res.json()};}
let code,clients=[];
test('creates a private room with opaque session and hides it from unauthenticated readers',async()=>{
 const h=await call('/v1/rooms',{name:'مضيف'});assert.equal(h.status,201);assert.match(h.code,/^[A-F0-9]{8}$/);assert.match(h.token,/^[A-Za-z0-9_-]{43}$/);code=h.code;clients.push(h);
 assert.equal((await call('/v1/rooms/'+code)).status,401);
});
test('joins four distinct seats and rejects an extra player',async()=>{
 for(let i=1;i<4;i++){const c=await call(`/v1/rooms/${code}/join`,{name:'لاعب '+i});assert.equal(c.status,200);assert.equal(c.seat,i);clients.push(c);}
 assert.equal(new Set(clients.map(c=>c.token)).size,4);
 assert.equal((await call(`/v1/rooms/${code}/join`,{name:'خامس'})).status,409);
});
test('only the host can start and everyone must explicitly be ready',async()=>{
 assert.equal((await call(`/v1/rooms/${code}/start`,{},clients[1].token)).status,403);
 assert.equal((await call(`/v1/rooms/${code}/start`,{},clients[0].token)).status,409);
 for(const c of clients)assert.equal((await call(`/v1/rooms/${code}/ready`,{ready:true},c.token)).status,200);
 const start=await call(`/v1/rooms/${code}/start`,{},clients[0].token);assert.equal(start.status,200);assert.equal(start.game.phase,'bidding');
});
test('each client receives only their own hand and no seed/deck/other hands',async()=>{
 const views=await Promise.all(clients.map(c=>call(`/v1/rooms/${code}`,undefined,c.token)));
 assert.ok(views.every(v=>v.game.hand.length===5));
 for(let i=0;i<4;i++){
  const json=JSON.stringify(views[i]);for(const forbidden of ['originalHands','undealtCards','actionHistory','"state"','"seed"'])assert.ok(!json.includes(forbidden));
  for(let j=0;j<4;j++)if(j!==i)for(const card of views[j].game.hand)assert.ok(!json.includes(card.id));
 }
});
test('wrong-turn and stale-revision actions are rejected without changing state',async()=>{
 const host=await call(`/v1/rooms/${code}`,undefined,clients[0].token),turn=host.game.players.find(p=>p.id===host.game.turnPlayerID).seat;
 const wrong=clients[(turn+1)%4];assert.equal((await call(`/v1/rooms/${code}/action`,{revision:host.revision,index:0},wrong.token)).status,400);
 const who=clients[turn];assert.equal((await call(`/v1/rooms/${code}/action`,{revision:host.revision-1,index:0},who.token)).status,409);
 assert.equal((await call(`/v1/rooms/${code}`,undefined,who.token)).revision,host.revision);
});
test('four real HTTP clients play bidding, declarations and all eight tricks through the original engine',async()=>{
 let played=0;let state=await call(`/v1/rooms/${code}`,undefined,clients[0].token);
 for(let step=0;step<100&&state.game.phase!=='finished';step++){
  const seat=state.game.players.find(p=>p.id===state.game.turnPlayerID)?.seat;assert.ok(Number.isInteger(seat));
  const c=clients[seat],view=await call(`/v1/rooms/${code}`,undefined,c.token);assert.ok(view.game.actions.length);
  let action=view.game.actions[0];
  if(view.game.phase==='bidding')action=view.game.actions.find(a=>a.label.includes('صن'))||view.game.actions.find(a=>a.label.includes('بس')||a.label.includes('قفل'))||action;
  if(view.game.phase==='playing')played++;
  state=await call(`/v1/rooms/${code}/action`,{revision:view.revision,index:action.id},c.token);assert.equal(state.status,200);
 }
 assert.equal(state.game.phase,'finished');assert.equal(state.game.completedTricks,8);assert.equal(played,32);assert.ok(state.game.result);
 const results=await Promise.all(clients.map(c=>call(`/v1/rooms/${code}`,undefined,c.token)));
 for(const r of results)assert.deepEqual(r.game.result,state.game.result);
});
test('reconnecting with a retained session restores the same seat and result',async()=>{
 const a=await call(`/v1/rooms/${code}`,undefined,clients[2].token),b=await call(`/v1/rooms/${code}`,undefined,clients[2].token);assert.equal(b.seat,2);assert.deepEqual(a.game.result,b.game.result);
});
test('an old session cannot impersonate another room and a guest cannot advance rounds',async()=>{
 assert.equal((await call(`/v1/rooms/${code}/next`,{},clients[1].token)).status,403);
 assert.equal((await call(`/v1/rooms/${code}`,undefined,'A'.repeat(43))).status,401);
});
test('next-round requests require a current revision and host authority',async()=>{
 const v=await call(`/v1/rooms/${code}`,undefined,clients[0].token);
 assert.equal((await call(`/v1/rooms/${code}/next`,{revision:v.revision-1},clients[0].token)).status,409);
 const next=await call(`/v1/rooms/${code}/next`,{revision:v.revision},clients[0].token);assert.equal(next.status,200);assert.equal(next.game.phase,'bidding');
});
test('leaving a running game closes it for every session',async()=>{
 assert.equal((await call(`/v1/rooms/${code}/leave`,{},clients[0].token)).closed,true);
 assert.equal((await call(`/v1/rooms/${code}`,undefined,clients[1].token)).status,404);
});
