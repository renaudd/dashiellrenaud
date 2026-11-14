/**
 * Copyright (c) 2026 Dashiell Renaud (https://dashiellrenaud.com)
 * Licensed under Creative Commons Attribution-NonCommercial-NoDerivatives 4.0
 * International (CC BY-NC-ND 4.0): https://creativecommons.org/licenses/by-nc-nd/4.0/
 * SPDX-License-Identifier: CC-BY-NC-ND-4.0
 */

(function () {
  var isLocalDev =
    typeof window !== "undefined" &&
    window.location &&
    (window.location.hostname === "127.0.0.1" || window.location.hostname === "localhost");

  window.NIGHTMERCHANT_CONFIG = window.NIGHTMERCHANT_CONFIG || {
    // Cloud Run backend URL in production; "" on localhost/127.0.0.1 for local server dev
    apiBaseUrl: isLocalDev ? "" : "https://instantgramsf-api-935380114521.us-west2.run.app",

    // Non-secret Firebase project identifiers.
    // NOTE: Do NOT commit a Google/Firebase Web API key here — the client receives
    // firebaseConfig dynamically at runtime from GET /api/auth/me on Cloud Run.
    firebaseConfig: {
      authDomain: "instantgramsf.firebaseapp.com",
      projectId: "instantgramsf",
      storageBucket: "instantgramsf.firebasestorage.app",
      messagingSenderId: "935380114521",
      appId: "1:935380114521:web:ea07f0698cdc4629d9a548",
      measurementId: "G-YN00GM5M78",
    },
  };
})();
