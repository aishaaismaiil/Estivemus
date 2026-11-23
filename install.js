(function(){
  "use strict";
  try{ if("serviceWorker" in navigator){ addEventListener("load",function(){ navigator.serviceWorker.register(new URL("sw.js",document.currentScript?document.currentScript.src:location.href).href).catch(function(){}); }); } }catch(e){}
  var standalone=(window.matchMedia&&matchMedia("(display-mode: standalone)").matches)||navigator.standalone;
  var btns=[].slice.call(document.querySelectorAll("[data-install]"));
  var ua=navigator.userAgent||"";
  var ios=/iphone|ipad|ipod/i.test(ua)||(/Macintosh/.test(ua)&&navigator.maxTouchPoints>1);
  var deferred=null,dlg=null;
  function hide(){btns.forEach(function(b){b.hidden=true;});}
  if(standalone){hide();return;}
  btns.forEach(function(b){b.hidden=false;});
  addEventListener("beforeinstallprompt",function(e){e.preventDefault();deferred=e;});
  addEventListener("appinstalled",function(){deferred=null;hide();if(dlg&&dlg.open)dlg.close();});
  function mk(html){
    if(dlg)dlg.remove();
    dlg=document.createElement("dialog");dlg.className="inst-d";dlg.setAttribute("aria-labelledby","inst-t");
    dlg.innerHTML=html;document.body.appendChild(dlg);
    dlg.addEventListener("click",function(e){if(e.target===dlg)dlg.close();});
    return dlg;
  }
  function steps(){
    var li=ios
      ?"<li>Abre esta página no <b>Safari</b>.</li><li>Toca no botão de partilhar (quadrado com uma seta para cima).</li><li>Escolhe <b>Adicionar ao ecrã principal</b>.</li>"
      :"<li>Abre o menu do navegador (os três pontos).</li><li>Escolhe <b>Instalar app</b> ou <b>Adicionar ao ecrã principal</b>.</li>";
    var d=mk('<h2 id="inst-t">Como instalar</h2><ol>'+li+'</ol><div class="row"><button class="ok" type="button" data-x>Percebi</button></div>');
    d.querySelector("[data-x]").addEventListener("click",function(){d.close();});
    d.showModal();
  }
  function ask(){
    var d=mk('<h2 id="inst-t">Queres instalar a Estivemus?</h2><p>Fica no ecrã inicial do telemóvel, como uma app. É grátis e ocupa quase nada.</p><div class="row"><button class="ok" type="button" data-y>Instalar</button><button class="no" type="button" data-n>Agora não</button></div>');
    var y=d.querySelector("[data-y]");
    d.querySelector("[data-n]").addEventListener("click",function(){d.close();});
    y.addEventListener("click",function(){
      if(y.disabled)return;y.disabled=true;
      if(deferred){
        var p=deferred;deferred=null;d.close();
        try{p.prompt();}catch(e){steps();}
      }else{d.close();steps();}
    });
    d.showModal();
  }
  btns.forEach(function(b){b.addEventListener("click",ask);});
})();
