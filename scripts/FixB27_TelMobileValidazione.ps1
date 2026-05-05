# ============================================================
# Fix Bug B.2.7 - Validazione cellulare IT su candidatura.html
# Target: miaspesa-landing\candidatura.html
# Convenzione: here-string @'...'@ + UTF8 senza BOM
# Data: 05/05/2026
#
# Modifiche:
# 1) Input: aggiunti inputmode="tel" e maxlength="20"
# 2) JS: validazione regex cellulare IT con messaggio differenziato
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
# STEP 1 - Aggiungi inputmode="tel" e maxlength all'input HTML
# ------------------------------------------------------------

$htmlOld = @'
        <input type="tel" id="telefonoMobile" placeholder="+39 333 1234567" autocomplete="tel">
'@

$htmlNew = @'
        <!-- Ez 05.05.26 - Bug B.2.7 fix: inputmode tel + maxlength -->
        <input type="tel" id="telefonoMobile" placeholder="+39 333 1234567" autocomplete="tel" inputmode="tel" maxlength="20">
'@

if ($content.IndexOf($htmlOld) -lt 0) {
    Write-Host "ERRORE: pattern HTML input telefonoMobile non trovato" -ForegroundColor Red
    exit 1
}
if ($content.IndexOf('inputmode="tel"') -ge 0) {
    Write-Host "WARN: inputmode=tel gia' presente, skip step 1" -ForegroundColor Yellow
} else {
    $content = $content.Replace($htmlOld, $htmlNew)
    Write-Host "[1/2] HTML: aggiunti inputmode=tel + maxlength=20" -ForegroundColor Green
}

# ------------------------------------------------------------
# STEP 2 - Sostituisci la validazione JS con regex cellulare IT
# ------------------------------------------------------------

$jsOld = @'
    if (!mobile) { setErr('mobile'); ok = false; } else clearErr('mobile');
'@

$jsNew = @'
    // Ez 05.05.26 - Bug B.2.7 fix: validazione formato cellulare IT
    if (!mobile) {
      setErr('mobile', 'Campo obbligatorio');
      ok = false;
    } else {
      var mobileCleaned = mobile.replace(/[\s\-\.\(\)]/g, '');
      if (!/^(\+39|0039)?3\d{8,9}$/.test(mobileCleaned)) {
        setErr('mobile', 'Numero non valido (es. 333 1234567)');
        ok = false;
      } else {
        clearErr('mobile');
      }
    }
'@

if ($content.IndexOf($jsOld) -lt 0) {
    Write-Host "ERRORE: pattern JS validazione mobile non trovato" -ForegroundColor Red
    exit 1
}
if ($content.IndexOf('mobileCleaned') -ge 0) {
    Write-Host "WARN: validazione regex gia' presente, skip step 2" -ForegroundColor Yellow
} else {
    $content = $content.Replace($jsOld, $jsNew)
    Write-Host "[2/2] JS: validazione regex cellulare IT aggiunta" -ForegroundColor Green
}

# ------------------------------------------------------------
# STEP 3 - Scrittura UTF8 senza BOM
# ------------------------------------------------------------

[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "OK - Bug B.2.7 fixato" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "File scritto: $($content.Length) caratteri (UTF8 no-BOM)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Casi di test (mobile + desktop):" -ForegroundColor Yellow
Write-Host "  VALIDI:" -ForegroundColor Cyan
Write-Host "    +39 333 1234567" -ForegroundColor Gray
Write-Host "    3331234567" -ForegroundColor Gray
Write-Host "    +393331234567" -ForegroundColor Gray
Write-Host "    0039 333 1234567" -ForegroundColor Gray
Write-Host "    333-1234567" -ForegroundColor Gray
Write-Host "  NON VALIDI (devono mostrare 'Numero non valido'):" -ForegroundColor Cyan
Write-Host "    123456 (troppo corto)" -ForegroundColor Gray
Write-Host "    02 1234567 (numero fisso, non inizia con 3)" -ForegroundColor Gray
Write-Host "    abcd1234 (lettere)" -ForegroundColor Gray
Write-Host "    +39 333 12345678901 (troppo lungo)" -ForegroundColor Gray
Write-Host ""
Write-Host "Verifica mobile reale:" -ForegroundColor Yellow
Write-Host "  Su iOS/Android la tastiera deve aprirsi in modalita' numerica (inputmode=tel)" -ForegroundColor Yellow
