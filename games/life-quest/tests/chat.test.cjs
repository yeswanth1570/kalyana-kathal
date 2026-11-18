const test=require('node:test');
const assert=require('node:assert/strict');
const vm=require('node:vm');
const fs=require('node:fs');
const source=fs.readFileSync(require('node:path').join(__dirname,'../web/chat.js'),'utf8');
// Exercise the shipped DOM script with real promises and controlled network replies.
function harness(fetch,paired=true){
 const elements=new Map(),events=[],timers=new Map();let timerId=0;
 function element(id=''){
  const handlers={};const el={id,hidden:false,disabled:false,value:'',style:{},children:[],classList:{add(){},remove(){},toggle(){}},setAttribute(){},focus(){},append(...children){this.children.push(...children)},replaceChildren(){this.children=[]},addEventListener(kind,fn){handlers[kind]=fn},async dispatch(kind){return handlers[kind]?.({preventDefault(){}})}};
  return el;
 }
 const $=id=>{if(!elements.has(id))elements.set(id,element(id));return elements.get(id)};
 const document={getElementById:$,createElement:()=>element(),body:{append(el){elements.set(el.id,el)}}};
 const values=new Map(paired?[['kalyana-api','https://pc.example'],['kalyana-code','private-test-code']]:[]);
 const window={kalyanaGameEvent:data=>events.push(JSON.parse(data)),addEventListener(){}};
 const context={window,document,sessionStorage:{getItem:k=>values.get(k),setItem:(k,v)=>values.set(k,v)},location:{hash:'',pathname:'/',search:''},history:{replaceState(){}},URL,URLSearchParams,structuredClone,AbortController,AbortSignal,queueMicrotask,innerHeight:800,fetch,setTimeout(fn,delay){const id=++timerId;timers.set(id,{fn,delay});return id},clearTimeout:id=>timers.delete(id)};
 vm.runInNewContext(source,context);
 return {api:window.kalyanaChat,$,events,timers,open(id=1){window.kalyanaChat.open({id,actor:'Sharmila',stage:1,phase:0,approval:20,hint:'Listen.',messages:[],turns:0})}};
}
const ready={ok:true,json:async()=>({ready:true,model:'qwen'})};
const reply={ok:true,json:async()=>({source:'qwen',reply:'Let us plan together.',approval_delta:30,emotion:'warm',model:'qwen',seconds:1})};
const flush=async()=>{for(let i=0;i<8;i++)await Promise.resolve()};
test('No pairing skips immediately and keeps credentials out of callback',async()=>{
 const h=harness(()=>assert.fail('No fetch expected'),false);h.open();await flush();
 assert.equal(h.events[0].kind,'skip');assert.equal(h.events[0].id,1);assert.equal(h.$('character-chat').hidden,true);assert(!JSON.stringify(h.events).includes('private-test-code'));
});
test('Unreachable PC and model-not-ready both skip',async()=>{
 for(const fetch of [async()=>{throw Error('offline')},async()=>({ok:true,json:async()=>({ready:false})})]){
  const h=harness(fetch);h.open();await flush();assert.equal(h.events[0].kind,'skip');
 }
});
test('Health check has a four-second deadline and aborts when skipped',async()=>{
 let signal;const h=harness((_url,opts)=>new Promise((resolve,reject)=>{signal=opts.signal;signal.addEventListener('abort',()=>reject(Error('timeout')))}));h.open();
 const deadline=[...h.timers.values()][0];assert.equal(deadline.delay,4000);deadline.fn();await flush();assert(signal.aborted);assert.equal(h.events[0].kind,'skip');
});
test('Ready model accepts manual text and continue after a real reply',async()=>{
 let sent;const h=harness(async(url,opts)=>{if(url.endsWith('health'))return ready;sent=JSON.parse(opts.body);return reply});
 h.open();await flush();assert.equal(h.$('chat-send').disabled,false);assert.equal(h.$('chat-return').disabled,true);
 h.$('chat-input').value='Sharmila, let us plan the festival.';await h.$('chat-form').dispatch('submit');
 assert.equal(sent.text,'Sharmila, let us plan the festival.');assert.equal(h.events[0].kind,'reply');assert.equal(h.events[0].id,1);assert.equal(h.$('chat-return').disabled,false);
 await h.$('chat-return').dispatch('click');assert.equal(h.events[1].kind,'continue');
});
test('Connection loss during generation skips instead of trapping player',async()=>{
 const h=harness(async url=>{if(url.endsWith('health'))return ready;throw Error('relay lost')});h.open();await flush();h.$('chat-input').value='Hello Sharmila';await h.$('chat-form').dispatch('submit');assert.equal(h.events[0].kind,'skip');
});
test('Manual skip aborts generation; its late reply cannot enter next conversation',async()=>{
 let resolveChat,chatSignal;const h=harness(async(url,opts)=>{if(url.endsWith('health'))return ready;chatSignal=opts.signal;return new Promise(resolve=>resolveChat=resolve)});
 h.open();await flush();h.$('chat-input').value='Hello Sharmila';const pending=h.$('chat-form').dispatch('submit');await flush();await h.$('chat-skip').dispatch('click');
 assert(chatSignal.aborted);h.open(2);await flush();resolveChat(reply);await pending;assert.deepEqual(h.events.map(e=>e.kind),['skip']);assert.equal(h.$('chat-send').disabled,false);
});
test('Closing a health check ignores its stale failure after reopening',async()=>{
 let rejectFirst;let count=0;const h=harness(()=>++count===1?new Promise((_,reject)=>rejectFirst=reject):Promise.resolve(ready));h.open();h.api.hide();h.open(2);await flush();rejectFirst(Error('old network failure'));await flush();assert.equal(h.events.length,0);assert.equal(h.$('character-chat').hidden,false);
});
