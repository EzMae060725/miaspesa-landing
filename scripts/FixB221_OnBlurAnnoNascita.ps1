# ============================================================
# Fix Bug B.2.21 - Validazione onBlur anno di nascita
# Target: miaspesa-landing\candidatura.html
# Convenzione: here-string @'...'@ + UTF8 senza BOM
# Data: 05/05/2026
#
# Problema: anno di nascita validato solo al click "Avanti".
# Utente poteva digitare 2 o 3 cifre (es. "98", "198") e
# scoprire l'errore solo dopo lo step.
#
# Soluzione: stesso pattern di B.2.19 (email) e B.2.20
# (nome/cognome) - validazione onBlur con check:
#   1) deve essere numero (gia' garantito da type=number)
#   2) deve avere 4 cifre (range 1924-2006)
#   3) range plausibile maggiorenni in IT
#
# Note compatibilita': lo script funziona indipendentemente
# da B.2.20 (gia' applicato o no), perche' usa anchor stabile.
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
# STEP 1 - Aggiungo onblur+oninput a input annoNascita
# ------------------------------------------------------------

$old1 = @'
<input type="number" id="annoNascita" placeholder="es. 1980" min="1924" max="2006">
'@

$new1 = @'
<input type="number" id="annoNascita" placeholder="es. 1980" min="1924" max="2006" onblur="validateAnno()" oninput="clearErr('anno')">
'@

if ($content.IndexOf($old1) -lt 0) {
    Write-Host "ERRORE: pattern input annoNascita non trovato" -ForegroundColor Red
    exit 1
}
if ($content.IndexOf('onblur="validateAnno()"') -ge 0) {
    Write-Host "WARN: input annoNascita gia' fixato, skip step 1" -ForegroundColor Yellow
} else {
    $content = $content.Replace($old1, $new1)
    Write-Host "[1/2] Input annoNascita: aggiunti onblur+oninput" -ForegroundColor Green
}

# ------------------------------------------------------------
# STEP 2 - Aggiungo funzione validateAnno
# Anchor stabile compat pre/post B.2.20
# ------------------------------------------------------------

$old2 = @'
var emailConfirmed = false;
function showEmailConfirm() {
'@

$new2 = @'
// Ez 05.05.26 - Bug B.2.21 fix: validazione onBlur anno nascita (4 cifre + range 1924-2006)
function validateAnno() {
  var raw = document.getElementById('annoNascita').value.trim();
  if (!raw) {
    setErr('anno', 'Inserisci anno di nascita');
    return false;
  }
  // Deve essere esattamente 4 cifre
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

var emailConfirmed = false;
function showEmailConfirm() {
'@

if ($content.IndexOf($old2) -lt 0) {
    Write-Host "ERRORE: anchor 'var emailConfirmed' non trovato" -ForegroundColor Red
    exit 1
}
if ($content.IndexOf("Bug B.2.21 fix: validazione onBlur anno nascita") -ge 0) {
    Write-Host "WARN: funzione validateAnno gia' presente, skip step 2" -ForegroundColor Yellow
} else {
    $content = $content.Replace($old2, $new2)
    Write-Host "[2/2] Funzione validateAnno aggiunta" -ForegroundColor Green
}

# ------------------------------------------------------------
# Scrittura UTF8 senza BOM
# ------------------------------------------------------------

[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "OK - Bug B.2.21 fixato" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "File scritto: $($content.Length) caratteri (UTF8 no-BOM)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Casi di test (su candidatura.html step 1):" -ForegroundColor Yellow
Write-Host "  Caso 1: clicca su Anno, scrivi '98', clicca fuori" -ForegroundColor Cyan
Write-Host "    Atteso: errore 'Anno deve avere 4 cifre (es. 1980)'" -ForegroundColor Gray
Write-Host "  Caso 2: scrivi '198', clicca fuori" -ForegroundColor Cyan
Write-Host "    Atteso: errore 'Anno deve avere 4 cifre (es. 1980)'" -ForegroundColor Gray
Write-Host "  Caso 3: scrivi '1900', clicca fuori" -ForegroundColor Cyan
Write-Host "    Atteso: errore 'Anno non valido (1924-2006)'" -ForegroundColor Gray
Write-Host "  Caso 4: scrivi '2010', clicca fuori" -ForegroundColor Cyan
Write-Host "    Atteso: errore 'Anno non valido (1924-2006)'" -ForegroundColor Gray
Write-Host "  Caso 5: scrivi '1980', clicca fuori" -ForegroundColor Cyan
Write-Host "    Atteso: niente errore" -ForegroundColor Gray
