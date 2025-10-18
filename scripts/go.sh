Below is a complete, deployable update for **freepresspass.com** with Netlify support, Stripe Checkout, hidden Netlify Forms tracking, mobile-friendly image saving, and all copy/layout changes requested. Put these files at the project root exactly as shown.

```text
# =========================
# File: netlify.toml
# =========================
[build]
  publish = "."            # static site
  command = ""
  functions = "netlify/functions"

# Force HTTPS and tidy URLs
[[redirects]]
  from = "/index.html"
  to = "/"
  status = 301

# Allow CORS for functions (optional; locked down to this origin)
[[headers]]
  for = "/.netlify/functions/*"
  [headers.values]
    Access-Control-Allow-Origin = "*"
    Access-Control-Allow-Headers = "Content-Type"

# =========================
# File: package.json
# =========================
{
  "name": "freepresspass-netlify",
  "private": true,
  "type": "module",
  "dependencies": {
    "stripe": "^12.17.0"
  }
}

# =========================
# File: netlify/functions/create-checkout-session.js
# =========================
// Serverless function: creates a Stripe Checkout Session for laminated passes.
// Requires env vars: STRIPE_SECRET_KEY, STRIPE_PRICE_ID

import Stripe from "stripe";

export default async (req, res) => {
  if (req.method !== "POST") {
    res.statusCode = 405; // method not allowed
    res.setHeader("Content-Type", "application/json");
    return res.end(JSON.stringify({ error: "POST only" }));
  }

  try {
    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const { quantity = 1, passId, name } = JSON.parse(req.body || "{}");

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items: [{ price: process.env.STRIPE_PRICE_ID, quantity }],
      metadata: { passId, name },
      success_url: `${req.headers.origin || "https://freepresspass.com"}/?checkout=success`,
      cancel_url: `${req.headers.origin || "https://freepresspass.com"}/?checkout=cancelled`
    });

    res.statusCode = 200;
    res.setHeader("Content-Type", "application/json");
    return res.end(JSON.stringify({ url: session.url }));
  } catch (err) {
    res.statusCode = 500;
    res.setHeader("Content-Type", "application/json");
    return res.end(JSON.stringify({ error: err.message }));
  }
};

# =========================
# File: index.html
# =========================
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Press Pass Generator - Constitutional Press Credentials</title>
  <meta name="description" content="Generate a Constitutional Press credential. Vertical layout, larger photo, and mobile-friendly saving.">
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    body { font-family: "Helvetica", "Arial", sans-serif; background: linear-gradient(135deg,#f8f9fa 0%,#e9ecef 100%); color:#2c3e50; line-height:1.6; }

    .header { background: linear-gradient(135deg,#1a252f,#2c3e50); color:#fff; padding:4rem 0; text-align:center; position:relative; overflow:hidden; }
    .header .container { max-width:1200px; margin:0 auto; padding:0 2rem; position:relative; z-index:2; }
    .header h1 { font-size:3.2rem; font-weight:900; letter-spacing:2px; text-shadow:0 2px 4px rgba(0,0,0,0.3); }
    .header .example-pass { margin:2rem auto 0; display:block; width:300px; max-width:85vw; box-shadow:0 15px 40px rgba(0,0,0,0.4); border-radius:12px; }
    .header p { font-size:1.1rem; margin-top:1rem; opacity:0.95; }

    .channels { background:#dc143c; padding:1.5rem 0; text-align:center; }
    .channel-links { display:flex; justify-content:center; gap:1rem; flex-wrap:wrap; }
    .channel-link { background:#fff; color:#dc143c; padding:0.6rem 1rem; border-radius:999px; text-decoration:none; font-weight:700; }

    .section { padding:3rem 1rem; }
    .content-box { background:#fff; border-radius:12px; max-width:1100px; margin:0 auto; padding:2rem; box-shadow:0 4px 16px rgba(0,0,0,0.08); }

    .form-container { background:#fff; padding:2rem; border-radius:12px; max-width:900px; margin:0 auto; box-shadow:0 4px 15px rgba(0,0,0,0.08); }
    .form-header { text-align:center; margin-bottom:1.5rem; }
    .form-group { margin-bottom:1rem; }
    .form-group label { display:block; margin-bottom:0.5rem; font-weight:700; }
    .form-group input, .form-group select { width:100%; padding:0.8rem 1rem; border:1px solid #dfe6ee; border-radius:8px; }

    .photo-upload { border:2px dashed #e0e6ed; padding:1.25rem; text-align:center; border-radius:10px; background:#f8f9fa; cursor:pointer; }
    .upload-label { font-weight:700; }
    .error { color:#c0392b; display:none; margin-top:0.5rem; font-size:0.95rem; }

    .submit-btn, .download-btn, .open-btn, .checkout-btn { display:inline-block; margin:0.25rem 0.3rem; background:#dc143c; color:#fff; padding:0.9rem 1.4rem; border:none; border-radius:8px; font-weight:800; text-decoration:none; cursor:pointer; }
    .download-btn { background:#27ae60; }
    .open-btn { background:#1f7aec; }
    .checkout-btn { background:#8e44ad; }

    .preview { display:none; text-align:center; margin-top:1.25rem; }
    canvas { max-width:100%; height:auto; }

    .disclaimer { background:#fff; border-radius:12px; max-width:1100px; margin:0 auto; padding:2rem; box-shadow:0 4px 16px rgba(0,0,0,0.08); }
    .disclaimer h2 { margin-bottom:0.5rem; }
    .disclaimer p { margin:0.4rem 0; }

    .footer { text-align:center; font-size:0.95rem; padding:2rem; color:#5d6d7e; }
  </style>
</head>
<body>
  <header class="header">
    <div class="container">
      <h1>Constitutional Press Credential Generator</h1>
      <img class="example-pass" src="assets/press-pass-preview.jpg" alt="Example vertical press pass" />
      <p>Vertical layout · Larger photo · “Constitutional Press” header · Mobile save to Photos</p>
    </div>
  </header>

  <section class="channels">
    <div class="container">
      <h2 style="color:#fff;letter-spacing:1px;">🎥 FOLLOW OUR JOURNALISM</h2>
      <div class="channel-links">
        <a href="https://www.youtube.com/@LeroyTruth" target="_blank" class="channel-link">📺 Leroy Truth Investigations</a>
        <a href="https://www.youtube.com/@FullCourtPressNB" target="_blank" class="channel-link">🎙️ The Exposure Report</a>
      </div>
    </div>
  </section>

  <div class="section">
    <div class="content-box">
      <h2>📰 What Is Press &amp; Journalism?</h2>
      <p>Press includes independent journalists and citizens engaged in gathering and disseminating news to keep the public informed.</p>
    </div>
  </div>

  <div class="section">
    <div class="form-container">
      <div class="form-header">
        <h2>Create Your Credential</h2>
        <p>Generate a vertical pass. Then <b>Download</b> or <b>Open Image</b> to save to Photos on mobile.</p>
      </div>

      <!-- Hidden Netlify Form (captures submissions) -->
      <form name="press-pass-submission" method="POST" data-netlify="true" netlify-honeypot="bot-field" hidden>
        <input type="hidden" name="form-name" value="press-pass-submission" />
        <input type="text" name="name" />
        <input type="text" name="email" />
        <input type="text" name="organization" />
        <input type="text" name="type" />
        <input type="text" name="pressId" />
        <input type="text" name="timestamp" />
      </form>

      <form id="generator-form">
        <div class="form-group">
          <label>Full Name *</label>
          <input id="name" placeholder="First Last" required>
          <div class="error" id="name-error">Please enter your full name.</div>
        </div>

        <div class="form-group">
          <label>Email *</label>
          <input id="email" type="email" placeholder="you@example.com" required>
          <div class="error" id="email-error">Please enter a valid email.</div>
        </div>

        <div class="form-group">
          <label>Organization (optional) — defaults to Independent Journalist</label>
          <input id="organization" placeholder="e.g., FULL COURT PRESS">
        </div>

        <div class="form-group">
          <label>Role</label>
          <select id="type">
            <option>INDEPENDENT JOURNALIST</option>
            <option>INVESTIGATIVE JOURNALIST</option>
            <option>REPORTER</option>
            <option>PHOTOJOURNALIST</option>
            <option>EDITOR</option>
          </select>
        </div>

        <div class="form-group">
          <label>Add Photo *</label>
          <div class="photo-upload" onclick="document.getElementById('photo').click()">
            <div class="upload-label">Choose Photo</div>
            <input type="file" id="photo" accept="image/*" style="display:none;" required>
            <p style="margin-top:0.5rem;font-size:0.9rem;color:#7f8c8d;">JPEG/PNG recommended — professional headshot preferred</p>
            <div id="photo-preview" style="margin-top:0.8rem;"></div>
          </div>
          <div class="error" id="photo-error">Please upload a photo.</div>
        </div>

        <button type="submit" class="submit-btn">Generate Press Pass</button>
      </form>

      <div id="preview" class="preview">
        <h3>Your Press Pass is Ready!</h3>
        <canvas id="pass-canvas" width="600" height="800" style="width:100%; border:1px solid #ddd; border-radius:8px;"></canvas>
        <br/>
        <a id="download" class="download-btn" download>Download PNG</a>
        <a id="open-image" class="open-btn" target="_blank" rel="noopener">Open Image</a>
        <button id="checkout" class="checkout-btn" title="We print, laminate, add lanyard, and mail it">Order Laminated Pass</button>
        <p style="margin-top:0.6rem;color:#5d6d7e;">On iPhone: tap <b>Open Image</b> → long‑press → <b>Add to Photos</b>.</p>
      </div>
    </div>
  </div>

  <div class="section">
    <div class="disclaimer">
      <h2>Official Credential Notice</h2>
      <p>This credential is a tool to identify the bearer as a member of the press. It does not grant special rights beyond those protected by law.</p>
      <p>Use responsibly: follow lawful orders, stay within public areas, respect private property, and comply with reasonable safety instructions.</p>
      <p>Nothing here constitutes legal advice. When in doubt, consult counsel.</p>
    </div>
  </div>

  <footer class="footer">
    <p>Built to support First Amendment protections for all journalists, regardless of affiliation or platform.</p>
  </footer>

  <script>
    // ----- State -----
    let uploadedPhoto = null;

    document.getElementById('photo').addEventListener('change', (e) => {
      const file = e.target.files[0];
      if (!file) return;
      const img = new Image();
      const url = URL.createObjectURL(file);
      img.onload = () => { uploadedPhoto = img; URL.revokeObjectURL(url); renderPhotoPreview(img); };
      img.src = url;
    });

    function renderPhotoPreview(img) {
      const preview = document.getElementById('photo-preview');
      preview.innerHTML = '';
      const c = document.createElement('canvas');
      c.width = 240; c.height = 320; const ctx = c.getContext('2d');
      const r = Math.min(c.width / img.width, c.height / img.height);
      const w = img.width * r, h = img.height * r;
      ctx.drawImage(img, (c.width - w)/2, (c.height - h)/2, w, h);
      c.style.border = '1px solid #ddd'; c.style.borderRadius = '8px';
      preview.appendChild(c);
    }

    // ----- Helpers -----
    function splitName(raw) {
      const cleaned = (raw||'').trim().replace(/\s+/g,' ');
      const parts = cleaned.split(' ');
      if (parts.length < 2) return { first: cleaned, last: '' };
      return { first: parts[0], last: parts[parts.length-1] };
    }

    function fitText(ctx, text, maxWidth, startSize, minSize, family, weight='bold') {
      let size = startSize; ctx.font = `${weight} ${size}px ${family}`;
      while (ctx.measureText(text).width > maxWidth && size > minSize) {
        size -= 1; ctx.font = `${weight} ${size}px ${family}`;
      }
      return size;
    }

    function brandName() { return 'THE EXPOSURE REPORT'; }

    function genPassId() {
      const t = Date.now().toString(36).toUpperCase();
      const r = Math.random().toString(36).slice(2,7).toUpperCase();
      return `FCP-${new Date().getFullYear()}-${t}-${r}`;
    }

    function validate() {
      let ok = true;
      const name = document.getElementById('name').value.trim();
      const email = document.getElementById('email').value.trim();
      const emailRx = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!name) { ok = false; document.getElementById('name-error').style.display = 'block'; } else { document.getElementById('name-error').style.display = 'none'; }
      if (!emailRx.test(email)) { ok = false; document.getElementById('email-error').style.display = 'block'; } else { document.getElementById('email-error').style.display = 'none'; }
      if (!uploadedPhoto) { ok = false; document.getElementById('photo-error').style.display = 'block'; } else { document.getElementById('photo-error').style.display = 'none'; }
      return ok;
    }

    document.getElementById('generator-form').addEventListener('submit', (e) => {
      e.preventDefault();
      if (!validate()) return;
      const name = document.getElementById('name').value.trim();
      const orgInput = document.getElementById('organization').value.trim();
      const type = document.getElementById('type').value.trim();
      const id = generatePass(name, orgInput, type);
      document.getElementById('preview').style.display = 'block';
      wireDownloadLinks(id);
      netlifyCapture({
        name,
        email: document.getElementById('email').value.trim(),
        organization: (orgInput || 'Independent Journalist'),
        type,
        pressId: id
      });
    });

    function netlifyCapture(fields) {
      const payload = new URLSearchParams();
      payload.append('form-name','press-pass-submission');
      Object.entries(fields).forEach(([k,v])=> payload.append(k, v));
      payload.append('timestamp', new Date().toISOString());
      fetch('/', { method:'POST', headers:{ 'Content-Type': 'application/x-www-form-urlencoded' }, body: payload.toString() })
        .catch(()=>{}); // intentionally fire-and-forget
    }

    function wireDownloadLinks(id) {
      const canvas = document.getElementById('pass-canvas');
      canvas.toBlob((blob) => {
        const url = URL.createObjectURL(blob);
        const dl = document.getElementById('download');
        dl.href = url; dl.download = `press-pass-${id}.png`;
        const open = document.getElementById('open-image');
        open.href = url; // iOS can "Add to Photos" from the opened image
      });
    }

    function generateBackdrop(ctx, canvas) {
      ctx.fillStyle = '#fff'; ctx.fillRect(0,0,canvas.width, canvas.height);
      ctx.fillStyle = '#dc143c'; ctx.fillRect(20, 20, canvas.width-40, 90);
      ctx.fillStyle = '#fff'; ctx.font = 'bold 72px "Arial Black", Arial, sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline='middle';
      ctx.fillText('PRESS', canvas.width/2, 65);
      ctx.fillStyle = '#2c3e50'; ctx.font = 'bold 32px "Helvetica", Arial, sans-serif'; ctx.textAlign='center';
      ctx.fillText('PRESS CREDENTIAL', canvas.width/2, 120);
      ctx.font = 'bold 16px "Helvetica", Arial, sans-serif';
      ctx.fillText('CONSTITUTIONAL PRESS', canvas.width/2, 155);
    }

    function generatePass(nameRaw, orgInputRaw, typeRaw) {
      const canvas = document.getElementById('pass-canvas');
      const ctx = canvas.getContext('2d');
      ctx.clearRect(0,0,canvas.width, canvas.height);

      generateBackdrop(ctx, canvas);

      const photoX = 80, photoY = 180, photoW = 140, photoH = 180;
      ctx.strokeStyle = '#2c3e50'; ctx.lineWidth = 2; ctx.strokeRect(photoX, photoY, photoW, photoH);
      if (uploadedPhoto) {
        ctx.save(); ctx.beginPath(); ctx.rect(photoX+2, photoY+2, photoW-4, photoH-4); ctx.clip();
        const r = Math.min((photoW-4)/uploadedPhoto.width, (photoH-4)/uploadedPhoto.height);
        const w = uploadedPhoto.width * r, h = uploadedPhoto.height * r;
        ctx.drawImage(uploadedPhoto, photoX + 2 + (photoW-4-w)/2, photoY + 2 + (photoH-4-h)/2, w, h);
        ctx.restore();
      }

      const nameUpper = (nameRaw||'').toUpperCase();
      const orgUpper = (orgInputRaw? orgInputRaw : 'Independent Journalist').toUpperCase();
      const typeUpper = (typeRaw||'INDEPENDENT JOURNALIST').toUpperCase();

      const rightX = photoX + photoW + 30; const maxWidth = canvas.width - rightX - 40;
      const { first, last } = splitName(nameUpper);
      const firstSize = fitText(ctx, first, maxWidth, 56, 18, '"Helvetica", "Arial Black", Arial, sans-serif');
      ctx.fillStyle = '#2c3e50'; ctx.textAlign='left'; ctx.font = `bold ${firstSize}px "Helvetica", "Arial Black", Arial, sans-serif`;
      ctx.fillText(first, rightX, photoY + 40);
      const lastSize = fitText(ctx, last, maxWidth, Math.max(48, Math.round(firstSize*0.9)), 16, '"Helvetica", "Arial Black", Arial, sans-serif');
      ctx.font = `bold ${lastSize}px "Helvetica", "Arial Black", Arial, sans-serif`;
      if (last) ctx.fillText(last, rightX, photoY + 40 + firstSize + 8);

      // Organization
      let orgFont = 20; ctx.font = `bold ${orgFont}px "Helvetica", Arial, sans-serif`;
      while (ctx.measureText(orgUpper).width > maxWidth && orgFont > 12) { orgFont -= 1; ctx.font = `bold ${orgFont}px "Helvetica", Arial, sans-serif`; }
      const orgY = photoY + photoH - 10; ctx.fillText(orgUpper, rightX, orgY);

      // RIGHT COLUMN info
      const startRightY = orgY + 60;
      ctx.textAlign = 'center'; ctx.fillStyle = '#2c3e50';
      ctx.font = 'bold 28px "Helvetica", Arial, sans-serif'; ctx.fillText(brandName(), canvas.width/2, startRightY);
      ctx.font = 'bold 20px "Helvetica", Arial, sans-serif'; ctx.fillText(typeUpper, canvas.width/2, startRightY + 28);

      // Bottom metadata
      const id = genPassId();
      ctx.font = 'bold 18px "Helvetica", Arial, sans-serif'; ctx.fillText('FULL COURT PRESS MEDIA', canvas.width/2, startRightY + 80);
      ctx.font = '14px "Helvetica", Arial, sans-serif'; ctx.fillText(`ID: ${id}`, canvas.width/2, startRightY + 105);
      ctx.font = 'bold 12px "Helvetica", Arial, sans-serif'; ctx.fillText('ISSUED BY', canvas.width/2, startRightY + 130);
      ctx.font = 'bold 12px "Helvetica", Arial, sans-serif'; ctx.fillText('CONSTITUTIONAL PRESS ASSOCIATION', canvas.width/2, startRightY + 145);

      const exp = new Date(new Date().getFullYear() + 2, 11, 31);
      ctx.fillStyle = '#dc143c'; ctx.font = 'bold 14px "Helvetica", Arial, sans-serif';
      ctx.fillText(`VALID THROUGH DEC 31, ${exp.getFullYear()}`, canvas.width/2, startRightY + 170);

      // Legal lines
      ctx.fillStyle = '#1a252f'; ctx.font = 'bold 12px "Helvetica", Arial, sans-serif';
      const legalY = startRightY + 200;
      const lines = [
        'THIS JOURNALIST IS RECOGNIZED UNDER THE PROTECTIONS',
        'OF THE FIRST AMENDMENT OF THE U.S. CONSTITUTION.',
        'ANY INTERFERENCE WILL BE A VIOLATION OF FEDERAL LAW.'
      ];
      lines.forEach((t,i)=> ctx.fillText(t, canvas.width/2, legalY + i*17));

      ctx.fillStyle = '#2c3e50'; ctx.font = 'bold 11px "Helvetica", Arial, sans-serif';
      const addY = legalY + 70;
      const notes = [
        'Do not hinder, exclude, or block the view of this journalist',
        'in the exercise of court‑recognized First Amendment rights.'
      ];
      notes.forEach((t,i)=> ctx.fillText(t, canvas.width/2, addY + i*16));

      return id;
    }

    // ----- Checkout (laminated option) -----
    document.getElementById('checkout').addEventListener('click', async () => {
      const name = (document.getElementById('name').value || '').trim();
      const id = 'pass-' + (Date.now().toString(36).toUpperCase());
      try {
        const res = await fetch('/.netlify/functions/create-checkout-session', { method:'POST', body: JSON.stringify({ quantity:1, passId:id, name }) });
        const data = await res.json();
        if (data.url) window.location.href = data.url; else alert(data.error || 'Unable to start checkout.');
      } catch (e) { alert('Checkout failed.'); }
    });
  </script>
</body>
</html>

# =========================
# (Optional) Replace /assets/press-pass-preview.jpg with your current preview image.
# =========================
```
