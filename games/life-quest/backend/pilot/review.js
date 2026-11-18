/* Served only by the loopback pilot. Nothing is saved unless the tester submits. */
(() => {
  'use strict';
  const launcher = document.createElement('button');
  launcher.textContent = 'Adult tester pilot';
  launcher.style.cssText = 'position:fixed;bottom:4px;left:6px;z-index:40;padding:7px;background:#203936;color:#f6e9cf;border:1px solid #b6a476;border-radius:7px';
  document.body.append(launcher);
  const panel = document.createElement('dialog');
  panel.style.cssText = 'max-width:min(640px,92vw);max-height:90dvh;overflow:auto;padding:22px;background:#f7eedc;color:#203936;border:2px solid #203936;border-radius:16px;font:16px system-ui';
  document.body.append(panel);
  let token = '', terms = null;
  function field(type, text) {
    const element = document.createElement(type);
    if (text) element.textContent = text;
    panel.append(element);
    return element;
  }
  function button(text, handler) {
    const b = field('button', text);
    b.type = 'button';
    b.style.margin = '8px 8px 0 0';
    b.onclick = handler;
    return b;
  }
  async function post(path, body, code=token) {
    const response = await fetch('/pilot/'+path,{
      method:'POST', headers:{'Content-Type':'application/json','Authorization':'Bearer '+code},
      body:JSON.stringify(body)
    });
    const data = await response.json();
    if (!response.ok) throw Error(data.error);
    return data;
  }
  launcher.onclick = () => {
    panel.replaceChildren();
    field('h2', 'Adult tester pilot');
    field('p', 'Optional. You can play free of contribution. This local session uses an operator-issued invitation.');
    const key = field('input');
    key.type = 'password';
    key.placeholder = 'Adult tester invitation code';
    key.autocomplete = 'off';
    if (token) field('p', 'This tab is enrolled. Only transcripts you explicitly submit are stored.');
    const message = field('p');
    button('Enroll for this tab', async () => {
      try {
        const active = key.value.trim();
        terms = await post('enroll', {}, active);
        token = active;
        launcher.textContent = 'Adult pilot enrolled';
        panel.close();
      } catch (error) { message.textContent = error.message; }
    });
    button('Withdraw a contribution', async () => {
      const receipt = window.prompt('Paste the contribution receipt');
      if (!receipt) return;
      try { message.textContent = (await post('withdraw',{receipt},key.value.trim()||token)).message; }
      catch (error) { message.textContent = error.message; }
    });
    button('Close', () => panel.close());
    panel.showModal();
  };
  window.schoolPilot = {
    review(scene) {
      if (!terms || !token || panel.open || !scene.school || !scene.messages.some(m=>m.role==='user')) return;
      panel.replaceChildren();
      field('h2', 'Review optional training contribution');
      field('p','Edit the fictional conversation to remove personal information. Discarding it has no effect on the game.');
      const inputs = scene.messages.map(turn => {
        const label = field('label',turn.role==='user'?'Tester':'Sundaram');
        label.style.display = 'block';
        const area = document.createElement('textarea');
        area.value = turn.content;
        area.maxLength = 1200;
        area.rows = 2;
        area.style.cssText = 'display:block;width:100%;margin-bottom:9px';
        label.append(area);
        return {role:turn.role,area};
      });
      field('p','Conversation language');
      const language = field('select');
      for (const [value,label] of [['','Select language'],['ta','Tamil'],['ta-Latn','Tanglish'],['en','English']]) {
        language.add(new Option(label,value));
      }
      const label = field('label');
      label.style.display = 'block';
      const agreed = document.createElement('input');
      agreed.type = 'checkbox';
      label.append(agreed, terms.notice);
      const status = field('p');
      const submit = button('Submit reviewed transcript', async () => {
        if (!agreed.checked || !language.value) {
          status.textContent = 'Select a language and confirm the consent to submit.';
          return;
        }
        submit.disabled = true;
        try {
          const data = await post('submit',{
            level:scene.school.level, outcome:scene.school.outcome, language:language.value,
            agreed:true, version:terms.version,
            turns:inputs.map(({role,area})=>({role,content:area.value}))
          });
          panel.replaceChildren();
          field('p','Submitted for review. Keep this receipt to withdraw: '+data.receipt);
          button('Back to the game',()=>panel.close());
        } catch (error) {
          status.textContent = error.message;
          submit.disabled = false;
        }
      });
      button('Discard',()=>{panel.close();panel.replaceChildren()});
      panel.addEventListener('close',()=>{
        panel.replaceChildren();
        document.querySelector('#canvas')?.focus();
      },{once:true});
      panel.showModal();
    }
  };
})();
