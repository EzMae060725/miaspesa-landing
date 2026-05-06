# ============================================================
# Fix Bug B.2.30 - Refactor step 3: Tipologia + Insegna lista chiusa
# Target: miaspesa-landing\candidatura.html
# Convenzione: here-string @'...'@ + UTF8 senza BOM + CRLF normalize
# Convenzione PS5: __PIU__ placeholder per piu (u-grave) + __DOT__
# Data: 06/05/2026
#
# Refactor architetturale:
# 1) Aggiungo <select id="tipologia"> come PRIMO campo step 3
#    Tassonomia 9 voci + Altro (10 totali):
#      1. Ipermercato (>2500mq)
#      2. Supermercato (1000-2500mq)
#      3. Superette (400-1000mq)
#      4. Convenience / piccolo formato (<400mq)
#      5. Discount
#      6. Online / e-commerce
#      7. Cash & Carry / Ingrosso
#      8. Mercato (farmer market / ambulanti)  -> NO insegna
#      9. Negozio tradizionale / sotto casa     -> NO insegna
#     10. Altro                                  -> insegna libera opzionale
#
# 2) Refactor insegna:
#    - Sostituisco la datalist statica (16 voci) con datalist
#      dinamica popolata da data/insegne-gdo-italia.json
#    - Filtro: tipologia (mappa al campo "tipo" del JSON) +
#      regione (campo "regioni" del JSON)
#    - Mostra/nascondi campo insegna in base a tipologia:
#      * Tipologia 1-7 (GDO) -> mostra datalist filtrata
#      * Tipologia 8-9 -> nascondi campo insegna
#      * Tipologia 10 -> mostra campo libero
#    - Voce "Altro" in datalist -> mostra campo "Specifica"
#
# 3) Validazione hard:
#    - Tipologia obbligatoria
#    - Insegna obbligatoria solo se tipologia 1-7
#    - Specifica obbligatoria se "Altro" scelto in datalist
#
# Mapping tipologia -> tipo JSON:
#    Ipermercato       -> "iper"
#    Supermercato      -> "super"
#    Superette         -> "super" (sottoinsieme)
#    Convenience       -> "convenience"
#    Discount          -> "discount"
#    Online            -> "online"
#    Cash & Carry      -> "cashcarry"
# ============================================================

$ErrorActionPreference = "Stop"

$path = "C:\Users\ACER\OneDrive\Desktop\Progetti\miaspesa-landing\candidatura.html"

if (-not (Test-Path $path)) {
    Write-Host "ERRORE: file non trovato: $path" -ForegroundColor Red
    exit 1
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$rawContent = [System.IO.File]::ReadAllText($path, $utf8NoBom)

Write-Host "File letto: $($rawContent.Length) caratteri" -ForegroundColor Cyan
$crlfCount = [regex]::Matches($rawContent, "`r`n").Count
Write-Host "Line endings: CRLF=$crlfCount" -ForegroundColor Cyan

# Backup
$bakPath = $path + ".bak_b230"
if (-not (Test-Path $bakPath)) {
    [System.IO.File]::WriteAllText($bakPath, $rawContent, $utf8NoBom)
    Write-Host "Backup salvato: $bakPath" -ForegroundColor Cyan
}

# Normalize LF
$content = $rawContent.Replace("`r`n", "`n")
Write-Host ""

if ($content.IndexOf('id="tipologia"') -ge 0) {
    Write-Host "WARN: gia' fixato (tipologia presente), niente da fare" -ForegroundColor Yellow
    exit 0
}

# Caratteri unicode runtime (compat PS5)
$piu = [char]0x00F9      # u-grave per "piu"
$dot = [char]0x00B7      # middle dot ·
$arrow = [char]0x2192    # freccia

# ============================================================
# STEP 1 - Sostituisco l'intero blocco insegna originale
# (16 opzioni hardcoded) con tipologia + nuova insegna dinamica
# ============================================================

# 4 varianti possibili del wrapper insegna (pre/post B.2.28/29)
# Strategy: cerco il pattern stretto sull'apertura del field e
# del datalist statico, ricostruisco tutto

$old1_v1 = (@'
<div class="field">
      <label>Insegna dove fate la spesa pi__PIU__ spesso <span class="opt">(opzionale)</span></label>
      <input type="text" id="supermercato" placeholder="es. Esselunga, Conad, Lidl..." list="insegne-list">
      <datalist id="insegne-list">
        <option>Esselunga</option><option>Conad</option><option>Coop</option>
        <option>Carrefour</option><option>Lidl</option><option>Eurospin</option>
        <option>Penny Market</option><option>In's Mercato</option><option>Aldi</option>
        <option>Bennet</option><option>Iper</option><option>Pam</option>
        <option>Sigma</option><option>Despar</option><option>MD</option><option>Altro</option>
      </datalist>
    </div>
'@).Replace('__PIU__', $piu)

$old1_v2 = (@'
<div class="field" id="f-supermercato">
      <label>Insegna dove fate la spesa pi__PIU__ spesso <span class="opt">(opzionale)</span></label>
      <input type="text" id="supermercato" placeholder="es. Esselunga, Conad, Lidl..." list="insegne-list" onblur="validateInsegna()" oninput="clearErr('supermercato')">
      <datalist id="insegne-list">
        <option>Esselunga</option><option>Conad</option><option>Coop</option>
        <option>Carrefour</option><option>Lidl</option><option>Eurospin</option>
        <option>Penny Market</option><option>In's Mercato</option><option>Aldi</option>
        <option>Bennet</option><option>Iper</option><option>Pam</option>
        <option>Sigma</option><option>Despar</option><option>MD</option><option>Altro</option>
      </datalist>
      <div class="err">Insegna non valida</div>
    </div>
'@).Replace('__PIU__', $piu)

$new1 = (@'
<!-- Ez 06.05.26 - Bug B.2.30 fix: tipologia + insegna lista chiusa per regione -->
    <div class="field" id="f-tipologia">
      <label>Tipologia di negozio dove fate la spesa pi__PIU__ spesso *</label>
      <select id="tipologia" onchange="onTipologiaChange()">
        <option value="">Seleziona...</option>
        <option value="iper">Ipermercato (oltre 2500 mq)</option>
        <option value="super">Supermercato (1000-2500 mq)</option>
        <option value="superette">Superette (400-1000 mq)</option>
        <option value="convenience">Convenience / piccolo formato (sotto 400 mq)</option>
        <option value="discount">Discount</option>
        <option value="online">Online / e-commerce</option>
        <option value="cashcarry">Cash & Carry / Ingrosso</option>
        <option value="mercato">Mercato (farmer market / ambulanti)</option>
        <option value="tradizionale">Negozio tradizionale / sotto casa</option>
        <option value="altro">Altro</option>
      </select>
      <div class="err">Seleziona una tipologia</div>
    </div>

    <div class="field" id="f-supermercato" style="display:none">
      <label id="lbl-insegna">Insegna dove fate la spesa pi__PIU__ spesso *</label>
      <input type="text" id="supermercato" placeholder="Inizia a digitare..." list="insegne-list" autocomplete="off" onblur="validateInsegna()" oninput="onInsegnaInput()">
      <datalist id="insegne-list"></datalist>
      <div class="err">Insegna non valida</div>
    </div>

    <div class="field" id="f-insegnaSpec" style="display:none">
      <label>Specifica nome insegna *</label>
      <input type="text" id="insegnaSpec" placeholder="es. nome insegna locale" maxlength="80" onblur="validateInsegnaSpec()" oninput="clearErr('insegnaSpec')">
      <div class="err">Specifica obbligatoria (min 3 caratteri)</div>
    </div>
'@).Replace('__PIU__', $piu)

$applied = $false
if ($content.IndexOf($old1_v2) -ge 0) {
    $content = $content.Replace($old1_v2, $new1)
    Write-Host "[1/4] Wrapper insegna ricostruito (variante post-B.2.28/29)" -ForegroundColor Green
    $applied = $true
} elseif ($content.IndexOf($old1_v1) -ge 0) {
    $content = $content.Replace($old1_v1, $new1)
    Write-Host "[1/4] Wrapper insegna ricostruito (variante originale)" -ForegroundColor Green
    $applied = $true
}

if (-not $applied) {
    Write-Host "ERRORE: pattern wrapper insegna non trovato in nessuna variante nota" -ForegroundColor Red
    exit 1
}

# ============================================================
# STEP 2 - Sostituisco validateInsegna nel JS (gia' presente
# post B.2.22) con nuova versione che gestisce datalist chiusa
# + aggiungo onTipologiaChange, loadInsegneData, validateInsegnaSpec
#
# Anchor: chiusura validateInsegna esistente
# ============================================================

# Variante 1: validateInsegna esiste post B.2.22
$old2_v1 = @'
function validateInsegna() {
  var v = document.getElementById('supermercato').value.trim();
  if (!v) {
    clearErr('supermercato');
    return true;
  }
  if (v.length < 3) {
    setErr('supermercato', 'Insegna troppo corta (min 3 caratteri)');
    return false;
  }
  if (!/^[A-Za-z0-9\u00C0-\u00FF\s'\-\&\.]{3,60}$/.test(v)) {
    setErr('supermercato', 'Insegna non valida');
    return false;
  }
  clearErr('supermercato');
  return true;
}
'@

# Variante 2: NON esiste validateInsegna (pre B.2.22)
# In questo caso aggiungo prima di "var emailConfirmed"
$old2_v2 = "var emailConfirmed = false;`nfunction showEmailConfirm() {"

$new2_block = @'

// =============================================================
// Ez 06.05.26 - Bug B.2.30 fix: gestione tipologia + insegna lista chiusa per regione
// =============================================================
var INSEGNE_DATA = null;
var INSEGNE_LOADING = false;
var SELECTED_INSEGNA = null;

function loadInsegneData() {
  if (INSEGNE_DATA || INSEGNE_LOADING) return Promise.resolve(INSEGNE_DATA);
  INSEGNE_LOADING = true;
  return fetch('data/insegne-gdo-italia.json')
    .then(function(r) { return r.json(); })
    .then(function(data) {
      INSEGNE_DATA = data;
      INSEGNE_LOADING = false;
      return data;
    })
    .catch(function(err) {
      INSEGNE_LOADING = false;
      console.error('Errore caricamento insegne:', err);
      throw err;
    });
}

function onTipologiaChange() {
  var t = document.getElementById('tipologia').value;
  var fInsegna = document.getElementById('f-supermercato');
  var fSpec = document.getElementById('f-insegnaSpec');
  var ins = document.getElementById('supermercato');
  var spec = document.getElementById('insegnaSpec');

  // Reset campi insegna a ogni cambio tipologia
  ins.value = '';
  spec.value = '';
  SELECTED_INSEGNA = null;
  clearErr('tipologia'); clearErr('supermercato'); clearErr('insegnaSpec');

  if (!t) {
    fInsegna.style.display = 'none';
    fSpec.style.display = 'none';
    return;
  }

  // Tipologie senza insegna (mercato, tradizionale)
  if (t === 'mercato' || t === 'tradizionale') {
    fInsegna.style.display = 'none';
    fSpec.style.display = 'none';
    return;
  }

  // Tipologia "altro": campo libero direttamente nello spec
  if (t === 'altro') {
    fInsegna.style.display = 'none';
    fSpec.style.display = 'block';
    document.querySelector('#f-insegnaSpec label').textContent = 'Specifica dove fai la spesa (opzionale)';
    document.getElementById('insegnaSpec').placeholder = 'es. specifica luogo';
    return;
  }

  // Tipologie GDO (1-7): mostra datalist filtrata per tipo + regione
  fInsegna.style.display = 'block';
  fSpec.style.display = 'none';
  document.querySelector('#f-insegnaSpec label').textContent = 'Specifica nome insegna *';
  document.getElementById('insegnaSpec').placeholder = 'es. nome insegna locale';

  loadInsegneData().then(function(data) {
    var regione = document.getElementById('regione').value;
    // Edge case: regione select value 'VdA' nel form ma "Valle d'Aosta" nel JSON
    var regioneCanonica = (regione === 'VdA') ? "Valle d'Aosta" : regione;

    // Mappa Superette su "super" (sottoinsieme): mostra tutti i super
    var tipoFiltro = (t === 'superette') ? 'super' : t;

    var filtered = data.filter(function(ins) {
      if (ins.tipo.indexOf(tipoFiltro) < 0) return false;
      if (!regione) return true;  // se regione non scelta, mostra tutto
      return ins.regioni.indexOf(regioneCanonica) >= 0;
    });

    // Sposto "Altro" in fondo
    filtered.sort(function(a, b) {
      if (a.nome === 'Altro') return 1;
      if (b.nome === 'Altro') return -1;
      return a.nome.localeCompare(b.nome);
    });

    var dl = document.getElementById('insegne-list');
    dl.innerHTML = '';
    filtered.forEach(function(ins) {
      var opt = document.createElement('option');
      opt.value = ins.nome;
      dl.appendChild(opt);
    });
  });
}

function onInsegnaInput() {
  var v = document.getElementById('supermercato').value.trim();
  clearErr('supermercato');
  var fSpec = document.getElementById('f-insegnaSpec');
  // Se utente sceglie "Altro" mostra campo specifica
  if (v.toLowerCase() === 'altro') {
    SELECTED_INSEGNA = { nome: 'Altro' };
    fSpec.style.display = 'block';
    document.querySelector('#f-insegnaSpec label').textContent = 'Specifica nome insegna *';
    document.getElementById('insegnaSpec').focus();
  } else {
    // Match esatto in lista
    if (INSEGNE_DATA) {
      var match = INSEGNE_DATA.find(function(ins) {
        return ins.nome.toLowerCase() === v.toLowerCase();
      });
      if (match) {
        SELECTED_INSEGNA = match;
        if (document.getElementById('supermercato').value !== match.nome) {
          document.getElementById('supermercato').value = match.nome;
        }
        fSpec.style.display = 'none';
        document.getElementById('insegnaSpec').value = '';
      } else {
        SELECTED_INSEGNA = null;
        fSpec.style.display = 'none';
      }
    }
  }
}

function validateInsegna() {
  var t = document.getElementById('tipologia').value;
  // Tipologie senza insegna: skip validazione
  if (t === 'mercato' || t === 'tradizionale' || t === 'altro' || !t) {
    clearErr('supermercato');
    return true;
  }
  var v = document.getElementById('supermercato').value.trim();
  if (!v) {
    setErr('supermercato', 'Seleziona un\'insegna');
    return false;
  }
  if (!SELECTED_INSEGNA) {
    setErr('supermercato', 'Seleziona un\'insegna dalla lista');
    return false;
  }
  clearErr('supermercato');
  return true;
}

function validateInsegnaSpec() {
  var v = document.getElementById('insegnaSpec').value.trim();
  var fSpec = document.getElementById('f-insegnaSpec');
  // Se campo nascosto, skip
  if (fSpec.style.display === 'none') {
    clearErr('insegnaSpec');
    return true;
  }
  var t = document.getElementById('tipologia').value;
  // "altro" tipologia: campo opzionale
  if (t === 'altro') {
    if (v && v.length < 3) {
      setErr('insegnaSpec', 'Min 3 caratteri se compilato');
      return false;
    }
    clearErr('insegnaSpec');
    return true;
  }
  // Insegna "Altro" scelta in datalist GDO: obbligatorio
  if (!v || v.length < 3) {
    setErr('insegnaSpec', 'Specifica obbligatoria (min 3 caratteri)');
    return false;
  }
  if (!/^[A-Za-z0-9\u00C0-\u00FF\s'\-\&\.]{3,80}$/.test(v)) {
    setErr('insegnaSpec', 'Caratteri non validi');
    return false;
  }
  clearErr('insegnaSpec');
  return true;
}

function validateTipologia() {
  var t = document.getElementById('tipologia').value;
  if (!t) {
    setErr('tipologia', 'Seleziona una tipologia');
    return false;
  }
  clearErr('tipologia');
  return true;
}

'@

# Caso 1: validateInsegna esiste -> sostituisco con commento di rimozione
if ($content.IndexOf($old2_v1) -ge 0) {
    $content = $content.Replace($old2_v1, "// Ez 06.05.26 - validateInsegna v1 sostituita da B.2.30 (vedi sotto blocco refactor)")
    Write-Host "[2/4] validateInsegna v1 rimossa (sostituita da v2 sotto)" -ForegroundColor Green
}

# Inserisco nuovo blocco prima di "var emailConfirmed"
$anchor = "var emailConfirmed = false;`nfunction showEmailConfirm() {"
if ($content.IndexOf($anchor) -ge 0) {
    $content = $content.Replace($anchor, $new2_block + "`n" + $anchor)
    Write-Host "[3/4] Blocco JS B.2.30 inserito (loadInsegneData + onTipologiaChange + validate*)" -ForegroundColor Green
} else {
    Write-Host "ERRORE: anchor 'var emailConfirmed' non trovato" -ForegroundColor Red
    exit 1
}

# ============================================================
# STEP 3 - validateStep step 3: chiama validateTipologia +
# validateInsegna + validateInsegnaSpec + invia payload con tipologia
# ============================================================

# Variante post-B.2.27: gia' chiama validateInsegna in step 3
$old3_v1 = @"
  // Ez 05.05.26 - Bug B.2.27 fix: validateStep step 3 chiama validateInsegna (gate hard)
  if (s === 3) {
    if (!validateInsegna()) { ok = false; }
  }
  return ok;
}
"@
$old3_v1 = $old3_v1.Replace("`r`n", "`n")

# Variante 2: validateStep step 3 da B.2.23 (con commento diverso)
$old3_v2 = @"
  // Ez 05.05.26 - Bug B.2.23 fix: validazione step 3 (insegna opzionale ma se compilata deve essere valida)
  if (s === 3) {
    if (!validateInsegna()) { ok = false; }
  }
  return ok;
}
"@
$old3_v2 = $old3_v2.Replace("`r`n", "`n")

# Variante 3: pre-B.2.23 (no step 3 in validateStep)
$old3_v3 = "  return ok;`n}"

$new3 = @"
  // Ez 06.05.26 - Bug B.2.30 fix: validazione step 3 (tipologia + insegna lista chiusa)
  if (s === 3) {
    if (!validateTipologia()) { ok = false; }
    if (!validateInsegna()) { ok = false; }
    if (!validateInsegnaSpec()) { ok = false; }
  }
  return ok;
}
"@
$new3 = $new3.Replace("`r`n", "`n")

if ($content.IndexOf($old3_v1) -ge 0) {
    $content = $content.Replace($old3_v1, $new3)
    Write-Host "[4/4] validateStep step 3 aggiornato (variante B.2.27)" -ForegroundColor Green
} elseif ($content.IndexOf($old3_v2) -ge 0) {
    $content = $content.Replace($old3_v2, $new3)
    Write-Host "[4/4] validateStep step 3 aggiornato (variante B.2.23)" -ForegroundColor Green
} else {
    # Variante 3: nessuno step 3 ancora, devo aggiungerlo
    # Pattern stretto per evitare match multipli
    $count = ([regex]::Matches($content, [regex]::Escape($old3_v3))).Count
    if ($count -eq 1) {
        $content = $content.Replace($old3_v3, $new3)
        Write-Host "[4/4] validateStep step 3 aggiunto (pre-B.2.23)" -ForegroundColor Green
    } else {
        Write-Host "WARN: pattern validateStep step 3 trovato $count volte, skip" -ForegroundColor Yellow
    }
}

# ============================================================
# STEP 4 - Aggiorno payload invia() per includere tipologia
# ============================================================

$old4 = "    supermercato: document.getElementById('supermercato').value,"
$new4 = @'
    tipologia: document.getElementById('tipologia').value,
    supermercato: (document.getElementById('supermercato').value || document.getElementById('insegnaSpec').value || '').trim(),
    insegnaSpec: document.getElementById('insegnaSpec').value.trim() || null,
'@

if ($content.IndexOf($old4) -ge 0) {
    $content = $content.Replace($old4, $new4)
    Write-Host "[5/5] Payload invia: aggiunto tipologia + insegnaSpec" -ForegroundColor Green
} else {
    Write-Host "WARN: pattern payload supermercato non trovato" -ForegroundColor Yellow
}

# ============================================================
# Scrittura
# ============================================================

[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "OK - Bug B.2.30 fixato (refactor step 3)" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "File scritto: $($content.Length) caratteri (UTF8 no-BOM, LF)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Casi di test:" -ForegroundColor Yellow
Write-Host "  Step 3 - tipologia 'Supermercato' + regione Lombardia:" -ForegroundColor Cyan
Write-Host "    Datalist deve mostrare ~30 super per Lombardia (Esselunga, Iperal, Italmark, Tigros...)" -ForegroundColor Gray
Write-Host "    Digita 'esse' -> autocomplete 'Esselunga'" -ForegroundColor Gray
Write-Host ""
Write-Host "  Step 3 - tipologia 'Mercato' o 'Negozio tradizionale':" -ForegroundColor Cyan
Write-Host "    Campo Insegna NASCOSTO" -ForegroundColor Gray
Write-Host "    Avanti consentito senza compilare insegna" -ForegroundColor Gray
Write-Host ""
Write-Host "  Step 3 - tipologia 'Discount':" -ForegroundColor Cyan
Write-Host "    Datalist mostra solo Lidl/Eurospin/MD/Penny/Aldi/In's/Todis/Risparmio Casa..." -ForegroundColor Gray
Write-Host ""
Write-Host "  Step 3 - tipologia 'Altro':" -ForegroundColor Cyan
Write-Host "    Mostra solo campo libero 'Specifica' opzionale" -ForegroundColor Gray
Write-Host ""
Write-Host "  Edge - scegli 'Altro' nella datalist GDO:" -ForegroundColor Cyan
Write-Host "    Mostra campo 'Specifica nome insegna' obbligatorio" -ForegroundColor Gray
Write-Host ""
Write-Host "Backup originale (.bak_b230) salvato accanto al file" -ForegroundColor Yellow
