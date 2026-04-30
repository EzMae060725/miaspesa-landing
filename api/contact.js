// ============================================================
// FILE: api/contact.js
// Vercel Serverless Function — Form Contatti miaspesa.com
// VERSION: 1.0
// CREATED: 2026-04-30 12:50 (Ez)
// ============================================================
//
// Endpoint: POST /api/contact
// Body: { nome, email, motivo, messaggio, website (honeypot) }
// Response: { success: true } | { success: false, error: '...' }
//
// Mailing: SendGrid -> info@miaspesa.com (To) + panel@miaspesa.com (CC)
// From/Reply-To: rispetta dominio miaspesa.com (no nomesis.it nei flussi consumer)
// ============================================================

import sgMail from '@sendgrid/mail';

// In-memory rate-limit (per istanza serverless, sufficiente come freno spam)
// Vercel serverless ricicla le istanze, quindi questa mappa si svuota da sola
const rateLimitMap = new Map();
const RATE_LIMIT_MAX = 5;       // max submit
const RATE_LIMIT_WINDOW = 3600; // per ora (in secondi)

function getClientIp(req) {
  return (
    req.headers['x-forwarded-for']?.split(',')[0].trim() ||
    req.headers['x-real-ip'] ||
    req.socket?.remoteAddress ||
    'unknown'
  );
}

function checkRateLimit(ip) {
  const now = Math.floor(Date.now() / 1000);
  const entry = rateLimitMap.get(ip);

  if (!entry) {
    rateLimitMap.set(ip, { count: 1, windowStart: now });
    return true;
  }

  // Reset finestra se scaduta
  if (now - entry.windowStart > RATE_LIMIT_WINDOW) {
    rateLimitMap.set(ip, { count: 1, windowStart: now });
    return true;
  }

  if (entry.count >= RATE_LIMIT_MAX) {
    return false;
  }

  entry.count += 1;
  return true;
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export default async function handler(req, res) {
  // CORS / method check
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ success: false, error: 'Metodo non consentito' });
  }

  try {
    const { nome, email, motivo, messaggio, website } = req.body || {};

    // Honeypot: se compilato, è un bot. Rispondi success per non dargli feedback,
    // ma non inviare nulla.
    if (website && website.length > 0) {
      console.log('Honeypot triggered, ignoring submission from IP:', getClientIp(req));
      return res.status(200).json({ success: true });
    }

    // Validazione server-side
    if (!nome || !email || !motivo || !messaggio) {
      return res.status(400).json({ success: false, error: 'Compila tutti i campi obbligatori.' });
    }
    if (typeof nome !== 'string' || nome.length < 2 || nome.length > 100) {
      return res.status(400).json({ success: false, error: 'Nome non valido.' });
    }
    if (typeof email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 120) {
      return res.status(400).json({ success: false, error: 'Email non valida.' });
    }
    const motiviAmmessi = [
      'Domanda generale',
      'Iscrizione al panel',
      'Problema tecnico',
      'Stampa / media',
      'Collaborazioni B2B',
      'Altro'
    ];
    if (!motiviAmmessi.includes(motivo)) {
      return res.status(400).json({ success: false, error: 'Motivo non valido.' });
    }
    if (typeof messaggio !== 'string' || messaggio.length < 10 || messaggio.length > 3000) {
      return res.status(400).json({ success: false, error: 'Il messaggio deve contenere tra 10 e 3000 caratteri.' });
    }

    // Rate-limit per IP
    const ip = getClientIp(req);
    if (!checkRateLimit(ip)) {
      return res.status(429).json({ success: false, error: 'Troppe richieste. Riprova tra un\'ora.' });
    }

    // SendGrid setup
    const apiKey = process.env.SENDGRID_API_KEY;
    if (!apiKey) {
      console.error('SENDGRID_API_KEY non configurata');
      return res.status(500).json({ success: false, error: 'Servizio email temporaneamente non disponibile.' });
    }
    sgMail.setApiKey(apiKey);

    const toEmail = process.env.CONTACT_TO_EMAIL || 'info@miaspesa.com';
    const ccEmail = process.env.CONTACT_CC_EMAIL || 'panel@miaspesa.com';
    const fromEmail = process.env.CONTACT_FROM_EMAIL || 'info@miaspesa.com';
    const fromName = 'Form Contatti — miaspesa.com';

    // Costruzione email
    const subject = `[Contatti miaspesa] ${motivo} — ${nome}`;

    const textBody = [
      `Nuovo messaggio dal form Contatti di miaspesa.com`,
      ``,
      `Da: ${nome} <${email}>`,
      `Motivo: ${motivo}`,
      `IP: ${ip}`,
      `Data: ${new Date().toISOString()}`,
      ``,
      `--- Messaggio ---`,
      messaggio,
      `---`,
    ].join('\n');

    const htmlBody = `
<div style="font-family:'DM Sans',Arial,sans-serif;max-width:640px;margin:0 auto;color:#1A1A2E;">
  <div style="background:#3C3489;color:#fff;padding:20px 24px;border-radius:12px 12px 0 0;">
    <h2 style="margin:0;font-size:1.1rem;font-weight:600;">Nuovo messaggio dal form Contatti</h2>
    <div style="opacity:0.85;font-size:0.85rem;margin-top:4px;">miaspesa.com</div>
  </div>
  <div style="background:#fff;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 12px 12px;padding:24px;">
    <table style="width:100%;border-collapse:collapse;font-size:0.92rem;margin-bottom:18px;">
      <tr><td style="padding:6px 0;color:#6B7280;width:90px;">Da:</td><td style="padding:6px 0;font-weight:600;">${escapeHtml(nome)} &lt;${escapeHtml(email)}&gt;</td></tr>
      <tr><td style="padding:6px 0;color:#6B7280;">Motivo:</td><td style="padding:6px 0;font-weight:600;">${escapeHtml(motivo)}</td></tr>
      <tr><td style="padding:6px 0;color:#6B7280;">IP:</td><td style="padding:6px 0;font-family:monospace;font-size:0.85rem;">${escapeHtml(ip)}</td></tr>
      <tr><td style="padding:6px 0;color:#6B7280;">Data:</td><td style="padding:6px 0;">${new Date().toLocaleString('it-IT', { timeZone: 'Europe/Rome' })}</td></tr>
    </table>
    <div style="background:#F3F4F6;padding:18px 20px;border-radius:8px;border-left:3px solid #3C3489;">
      <div style="font-size:0.78rem;color:#6B7280;text-transform:uppercase;letter-spacing:1px;margin-bottom:8px;">Messaggio</div>
      <div style="white-space:pre-wrap;line-height:1.6;">${escapeHtml(messaggio)}</div>
    </div>
    <div style="margin-top:20px;font-size:0.82rem;color:#6B7280;">
      Per rispondere, usa il pulsante "Rispondi" del client email — il Reply-To è impostato su ${escapeHtml(email)}.
    </div>
  </div>
</div>`;

    const msg = {
      to: toEmail,
      cc: ccEmail,
      from: { email: fromEmail, name: fromName },
      replyTo: { email: email, name: nome },
      subject: subject,
      text: textBody,
      html: htmlBody,
    };

    await sgMail.send(msg);

    console.log(`Contact form submitted by ${email} (${motivo}) from IP ${ip}`);

    return res.status(200).json({ success: true });

  } catch (err) {
    console.error('Contact form error:', err?.response?.body || err.message || err);
    return res.status(500).json({
      success: false,
      error: 'Si è verificato un errore. Riprova più tardi o scrivi direttamente a info@miaspesa.com.'
    });
  }
}
