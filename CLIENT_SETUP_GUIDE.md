# 📋 Client Setup Guide — FFP Vault App

> **Purpose:** This document lists everything we need from you to prepare the FFP Vault app for deployment on the Google Play Store and Apple App Store.  
> Please read through each section, follow the step-by-step instructions, and fill in the **Credentials Collection Form** at the end.

---

## Table of Contents

1. [Part 1: Email Sender Address (SMTP)](#part-1-email-sender-address-smtp)
2. [Part 2: RevenueCat In-App Purchase Setup](#part-2-revenuecat-in-app-purchase-setup)
   - [2.1 Create a RevenueCat Account](#21-create-a-revenuecat-account)
   - [2.2 Apple App Store Connect Setup](#22-apple-app-store-connect-setup)
   - [2.3 Google Play Console Setup](#23-google-play-console-setup)
   - [2.4 RevenueCat Dashboard Configuration](#24-revenuecat-dashboard-configuration)
3. [Part 3: Credentials Collection Form](#part-3-credentials-collection-form)

---

## Part 1: Email Sender Address (SMTP)

### What this is

When users reset their password or set up two-factor authentication (2FA), the app sends them a One-Time Password (OTP) via email. These emails currently come from a generic address. We need to update the **"From" address** to use your organization's email so recipients see a trusted sender.

### What we need from you

Choose **one** of the options below based on your email provider:

---

### Option A: Using Gmail / Google Workspace (Recommended)

If your organization uses Gmail or Google Workspace (`@yourcompany.com` via Google), this is the easiest path.

#### Step-by-step:

1. **Enable 2-Step Verification** on the Google Account you want to use:
   - Go to: https://myaccount.google.com/security
   - Click **"2-Step Verification"** and follow the steps to turn it on.

2. **Generate an App Password:**
   - Go to: https://myaccount.google.com/apppasswords (this link only works after 2-Step Verification is enabled)
   - Under **"Select app"**, choose **"Mail"**
   - Under **"Select device"**, choose **"Other"** and type: `FFP Vault App`
   - Click **"Generate"**
   - Google will show a **16-character password** (yellow box) — **copy it immediately**

   > 📹 **Video Tutorial:**  
   > - [How to Create Gmail App Password (2024)](https://www.youtube.com/watch?v=J4CtP1MBtOE)  
   > - [Gmail App Password Setup for Third-Party Email](https://www.youtube.com/watch?v=hXiPshHn9Pw)

3. **Provide us with:**
   - The **Gmail/Google Workspace email address** you want as the sender (e.g., `noreply@yourcompany.com`)
   - The **16-character App Password** you generated

---

### Option B: Using Your Own SMTP Server

If your organization has its own mail server (e.g., Microsoft 365, Zoho Mail, custom mail server), we need:

| Item | Description | Example |
|------|-------------|---------|
| **SMTP Host** | Your mail server hostname | `smtp.office365.com` or `mail.yourcompany.com` |
| **SMTP Port** | Usually `587` (TLS) or `465` (SSL) | `587` |
| **SMTP Username** | The login username/email | `noreply@yourcompany.com` |
| **SMTP Password** | The password or app password for the account | `••••••••••••••••` |
| **From Address** | The sender email users will see | `noreply@yourcompany.com` |

> ⚠️ **Important:** For Microsoft 365 / Outlook, you may need to use an app password instead of your regular password. For Zoho, you need to generate an app-specific password from the Zoho Mail admin panel.

---

### Which email address would you like to use?

> **Your Decision:** `____________________________________________`

We recommend something like `noreply@yourcompany.com` or `support@yourcompany.com`.

> 📝 **Also note:** The email template footer currently shows `support@financialfreedompower.com` as the contact address. We will update this to match your support email when we update the sender address. **Please also provide your preferred support/contact email** if different from the sender address.

---

## Part 2: RevenueCat In-App Purchase Setup

### What this is

The app charges a **$6.99/month subscription** (with a **14-day free trial**) to access the Vault feature. We use a service called **[RevenueCat](https://www.revenuecat.com)** to handle all in-app purchases across iOS and Android. RevenueCat acts as a bridge between your app and Apple / Google's payment systems.

> 📹 **Recommended Watching:** [RevenueCat Official YouTube Channel](https://www.youtube.com/@RevenueCat) — browse their "Getting Started" playlist

---

### 2.1 Create a RevenueCat Account

1. Go to https://www.revenuecat.com and click **"Sign Up"** (free tier is fine to start)
2. After signing in, create a **New Project**:
   - **Project name:** We recommend `FFP Vault` (or your preferred name)
3. Inside the project, note the **Project ID** shown in the URL/settings — you'll need this later.

> **You'll need to give us:** Your RevenueCat login email (or add us as a collaborator) so we can complete the configuration.

---

### 2.2 Apple App Store Connect Setup

This section requires an active **Apple Developer Program membership** ($99/year).

> 📹 **Suggested YouTube search:** Search for *"App Store Connect Create Auto-Renewable Subscription 2024 Step by Step"* on YouTube for a visual walkthrough.

#### Step 1: Sign the Paid Applications Agreement

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **Agreements, Tax, and Banking**
3. Ensure the **Paid Applications** agreement is signed and active. If not, request it and complete all required tax/banking forms.
   - ⚠️ This can take 24-48 hours for Apple to approve.

#### Step 2: Create an App ID (if not already done)

1. Go to [Apple Developer Portal](https://developer.apple.com) → **Certificates, Identifiers & Profiles**
2. Under **Identifiers**, click **"+"** to create a new App ID
3. Select **"App IDs"** → **"App"**
4. **Bundle ID:** `com.ffpvault.app`
5. Under **Capabilities**, make sure **"In-App Purchase"** is checked
6. Click **Continue** → **Register**

#### Step 3: Create a Subscription Group

1. In **App Store Connect**, go to your app → **Features** tab → **Subscriptions**
2. Click **"Create Subscription Group"**
3. **Reference Name:** `FFP Vault Subscription`
4. Click **Create**

#### Step 4: Create a Subscription Product

1. Inside your Subscription Group, click **"Create"** (or the "+" button) → **"Create Subscription"**
2. **Product ID:** `ff_vault_monthly`
   > ⚠️ This Product ID must match what's configured in the app. Use exactly: `ff_vault_monthly`
3. **Reference Name:** `FFP Vault Pro Monthly`
4. **Subscription Family:** Leave as default (this is your only subscription)
5. Click **Create**
6. Next, add a **Subscription Price**:
   - **Country/Region:** United States (and any others you want to sell in)
   - **Price:** `$6.99 USD`
7. Add an **Introductory Offer** (the free trial):
   - Click **"Add Introductory Price"**
   - **Type:** Free
   - **Duration:** 14 days
   - **Eligibility:** New subscribers only
8. Click **Save**

#### Step 5: Generate an In-App Purchase Key (StoreKit 2)

This is required for RevenueCat to validate purchases with Apple.

1. Go to [App Store Connect](https://appstoreconnect.apple.com) → **Users and Access** → **Integrations** tab
2. Under **In-App Purchase Keys**, click **"+"** to generate a new key
3. **Key Name:** `RevenueCat Key`
4. Click **"Generate"**
5. **Download the `.p8` file** immediately — you cannot download it again later
6. Note the **Key ID** (shown in the table after generation)
7. Note the **Issuer ID** (shown at the top of the Integrations page)

#### Step 6: Get Your App Store Connect Shared Secret (for legacy StoreKit 1 fallback)

1. Go to [App Store Connect](https://appstoreconnect.apple.com) → your app → **App Information**
2. Under **App-Specific Shared Secret**, click **"Manage"**
3. Copy or generate the shared secret

---

### 2.3 Google Play Console Setup

This section requires an active **Google Play Developer account** ($25 one-time registration fee).

> 📹 **Suggested YouTube search:** Search for *"Google Play Console Create Subscription Base Plan 2024 Tutorial"* on YouTube for a visual walkthrough.

#### Step 1: Set Up a Payments Profile

1. Log in to [Google Play Console](https://play.google.com/console)
2. Go to your app → **Monetize** → **Monetization setup**
3. If not already done, create a **Payments Profile** with your business details and bank account
   - ⚠️ This needs to be set up before you can create any subscriptions

#### Step 2: Create a Subscription

1. In Google Play Console, go to your app → **Monetize** → **Products** → **Subscriptions**
2. Click **"Create Subscription"**
3. **Product ID:** `ff_vault_monthly`
   > ⚠️ This Product ID must match what's configured in the app. Use exactly: `ff_vault_monthly`
4. **Name:** `FFP Vault Pro Monthly`
5. **Benefits** (up to 4, shown to users):
   - `Secure document vault`
   - `Unlimited folder organization`
   - `PIN & biometric protection`
   - `Priority support`
6. Click **Create**

#### Step 3: Add a Base Plan

After creating the subscription, you need to add a base plan:

1. Click **"Add Base Plan"**
2. **Base Plan ID:** `monthly`
3. **Renewal Type:** Auto-renewing
4. **Billing Period:** Monthly
5. **Grace Period:** 3 days
6. **Account Hold:** 7 days (recommended)
7. Click **Set Price** → select **United States** → enter **$6.99 USD**
8. Click **Save**

#### Step 4: Add a Free Trial Offer

1. On your subscription, click **"Add Offer"**
2. **Offer Type:** Free trial (New Customer Acquisition)
3. **Base Plan:** Select the `monthly` base plan you just created
4. **Phases:** One phase — 14 days free, then auto-renew
5. **Eligibility:** New customers only (never had this subscription before)
6. Click **Save**

#### Step 5: Create a Service Account for RevenueCat

RevenueCat needs a service account to validate purchases with Google Play.

1. Go to [Google Cloud Console](https://console.cloud.google.com) → select your project (or create one)
2. Go to **IAM & Admin** → **Service Accounts** → **"Create Service Account"**
3. **Service Account Name:** `RevenueCat`
4. **Service Account ID:** `revenuecat` (auto-fills)
5. Click **"Create and Continue"**
6. **Role:** Select `Pub/Sub Admin` (RevenueCat recommends `Monitoring Admin` or a custom role — check [RevenueCat's Google Play Setup Guide](https://www.revenuecat.com/docs/creating-play-service-credentials) for the latest)
7. Click **Done**
8. Click on the service account you just created → **Keys** tab → **Add Key** → **Create New Key** → **JSON**
9. **Download the JSON key file** — you'll need to upload this to RevenueCat

#### Step 6: Grant Permissions in Google Play Console

1. Go back to [Google Play Console](https://play.google.com/console) → **Users and Permissions**
2. Click **"Invite new users"**
3. Enter the **service account email** (shown in the JSON key file, looks like `revenuecat@your-project.iam.gserviceaccount.com`)
4. **Permission:** Select **"Finance"** (or at minimum: View financial data, Manage orders, View app information)
5. Click **"Invite User"**
   > ⚠️ The invitation might not appear — Google sometimes auto-grants permissions for service accounts. Verify in RevenueCat later.

---

### 2.4 RevenueCat Dashboard Configuration

Now that you've set up the App Store and Google Play products, connect them to RevenueCat.

#### Step 1: Add Your Apps to RevenueCat

1. In your RevenueCat dashboard (https://app.revenuecat.com), go to your project
2. Go to **Settings** → **Apps**
3. For **iOS:**
   - Click **"Add App"** → Select **"App Store"**
   - **App Name:** `FFP Vault`
   - **Bundle ID:** `com.ffpvault.app`
   - Upload the **In-App Purchase Key (.p8 file)** you downloaded earlier
   - Enter the **Key ID** and **Issuer ID** from Apple
   - (Optional) Enter the **App-Specific Shared Secret** for StoreKit 1 fallback
4. For **Android:**
   - Click **"Add App"** → Select **"Google Play"**
   - **App Name:** `FFP Vault`
   - **Package ID:** `com.ffpvault.app`
   - Upload the **Service Account JSON Key** file you downloaded from Google Cloud

#### Step 2: Import Products

1. Go to **Products** in RevenueCat
2. For iOS: You should see `ff_vault_monthly` appear after RevenueCat syncs with App Store Connect
3. For Android: You should see `ff_vault_monthly` appear after RevenueCat syncs with Google Play
4. If products don't appear, click **"Sync"** or wait a few minutes for the initial sync

#### Step 3: Configure Entitlements

1. Go to **Entitlements** → Click **"Create"**
2. **Entitlement ID:** `ffpvaultapp_pro`
   > ⚠️ This must match exactly — it's what the app checks to unlock the Vault
3. **Display Name:** `FFP Vault Pro`
4. Attach the `ff_vault_monthly` product from both iOS and Android to this entitlement
5. Click **Save**

#### Step 4: Configure Offerings

1. Go to **Offerings** → Click **"Create Offering"**
2. **Offering Identifier:** `default`
3. **Display Name:** `Default`
4. Add a **Package**:
   - **Package Identifier:** `monthly`
   - **Package Type:** Monthly
   - **Product:** Select `ff_vault_monthly`
5. Click **Save**

#### Step 5: Set Up Webhooks (for server-side validation)

1. Go to **Settings** → **Webhooks** (or **Integrations**)
2. Click **"Add Webhook"**
3. **Webhook URL:** `https://us-central1-ffp-vault-app.cloudfunctions.net/revenuecatWebhook`
4. **Authorization Header:** Generate a secret value (we'll set this in Firebase) — or you can just note that we need a webhook secret
5. **Events to send:** Select **all subscription events** (INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, etc.)
6. Click **Save**

> ⚠️ The webhook URL above assumes the Firebase project is `ffp-vault-app` and the function is deployed. We will finalize this URL after deployment.

---

## Part 3: Credentials Collection Form

Please fill in the items below and send this back to us. Fill in what you can — we'll help with anything unclear.

---

### A. SMTP / Email Sender

| # | Item | Your Value |
|---|------|-------------|
| A1 | Email provider (**Gmail/Google Workspace** or **Other**) | `________________________` |
| A2 | Sender email address (e.g., `noreply@yourcompany.com`) | `________________________` |
| A3 | SMTP Host (if not Gmail) | `________________________` |
| A4 | SMTP Port (if not Gmail) | `________________________` |
| A5 | SMTP Username (if not Gmail) | `________________________` |
| A6 | SMTP Password or App Password | *(send securely, not in this form)* |
| A7 | Support/Contact email for email footer (if different from A2) | `________________________` |

---

### B. RevenueCat Account

| # | Item | Your Value |
|---|------|-------------|
| B1 | RevenueCat account email | `________________________` |
| B2 | RevenueCat Project Name | `________________________` |
| B3 | Are you on RevenueCat **Free** or **Pro** plan? | `________________________` |

---

### C. Apple App Store Connect

| # | Item | Your Value |
|---|------|-------------|
| C1 | Apple Developer account email | `________________________` |
| C2 | Is the **Paid Applications Agreement** signed? | ☐ Yes &nbsp; ☐ No |
| C3 | App Store Connect App created? (Bundle ID: `com.ffpvault.app`) | ☐ Yes &nbsp; ☐ No |
| C4 | Subscription Group created? (`FFP Vault Subscription`) | ☐ Yes &nbsp; ☐ No |
| C5 | Subscription Product ID created? (`ff_vault_monthly`) | ☐ Yes &nbsp; ☐ No |
| C6 | In-App Purchase Key (.p8 file) | *(attach file securely)* |
| C7 | In-App Purchase **Key ID** | `________________________` |
| C8 | In-App Purchase **Issuer ID** | `________________________` |
| C9 | App-Specific Shared Secret (StoreKit 1 fallback) | `________________________` |

---

### D. Google Play Console

| # | Item | Your Value |
|---|------|-------------|
| D1 | Google Play Developer account email | `________________________` |
| D2 | Payments Profile set up? | ☐ Yes &nbsp; ☐ No |
| D3 | App created in Play Console? (Package: `com.ffpvault.app`) | ☐ Yes &nbsp; ☐ No |
| D4 | Subscription Product created? (`ff_vault_monthly`) | ☐ Yes &nbsp; ☐ No |
| D5 | Base Plan created? (`monthly`, auto-renewing, $6.99) | ☐ Yes &nbsp; ☐ No |
| D6 | Free trial offer created? (14 days) | ☐ Yes &nbsp; ☐ No |
| D7 | Google Cloud Service Account JSON key file | *(attach file securely)* |
| D8 | Service Account email (from JSON key file) | `________________________` |
| D9 | Is the service account invited to Play Console with Finance permissions? | ☐ Yes &nbsp; ☐ No |

---

### E. RevenueCat API Keys (we generate these from your dashboard)

| # | Item | Your Value |
|---|------|-------------|
| E1 | RevenueCat **Apple API Key** (starts with `appl_`) | `________________________` |
| E2 | RevenueCat **Google API Key** (starts with `goog_`) | `________________________` |
| E3 | RevenueCat **Webhook Secret** (you chose this in Step 2.4, Step 5) | `________________________` |

> **Note:** RevenueCat now supports a **unified API key** (starts with `rc_`). If you prefer, you can use the unified key instead of separate Apple/Google keys. We need whichever you choose.

---

## Appendix: Quick Reference — App Configuration Values

These are the fixed values hardcoded in the app. **Do not change these** unless we coordinate a code update:

| Config Item | Value |
|-------------|-------|
| Firebase Project ID | `ffp-vault-app` |
| Firestore Database ID | `ffpvault` |
| iOS Bundle ID | `com.ffpvault.app` |
| Android Package Name | `com.ffpvault.app` |
| App Store Subscription Product ID | `ff_vault_monthly` |
| Play Store Subscription Product ID | `ff_vault_monthly` |
| RevenueCat Entitlement ID | `ffpvaultapp_pro` |
| RevenueCat Offering Identifier | `default` |
| RevenueCat Package Identifier | `monthly` |
| Subscription Price | `$6.99 USD / month` |
| Free Trial Duration | `14 days` |
| Plan Display Name | `FFP Vault Pro` |

---

## Appendix: Useful Links

| Resource | Link |
|----------|------|
| RevenueCat Dashboard | https://app.revenuecat.com |
| RevenueCat Docs — iOS Setup | https://www.revenuecat.com/docs/apple-app-store |
| RevenueCat Docs — Android Setup | https://www.revenuecat.com/docs/google-play-store |
| RevenueCat Codelabs (step-by-step) | https://revenuecat.github.io/codelabs/ |
| RevenueCat Official YouTube | https://www.youtube.com/@RevenueCat |
| App Store Connect | https://appstoreconnect.apple.com |
| Google Play Console | https://play.google.com/console |
| Google Cloud Console | https://console.cloud.google.com |
| Gmail App Password (Google help) | https://support.google.com/accounts/answer/185833 |
| 📹 Gmail App Password Video Tutorial | https://www.youtube.com/watch?v=J4CtP1MBtOE |
| 📹 Gmail App Password (alternative) | https://www.youtube.com/watch?v=hXiPshHn9Pw |

---

> **Questions?** Contact us at any time if any step is unclear or if you need help navigating these platforms. We're happy to jump on a call and walk through anything together.
