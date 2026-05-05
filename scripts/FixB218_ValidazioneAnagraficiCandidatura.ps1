# ============================================================
# Fix Bug B.2.18 - Validazione campi anagrafici candidatura
# Target: miaspesa-landing\candidatura.html
# Convenzione: here-string @'...'@ + UTF8 senza BOM
# Data: 05/05/2026
#
# Modifiche su validateStep step 1:
# - Nome: trim + regex [A-Za-zÀ-ÿ ' -]{2,50}
# - Cognome: idem
# - Email: regex con TLD min 2 char (blocca "nome@dominio.i")
#
# Mantiene il nudge "Hai inserito X - e' corretto?" (UX)
# ma aggiunge hard regex sotto come blocco prima dello step 2.
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
# STEP 1 - Validazione nome
# ------------------------------------------------------------

$old1 = @'
    if (!nome) { setErr('nome'); ok = false; } else clearErr('nome');
'@

$new1 = @'
    // Ez 05.05.26 - Bug B.2.18 fix: validazione nome (min 2 char, lettere/spazi/apostrofi/trattini)
    if (!nome || nome.length < 2) {
      setErr('nome', 'Inserisci nome (min 2 lettere)');
      ok = false;
    } else if (!/^[A-Za-z\u00C0-\u00FF\s'\-]{2,50}$/.test(nome)) {
      setErr('nome', 'Nome non valido (solo lettere)');
      ok = false;
    } else {
      clearErr('nome');
    }
'@

if ($content.IndexOf($old1) -lt 0) {
    Write-Host "ERRORE: pattern validazione nome non trovato" -ForegroundColor Red
    exit 1
}
if ($content.IndexOf("Bug B.2.18 fix: validazione nome") -ge 0) {
    Write-Host "WARN: validazione nome gia' fixata, skip step 1" -ForegroundColor Yellow
} else {
    $content = $content.Replace($old1, $new1)
    Write-Host "[1/3] Nome: regex [A-Za-z accentate ' -] min 2 char" -ForegroundColor Green
}

# ------------------------------------------------------------
# STEP 2 - Validazione cognome
# ------------------------------------------------------------

$old2 = @'
    if (!cognome) { setErr('cognome'); ok = false; } else clearErr('cognome');
'@

$new2 = @'
    // Ez 05.05.26 - Bug B.2.18 fix: validazione cognome (min 2 char, stesse regole nome)
    if (!cognome || cognome.length < 2) {
      setErr('cognome', 'Inserisci cognome (min 2 lettere)');
      ok = false;
    } else if (!/^[A-Za-z\u00C0-\u00FF\s'\-]{2,50}$/.test(cognome)) {
      setErr('cognome', 'Cognome non valido (solo lettere)');
      ok = false;
    } else {
      clearErr('cognome');
    }
'@

if ($content.IndexOf($old2) -lt 0) {
    Write-Host "ERRORE: pattern validazione cognome non trovato" -ForegroundColor Red
    exit 1
}
if ($content.IndexOf("Bug B.2.18 fix: validazione cognome") -ge 0) {
    Write-Host "WARN: validazione cognome gia' fixata, skip step 2" -ForegroundColor Yellow
} else {
    $content = $content.Replace($old2, $new2)
    Write-Host "[2/3] Cognome: regex [A-Za-z accentate ' -] min 2 char" -ForegroundColor Green
}

# ------------------------------------------------------------
# STEP 3 - Validazione email con TLD minimo 2 char
# Blocca "nome@dominio.i" (TLD 1 char) ma accetta .it, .com, .museum
# ------------------------------------------------------------

$old3 = @'
    if (!email || !email.includes('@')) { setErr('email', 'Email non valida'); ok = false; } else clearErr('email');
'@

$new3 = @'
    // Ez 05.05.26 - Bug B.2.18 fix: regex email con TLD min 2 char (blocca nome@dominio.i)
    if (!email) {
      setErr('email', 'Inserisci email');
      ok = false;
    } else if (!/^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,}$/.test(email)) {
      setErr('email', 'Email non valida (es. nome@dominio.it)');
      ok = false;
    } else {
      clearErr('email');
    }
'@

if ($content.IndexOf($old3) -lt 0) {
    Write-Host "ERRORE: pattern validazione email non trovato" -ForegroundColor Red
    exit 1
}
if ($content.IndexOf("Bug B.2.18 fix: regex email con TLD") -ge 0) {
    Write-Host "WARN: validazione email gia' fixata, skip step 3" -ForegroundColor Yellow
} else {
    $content = $content.Replace($old3, $new3)
    Write-Host "[3/3] Email: regex con TLD min 2 char" -ForegroundColor Green
}

# ------------------------------------------------------------
# Scrittura UTF8 senza BOM
# ------------------------------------------------------------

[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "OK - Bug B.2.18 fixato" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "File scritto: $($content.Length) caratteri (UTF8 no-BOM)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Casi di test:" -ForegroundColor Yellow
Write-Host "  NOME/COGNOME VALIDI:" -ForegroundColor Cyan
Write-Host "    Mario, Rossi, Maria Grazia, D'Angelo, Maria-Luisa, Andrea" -ForegroundColor Gray
Write-Host "  NOME/COGNOME NON VALIDI (devono mostrare errore):" -ForegroundColor Cyan
Write-Host "    A (troppo corto)" -ForegroundColor Gray
Write-Host "    Mario123 (numeri non leciti)" -ForegroundColor Gray
Write-Host "    @#! (simboli)" -ForegroundColor Gray
Write-Host "  EMAIL VALIDE:" -ForegroundColor Cyan
Write-Host "    mario@gmail.com, m.rossi@nomesis.it, test@domain.museum" -ForegroundColor Gray
Write-Host "  EMAIL NON VALIDE (devono mostrare errore):" -ForegroundColor Cyan
Write-Host "    nome@dominio.i (TLD 1 char) <- IL KO ORIGINALE" -ForegroundColor Gray
Write-Host "    nome@dominio (no TLD)" -ForegroundColor Gray
Write-Host "    @dominio.it (no local part)" -ForegroundColor Gray
Write-Host "    nomedominio.it (no @)" -ForegroundColor Gray
