/**
 * Quick test of the gold/silver scraper
 */

const { scrapeGoldSilverPrices } = require('./scrapers/gold-silver-scraper');

console.log('🧪 Testing gold/silver scraper...\n');

scrapeGoldSilverPrices()
  .then(result => {
    console.log('\n✅ Scraper test completed!');
    console.log('Results:', JSON.stringify(result, null, 2));
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Scraper test failed:', error);
    process.exit(1);
  });
