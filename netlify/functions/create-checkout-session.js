const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const getBaseUrl = (event) => {
  if (process.env.URL) {
    return process.env.URL;
  }

  const headers = event.headers || {};
  const host = headers['x-forwarded-host'] || headers.host;
  if (!host) {
    return 'http://localhost:3000';
  }
  const proto = headers['x-forwarded-proto'] || 'https';
  return `${proto}://${host}`;
};

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      body: JSON.stringify({ error: 'Method not allowed' })
    };
  }

  let payload = {};
  try {
    payload = JSON.parse(event.body || '{}');
  } catch (error) {
    payload = {};
  }

  try {
    const { quantity = 1, passId, name } = payload;
    const baseUrl = getBaseUrl(event);

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price: process.env.STRIPE_PRICE_ID,
        quantity
      }],
      mode: 'payment',
      success_url: `${baseUrl}/?checkout=success`,
      cancel_url: `${baseUrl}/?checkout=cancelled`,
      metadata: {
        passId,
        name
      }
    });

    return {
      statusCode: 200,
      body: JSON.stringify({ url: session.url })
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};
