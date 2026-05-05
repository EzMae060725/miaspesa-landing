# ============================================================
# Fix Bug B.2.19 - Regex email PRIMA del nudge di conferma
# Target: miaspesa-landing\candidatura.html
# Convenzione: here-string @'...'@ + UTF8 senza BOM
# Data: 05/05/2026
#
# Problema: la funzione showEmailConfirm() apriva il nudge
# "Hai inserito X - e' corretto?" con il solo check
# !email.includes('@'). L'utente confermava email rotte
# (es. "nome@dominio.i") e l'errore arrivava solo al click
# Avanti, dopo aver "certificato" un'email invalida.
#
# Soluzione: regex hard come gate. Se KO -> setErr inline
# subito + non mostra il nudge. Se OK -> nudge come oggi.
#
# Nota: la regex hard in validateStep (B.2.18) resta come
# double-check di sicurezza contro bypass JS.
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
# Sostituzione showEmailConfirm con regex gate
# ------------------------------------------------------------

$old = @'
function showEmailConfirm() {
  var email = document.getElementById('email').value.trim();
  if (!email || !email.includes('@')) return;
  if (emailConfirmed) return;
  document.getElementById('email-preview').textContent = email;
  document.getElementById('email-confirm').style.display = 'block';
  document.getElementById('email-ok').style.display = 'none';
}
'@

$new = @'
function showEmailConfirm() {
  // Ez 05.05.26 - Bug B.2.19 fix: regex hard PRIMA del nudge di conferma
  var email = document.getElementById('email').value.trim();
  if (!email) {
    document.getElementById('email-confirm').style.display = 'none';
    return;
  }
  // Regex con TLD min 2 char (coerente con validateStep)
  if (!/^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,}$/.test(email)) {
    setErr('email', 'Email non valida (es. nome@dominio.it)');
    document.getElementById('email-confirm').style.display = 'none';
    document.getElementById('email-ok').style.display = 'none';
    emailConfirmed = false;
    return;
  }
  // Email sintatticamente valida: pulisce errore e mostra nudge semantico
  clearErr('email');
  if (emailConfirmed) return;
  document.getElementById('email-preview').textContent = email;
  document.getElementById('email-confirm').style.display = 'block';
  document.getElementById('email-ok').style.display = 'none';
}
'@

if ($content.IndexOf($old) -lt 0) {
    if ($content.IndexOf("Bug B.2.19 fix: regex hard PRIMA del nudge") -ge 0) {
        Write-Host "WARN: gia' fixato, niente da fare" -ForegroundColor Yellow
        exit 0
    }
    Write-Host "ERRORE: pattern showEmailConfirm non trovato" -ForegroundColor Red
    exit 1
}

$content = $content.Replace($old, $new)
Write-Host "[OK] showEmailConfirm: regex gate aggiunto prima del nudge" -ForegroundColor Green

# ------------------------------------------------------------
# Scrittura UTF8 senza BOM
# ------------------------------------------------------------

[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "OK - Bug B.2.19 fixato" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "File scritto: $($content.Length) caratteri (UTF8 no-BOM)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Casi di test (su candidatura.html step 1):" -ForegroundColor Yellow
Write-Host "  Caso 1: digita 'nome@dominio.i' -> click fuori dal campo" -ForegroundColor Cyan
Write-Host "    Atteso: errore inline 'Email non valida (es. nome@dominio.it)'" -ForegroundColor Gray
Write-Host "    Atteso: NESSUN nudge 'Hai inserito X - e' corretto?'" -ForegroundColor Gray
Write-Host ""
Write-Host "  Caso 2: digita 'nome@dominio.it' -> click fuori dal campo" -ForegroundColor Cyan
Write-Host "    Atteso: niente errore inline" -ForegroundColor Gray
Write-Host "    Atteso: appare nudge 'Hai inserito nome@dominio.it - e' corretto?'" -ForegroundColor Gray
Write-Host "    Click 'Si, e' corretta' -> nudge sparisce, appare '[v] Email confermata'" -ForegroundColor Gray
Write-Host ""
Write-Host "  Caso 3: confermo OK, poi torno a editare l'email a 'nome@dominio.i'" -ForegroundColor Cyan
Write-Host "    Atteso: emailConfirmed reset a false" -ForegroundColor Gray
Write-Host "    Atteso: errore inline al blur" -ForegroundColor Gray
