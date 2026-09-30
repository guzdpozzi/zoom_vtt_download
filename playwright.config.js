/** @type {import('@playwright/test').PlaywrightTestConfig} */
module.exports = {
  testDir: 'tests',
  timeout: 120000,
  use: {
    headless: true,
    // let the browser start maximized by using null viewport and start-maximized arg
    viewport: null,
    launchOptions: {
      args: ['--start-maximized']
    },
    actionTimeout: 30000,
    ignoreHTTPSErrors: true
  }
};
