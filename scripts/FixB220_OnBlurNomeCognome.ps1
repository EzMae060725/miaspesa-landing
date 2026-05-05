# ============================================================
# Fix Bug B.2.20 - Validazione onBlur nome/cognome
# Target: miaspesa-landing\candidatura.html
# Convenzione: here-string @'...'@ + UTF8 senza BOM
# Data: 05/05/2026
#
# Problema: nome e cognome venivano validati solo al click
# "Avanti" allo step 2. L'utente non sapeva subito di aver
# inserito sporco (es. "A" o "Mario123").
#
# Soluzione: stesso pattern di B.2.19 sull'email - validazione
# onBlur con regex coerente al validateStep, errore inline
# appena l'utente esce dal campo.
#
# Modifiche:
# 1) <input id="nome">: aggiunti onblur+oninput
# 2) <input id="cognome">: aggiunti onblur+oninput
# 3) Nuova funzione validateNomeCognome(id) prima di
#    showEmailConfirm
# ============================================================

$ErrorActionPreference = "Stop"

$path = "C:\Users\ACER\OneDrive\Desktop\Progetti\miaspesa-landing\candidatura.html"

if (-not (Test-Path $path)) {
    Write-Host "ERRORE: file non trovato: $path" -ForegroundColor Red
    exit 1
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$content = [System.IO.File]::ReadAllText($path, $utf8NoBom)

Write-Host "File letto: $($content.Length) caratteri" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# STEP 1 - Aggiungo onblur+oninput a input nome
# ------------------------------------------------------------

$old1 = @'
<input type="text" id="nome" placeholder="Mario" autocomplete="given-name">
'@

$new1 = @'
<input type="text" id="nome" placeholder="Mario" autocomplete="given-name" onblur="validateNomeCognome('nome')" oninput="clearErr('nome')">
'@

if ($content.IndexOf($old1) -lt 0) {
    Write-Host "ERRORE: pattern input nome non trovato" -ForegroundColor Red
    exit 1
}
if ($content.IndexOf("onblur=`"validateNomeCognome('nome')`"") -ge 0) {
    Write-Host "WARN: input nome gia' fixato, skip step 1" -ForegroundColor Yellow
} else {
    $content = $content.Replace($old1, $new1)
    Write-Host "[1/3] Input nome: aggiunti onblur+oninput" -ForegroundColor Green
}

# ------------------------------------------------------------
# STEP 2 - Aggiungo onblur+oninput a input cognome
# ------------------------------------------------------------

$old2 = @'
<input type="text" id="cognome" placeholder="Rossi" autocomplete="family-name">
'@

$new2 = @'
<input type="text" id="cognome" placeholder="Rossi" autocomplete="family-name" onblur="validateNomeCognome('cognome')" oninput="clearErr('cognome')">
'@

if ($content.IndexOf($old2) -lt 0) {
    Write-Host "ERRORE: pattern input cognome non trovato" -ForegroundColor Red
    exit 1
}
if ($content.IndexOf("onblur=`"validateNomeCognome('cognome')`"") -ge 0) {
    Write-Host "WARN: input cognome gia' fixato, skip step 2" -ForegroundColor Yellow
} else {
    $content = $content.Replace($old2, $new2)
    Write-Host "[2/3] Input cognome: aggiunti onblur+oninput" -ForegroundColor Green
}

# ------------------------------------------------------------
# STEP 3 - Aggiungo funzione validateNomeCognome prima di showEmailConfirm
# ------------------------------------------------------------

$old3 = @'
var emailConfirmed = false;
function showEmailConfirm() {
'@

$new3 = @'
// Ez 05.05.26 - Bug B.2.20 fix: validazione onBlur nome/cognome (stesso pattern email B.2.19)
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

var emailConfirmed = false;
function showEmailConfirm() {
'@

if ($content.IndexOf($old3) -lt 0) {
    Write-Host "ERRORE: anchor 'var emailConfirmed' non trovato" -ForegroundColor Red
    exit 1
}
if ($content.IndexOf("Bug B.2.20 fix: validazione onBlur nome/cognome") -ge 0) {
    Write-Host "WARN: funzione validateNomeCognome gia' presente, skip step 3" -ForegroundColor Yellow
} else {
    $content = $content.Replace($old3, $new3)
    Write-Host "[3/3] Funzione validateNomeCognome aggiunta" -ForegroundColor Green
}

# ------------------------------------------------------------
# Scrittura UTF8 senza BOM
# ------------------------------------------------------------

[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "OK - Bug B.2.20 fixato" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "File scritto: $($content.Length) caratteri (UTF8 no-BOM)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Casi di test (su candidatura.html step 1):" -ForegroundColor Yellow
Write-Host "  Caso 1: clicca su Nome, scrivi 'A', clicca fuori" -ForegroundColor Cyan
Write-Host "    Atteso: errore inline 'Inserisci nome (min 2 lettere)' SUBITO" -ForegroundColor Gray
Write-Host "  Caso 2: scrivi 'Mario123', clicca fuori" -ForegroundColor Cyan
Write-Host "    Atteso: errore inline 'Nome non valido (solo lettere)'" -ForegroundColor Gray
Write-Host "  Caso 3: scrivi 'Mario', clicca fuori" -ForegroundColor Cyan
Write-Host "    Atteso: niente errore" -ForegroundColor Gray
Write-Host "  Caso 4: dopo errore, ricomincia a digitare" -ForegroundColor Cyan
Write-Host "    Atteso: errore sparisce all'inizio digitazione (oninput)" -ForegroundColor Gray
Write-Host "  Stessi 4 casi sul Cognome" -ForegroundColor Cyan
