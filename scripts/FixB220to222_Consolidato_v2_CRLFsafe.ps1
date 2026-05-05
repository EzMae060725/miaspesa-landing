# ============================================================
# Fix Bug B.2.20 + B.2.21 + B.2.22 v2 (CRLF-safe consolidato)
# Target: miaspesa-landing\candidatura.html
# Convenzione: here-string @'...'@ + UTF8 senza BOM + CRLF normalize
# Data: 05/05/2026
#
# Problema dei v1: file su disco in CRLF (post Git/Vercel autocrlf),
# pattern PS @'...'@ produce LF, mismatch -> Replace fallisce.
#
# Soluzione: normalizzo CRLF -> LF dopo ReadAllText, lavoro solo
# in LF (Vercel/Node accettano entrambi).
#
# Idempotente: skippa pezzi gia' applicati. Recupera anche lo
# stato parziale lasciato da B.2.22 v1 (input comune con onblur
# ma funzioni JS mancanti).
#
# Fix consolidati:
# - B.2.20: nome + cognome onBlur
# - B.2.21: anno nascita onBlur
# - B.2.22: comune + insegna onBlur (insegna opzionale)
# ============================================================

$ErrorActionPreference = "Stop"

$path = "C:\Users\ACER\OneDrive\Desktop\Progetti\miaspesa-landing\candidatura.html"

if (-not (Test-Path $path)) {
    Write-Host "ERRORE: file non trovato: $path" -ForegroundColor Red
    exit 1
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$rawContent = [System.IO.File]::ReadAllText($path, $utf8NoBom)

Write-Host "File letto: $($rawContent.Length) caratteri (raw)" -ForegroundColor Cyan

# Diagnostica line endings
$crlfCount = [regex]::Matches($rawContent, "`r`n").Count
Write-Host "Line endings: CRLF=$crlfCount" -ForegroundColor Cyan

# Backup prima di toccare
$bakPath = $path + ".bak_b220_222"
if (-not (Test-Path $bakPath)) {
    [System.IO.File]::WriteAllText($bakPath, $rawContent, $utf8NoBom)
    Write-Host "Backup salvato: $bakPath" -ForegroundColor Cyan
}

# Normalizzo CRLF -> LF per matching robusto
$content = $rawContent.Replace("`r`n", "`n")
Write-Host "Dopo normalize LF: $($content.Length) caratteri" -ForegroundColor Cyan
Write-Host ""

$changed = $false

# ============================================================
# B.2.20 - Nome + Cognome
# ============================================================

# Input nome
$old_nome = '<input type="text" id="nome" placeholder="Mario" autocomplete="given-name">'
$new_nome = '<input type="text" id="nome" placeholder="Mario" autocomplete="given-name" onblur="validateNomeCognome(''nome'')" oninput="clearErr(''nome'')">'

if ($content.IndexOf($old_nome) -ge 0) {
    $content = $content.Replace($old_nome, $new_nome)
    Write-Host "[B.2.20] Input nome: onblur+oninput aggiunti" -ForegroundColor Green
    $changed = $true
} elseif ($content.IndexOf("validateNomeCognome('nome')") -ge 0) {
    Write-Host "[B.2.20] Input nome gia' fixato, skip" -ForegroundColor Yellow
} else {
    Write-Host "[B.2.20] WARN: input nome - pattern atteso non trovato" -ForegroundColor Yellow
}

# Input cognome
$old_cog = '<input type="text" id="cognome" placeholder="Rossi" autocomplete="family-name">'
$new_cog = '<input type="text" id="cognome" placeholder="Rossi" autocomplete="family-name" onblur="validateNomeCognome(''cognome'')" oninput="clearErr(''cognome'')">'

if ($content.IndexOf($old_cog) -ge 0) {
    $content = $content.Replace($old_cog, $new_cog)
    Write-Host "[B.2.20] Input cognome: onblur+oninput aggiunti" -ForegroundColor Green
    $changed = $true
} elseif ($content.IndexOf("validateNomeCognome('cognome')") -ge 0) {
    Write-Host "[B.2.20] Input cognome gia' fixato, skip" -ForegroundColor Yellow
} else {
    Write-Host "[B.2.20] WARN: input cognome - pattern atteso non trovato" -ForegroundColor Yellow
}

# ============================================================
# B.2.21 - Anno nascita
# ============================================================

$old_anno = '<input type="number" id="annoNascita" placeholder="es. 1980" min="1924" max="2006">'
$new_anno = '<input type="number" id="annoNascita" placeholder="es. 1980" min="1924" max="2006" onblur="validateAnno()" oninput="clearErr(''anno'')">'

if ($content.IndexOf($old_anno) -ge 0) {
    $content = $content.Replace($old_anno, $new_anno)
    Write-Host "[B.2.21] Input annoNascita: onblur+oninput aggiunti" -ForegroundColor Green
    $changed = $true
} elseif ($content.IndexOf('onblur="validateAnno()"') -ge 0) {
    Write-Host "[B.2.21] Input annoNascita gia' fixato, skip" -ForegroundColor Yellow
} else {
    Write-Host "[B.2.21] WARN: input annoNascita - pattern atteso non trovato" -ForegroundColor Yellow
}

# ============================================================
# B.2.22 - Comune + Insegna
# ============================================================

# Input comune (potrebbe essere gia' parzialmente fixato da B.2.22 v1)
$old_com = '<input type="text" id="comune" placeholder="es. Brescia">'
$new_com = '<input type="text" id="comune" placeholder="es. Brescia" onblur="validateComune()" oninput="clearErr(''comune'')">'

if ($content.IndexOf($old_com) -ge 0) {
    $content = $content.Replace($old_com, $new_com)
    Write-Host "[B.2.22] Input comune: onblur+oninput aggiunti" -ForegroundColor Green
    $changed = $true
} elseif ($content.IndexOf('onblur="validateComune()"') -ge 0) {
    Write-Host "[B.2.22] Input comune gia' fixato (anche da v1 parziale), skip" -ForegroundColor Yellow
} else {
    Write-Host "[B.2.22] WARN: input comune - pattern atteso non trovato" -ForegroundColor Yellow
}

# Wrapper insegna (multi-riga: uso pattern LF-only post normalize)
$old_ins = @"
<div class="field">
      <label>Insegna dove fate la spesa più spesso <span class="opt">(opzionale)</span></label>
      <input type="text" id="supermercato" placeholder="es. Esselunga, Conad, Lidl..." list="insegne-list">
"@

# Forzo LF nel pattern (here-string PS5 puo' produrre CRLF su alcune versioni)
$old_ins = $old_ins.Replace("`r`n", "`n")

$new_ins = @"
<div class="field" id="f-supermercato">
      <label>Insegna dove fate la spesa più spesso <span class="opt">(opzionale)</span></label>
      <input type="text" id="supermercato" placeholder="es. Esselunga, Conad, Lidl..." list="insegne-list" onblur="validateInsegna()" oninput="clearErr('supermercato')">
      <div class="err">Insegna non valida</div>
"@
$new_ins = $new_ins.Replace("`r`n", "`n")

if ($content.IndexOf($old_ins) -ge 0) {
    $content = $content.Replace($old_ins, $new_ins)
    Write-Host "[B.2.22] Wrapper insegna: id+err+onblur+oninput aggiunti" -ForegroundColor Green
    $changed = $true
} elseif ($content.IndexOf('id="f-supermercato"') -ge 0) {
    Write-Host "[B.2.22] Wrapper insegna gia' fixato, skip" -ForegroundColor Yellow
} else {
    Write-Host "[B.2.22] WARN: wrapper insegna - pattern atteso non trovato" -ForegroundColor Yellow
}

# ============================================================
# Funzioni JS validate* (anchor stabile)
# ============================================================

$old_js = @"
var emailConfirmed = false;
function showEmailConfirm() {
"@
$old_js = $old_js.Replace("`r`n", "`n")

$new_js = @"
// Ez 05.05.26 - Fix B.2.20+21+22: funzioni validate onBlur consolidate
function validateNomeCognome(id) {
  var v = document.getElementById(id).value.trim();
  var label = (id === 'nome') ? 'nome' : 'cognome';
  if (!v) {
    setErr(id, 'Inserisci ' + label);
    return false;
  }
  if (v.length < 2) {
    setErr(id, 'Inserisci ' + label + ' (min 2 lettere)');
    return false;
  }
  if (!/^[A-Za-z\u00C0-\u00FF\s'\-]{2,50}$/.test(v)) {
    setErr(id, label.charAt(0).toUpperCase() + label.slice(1) + ' non valido (solo lettere)');
    return false;
  }
  clearErr(id);
  return true;
}

function validateAnno() {
  var raw = document.getElementById('annoNascita').value.trim();
  if (!raw) {
    setErr('anno', 'Inserisci anno di nascita');
    return false;
  }
  if (!/^\d{4}$/.test(raw)) {
    setErr('anno', 'Anno deve avere 4 cifre (es. 1980)');
    return false;
  }
  var anno = parseInt(raw, 10);
  if (anno < 1924 || anno > 2006) {
    setErr('anno', 'Anno non valido (1924-2006)');
    return false;
  }
  clearErr('anno');
  return true;
}

function validateComune() {
  var v = document.getElementById('comune').value.trim();
  if (!v) {
    setErr('comune', 'Inserisci il comune');
    return false;
  }
  if (v.length < 3) {
    setErr('comune', 'Comune troppo corto (min 3 lettere)');
    return false;
  }
  if (!/^[A-Za-z\u00C0-\u00FF\s'\-\.]{3,60}$/.test(v)) {
    setErr('comune', 'Comune non valido (solo lettere)');
    return false;
  }
  clearErr('comune');
  return true;
}

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

var emailConfirmed = false;
function showEmailConfirm() {
"@
$new_js = $new_js.Replace("`r`n", "`n")

if ($content.IndexOf($old_js) -ge 0) {
    $content = $content.Replace($old_js, $new_js)
    Write-Host "[JS] Funzioni validate* aggiunte (4 funzioni)" -ForegroundColor Green
    $changed = $true
} elseif ($content.IndexOf("Fix B.2.20+21+22: funzioni validate") -ge 0) {
    Write-Host "[JS] Funzioni validate* gia' presenti, skip" -ForegroundColor Yellow
} else {
    Write-Host "[JS] WARN: anchor 'var emailConfirmed' non trovato" -ForegroundColor Yellow
}

# ============================================================
# Scrittura UTF8 senza BOM (resta LF, accettato da Vercel/Node)
# ============================================================

if (-not $changed) {
    Write-Host ""
    Write-Host "Nessuna modifica necessaria - file gia' aggiornato" -ForegroundColor Yellow
    exit 0
}

[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "OK - B.2.20+21+22 fixati (CRLF-safe v2)" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "File scritto: $($content.Length) caratteri (UTF8 no-BOM, LF)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backup originale (CRLF) salvato in:" -ForegroundColor Yellow
Write-Host "  $bakPath" -ForegroundColor Gray
Write-Host ""
Write-Host "Test rapido nel browser:" -ForegroundColor Yellow
Write-Host "  Step 1: Nome 'A' -> errore al blur. Anno '98' -> errore al blur." -ForegroundColor Gray
Write-Host "  Step 2: Comune 'Br' -> errore al blur." -ForegroundColor Gray
Write-Host "  Step 3: Insegna 'A' -> errore. Vuoto -> OK." -ForegroundColor Gray
