/**
 * Debug scraper - save HTML to see structure
 */

const axios = require('axios');
const fs = require('fs');

const headers = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
};

async function saveHtml() {
  try {
    const goldResponse = await axios.get('https://www.google.com/finance/quote/XAU-USD', {
      headers,
      timeout: 10000,
    });

    fs.writeFileSync('gold-page.html', goldResponse.data);
    console.log('✅ Saved gold HTML to gold-page.html');

    // Also show first 5 numbers found in the 2000-3000 range
    const goldText = goldResponse.data;
    const matches = goldText.match(/\d{4}\.?\d{0,2}/g) || [];
    console.log('First 10 4-digit numbers found:', matches.slice(0, 10));

    const silverResponse = await axios.get('https://www.google.com/finance/quote/XAG-USD', {
      headers,
      timeout: 10000,
    });

    fs.writeFileSync('silver-page.html', silverResponse.data);
    console.log('✅ Saved silver HTML to silver-page.html');

  } catch (error) {
    console.error('Error:', error.message);
  }
}

saveHtml();
