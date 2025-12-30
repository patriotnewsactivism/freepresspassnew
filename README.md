# Free Press Pass Generator (Next.js)

A Next.js app for generating digital press passes with Netlify deployment and Stripe Checkout for physical passes.

## Features

- Digital press pass generation on canvas
- Mobile-friendly design with "Open Image" functionality for iOS
- Stripe integration for purchasing laminated passes
- Netlify Forms tracking for issued passes
- YouTube exposure report embed

## Local Development

1. Install dependencies: `npm install`
2. Run the dev server: `npm run dev`
3. Open `http://localhost:3000`

## Build and Start

- Build the app: `npm run build`
- Start the production server: `npm run start`

## Netlify Setup

Set the following environment variables in Netlify:
- `STRIPE_SECRET_KEY` - Your Stripe secret key
- `STRIPE_PRICE_ID` - Price ID for the laminated pass

The Netlify config is already set for Next.js (`netlify.toml`) and uses the Next.js plugin.

## Customization

To customize the press pass preview image, update the canvas drawing logic in `pages/index.js`.

## License

This project is licensed under the MIT License.
