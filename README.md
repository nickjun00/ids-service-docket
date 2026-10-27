# IDS Service Docket

This repository contains the admin website and a Flutter starter app for
Android and iOS in `mobile_app/`.

## Admin website

A responsive, single-column login screen with an email field and a Get OTP button. Visible hints show the test email and demo verification code for client testing. Submitting the authorized email opens a verification screen with six code boxes, paste support, Verify, Request again, and Back controls.

To run the website locally, open a terminal in the repository root and run
(requires Node.js):

```sh
npm start
```

Open [http://localhost:8000](http://localhost:8000) in your browser. No npm
packages need to be installed. Keep the terminal running while using the
website; press `Ctrl+C` to stop the server.

Sign in with `admin@megascreen.com.my`, click **Get OTP**, and enter `888888`. The email and code are shown on their respective screens; no email is sent. On the home page, click **Manage Account** beside **Sign out** to open the account page. You can also open [http://localhost:8000/account.html](http://localhost:8000/account.html) after signing in.

Manage Account is for managing all accounts. It starts with **0 accounts** and a **No accounts yet** empty state. Click **Add Accounts**, enter a full name and email address, then submit to add an account to the list. Duplicate account emails are rejected. Accounts are saved in this browser and remain after reloading or signing out. This demo does not send invitations or enable account sign-in.

To remove an account, click **Delete** on its row and confirm. The list and account count update immediately. Deleting the last account shows **No accounts yet** again. Deletions are saved in this browser.

Only `admin@megascreen.com.my` is accepted (case insensitive). Change `ALLOWED_EMAIL` in `admin_website/assets/js/app.js` and the visible email hint in `admin_website/index.html` to update the account.

Use `888888` on the verification screen to open `home.html`. Other codes show an error. Request again reminds you of the fixed code; no emails are sent. Sign out returns to the login screen.

This is a browser-only demo with a temporary session in sessionStorage, not production authentication. When adding the backend, enforce the allowed email and verify codes on the server.


Project structure:

```text
admin_website/      Static admin website
  index.html        Email and verification screens
  home.html         Home page
  account.html      Account management page
  assets/
    images/         Logos, favicon, and background
    css/            Shared and home page styles
    js/             Login and home page scripts
mobile_app/         Flutter app for Android and iOS
package.json        npm start command
server.js           Local static website server
ai-rules.txt        Project implementation instructions
min-requirement.txt Project requirements and planned features
```

## Flutter mobile app

From the repository root, run:

```sh
cd mobile_app
flutter pub get
flutter run
```

Start a simulator/emulator or connect a phone before running the app. See
[the mobile app README](mobile_app/README.md) for setup, including the Android
JDK requirement. The IDS app starts with an email login page, requests camera
and location access, and verifies the demo code `888888` for
`admin@megascreen.com.my`. No email is sent. iOS uses a 17.0 minimum target.
Other product features in `min-requirement.txt` remain planned work.
