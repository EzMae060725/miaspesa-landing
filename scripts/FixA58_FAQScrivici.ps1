# ============================================================
# Fix Bug A.5.8 - Link "Hai altre domande? Scrivici" sotto FAQ
# Target: miaspesa-landing\index.html
# Convenzione: here-string @'...'@ + UTF8 senza BOM
# Data: 05/05/2026
# ============================================================

$ErrorActionPreference = "Stop"

$path = "C:\Users\ACER\OneDrive\Desktop\Progetti\miaspesa-landing\index.html"

if (-not (Test-Path $path)) {
    Write-Host "ERRORE: file non trovato: $path" -ForegroundColor Red
    exit 1
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$content = [System.IO.File]::ReadAllText($path, $utf8NoBom)

Write-Host "File letto: $($content.Length) caratteri" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# STEP 1 - Aggiungi CSS .faq-more dopo gli stili FAQ esistenti
# ------------------------------------------------------------

$cssOld = @'
  .faq-item.open .faq-a { display: block; padding-top: 14px; }
'@

$cssNew = @'
  .faq-item.open .faq-a { display: block; padding-top: 14px; }
  /* Ez 05.05.26 - Bug A.5.8 fix: stile link "Scrivici" sotto FAQ */
  .faq-more {
    text-align: center;
    margin-top: 56px;
    font-size: 0.95rem;
    color: var(--grigio);
  }
  .faq-more a {
    color: var(--viola);
    font-weight: 700;
    text-decoration: none;
    border-bottom: 2px solid var(--viola);
    padding-bottom: 2px;
    margin-left: 4px;
    transition: opacity 0.2s, border-color 0.2s;
  }
  .faq-more a:hover { opacity: 0.7; }
'@

if ($content.IndexOf($cssOld) -lt 0) {
    Write-Host "ERRORE: pattern CSS non trovato (faq-item.open .faq-a)" -ForegroundColor Red
    exit 1
}
if ($content.IndexOf("/* Ez 05.05.26 - Bug A.5.8 fix") -ge 0) {
    Write-Host "WARN: il CSS .faq-more risulta gia' presente, skip step 1" -ForegroundColor Yellow
} else {
    $content = $content.Replace($cssOld, $cssNew)
    Write-Host "[1/2] CSS .faq-more aggiunto" -ForegroundColor Green
}

# ------------------------------------------------------------
# STEP 2 - Aggiungi link HTML prima della chiusura .faq-inner
# ------------------------------------------------------------

$htmlOld = @'
      <div class="faq-a">Ricevi le credenziali di accesso entro 48 ore. Da quel momento puoi iniziare a caricare scontrini e guadagnare punti. Prima di iniziare, ti consigliamo di esplorare l'ambiente di prova qui sopra.</div>
    </div>
  </div>
</section>

<!-- RASSICURAZIONI -->
'@

$htmlNew = @'
      <div class="faq-a">Ricevi le credenziali di accesso entro 48 ore. Da quel momento puoi iniziare a caricare scontrini e guadagnare punti. Prima di iniziare, ti consigliamo di esplorare l'ambiente di prova qui sopra.</div>
    </div>
    <!-- Ez 05.05.26 - Bug A.5.8 fix: link "Scrivici" sotto FAQ, punta a contatti.html (coerente con footer) -->
    <p class="faq-more reveal">Hai altre domande?<a href="contatti.html">Scrivici</a></p>
  </div>
</section>

<!-- RASSICURAZIONI -->
'@

if ($content.IndexOf($htmlOld) -lt 0) {
    Write-Host "ERRORE: pattern HTML non trovato (chiusura faq-inner)" -ForegroundColor Red
    exit 1
}
if ($content.IndexOf('class="faq-more reveal"') -ge 0) {
    Write-Host "WARN: il link HTML risulta gia' presente, skip step 2" -ForegroundColor Yellow
} else {
    $content = $content.Replace($htmlOld, $htmlNew)
    Write-Host "[2/2] Link HTML aggiunto prima della chiusura .faq-inner" -ForegroundColor Green
}

# ------------------------------------------------------------
# STEP 3 - Scrittura UTF8 senza BOM
# ------------------------------------------------------------

[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "OK - Bug A.5.8 fixato" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "File scritto: $($content.Length) caratteri (UTF8 no-BOM)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Verifica visiva:" -ForegroundColor Yellow
Write-Host "  1. Apri index.html in browser" -ForegroundColor Yellow
Write-Host "  2. Scrolla fino a fondo FAQ" -ForegroundColor Yellow
Write-Host "  3. Controlla che 'Hai altre domande? Scrivici' sia visibile e cliccabile" -ForegroundColor Yellow
Write-Host "  4. Click su Scrivici -> deve aprire contatti.html" -ForegroundColor Yellow
