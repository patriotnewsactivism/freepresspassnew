import Head from 'next/head';
import Script from 'next/script';
import { useCallback, useEffect, useRef, useState } from 'react';

const DEFAULT_NAME = 'YOUR NAME HERE';
const DEFAULT_TITLE = 'Investigative Journalist';
const BRAND_NAME = 'CONSTITUTIONAL PRESS ASSOCIATION';

const genPassId = () => `pass-${Math.random().toString(36).substring(2, 10).toUpperCase()}`;

export default function Home() {
  const canvasRef = useRef(null);
  const [name, setName] = useState('');
  const [title, setTitle] = useState(DEFAULT_TITLE);
  const [photo, setPhoto] = useState(null);

  const drawPass = useCallback((displayName, displayTitle, photoImage) => {
    const canvas = canvasRef.current;
    if (!canvas) return null;
    const ctx = canvas.getContext('2d');
    if (!ctx) return null;

    const nameText = (displayName || DEFAULT_NAME).toString();
    const titleText = (displayTitle || DEFAULT_TITLE).toString();

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    ctx.fillStyle = '#f8f9fa';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.strokeStyle = '#2c3e50';
    ctx.lineWidth = 3;
    ctx.strokeRect(5, 5, canvas.width - 10, canvas.height - 10);

    const headerHeight = 80;
    ctx.fillStyle = '#dc143c';
    ctx.fillRect(0, 0, canvas.width, headerHeight);

    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 24px "Helvetica", Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('PRESS PASS', canvas.width / 2, 35);

    const photoX = 20;
    const photoY = 100;
    const photoW = canvas.width - 40;
    const photoH = 250;

    ctx.fillStyle = '#e9ecef';
    ctx.fillRect(photoX, photoY, photoW, photoH);

    if (photoImage) {
      const ratio = Math.min(photoW / photoImage.width, photoH / photoImage.height);
      const drawW = photoImage.width * ratio;
      const drawH = photoImage.height * ratio;
      const offsetX = photoX + (photoW - drawW) / 2;
      const offsetY = photoY + (photoH - drawH) / 2;
      ctx.drawImage(photoImage, offsetX, offsetY, drawW, drawH);
    } else {
      ctx.fillStyle = '#2c3e50';
      ctx.font = '18px "Helvetica", Arial, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('PHOTO AREA', canvas.width / 2, 225);
    }

    const orgY = 370;
    ctx.textAlign = 'center';
    ctx.fillStyle = '#2c3e50';
    ctx.font = 'bold 32px "Helvetica", Arial, sans-serif';
    ctx.fillText(nameText || DEFAULT_NAME, canvas.width / 2, orgY);

    const startRightY = orgY + 70;
    ctx.textAlign = 'center';
    ctx.fillStyle = '#2c3e50';
    ctx.font = 'bold 32px "Helvetica", Arial, sans-serif';
    ctx.fillText(BRAND_NAME, canvas.width / 2, startRightY);
    ctx.font = 'bold 24px "Helvetica", Arial, sans-serif';
    ctx.fillText(titleText, canvas.width / 2, startRightY + 35);

    const id = genPassId();
    ctx.font = 'bold 18px "Helvetica", Arial, sans-serif';
    ctx.fillText('FULL COURT PRESS MEDIA', canvas.width / 2, startRightY + 80);
    ctx.font = '14px "Helvetica", Arial, sans-serif';
    ctx.fillText(`ID: ${id}`, canvas.width / 2, startRightY + 105);
    ctx.font = 'bold 12px "Helvetica", Arial, sans-serif';
    ctx.fillText('ISSUED BY', canvas.width / 2, startRightY + 130);
    ctx.font = 'bold 12px "Helvetica", Arial, sans-serif';
    ctx.fillText(BRAND_NAME, canvas.width / 2, startRightY + 145);

    const exp = new Date(new Date().getFullYear() + 2, 11, 31);
    ctx.fillStyle = '#dc143c';
    ctx.font = 'bold 14px "Helvetica", Arial, sans-serif';
    ctx.fillText(`VALID THROUGH DEC 31, ${exp.getFullYear()}`, canvas.width / 2, startRightY + 170);

    ctx.fillStyle = '#1a252f';
    ctx.font = 'bold 12px "Helvetica", Arial, sans-serif';
    const legalY = startRightY + 200;
    const lines = [
      'THIS JOURNALIST IS RECOGNIZED UNDER THE PROTECTIONS',
      'OF THE FIRST AMENDMENT OF THE U.S. CONSTITUTION.',
      'ANY INTERFERENCE WILL BE A VIOLATION OF FEDERAL LAW.'
    ];
    lines.forEach((t, i) => ctx.fillText(t, canvas.width / 2, legalY + i * 17));

    ctx.fillStyle = '#2c3e50';
    ctx.font = 'bold 11px "Helvetica", Arial, sans-serif';
    const addY = legalY + 70;
    const notes = [
      'Do not hinder, exclude, or block the view of this journalist',
      'in the exercise of court-recognized First Amendment rights.'
    ];
    notes.forEach((t, i) => ctx.fillText(t, canvas.width / 2, addY + i * 16));

    return id;
  }, []);

  useEffect(() => {
    drawPass(DEFAULT_NAME, DEFAULT_TITLE, null);
  }, [drawPass]);

  const handleGenerate = () => {
    const displayName = (name || '').trim() || DEFAULT_NAME;
    const displayTitle = (title || '').trim() || DEFAULT_TITLE;
    drawPass(displayName, displayTitle, photo);

    const formData = new FormData();
    formData.append('form-name', 'press-passes');
    formData.append('name', displayName);
    formData.append('title', displayTitle);
    formData.append('issued-at', new Date().toISOString());

    fetch('/', { method: 'POST', body: formData }).catch(() => {});
  };

  const handleDownload = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const link = document.createElement('a');
    link.download = 'press-pass.png';
    link.href = canvas.toDataURL('image/png');
    link.click();
  };

  const handleOpenImage = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const dataUrl = canvas.toDataURL('image/png');
    window.open(dataUrl, '_blank');
  };

  const handleCheckout = async () => {
    const trimmedName = (name || '').trim();
    const id = `pass-${Date.now().toString(36).toUpperCase()}`;
    try {
      const res = await fetch('/.netlify/functions/create-checkout-session', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ quantity: 1, passId: id, name: trimmedName })
      });

      const data = await res.json();
      if (data.url) {
        window.location.href = data.url;
      } else {
        alert(data.error || 'Unable to start checkout.');
      }
    } catch (e) {
      alert('Checkout failed.');
    }
  };

  const handlePhotoChange = (event) => {
    const file = event.target.files && event.target.files[0];
    if (!file) {
      setPhoto(null);
      return;
    }

    const img = new Image();
    const url = URL.createObjectURL(file);
    img.onload = () => {
      URL.revokeObjectURL(url);
      setPhoto(img);
    };
    img.src = url;
  };

  return (
    <>
      <Head>
        <title>Constitutional Press Pass</title>
        <meta name="description" content="Generate a Constitutional Press Pass." />
      </Head>
      <Script src="https://sites.super.myninja.ai/_assets/ninja-daytona-script.js" strategy="afterInteractive" />
      <header>
        <h1>Constitutional Press</h1>
      </header>

      <main>
        <div className="container">
          <div className="form-section">
            <h2>Generate Your Press Pass</h2>
            <form
              id="passForm"
              name="press-passes"
              method="POST"
              data-netlify="true"
              onSubmit={(event) => event.preventDefault()}
            >
              <input type="hidden" name="form-name" value="press-passes" />
              <div className="form-group">
                <label htmlFor="name">Full Name:</label>
                <input
                  type="text"
                  id="name"
                  name="name"
                  required
                  value={name}
                  onChange={(event) => setName(event.target.value)}
                />
              </div>

              <div className="form-group">
                <label htmlFor="title">Title:</label>
                <input
                  type="text"
                  id="title"
                  name="title"
                  required
                  value={title}
                  onChange={(event) => setTitle(event.target.value)}
                />
              </div>

              <div className="form-group">
                <label htmlFor="photo">Add Photo:</label>
                <input type="file" id="photo" name="photo" accept="image/*" onChange={handlePhotoChange} />
              </div>

              <button type="button" id="generate" onClick={handleGenerate}>
                Generate Press Pass
              </button>
              <button type="button" id="checkout" onClick={handleCheckout}>
                Get Laminated Pass ($10-15)
              </button>
            </form>
          </div>

          <div className="preview-section">
            <h2>Press Pass Preview</h2>
            <canvas id="passCanvas" ref={canvasRef} width="400" height="600"></canvas>
            <div className="actions">
              <button id="download" onClick={handleDownload}>
                Download
              </button>
              <button id="openImage" onClick={handleOpenImage}>
                Open Image
              </button>
            </div>
          </div>
        </div>

        <div className="exposure-reports">
          <h2>Exposure Reports</h2>
          <iframe
            id="reportsFrame"
            title="Exposure Reports"
            src="https://www.youtube.com/embed?listType=playlist&list=PL8f30603cbb"
            width="100%"
            height="400"
            frameBorder="0"
            allowFullScreen
          ></iframe>
        </div>
      </main>

      <footer>
        <p>
          This journalist is recognized under the protections of the First Amendment of the U.S. Constitution.
          Any interference will be a violation of federal law.
        </p>
        <p>
          Do not hinder, exclude, or block the view of this journalist in the exercise of court-recognized
          First Amendment rights.
        </p>
      </footer>
    </>
  );
}
