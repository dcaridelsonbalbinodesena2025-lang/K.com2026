<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Analisador Master - Final Pro</title>
    <style>
        :root { 
            --blue: #007aff; --red: #ff3b30; --green: #4cd964; --green-lemon: #ccff00; 
            --dark-green: #006400; --gold: #ffd700; --lilac: #b666d2; --dark: #000000; 
        }
        
        body, html { 
            margin: 0; padding: 0; width: 100%; height: 100%; 
            background-color: #b0b0b0; font-family: 'Segoe UI', sans-serif; 
            overflow: hidden; display: flex; justify-content: center;
        }

        .main-app {
            width: 90%; height: 98%; margin-top: 1%;
            display: flex; flex-direction: column; background: #000;
            border-radius: 15px; overflow: hidden; box-shadow: 0 5px 15px rgba(0,0,0,0.3);
            position: relative;
        }
        
        .display { height: 52%; background: #000; position: relative; display: flex; flex-direction: column; overflow: hidden; }
        
        #iframe-visor {
            position: absolute; top: 0; left: -100%; width: 100%; height: 100%;
            z-index: 100; background: white; transition: left 0.4s ease-in-out;
        }
        #iframe-visor.open { left: 0 !important; }
        
        .close-iframe-btn {
            position: absolute; top: 5px; right: 5px; z-index: 101;
            background: var(--red); color: white; border: none; padding: 8px 12px; border-radius: 4px; font-weight: bold;
        }

        #standby-screen { position: absolute; width: 100%; height: 100%; display: flex; flex-direction: column; justify-content: center; align-items: center; z-index: 20; }
        .visor-half { height: 50%; width: 100%; display: none; flex-direction: column; justify-content: center; align-items: center; }
        .res-balloon { 
            width: 95%; height: 92%; border-radius: 10px; display: flex; flex-direction: column; 
            justify-content: center; align-items: center; border: 2px solid rgba(255,255,255,0.1); 
            transition: all 0.3s; cursor: pointer; text-align: center;
        }
        .selected-res { border: 4px solid var(--gold) !important; transform: scale(0.98); box-shadow: 0 0 15px var(--gold); }

        .stats-badge { display: inline-block; padding: 1px 5px; border-radius: 3px; color: white; font-weight: bold; font-size: 0.7rem; margin: 1px; }
        .bg-jg { background-color: var(--blue); } .bg-gp { background-color: var(--dark-green); } .bg-gc { background-color: var(--red); }

        .neon-text { font-weight: 900; font-size: 2.8rem; animation: neon-pulse 1.5s infinite alternate; }
        @keyframes neon-pulse { from { text-shadow: 0 0 10px #fff, 0 0 20px var(--blue); } to { text-shadow: 0 0 15px #fff, 0 0 30px var(--blue); } }

        .corner-balloon {
            background: white; color: black; padding: 2px 10px;
            border-radius: 15px; font-size: 0.75rem; font-weight: 800;
            margin-top: 4px; box-shadow: 0 2px 5px rgba(0,0,0,0.3);
            display: inline-block;
        }

        .bible-bar { height: 35px; background: #111; font-size: 1.1rem; font-weight: 900; display: flex; align-items: center; overflow: hidden; white-space: nowrap; border-bottom: 1px solid #222; }
        .marquee { display: inline-block; padding-left: 100%; animation: scroll 60s linear infinite, colorChange 10s infinite alternate; }
        @keyframes scroll { 0% { transform: translateX(0); } 100% { transform: translateX(-100%); } }
        @keyframes colorChange { 0% { color: var(--gold); } 50% { color: var(--blue); } 100% { color: var(--green-lemon); } }

        .team-inputs { height: 35px; background: #111; display: flex; padding: 0; align-items: center; width: 100%; }
        .input-team { width: 50%; height: 100%; background: #222; border: 1px solid #333; color: white; border-radius: 0; text-align: center; font-size: 0.9rem; text-transform: uppercase; box-sizing: border-box; }

        .val-area { height: 40px; display: flex; justify-content: space-between; align-items: center; padding: 0 10px; background: #000; }
        .value-box { background: #151515; width: 30%; height: 32px; display: flex; justify-content: center; align-items: center; border-bottom: 2px solid #444; font-size: 1.4rem; font-weight: 900; }
        #c1, #c4 { color: var(--blue); } #c2, #c5 { color: var(--green-lemon); } #c3, #c6 { color: var(--red); }

        .keypad-area { flex: 1; display: grid; grid-template-columns: repeat(4, 1fr); gap: 3px; padding: 3px; background: #333; }
        button { border: none; background: #1a1a1a; color: white; font-weight: bold; cursor: pointer; font-size: 1.6rem; display: flex; align-items: center; justify-content: center; }
        button:disabled { opacity: 0.15; }
        .btn-compact { font-size: 0.8rem; text-transform: uppercase; }

        #history-screen { display: none; position: absolute; top: 0; left: 0; width: 100%; height: 100%; background: #000; z-index: 200; flex-direction: column; color: white; box-sizing: border-box; }
        .history-header { padding: 10px 10px 0 10px; flex-shrink: 0; background: #000; }
        #history-list { flex: 1; overflow-y: auto; padding: 0 10px 10px 10px; }
        .card { background: #111; border: 1px solid #333; border-radius: 8px; padding: 10px; margin-bottom: 10px; }
        .thermometer { height: 8px; background: #222; border-radius: 4px; margin: 3px 0; overflow: hidden; flex: 1; margin: 0 10px; }
        .thermometer-bar { height: 100%; background: var(--green); transition: width 0.5s; }
        .ticket-summary { display: flex; justify-content: space-around; background: #111; padding: 6px; border-radius: 6px; margin-bottom: 5px; border: 1px solid var(--gold); font-size: 0.8rem; }
        .strat-summary { background: #000; padding: 5px; border-radius: 6px; border: 1px solid #222; font-size: 0.75rem; margin-bottom: 8px; line-height: 1.4; }
        .btn-back-small { width: 100%; padding: 8px; background: var(--red); color: white; border-radius: 6px; border: none; font-weight: bold; font-size: 0.8rem; cursor: pointer; margin-bottom: 10px; }
        .calc-debug { font-size: 0.7rem; font-weight: bold; opacity: 0.8; margin-top: -2px; }

        .prob-line { font-family: monospace; font-size: 0.68rem; margin: 2px 0; }
        .v-lemon { color: var(--green-lemon) !important; font-weight: bold; }
        .v-yellow { color: #ffff00 !important; font-weight: bold; }
        .v-red { color: var(--red) !important; font-weight: bold; }
    </style>
</head>
<body>

    <div class="main-app">
        <div id="history-screen">
            <div class="history-header">
                <h4 style="color:var(--gold); text-align:center; margin: 5px 0;">📊 PAINEL DE CONTROLE</h4>
                <div id="ticket-stats" class="ticket-summary"></div>
                <div id="market-stats" style="margin-bottom: 8px;"></div>
                <div id="strat-stats" class="strat-summary"></div>
                <button class="btn-back-small" onclick="toggleHistory(false)">VOLTAR PARA CALCULADORA</button>
            </div>
            <div id="history-list"></div>
        </div>

        <div class="display">
            <div id="iframe-visor">
                <button class="close-iframe-btn" onclick="toggleIframe(false)">X</button>
                <iframe src="https://www.sofascore.com/pt/" style="width:100%; height:100%; border:none;"></iframe>
            </div>
            <div id="standby-screen">
                <div class="neon-text" style="color:var(--blue);">K.C⚽️M</div>
                <div style="color:#fff; font-size:0.9rem;">ARIDELSON B. MASTER</div>
            </div>
            
            <div class="visor-half top-half" id="box-top">
                <div class="res-balloon" id="bal-top" onclick="selectStrategy('K.C⚽️M')">
                    <div id="miniA"></div>
                    <span class="neon-text" id="title-top" style="font-size:2.2rem">K.C⚽️M</span>
                    <span id="res-top" style="font-weight:900; font-size:1.8rem"></span>
                    <div id="debug-top" class="calc-debug"></div>
                    <div id="corn-top" class="corner-balloon"></div>
                </div>
            </div>
            <div class="visor-half" id="box-btm">
                <div class="res-balloon" id="bal-btm" onclick="selectStrategy('R⚽️3')">
                    <div id="miniB"></div>
                    <span class="neon-text" id="title-btm" style="font-size:2.2rem">R⚽️3</span>
                    <span id="res-btm" style="font-weight:900; font-size:1.8rem"></span>
                    <div id="debug-btm" class="calc-debug"></div>
                    <div id="corn-btm" class="corner-balloon"></div>
                </div>
            </div>
        </div>

        <div class="bible-bar">
            <div class="marquee">
                "Tudo posso naquele que me fortalece" • "O Senhor é o meu pastor e nada me faltará" • Aridelson B. Master
            </div>
        </div>

        <div class="team-inputs">
            <input type="text" id="tA" class="input-team" placeholder="CASA" oninput="v()" onkeydown="if(event.key==='Enter'){document.getElementById('tB').focus();}">
            <input type="text" id="tB" class="input-team" placeholder="FORA" oninput="v()" onkeydown="if(event.key==='Enter'){this.blur(); n(0);}">
        </div>

        <div class="val-area">
            <div style="width:45%; display:flex; justify-content:space-between;"><div class="value-box" id="c1">--</div><div class="value-box" id="c2">--</div><div class="value-box" id="c3">--</div></div>
            <div style="color:#555; font-weight:bold">/</div>
            <div style="width:45%; display:flex; justify-content:space-between;"><div class="value-box" id="c4">--</div><div class="value-box" id="c5">--</div><div class="value-box" id="c6">--</div></div>
        </div>

        <div class="keypad-area">
            <button class="lockable" onclick="t('1')" disabled>1</button>
            <button class="lockable" onclick="t('2')" disabled>2</button>
            <button class="lockable" onclick="t('3')" disabled>3</button>
            <button class="btn-compact lockable" style="background:white !important; color:black" onclick="backspace()" disabled>CORRIGIR</button>
            
            <button class="lockable" onclick="t('4')" disabled>4</button>
            <button class="lockable" onclick="t('5')" disabled>5</button>
            <button class="lockable" onclick="t('6')" disabled>6</button>
            <button class="lockable" style="background:var(--green) !important; color:black" onclick="n(1)" disabled>&gt;</button>
            
            <button class="lockable" onclick="t('7')" disabled>7</button>
            <button class="lockable" onclick="t('8')" disabled>8</button>
            <button class="lockable" onclick="t('9')" disabled>9</button>
            
            <button class="lockable" style="background:var(--red) !important" onclick="n(-1)" disabled>&lt;</button>
            
            <button class="btn-compact lockable" style="background:var(--red) !important" onclick="cleanAll()" disabled>DELETE</button>
            <button class="lockable" onclick="t('0')" disabled>0</button>
            <button class="btn-compact lockable" style="background:var(--blue) !important" onclick="addGame()" disabled>ADD</button>
            <button class="btn-compact" style="background:var(--lilac) !important" onclick="finishTicket()">CONCLUIR</button>
            <button class="btn-compact" style="grid-column: span 2; background:var(--gold) !important; color:black" onclick="toggleIframe(true)">📊 FORZA</button>
            <button class="btn-compact" style="grid-column: span 2; background:#222 !important;" onclick="toggleHistory(true)">📜 HISTÓRICO</button>
        </div>
    </div>

    <script>
        let idx = 1, curTkt = [], allTkts = JSON.parse(localStorage.getItem('ari_master_v8')) || [];
        let selectedStrat = 'K.C⚽️M'; 
        let tempProb = null;

        function selectStrategy(s) { selectedStrat = s; document.getElementById('bal-top').classList.toggle('selected-res', s === 'K.C⚽️M'); document.getElementById('bal-btm').classList.toggle('selected-res', s === 'R⚽️3'); }
        function toggleIframe(show) { const iframe = document.getElementById('iframe-visor'); if(show) iframe.classList.add('open'); else iframe.classList.remove('open'); }
        
        function v() { 
            const a=document.getElementById('tA').value, b=document.getElementById('tB').value; 
            const isFilled = (a.trim() !== "" && b.trim() !== "");
            document.querySelectorAll('.lockable').forEach(x => x.disabled = !isFilled);
            if(isFilled && idx === 1) { document.getElementById('c1').style.background = '#252525'; }
        }

        function t(n) { let c=document.getElementById('c'+idx); c.innerText=(c.innerText==='--')?n:c.innerText+n; }
        function backspace() { let c = document.getElementById('c' + idx); if (c.innerText !== '--') { c.innerText = c.innerText.slice(0, -1); if (c.innerText === '') c.innerText = '--'; } else { n(-1); } }
        
        function n(d) { 
            idx=Math.max(1,Math.min(6,idx+d)); 
            document.querySelectorAll('.value-box').forEach(e=>e.style.background='#151515'); 
            document.getElementById('c'+idx).style.background='#252525'; 
            if(d===1 && idx===6) { toggleIframe(false); calc(); } 
        }

        function cleanAll() { document.getElementById('tA').value=""; document.getElementById('tB').value=""; v(); cleanCalc(); }
        function cleanCalc() { for(let i=1;i<=6;i++)document.getElementById('c'+i).innerText='--'; document.getElementById('box-top').style.display='none'; document.getElementById('box-btm').style.display='none'; idx=1; document.querySelectorAll('.value-box').forEach(e=>e.style.background='#151515'); document.getElementById('standby-screen').style.display='flex'; tempProb = null; }
        function abreviar(n) { if(!n) return ""; let p = n.trim().split(" "); return p[0].toUpperCase().substring(0, 5); }

        function calc() {
            const g=(i)=>parseFloat(document.getElementById('c'+i).innerText)||0;
            const jA=g(1), gpA=g(2), gcA=g(3), jB=g(4), gpB=g(5), gcB=g(6);
            if(jA>0 && jB>0){
                document.getElementById('standby-screen').style.display='none';
                document.getElementById('box-top').style.display='flex'; document.getElementById('box-btm').style.display='flex';
                document.getElementById('miniA').innerHTML=`<span class="stats-badge bg-jg">JG:${jA}</span><span class="stats-badge bg-gp">GP:${gpA}</span><span class="stats-badge bg-gc">GC:${gcA}</span>`;
                document.getElementById('miniB').innerHTML=`<span class="stats-badge bg-jg">JG:${jB}</span><span class="stats-badge bg-gp">GP:${gpB}</span><span class="stats-badge bg-gc">GC:${gcB}</span>`;
                
                let mA = gpA/jA, mCA = gcA/jA, mB = gpB/jB, mCB = gcB/jB;
                
                // AJUSTE: SUBTRAINDO 1 DE CADA TIME (TOTAL DIMINUI 2)
                let intensA = (mA + mCB) - 1; 
                let intensB = (mB + mCA) - 1; 
                if(intensA < 0) intensA = 0; if(intensB < 0) intensB = 0;

                let totalCorners = (intensA + intensB) + 5;
                let mediaGols = (gpA+gpB)/(jA+jB);

                let pWinA = Math.min(95, Math.max(5, (intensA / (intensA + intensB + 0.5)) * 100));
                let pWinB = Math.min(95, Math.max(5, (intensB / (intensA + intensB + 0.5)) * 100));
                let pDraw = 100 - pWinA - pWinB;
                let pAmbasS = Math.min(95, ( (mA+mB)/(mA+mB+mCA+mCB) ) * 100 + 15);
                
                tempProb = {
                    v: [pWinA.toFixed(0), pDraw.toFixed(0), pWinB.toFixed(0)],
                    dc: [(pWinA + pDraw).toFixed(0), (pWinA + pWinB).toFixed(0), (pWinB + pDraw).toFixed(0)],
                    am: [pAmbasS.toFixed(0), (100 - pAmbasS).toFixed(0)]
                };
                
                setR('bal-top','res-top','title-top', getL(mediaGols,'k'), getC(mediaGols,'k'));
                document.getElementById('debug-top').innerText = "Média Gols: " + mediaGols.toFixed(2);
                document.getElementById('corn-top').innerText = totalCorners.toFixed(1) + "🚩: " + (Math.floor(totalCorners)-0.5) + " Over Esc.";

                let fR = intensA + intensB;
                let cA = Math.round(intensA + 2.5);
                let cB = Math.round(intensB + 2.5);
                
                setR('bal-btm','res-btm','title-btm', getL(fR,'r'), getC(fR,'r'));
                document.getElementById('debug-btm').innerText = "Fator R⚽️3: " + fR.toFixed(2);
                document.getElementById('corn-btm').innerText = abreviar(document.getElementById('tA').value) + ": " + cA + "🚩 vs " + abreviar(document.getElementById('tB').value) + ": " + cB + "🚩";
                
                selectStrategy('K.C⚽️M'); 
            }
        }

        function getL(v,t) { if(t==='k') return v<2?"4.5 UN":v<=2.29?"0.5 OV":v<=3.29?"1.5 OV":"2.5 OV"; return v<4?"4.5 UN":v<=5.99?"0.5 OV":v<=7.99?"1.5 OV":"2.5 OV"; }
        function getC(v,t) { return v<(t==='k'?2:4)?"#ff3b30":"#4cd964"; }
        function setR(b,r,t,txt,c) { document.getElementById(b).style.background=c; document.getElementById(r).innerText=txt; let cl=c==="#4cd964"?"black":"white"; document.getElementById(r).style.color=cl; document.getElementById(t).style.color=cl; document.getElementById(b).querySelector('.calc-debug').style.color=cl;}
        
        function addGame() { 
            const resK = document.getElementById('res-top').innerText;
            const resR = document.getElementById('res-btm').innerText;
            if(!resK) return; 
            curTkt.push({ 
                t: document.getElementById('tA').value.toUpperCase()+" x "+document.getElementById('tB').value.toUpperCase(), 
                k: (selectedStrat === 'K.C⚽️M') ? resK : resR, 
                strat: selectedStrat, 
                escK: document.getElementById('corn-top').innerText, 
                escR: document.getElementById('corn-btm').innerText,
                prob: tempProb,
                s: 'pending' 
            }); 
            cleanAll(); toggleIframe(true); 
        }

        function finishTicket() { if(curTkt.length===0) return; allTkts.unshift({ id:Date.now(), games:curTkt, data:new Date().toLocaleString() }); localStorage.setItem('ari_master_v8', JSON.stringify(allTkts)); curTkt=[]; cleanAll(); toggleIframe(false); document.getElementById('standby-screen').style.display = 'flex'; }
        function toggleHistory(s) { document.getElementById('history-screen').style.display=s?'flex':'none'; if(s)renderH(); }
        
        function getClProb(val) { if(val >= 60) return 'v-lemon'; if(val >= 50) return 'v-yellow'; return 'v-red'; }
        function getClRank(val, arr) { let s = [...arr].sort((a,b)=>b-a); if(val == s[0]) return 'v-lemon'; if(val == s[1]) return 'v-yellow'; return 'v-red'; }

        function renderH() {
            const l=document.getElementById('history-list'), mStats=document.getElementById('market-stats'), tStats=document.getElementById('ticket-stats'), sStats=document.getElementById('strat-stats');
            l.innerHTML=""; mStats.innerHTML=""; sStats.innerHTML="";
            let markets = {"0.5 OV":{g:0,r:0}, "1.5 OV":{g:0,r:0}, "2.5 OV":{g:0,r:0}, "4.5 UN":{g:0,r:0}};
            let tGreen = 0, tRed = 0, sk_win=0, sk_loss=0, sr_win=0, sr_loss=0;
            
            allTkts.forEach((t,ti)=>{
                let isTicketRed = t.games.some(g => g.s === 'loss'), isTicketPending = t.games.some(g => g.s === 'pending');
                if(!isTicketPending) { if(isTicketRed) tRed++; else tGreen++; }
                let d=document.createElement('div'); d.className="card";
                d.innerHTML=`<div style="font-size:0.75rem; color:var(--gold); font-weight:bold; margin-bottom:5px">Bilhete ${allTkts.length-ti}; Data: ${t.data}</div>`;
                t.games.forEach((g,gi)=>{
                    if(markets[g.k]) { if(g.s==='win') markets[g.k].g++; if(g.s==='loss') markets[g.k].r++; }
                    if(g.strat === 'K.C⚽️M') { if(g.s==='win') sk_win++; if(g.s==='loss') sk_loss++; }
                    if(g.strat === 'R⚽️3') { if(g.s==='win') sr_win++; if(g.s==='loss') sr_loss++; }
                    
                    let p = g.prob || {v:[0,0,0], dc:[0,0,0], am:[0,0]};
                    let borderColor = g.s==='win'?'var(--green)':g.s==='loss'?'var(--red)':'#444';
                    
                    d.innerHTML+=`<div style="display:flex; flex-direction:column; margin-top:5px; border:1px solid ${borderColor}; padding:6px; border-radius:6px; background:#000">
                        <div style="display:flex; justify-content:space-between; align-items:center;">
                            <span style="font-size:0.8rem">
                                <b>${g.t}</b><br>
                                <span style="color:var(--green-lemon)">${g.k}</span> <span style="font-size:0.65rem; color:${g.strat === 'K.C⚽️M' ? 'var(--blue)' : 'var(--lilac)'}">[${g.strat}]</span>
                            </span>
                            <div style="display:flex; gap:5px"><button onclick="mark(${ti},${gi},'win')" style="background:var(--green); color:black; border-radius:50%; width:26px; height:26px; font-size:0.7rem">V</button><button onclick="mark(${ti},${gi},'loss')" style="background:var(--red); color:white; border-radius:50%; width:26px; height:26px; font-size:0.7rem">X</button></div>
                        </div>
                        
                        <div class="prob-line" style="margin-top:4px">
                            C: <span class="${getClProb(p.v[0])}">${p.v[0]}%</span> E: <span class="${getClProb(p.v[1])}">${p.v[1]}%</span> F: <span class="${getClProb(p.v[2])}">${p.v[2]}%</span>
                        </div>
                        <div class="prob-line">
                            1X: <span class="${getClRank(p.dc[0],p.dc)}">${p.dc[0]}%</span> 12: <span class="${getClRank(p.dc[1],p.dc)}">${p.dc[1]}%</span> 2X: <span class="${getClRank(p.dc[2],p.dc)}">${p.dc[2]}%</span>
                        </div>
                        <div class="prob-line">
                            AMBAS: S: <span class="${p.am[0]>=p.am[1]?'v-lemon':'v-red'}">${p.am[0]}%</span> N: <span class="${p.am[1]>p.am[0]?'v-lemon':'v-red'}">${p.am[1]}%</span>
                        </div>

                        <div style="font-size:0.65rem; color:#fff; opacity:0.8; margin-top:4px; padding-top:4px; border-top:1px solid #222;">
                            <div>🚩 ${g.escK}</div>
                            <div style="margin-top:2px;">🚩 ${g.escR}</div>
                        </div>
                    </div>`;
                });
                d.innerHTML+=`<button onclick="delH(${ti})" style="background:none; border:none; color:#555; font-size:0.7rem; margin-top:5px;">🗑️ APAGAR BILHETE</button>`;
                l.appendChild(d);
            });
            let totalT = tGreen + tRed, pgT = totalT>0?Math.round((tGreen/totalT)*100):0, prT = totalT>0?Math.round((tRed/totalT)*100):0;
            tStats.innerHTML = `<div style="color:var(--green)">GREEN: ${tGreen} (${pgT}%)</div><div style="color:var(--red)">RED: ${tRed} (${prT}%)</div>`;
            let tK = sk_win+sk_loss, pKw = tK>0?Math.round((sk_win/tK)*100):0, pKl = tK>0?Math.round((sk_loss/tK)*100):0;
            let tR = sr_win+sr_loss, pRw = tR>0?Math.round((sr_win/tR)*100):0, pRl = tR>0?Math.round((sr_loss/tR)*100):0;
            sStats.innerHTML = `<div><b>K.C⚽️M:</b> 🥰(${sk_win}) ${pKw}% | 😡(${sk_loss}) ${pKl}%</div><div style="margin-top:3px"><b>R⚽️3:</b> 🥰(${sr_win}) ${pRw}% | 😡(${sr_loss}) ${pRl}%</div>`;
            for(let m in markets){ let tot=markets[m].g+markets[m].r, per=tot>0?Math.round((markets[m].g/tot)*100):0; mStats.innerHTML+=`<div style="display:flex; align-items:center; margin-bottom:5px; font-size:0.75rem;"><span style="width:50px">${m}</span><div class="thermometer"><div class="thermometer-bar" style="width:${per}%"></div></div><span style="color:var(--green-lemon); width:35px; text-align:right">${per}%</span></div>`; }
        }
        function mark(ti,gi,st){ allTkts[ti].games[gi].s=st; localStorage.setItem('ari_master_v8',JSON.stringify(allTkts)); renderH(); }
        function delH(i){ if(confirm("Apagar?")){ allTkts.splice(i,1); localStorage.setItem('ari_master_v8',JSON.stringify(allTkts)); renderH(); } }
        window.onload = function() { toggleIframe(false); document.getElementById('standby-screen').style.display = 'flex'; };
    </script>
</body>
</html>
