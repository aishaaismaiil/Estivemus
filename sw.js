/* Service worker mínimo: só torna a app instalável. Não guarda nada em cache,
   por isso nunca mostra dados antigos nem guarda dados pessoais. */
self.addEventListener("install",()=>self.skipWaiting());
self.addEventListener("activate",e=>e.waitUntil(self.clients.claim()));
self.addEventListener("fetch",e=>{
  const u=new URL(e.request.url);
  if(e.request.method!=="GET"||u.origin!==location.origin)return;
  e.respondWith(fetch(e.request).catch(()=>new Response("Sem ligação à internet. Tenta outra vez.",{status:503,headers:{"Content-Type":"text/plain; charset=utf-8"}})));
});
