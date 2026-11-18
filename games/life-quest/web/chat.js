/* Native mobile text input sits above the Godot canvas. Credentials never enter public source. */
(() => {
'use strict';
const $=id=>document.getElementById(id);
const escapeSave=(key,value)=>{try{sessionStorage.setItem(key,value)}catch{}};
const recall=key=>{try{return sessionStorage.getItem(key)||''}catch{return ''}};
let endpoint=recall('kalyana-api'),key=recall('kalyana-code');
const fragment=new URLSearchParams(location.hash.slice(1));
if(fragment.has('api')&&fragment.has('key')){
 endpoint=fragment.get('api');key=fragment.get('key');escapeSave('kalyana-api',endpoint);escapeSave('kalyana-code',key);
 history.replaceState(null,'',location.pathname+location.search);
}
const section=document.createElement('section');section.id='character-chat';section.hidden=true;section.setAttribute('aria-label','Qwen character conversation');
section.innerHTML=`<div class="chat-window"><header class="chat-head"><div class="chat-reel" id="chat-reel"></div><div class="chat-identity"><div id="chat-avatar" aria-hidden="true">S</div><div><h2 id="chat-name"></h2><p id="chat-model">Qwen on your PC · typed conversation</p></div><button class="chat-connect" id="chat-connect">Connect PC</button></div><div class="chat-trust"><span id="chat-trust"></span><progress id="chat-trust-bar" max="100"></progress></div></header><div class="chat-messages" id="chat-messages" role="log" aria-live="polite" aria-relevant="additions"></div><footer class="chat-compose"><p id="chat-hint"></p><div id="chat-status" role="status"></div><form id="chat-form"><label for="chat-input">Your reply</label><div class="chat-input-row"><textarea id="chat-input" rows="2" maxlength="500" placeholder="Type naturally… Tamil, Tanglish or English" autocomplete="off" enterkeyhint="send"></textarea><button type="submit" id="chat-send">Send ↗</button></div></form><button id="chat-return" class="chat-return" disabled>Back to the scene →</button><button type="button" id="chat-skip" class="chat-return">Skip conversation · keep playing →</button><p class="chat-privacy">Real Qwen replies on your PC. No voice recording or conversation logs.</p></footer></div>`;
document.body.append(section);
const connection=document.createElement('section');connection.id='qwen-connection';connection.hidden=true;connection.setAttribute('role','dialog');connection.setAttribute('aria-modal','true');connection.setAttribute('aria-label','Connect Qwen on your PC');
connection.innerHTML=`<form id="qwen-form" class="connection-card"><span class="connection-tag">YOUR PC IS THE CHARACTER ENGINE</span><h2>Connect to Qwen</h2><p>Open the private phone link created by <strong>Start-Phone-Chat.ps1</strong> on your PC, or paste the details below.</p><label for="qwen-url">PC HTTPS relay address</label><input id="qwen-url" type="url" placeholder="https://…trycloudflare.com" required autocapitalize="off" spellcheck="false"><label for="qwen-key">Private access code</label><input id="qwen-key" type="password" required autocomplete="off"><p class="connection-note">Keep your PC, Ollama and the relay on. The access code stays in this browser tab and is never published to GitHub.</p><p id="qwen-status" role="status"></p><button type="submit" id="qwen-test">Connect & check model</button><button type="button" id="qwen-cancel">Back</button></form>`;
document.body.append(connection);
let current=null,busy=false,turns=0,phaseGain=0,abort,generation=0;
function callback(data){if(typeof window.kalyanaGameEvent==='function')window.kalyanaGameEvent(JSON.stringify({id:current?.id,...data}))}
function bubble(role,text){const el=document.createElement('div');el.className='chat-bubble '+role;const name=document.createElement('span');name.className='bubble-name';name.textContent=role==='user'?'YOU':current.actor;const body=document.createElement('div');body.textContent=text;el.append(name,body);$('chat-messages').append(el);$('chat-messages').scrollTop=$('chat-messages').scrollHeight}
function trust(){ $('chat-trust').textContent=`TRUST ${current.approval} / 72 TO CLEAR`; $('chat-trust-bar').value=current.approval}
function controls(){ $('chat-send').disabled=busy; $('chat-input').disabled=busy; $('chat-connect').disabled=busy; $('chat-return').disabled=busy||(turns===0&&!current?.chat_only); $('chat-send').textContent=busy?'…':'Send ↗'; }
function validEndpoint(value){const u=new URL(value);if(u.username||u.password||u.search||u.hash)throw Error('Use only the relay origin, without a username, path or query.');if(u.protocol!=='https:'&&!((u.hostname==='localhost'||u.hostname==='127.0.0.1')&&u.protocol==='http:'))throw Error('The phone connection needs an HTTPS relay address.');return u.origin}
function skip(reason='Conversation skipped'){
 if(!current)return;
 const id=current.id;window.kalyanaChat.hide();callback({id,kind:'skip',reason});
}
async function checkAvailability(){
 const ticket=generation;
 if(!endpoint||!key){queueMicrotask(()=>{if(ticket===generation)skip('Qwen is not connected')});return}
 busy=true;controls();$('chat-status').textContent='Checking Qwen on your PC…';
 const controller=new AbortController();abort=controller;const timer=setTimeout(()=>controller.abort(),4000);
 try{
  const response=await fetch(endpoint+'/api/health',{headers:{Authorization:'Bearer '+key},signal:controller.signal});
  const data=await response.json();if(ticket!==generation)return;
  if(!response.ok||!data.ready)throw Error('Qwen is unavailable');
  $('chat-status').textContent='Your words. Their response. Take your time.';
 }catch(e){if(ticket===generation)skip('Qwen is unavailable')}
 finally{clearTimeout(timer);if(ticket===generation){busy=false;controls()}}
}
function openConnection(){ $('qwen-url').value=endpoint;$('qwen-key').value=key;$('qwen-status').textContent='';connection.hidden=false }
window.kalyanaChat={
 open(data){if(current&&current.id===data.id&&!section.hidden)return;abort?.abort();generation++;current=structuredClone(data);turns=data.turns||0;phaseGain=0;busy=false;$('chat-name').textContent=data.actor;$('chat-avatar').textContent=data.actor[0];$('chat-avatar').classList.toggle('sharmila',data.actor==='Sharmila');$('chat-reel').textContent=`ACT ${String(data.stage+1).padStart(2,'0')} / 05  ·  CONVERSATION ${data.phase+1} / 3`;$('chat-hint').textContent=data.hint;$('chat-messages').replaceChildren();for(const message of data.messages)bubble(message.role==='user'?'user':'assistant',message.content);$('chat-return').textContent=data.chat_only?'Back to title →':'Back to the scene →';$('chat-input').value='';$('chat-status').textContent=endpoint&&key?'Your words. Their response. Take your time.':'Connect your PC to talk to the Qwen character.';trust();controls();section.hidden=false;document.getElementById('fullscreen').hidden=true;checkAvailability();},
 hide(){generation++;abort?.abort();busy=false;$('chat-status').classList.remove('thinking');section.hidden=true;connection.hidden=true;current=null;document.getElementById('fullscreen').hidden=false;document.getElementById('canvas').focus()},
 connect:openConnection
};
$('chat-skip').addEventListener('click',()=>skip());
$('chat-connect').addEventListener('click',openConnection);
$('qwen-cancel').addEventListener('click',()=>connection.hidden=true);
$('qwen-form').addEventListener('submit',async event=>{
 event.preventDefault();let address;try{address=validEndpoint($('qwen-url').value.trim())}catch(e){$('qwen-status').textContent=e.message;return}
 const code=$('qwen-key').value.trim();$('qwen-test').disabled=true;$('qwen-status').textContent='Checking your PC and Qwen model…';
 try{const response=await fetch(address+'/api/health',{headers:{Authorization:'Bearer '+code},signal:AbortSignal.timeout(12000)});const data=await response.json();if(!response.ok||!data.ready)throw Error(data.error||'Qwen is not ready on the PC.');endpoint=address;key=code;escapeSave('kalyana-api',endpoint);escapeSave('kalyana-code',key);$('qwen-status').textContent='Connected: '+data.model;$('chat-model').textContent=data.model+' · running on your PC';$('chat-status').textContent='Connected to Qwen. Type a message to begin.';connection.hidden=true}catch(e){$('qwen-status').textContent=e.name==='TimeoutError'?'The PC did not answer. Check the relay and try again.':e.message}finally{$('qwen-test').disabled=false}
});
$('chat-form').addEventListener('submit',async event=>{
 event.preventDefault();if(busy||!current)return;
 const text=$('chat-input').value.trim();if(text.length<2){$('chat-status').textContent='Write a message first.';return}
 if(!endpoint||!key){skip('Qwen is not connected');return}
 busy=true;controls();$('chat-status').classList.add('thinking');$('chat-status').textContent=current.actor+' is thinking with Qwen…';
 const ticket=generation,scene=structuredClone(current),controller=new AbortController();abort=controller;const timer=setTimeout(()=>controller.abort(),85000);
 try{
 const response=await fetch(endpoint+'/api/chat',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+key},body:JSON.stringify({stage:scene.stage,phase:scene.phase,approval:scene.approval,text,history:scene.messages.slice(-8)}),signal:controller.signal});
 const data=await response.json();if(ticket!==generation)return;if(!response.ok)throw Error(data.error||'The PC could not complete the reply.');if(data.source!=='qwen'||typeof data.reply!=='string'||!data.reply.trim()||!Number.isInteger(data.approval_delta))throw Error('The PC returned an invalid Qwen reply.');
 bubble('user',text);bubble('assistant',data.reply);current.messages.push({role:'user',content:text},{role:'assistant',content:data.reply});current.messages=current.messages.slice(-12);turns++;
 const raw=Math.max(-15,Math.min(30,data.approval_delta));const gain=raw>0?Math.min(raw,Math.max(0,36-phaseGain)):raw;phaseGain+=Math.max(0,gain);current.approval=Math.max(0,Math.min(100,current.approval+gain));trust();$('chat-input').value='';
 $('chat-status').textContent=`${gain>=0?'+':''}${gain} trust · ${data.emotion} · ${data.model} · ${data.seconds}s`;$('chat-model').textContent=data.model+' · running on your PC';callback({...data,kind:'reply',user_text:text,id:scene.id});
 }catch(e){if(ticket===generation)skip('Qwen connection lost')}
 finally{clearTimeout(timer);if(ticket===generation){busy=false;$('chat-status').classList.remove('thinking');controls()}}
});
$('chat-input').addEventListener('keydown',e=>{if(e.key==='Enter'&&!e.shiftKey&&!e.isComposing){e.preventDefault();$('chat-form').requestSubmit()}});
$('chat-return').addEventListener('click',()=>{if(!busy&&(turns>0||current?.chat_only))callback({kind:'continue'})});
// Follow the visual viewport while the phone keyboard is open. The textarea stays mounted.
function keyboardHeight(){const height=window.visualViewport?.height||innerHeight;section.style.height=height+'px';connection.style.height=height+'px'}
window.visualViewport?.addEventListener('resize',keyboardHeight);window.addEventListener('resize',keyboardHeight);keyboardHeight();
})();
