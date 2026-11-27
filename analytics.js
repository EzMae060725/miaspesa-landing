/* ============================================================
   FILE: analytics.js (sito miaspesa.com)
   VERSION: 1.1 — P109 (Ez 27.11.26): dispositivo di prova con ?prova=on / ?prova=off (sorgente "prova", etichetta in basso a sinistra)
   VERSION: 1.0 — P102 (Ez 25.11.26): analytics del sito SENZA cookie (approvato da Ezio il 25/11/2026)
   Manda al backend: pagina, provenienza (utm_source/medium/campaign o sito da cui si arriva), tipo di dispositivo.
   Nessun cookie e nessun dato personale. La provenienza della prima pagina resta solo per la sessione del browser
   (sessionStorage), per attribuire la candidatura alla fonte giusta. Il visitatore lo conta il backend con un'impronta
   anonima che cambia ogni giorno (l'IP non si salva).
   Uso dalle pagine: window.msTraccia('candidatura_aperta') ; window.msSorgente() -> { sorgente, mezzo, campagna }
   ============================================================ */
(function () {
  var API = 'https://panel-scontrini-production.up.railway.app/api/sito/visita';
  var CHIAVE = 'ms_sorgente';
  function dispositivo() {
    var w = Math.min(window.screen && window.screen.width || 9999, window.innerWidth || 9999);
    if (/Mobi|Android.*Mobile|iPhone/i.test(navigator.userAgent) || w < 600) return 'telefono';
    if (/iPad|Tablet|Android/i.test(navigator.userAgent) || w < 1025) return 'tablet';
    return 'pc';
  }
  function leggiSorgente() {
    try { var s = sessionStorage.getItem(CHIAVE); if (s) return JSON.parse(s); } catch (e) { /* niente */ }
    var q = new URLSearchParams(location.search), so = null;
    if (q.get('utm_source')) so = { sorgente: q.get('utm_source'), mezzo: q.get('utm_medium'), campagna: q.get('utm_campaign') };
    else if (q.get('fonte')) so = { sorgente: q.get('fonte') };
    else if (document.referrer) {
      try { var h = new URL(document.referrer).hostname.replace(/^www\./, ''); if (!/miaspesa\.com$/.test(h)) so = { sorgente: h }; } catch (e) { /* niente */ }
    }
    so = so || { sorgente: 'diretto' };
    try { sessionStorage.setItem(CHIAVE, JSON.stringify(so)); } catch (e) { /* niente */ }
    return so;
  }
  var SO = leggiSorgente();
  // P109 (Ez 27.11.26) - dispositivo di prova: ?prova=on una volta su questo browser e da li' le visite arrivano come sorgente "prova"
  // (in admin escluse dalle statistiche, salvo "mostra anche le visite di prova"); ?prova=off lo spegne. Vale per questo browser e questo sito.
  var PROVA = false;
  try {
    var qp = new URLSearchParams(location.search).get('prova');
    if (qp === 'on') localStorage.setItem('ms_prova', '1');
    if (qp === 'off') localStorage.removeItem('ms_prova');
    PROVA = localStorage.getItem('ms_prova') === '1';
  } catch (e) { /* niente */ }
  if (PROVA) SO = { sorgente: 'prova', mezzo: 'dispositivo', campagna: null };
  if (PROVA) {
    var etichetta = function () {
      if (document.getElementById('msProva')) return;
      var d = document.createElement('div');
      d.id = 'msProva';
      d.style.cssText = 'position:fixed;left:10px;bottom:10px;z-index:9999;background:#111827;color:#fff;font:600 12px/1.3 system-ui,sans-serif;padding:6px 10px;border-radius:8px;opacity:.85';
      d.innerHTML = '🧪 visite di prova (questo browser) · <a href="?prova=off" style="color:#FAC775">disattiva</a>';
      document.body.appendChild(d);
    };
    if (document.body) etichetta(); else document.addEventListener('DOMContentLoaded', etichetta);
  }
  window.msSorgente = function () { return SO; };
  window.msTraccia = function (evento) {
    try {
      fetch(API, { method: 'POST', keepalive: true, headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ evento: evento || 'vista', pagina: (location.pathname.replace(/\.html$/, '').replace(/\/index$/, '/') || '/'), sorgente: SO.sorgente, mezzo: SO.mezzo || null, campagna: SO.campagna || null, dispositivo: dispositivo() }) })
        .catch(function () { /* mai bloccante */ });
    } catch (e) { /* niente */ }
  };
  window.msTraccia('vista');
  if (/candidatura/.test(location.pathname)) window.msTraccia('candidatura_aperta');
})();
