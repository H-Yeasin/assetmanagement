import Stripe from 'stripe';

async function testKey(key) {
    try {
        const stripe = new Stripe(key);
        // Simple call to check authentication
        await stripe.customers.list({limit: 1});
        console.log(`KEY VALID: ${key}`);
    } catch (e) {
        console.log(`KEY INVALID: ${key} -> ${e.message}`);
    }
}

async function run() {
    await testKey("sk_test_51T9Ik4Rwf58IAzGDw6fryw1xAz9H6oUPMGzG2bHKK15x5MVZmOWBjKrJSXovTg3ImXbj5PhmfNwHDoZStWVoIPWn00qEjwA2c");
    await testKey("sk_test_51T9Ik4Rwf58IAzGDw6fryw1xAz9H6oUPMGzG2bHKK15x5MVZmOWBjKrJSXovTg3ImXbj5PhmfNwHDoZStWVoIPWn00qEjwA2cF");
    await testKey("sk_test_51T9Ik4Rwf58IAzGDw6fryw1xAz9H6oUPMGzG2bHKK15x5MVZmOWBjKrJSXovTg3ImXbj5PhmfNwHDoZStWVoIPWn00qEjwA2cFF");
}

run();
