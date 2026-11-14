/*
 * Night Merchant: InstantGram SF (reskin of Night Merchant: All Roads Lead to Rome)
 * Copyright (c) 2026 Dashiell Renaud.
 *
 * Licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0
 * International License (CC BY-NC-ND 4.0).
 * https://creativecommons.org/licenses/by-nc-nd/4.0/
 */

function getNightMerchantRuntimeConfig() {
  if (typeof window !== "undefined" && window.NIGHTMERCHANT_CONFIG && typeof window.NIGHTMERCHANT_CONFIG === "object") {
    return window.NIGHTMERCHANT_CONFIG;
  }
  return {};
}

function getNightMerchantApiBaseUrl() {
  const cfg = getNightMerchantRuntimeConfig();
  const raw = typeof cfg.apiBaseUrl === "string" ? cfg.apiBaseUrl.trim() : "";
  return raw.replace(/\/+$/, "");
}

function resolveAssetUrl(rawUrl) {
  const s = String(rawUrl || "");
  if (s.startsWith("/assets/")) {
    return `.${s}`;
  }
  return s;
}

function maskEmailClient(rawEmail) {
  const s = String(rawEmail || "").trim();
  if (!s || !s.includes("@")) return "email on file";
  const parts = s.split("@");
  const local = parts[0] || "";
  const domain = parts[1] || "";
  const domParts = domain.split(".");
  const domHead = domParts[0] || "";
  const domTail = domParts.length > 1 ? `.${domParts.slice(1).join(".")}` : "";
  const maskedLocal = local ? `${local[0]}***` : "***";
  const maskedDom = domHead ? `${domHead[0]}***${domTail}` : "***";
  return `${maskedLocal}@${maskedDom}`;
}

let _fbAuthModule = null;

let _fbAuthInstance = null;

let _fbInitPromise = null;

let _fbCurrentUser = null;

function getStoredSessionToken() {
  try {
    if (typeof window !== "undefined" && window.sessionStorage) {
      return window.sessionStorage.getItem("nm_session_token") || null;
    }
  } catch (_e) {}
  return null;
}

function setStoredSessionToken(tok) {
  if (typeof appState !== "undefined" && appState) {
    appState.sessionToken = tok || null;
  }
  try {
    if (typeof window !== "undefined" && window.sessionStorage) {
      if (tok) {
        window.sessionStorage.setItem("nm_session_token", String(tok));
      } else {
        window.sessionStorage.removeItem("nm_session_token");
      }
    }
  } catch (_e) {}
}

function getEffectiveFirebaseConfig() {
  const cfg = getNightMerchantRuntimeConfig();
  const baseFb = cfg && cfg.firebaseConfig && typeof cfg.firebaseConfig === "object" ? cfg.firebaseConfig : {};
  const runtimeFb =
    typeof appState !== "undefined" &&
      appState &&
      appState.runtimeFirebaseConfig &&
      typeof appState.runtimeFirebaseConfig === "object"
      ? appState.runtimeFirebaseConfig
      : {};
  const merged = { ...baseFb, ...runtimeFb };
  if (typeof merged.apiKey === "string") {
    merged.apiKey = merged.apiKey.replace(/^[<>"'\s]+|[<>"'\s]+$/g, "");
  }
  if (typeof merged.projectId === "string") {
    merged.projectId = merged.projectId.replace(/^[<>"'\s]+|[<>"'\s]+$/g, "");
  }
  return merged;
}

function isFirebaseClientConfigured() {
  if (typeof appState !== "undefined" && appState && appState.serverFirebaseEnabled === false && !getNightMerchantApiBaseUrl()) {
    return false;
  }
  const fb = getEffectiveFirebaseConfig();
  return Boolean(fb && typeof fb.apiKey === "string" && fb.apiKey.trim() && typeof fb.projectId === "string" && fb.projectId.trim());
}

async function setBestFirebasePersistence(auth, authMod, skipIndexedDb = false) {
  if (!auth || !authMod || typeof authMod.setPersistence !== "function") return null;
  const candidates = skipIndexedDb
    ? [authMod.browserLocalPersistence, authMod.browserSessionPersistence, authMod.inMemoryPersistence]
    : [
        authMod.indexedDBLocalPersistence,
        authMod.browserLocalPersistence,
        authMod.browserSessionPersistence,
        authMod.inMemoryPersistence,
      ];
  for (const persistence of candidates) {
    if (!persistence) continue;
    try {
      await authMod.setPersistence(auth, persistence);
      return persistence;
    } catch (_persistErr) {}
  }
  return null;
}

function isStoragePersistenceError(err) {
  const code = String((err && err.code) || "").toLowerCase();
  const msg = String((err && err.message) || "").toLowerCase();
  return (
    code.includes("web-storage-unsupported") ||
    msg.includes("indexeddb") ||
    msg.includes("sessionstorage") ||
    msg.includes("localstorage") ||
    msg.includes("quota") ||
    msg.includes("storage")
  );
}

async function runFirebaseAuthOpWithPersistenceFallback(auth, authMod, authOp) {
  try {
    return await authOp(auth);
  } catch (err) {
    if (!isStoragePersistenceError(err)) {
      throw err;
    }
    await setBestFirebasePersistence(auth, authMod, true);
    return authOp(auth);
  }
}

async function initFirebaseClientIfConfigured() {
  if (!isFirebaseClientConfigured()) return null;
  if (_fbAuthInstance) return _fbAuthInstance;
  if (_fbInitPromise) return _fbInitPromise;

  _fbInitPromise = (async () => {
    try {
      const fbCfg = getEffectiveFirebaseConfig();
      const [appMod, authMod] = await Promise.all([
        import("https://www.gstatic.com/firebasejs/13.1.0/firebase-app.js"),
        import("https://www.gstatic.com/firebasejs/13.1.0/firebase-auth.js"),
      ]);
      const existingApps = typeof appMod.getApps === "function" ? appMod.getApps() : [];
      const fbApp = existingApps.length > 0 ? existingApps[0] : appMod.initializeApp(fbCfg);
      const auth = authMod.getAuth(fbApp);
      await setBestFirebasePersistence(auth, authMod, false);
      if (typeof auth.authStateReady === "function") {
        await auth.authStateReady();
      }
      _fbAuthModule = authMod;
      _fbAuthInstance = auth;
      return auth;
    } catch (err) {
      console.error("[NightMerchant] Firebase client init failed:", err);
      _fbInitPromise = null;
      return null;
    }
  })();

  return _fbInitPromise;
}

async function getFirebaseIdToken() {
  if (isFirebaseClientConfigured()) {
    const auth = await initFirebaseClientIfConfigured();
    const userObj = (auth && auth.currentUser) || _fbCurrentUser;
    if (userObj && typeof userObj.getIdToken === "function") {
      try {
        const tok = await userObj.getIdToken();
        if (tok) {
          if (typeof appState !== "undefined" && appState) {
            appState.lastFirebaseIdToken = tok;
          }
          return tok;
        }
      } catch (_err) {}
    }
  }
  if (typeof appState !== "undefined" && appState && appState.lastFirebaseIdToken) {
    return appState.lastFirebaseIdToken;
  }
  return null;
}

async function signInWithFirebaseCustomToken(customToken) {
  if (!customToken || !isFirebaseClientConfigured()) return null;
  const auth = await initFirebaseClientIfConfigured();
  if (!auth || !_fbAuthModule) return null;
  const cred = await runFirebaseAuthOpWithPersistenceFallback(auth, _fbAuthModule, (a) =>
    _fbAuthModule.signInWithCustomToken(a, customToken)
  );
  if (cred && cred.user) {
    _fbCurrentUser = cred.user;
    const tok = await cred.user.getIdToken();
    if (typeof appState !== "undefined" && appState) {
      appState.lastFirebaseIdToken = tok || null;
    }
    return tok;
  }
  return null;
}

async function signInWithFirebaseEmailPassword(email, password) {
  if (!email || !password || !isFirebaseClientConfigured()) return null;
  const auth = await initFirebaseClientIfConfigured();
  if (!auth || !_fbAuthModule || typeof _fbAuthModule.signInWithEmailAndPassword !== "function") return null;
  try {
    const cred = await runFirebaseAuthOpWithPersistenceFallback(auth, _fbAuthModule, (a) =>
      _fbAuthModule.signInWithEmailAndPassword(a, email, password)
    );
    if (cred && cred.user) {
      _fbCurrentUser = cred.user;
      const tok = await cred.user.getIdToken();
      if (typeof appState !== "undefined" && appState) {
        appState.lastFirebaseIdToken = tok || null;
      }
      return tok;
    }
    return null;
  } catch (_err) {
    return null;
  }
}

function signInWithFirebaseGooglePopup() {
  if (_fbAuthInstance && _fbAuthModule) {
    const provider = new _fbAuthModule.GoogleAuthProvider();
    provider.setCustomParameters({ prompt: "select_account" });
    return _fbAuthModule.signInWithPopup(_fbAuthInstance, provider).then(async (cred) => {
      if (!cred || !cred.user) {
        throw new Error("Google sign-in did not return a user credential.");
      }
      _fbCurrentUser = cred.user;
      const tok = await cred.user.getIdToken();
      if (typeof appState !== "undefined" && appState) {
        appState.lastFirebaseIdToken = tok || null;
      }
      return tok;
    });
  }
  return initFirebaseClientIfConfigured().then(async (auth) => {
    if (!auth || !_fbAuthModule) {
      throw new Error("Firebase Google Sign-In is not configured on the server yet.");
    }
    const provider = new _fbAuthModule.GoogleAuthProvider();
    provider.setCustomParameters({ prompt: "select_account" });
    const cred = await _fbAuthModule.signInWithPopup(auth, provider);
    if (!cred || !cred.user) {
      throw new Error("Google sign-in did not return a user credential.");
    }
    _fbCurrentUser = cred.user;
    const tok = await cred.user.getIdToken();
    if (typeof appState !== "undefined" && appState) {
      appState.lastFirebaseIdToken = tok || null;
    }
    return tok;
  });
}

async function signOutFirebaseClient() {
  _fbCurrentUser = null;
  if (typeof appState !== "undefined" && appState) {
    appState.lastFirebaseIdToken = null;
  }
  setStoredSessionToken(null);
  if (!_fbAuthInstance || !_fbAuthModule) return;
  try {
    await _fbAuthModule.signOut(_fbAuthInstance);
  } catch (_err) { }
}

const COLS = ["A", "B", "C", "D", "E", "F"];

const ROWS = ["1", "2", "3", "4", "5", "6"];

// Market layout (display names): Weed, Party, Uppers, Opiates, Weapons, Henchmen
const TRACK_NAMES = ["Grain", "Marble", "Animals", "Wine", "Weapons", "Henchmen"];

const COL_SYMBOLS = ["<<", "<", "=", "=", ">", ">>"];

const MARKET_COLUMNS_META = [
  { col: 1, symbol: "<<", title: "Precious" },
  { col: 2, symbol: "<", title: "Rare" },
  { col: 3, symbol: "=", title: "Uncommon" },
  { col: 4, symbol: "=", title: "Uncommon" },
  { col: 5, symbol: ">", title: "Common" },
  { col: 6, symbol: ">>", title: "Abundant" },
];

const ROME_LANDMARKS = {
  A1: { icon: "🌊", sub: "Land's End (Pacific cliffs — no exits)" },
  B1: { icon: "🌉", sub: "Presidio (Golden Gate Bridge entry)" },
  C1: { icon: "⛵", sub: "Marina" },
  D1: { icon: "🦭", sub: "Fisherman's Wharf" },
  E1: { icon: "🗼", sub: "Telegraph Hill & Coit Tower" },
  F1: { icon: "🌉", sub: "Treasure Island (Bay Bridge entry)" },
  A2: { icon: "🌫️", sub: "Richmond" },
  B2: { icon: "🏰", sub: "Pac Heights" },
  C2: { icon: "🚡", sub: "Russian Hill" },
  D2: { icon: "🚋", sub: "Nob Hill" },
  E2: { icon: "🏮", sub: "Chinatown" },
  F2: { icon: "⛴️", sub: "Embarcadero & Ferry Building" },
  A3: { icon: "🌳", sub: "Golden Gate Park" },
  B3: { icon: "🏮", sub: "Japantown" },
  C3: { icon: "🏛️", sub: "Civic Center (Open-Air Market)" },
  D3: { icon: "💉", sub: "Tenderloin (Open-Air Market)" },
  E3: { icon: "💻", sub: "SoMa" },
  F3: { icon: "⚾", sub: "Ball Park (Stadium)" },
  A4: { icon: "🏄", sub: "Sunset" },
  B4: { icon: "🌼", sub: "Haight-Ashbury" },
  C4: { icon: "🏳️‍🌈", sub: "Castro" },
  D4: { icon: "🌯", sub: "Mission District (Open-Air Market)" },
  E4: { icon: "🏭", sub: "Potrero Hill" },
  F4: { icon: "🚢", sub: "Dogpatch" },
  A5: { icon: "🛣️", sub: "Merced (Route 1 entry)" },
  B5: { icon: "📡", sub: "Twin Peaks & Sutro Tower" },
  C5: { icon: "🍼", sub: "Noe Valley" },
  D5: { icon: "🌴", sub: "Dolores Park" },
  E5: { icon: "⛰️", sub: "Bernal Heights" },
  F5: { icon: "🛣️", sub: "Bayview (US-101 entry)" },
  A6: { icon: "🏘️", sub: "Daly City" },
  B6: { icon: "🏠", sub: "Ingleside" },
  C6: { icon: "🌤️", sub: "Sunnyside" },
  D6: { icon: "🛣️", sub: "Excelsior (I-280 entry)" },
  E6: { icon: "🌲", sub: "Visitacion Valley" },
  F6: { icon: "🏚️", sub: "Hunters Point" },
};

const FACTION_META = [
  {
    key: "MAGA",
    label: "MAGA",
    gem: "/assets/icons/ruby.png",
    color: "#b91c1c",
    gemSingular: "ruby",
    gemPlural: "rubies",
    title: "MAGA — Make America Great Again",
    bio: "Red hats in a blue city. MAGA runs deep through the Cops (SFPD, DEA, FBI, ICE), with few Criminals and Celebrities. Back the Blue makes every Cop hit harder.",
    alignedWith: ["TECH", "ISIS (sometimes)"],
    hostileTo: ["MS13 (most hostile)", "DSA (hugely)", "ISIS (sometimes)"],
    alignmentNote: "Working for MAGA makes everyone hate you; working against MAGA makes everyone like you. MS-13 mostly doesn't care.",
    defaultDeckCounts: { celebrities: 3, cops: 14, criminals: 2, total: 19 },
  },
  {
    key: "ISIS",
    label: "ISIS",
    gem: "/assets/icons/emerald.png",
    color: "#047857",
    gemSingular: "emerald",
    gemPlural: "emeralds",
    title: "ISIS — Sleeper Cells",
    bio: "Poor, violent, and the rarest faction in the city. ISIS hides mostly among the Criminals, then the Celebrities, and only rarely the Cops. It hates every faction except MS-13.",
    alignedWith: ["MS13"],
    hostileTo: ["MAGA", "TECH", "DSA"],
    alignmentNote: "ISIS hates you for working with anyone but ISIS or MS-13. Working for ISIS sometimes wins over everyone except MS-13; working against ISIS often pleases MAGA and sometimes annoys the DSA.",
    defaultDeckCounts: { celebrities: 4, cops: 1, criminals: 4, total: 9 },
  },
  {
    key: "TECH",
    label: "TECH",
    gem: "/assets/icons/diamond.png",
    color: "#475569",
    gemSingular: "diamond",
    gemPlural: "diamonds",
    title: "TECH — Silicon Valley Money",
    bio: "Very rich, very vulnerable, and enormously influential. Tech Bros turn up equally among Celebrities, Criminals, and Cops. Lurie, Zuckerberg, and their party-drug crowd.",
    alignedWith: ["DSA (somewhat)", "MAGA (somewhat)"],
    hostileTo: ["ISIS (somewhat)"],
    alignmentNote: "Working for TECH often pleases MAGA and annoys the DSA; working against them angers MAGA and pleases the DSA.",
    defaultDeckCounts: { celebrities: 7, cops: 8, criminals: 4, total: 19 },
  },
  {
    key: "DSA",
    label: "DSA",
    gem: "/assets/icons/sapphire.png",
    color: "#0369a1",
    gemSingular: "sapphire",
    gemPlural: "sapphires",
    title: "DSA — Democratic Socialists of America",
    bio: "Leftists, feminists, gays, natives, and locals. The DSA is best represented among the Celebrities, with some Criminals and very few Cops (the Firefighters).",
    alignedWith: ["ISIS", "MS13"],
    hostileTo: ["MAGA (most hostile)", "TECH (somewhat)"],
    alignmentNote: "Working for the DSA sometimes pleases TECH and often angers ISIS and MAGA; working against the DSA sometimes pleases TECH or MAGA.",
    defaultDeckCounts: { celebrities: 9, cops: 3, criminals: 6, total: 18 },
  },
  {
    key: "MS13",
    label: "MS13",
    gem: "/assets/icons/amethyst.png",
    color: "#7e22ce",
    gemSingular: "amethyst",
    gemPlural: "amethysts",
    title: "MS-13 — Mara Salvatrucha",
    bio: "The most indifferent faction in the city, and the most dangerous to cross. MS-13 lives among the Criminals and rarely shows up as a Celebrity or Cop. Less likely than ISIS to attack at 0 loyalty, but always attacks at -1 or lower, and is always very strong in combat.",
    alignedWith: ["DSA (slightly)", "ISIS (slightly)"],
    hostileTo: ["MAGA (somewhat)", "TECH (a little)"],
    alignmentNote: "MS-13 ignores what you do for or against anyone else. Working for MS-13 angers MAGA; working against MS-13 sometimes annoys the DSA and TECH.",
    defaultDeckCounts: { celebrities: 2, cops: 2, criminals: 6, total: 10 },
  },
];

const DEFAULT_POLITICAL_CLIMATE_FACTORS = [
  { id: "MAGA", label: "MAGA", gemName: "Ruby", subtitle: "Make America Great Again" },
  { id: "ISIS", label: "ISIS", gemName: "Emerald", subtitle: "Islamic State Sleeper Cells" },
  { id: "TECH", label: "TECH", gemName: "Diamond", subtitle: "Silicon Valley Money" },
  { id: "DSA", label: "DSA", gemName: "Sapphire", subtitle: "Democratic Socialists of America" },
  { id: "MS13", label: "MS-13", gemName: "Amethyst", subtitle: "Mara Salvatrucha" },
  { id: "Missions", label: "Gigs", gemName: "Contracts", subtitle: "Gig Economy" },
];

const DEFAULT_POLITICAL_CLIMATE_OPTIONS = [
  {
    id: "maga_1",
    factor: "MAGA",
    factorLabel: "MAGA",
    gemName: "Ruby",
    optionNumber: 1,
    timing: "endgame",
    title: "Mass Deportation",
    shortText: "Least MAGA favor is eliminated",
    description: "End of game (resolves FIRST): the player with the Least MAGA favor is deported — eliminated.",
  },
  {
    id: "maga_2",
    factor: "MAGA",
    factorLabel: "MAGA",
    gemName: "Ruby",
    optionNumber: 2,
    timing: "endgame",
    title: "Recall Election",
    shortText: "-10d per +Ruby; +5d per -Ruby",
    description: "End of game: San Francisco voters punish MAGA ties. Lose 10d per +Ruby; gain 5d per -Ruby.",
  },
  {
    id: "maga_3",
    factor: "MAGA",
    factorLabel: "MAGA",
    gemName: "Ruby",
    optionNumber: 3,
    timing: "midgame",
    title: "Back the Blue",
    shortText: "Cops +2 CP; +1 CP per +Ruby",
    description: "Cops gain +2 CP. Each +Ruby gives your SUV +1 CP in all combat.",
  },
  {
    id: "isis_1",
    factor: "ISIS",
    factorLabel: "ISIS",
    gemName: "Emerald",
    optionNumber: 1,
    timing: "endgame",
    title: "Decapitation",
    shortText: "Most ISIS favor loses 25d",
    description: "End of game: the player with the Most ISIS favor loses 25d.",
  },
  {
    id: "isis_2",
    factor: "ISIS",
    factorLabel: "ISIS",
    gemName: "Emerald",
    optionNumber: 2,
    timing: "endgame",
    title: "Fatwa",
    shortText: "+15d/+Emerald if MAGA ≤ 0, -10d if ≥ +1; -5d/-Emerald",
    description: "End of game: +15d per +Emerald if your MAGA favor is ≤ 0, or -10d per +Emerald if it is ≥ +1; -5d per -Emerald.",
  },
  {
    id: "isis_3",
    factor: "ISIS",
    factorLabel: "ISIS",
    gemName: "Emerald",
    optionNumber: 3,
    timing: "midgame",
    title: "Sanctuary City",
    shortText: "All players start with a free Emerald",
    description: "When enacted: every player immediately gains a free Emerald (+1 ISIS).",
  },
  {
    id: "techbros_1",
    factor: "TECH",
    factorLabel: "TECH",
    gemName: "Diamond",
    optionNumber: 1,
    timing: "endgame",
    title: "Series A",
    shortText: "Most TECH favor gains +20% wealth",
    description: "End of game: the player with the Most TECH favor gains +20% wealth.",
  },
  {
    id: "techbros_2",
    factor: "TECH",
    factorLabel: "TECH",
    gemName: "Diamond",
    optionNumber: 2,
    timing: "endgame",
    title: "Conflict of Interest",
    shortText: "-15d per +Diamond and -15d per -Diamond",
    description: "End of game: Lose 15d per +Diamond and 15d per -Diamond.",
  },
  {
    id: "techbros_3",
    factor: "TECH",
    factorLabel: "TECH",
    gemName: "Diamond",
    optionNumber: 3,
    timing: "midgame",
    title: "Lobbying Blitz",
    shortText: "Exchange +Diamonds 1-for-1 for +Rubies or +Sapphires",
    description: "Exchange +Diamonds 1-for-1 into +Rubies (MAGA) or +Sapphires (DSA) anytime.",
  },
  {
    id: "dsa_1",
    factor: "DSA",
    factorLabel: "DSA",
    gemName: "Sapphire",
    optionNumber: 1,
    timing: "endgame",
    title: "Billionaire Tax",
    shortText: "Most DSA favor takes 15d from the wealthiest rival",
    description: "End of game: the player with the Most DSA favor takes 15d from the wealthiest rival.",
  },
  {
    id: "dsa_2",
    factor: "DSA",
    factorLabel: "DSA",
    gemName: "Sapphire",
    optionNumber: 2,
    timing: "endgame",
    title: "Mutual Aid",
    shortText: "+10d per completed DSA Mission",
    description: "End of game: Gain 10d per completed Mission with +Sapphire or a DSA patron.",
  },
  {
    id: "dsa_3",
    factor: "DSA",
    factorLabel: "DSA",
    gemName: "Sapphire",
    optionNumber: 3,
    timing: "midgame",
    title: "Rent Control",
    shortText: "Spend +Sapphires when selling for +1 Scarcity per gem",
    description: "Spend +Sapphires when selling a Good for +1 Scarcity step per gem.",
  },
  {
    id: "ms13_1",
    factor: "MS13",
    factorLabel: "MS-13",
    gemName: "Amethyst",
    optionNumber: 1,
    timing: "endgame",
    title: "Protection Racket",
    shortText: "Most MS-13 favor gains 25d",
    description: "End of game: the player with the Most MS-13 favor gains 25d.",
  },
  {
    id: "ms13_2",
    factor: "MS13",
    factorLabel: "MS-13",
    gemName: "Amethyst",
    optionNumber: 2,
    timing: "endgame",
    title: "Plata o Plomo",
    shortText: "+10d per +Amethyst and +10d per -Amethyst",
    description: "End of game: Gain 10d per +Amethyst and 10d per -Amethyst.",
  },
  {
    id: "ms13_3",
    factor: "MS13",
    factorLabel: "MS-13",
    gemName: "Amethyst",
    optionNumber: 3,
    timing: "midgame",
    title: "Clique Fence",
    shortText: "Fenced cargo +1 Scarcity and no Mission failure",
    description: "Fenced cargo sells +1 Scarcity step higher and does not fail the Mission.",
  },
  {
    id: "missions_1",
    factor: "Missions",
    factorLabel: "Gigs",
    gemName: "Contracts",
    optionNumber: 1,
    timing: "endgame",
    title: "Five-Star Courier",
    shortText: "Most completed Missions gains 30d",
    description: "End of game: Most completed Missions gains 30d.",
  },
  {
    id: "missions_2",
    factor: "Missions",
    factorLabel: "Gigs",
    gemName: "Contracts",
    optionNumber: 2,
    timing: "endgame",
    title: "Full Time Employee",
    shortText: "Receive (gems of one faction × missions done for it) ₿",
    description: "End of game: each player receives A × B 10d. A = gems of any one faction, B = missions completed for that faction.",
  },
  {
    id: "missions_3",
    factor: "Missions",
    factorLabel: "Gigs",
    gemName: "Contracts",
    optionNumber: 3,
    timing: "midgame",
    title: "Surge Pricing",
    shortText: "Completed Missions pay 2× cash; failed Missions fine 10d",
    description: "Completed Missions pay 2× cash; failed or unfinished Missions fine 10d.",
  },
];

function hasActiveClimateOption(gs, optionId) {
  if (!gs || !gs.politicalClimate || !Array.isArray(gs.politicalClimate.activeIds)) return false;
  return gs.politicalClimate.activeIds.includes(optionId);
}

const EDGE_LABELS = {
  green: "Green (Open)",
  red: "Red (Blocked)",
  toll_2: "Toll 2(d)",
  toll_10: "Toll 10(d)",
  toll_15: "Toll 15(d)",
  mob: "Protesters",
  theater: "Open Mic",
  schizophrenic: "Schizophrenic",
  celebrities_1: "Celebrities ×1",
  celebrities_2: "Celebrities ×2",
  celebrities_3: "Celebrities ×3",
  cops_1: "Cops ×1",
  cops_2: "Cops ×2",
  cops_3: "Cops ×3",
  cops_4: "Cops ×4",
  criminals_1: "Criminals ×1",
  criminals_2: "Criminals ×2",
  criminals_3: "Criminals ×3",
};

function parseTollAmount(edgeVal) {
  if (!edgeVal) return 0;
  const m = /^toll_(\d+)$/i.exec(String(edgeVal).trim());
  return m ? Number(m[1]) || 0 : 0;
}

function formatEdgeLabel(edgeVal) {
  if (!edgeVal) return "None";
  if (EDGE_LABELS[edgeVal]) return EDGE_LABELS[edgeVal];
  const tollAmt = parseTollAmount(edgeVal);
  if (tollAmt > 0) return `Toll ${tollAmt}(d)`;
  return String(edgeVal);
}

// San Francisco has no Tiber: river helpers below are no-ops.
const WEST_BANK_CELLS = new Set();

const TIBER_BRIDGES = {};

function getTiberBridgeName(fromCoord, toCoord) {
  if (!fromCoord || !toCoord) return null;
  return TIBER_BRIDGES[`${fromCoord}|${toCoord}`] || null;
}

function isTiberCrossingBlocked(fromCoord, toCoord) {
  if (!fromCoord || !toCoord || fromCoord === toCoord) return false;
  if (WEST_BANK_CELLS.has(fromCoord) === WEST_BANK_CELLS.has(toCoord)) return false;
  return !getTiberBridgeName(fromCoord, toCoord);
}

const DIR_DELTAS_8 = {
  N: [0, -1],
  NE: [1, -1],
  E: [1, 0],
  SE: [1, 1],
  S: [0, 1],
  SW: [-1, 1],
  W: [-1, 0],
  NW: [-1, -1],
};

function getNeighborCoordInDir(coord, dir) {
  if (!coord || !DIR_DELTAS_8[dir]) return null;
  const cIdx = COLS.indexOf(coord.slice(0, 1));
  const rIdx = ROWS.indexOf(coord.slice(1));
  if (cIdx < 0 || rIdx < 0) return null;
  const [dc, dr] = DIR_DELTAS_8[dir];
  const nc = cIdx + dc;
  const nr = rIdx + dr;
  if (nc < 0 || nc >= COLS.length || nr < 0 || nr >= ROWS.length) return null;
  return `${COLS[nc]}${ROWS[nr]}`;
}

const SUV_COLOR_PALETTE = [
  { id: "Z1", label: "Cobalt", hex: "#4A5FD4" },
  { id: "Z3", label: "Amber", hex: "#EBA439" },
  { id: "Z6", label: "Crimson", hex: "#862D25" },
  { id: "Z7", label: "Emerald", hex: "#49884B" },
  { id: "Z9", label: "Sapphire", hex: "#5BC8FA" },
  { id: "Z11", label: "Amethyst", hex: "#C589CF" },
  { id: "Z2", label: "Lime", hex: "#D4FF5E" },
  { id: "Z4", label: "Rose", hex: "#D89CB0" },
  { id: "Z5", label: "Citron", hex: "#9CA14B" },
  { id: "Z8", label: "Violet", hex: "#6F5E8B" },
  { id: "Z10", label: "Bronze", hex: "#795548" },
  { id: "Z12", label: "Silver", hex: "#9E9E9E" },
];

const DIE_SYMBOL_COLORS = {
  Ruby: "#c81e32",
  Red: "#c81e32",
  Cobalt: "#1d4ed8",
  Blue: "#1d4ed8",
  Emerald: "#047857",
  Green: "#047857",
  Gold: "#b45309",
  Yellow: "#b45309",
  Amethyst: "#7e22ce",
  Purple: "#7e22ce",
  Sapphire: "#0284c7",
  Cyan: "#0284c7",
  Z1: "#4A5FD4",
  Z2: "#6b8e23",
  Z3: "#d97706",
  Z4: "#be185d",
  Z5: "#65a30d",
  Z6: "#862D25",
  Z7: "#49884B",
  Z8: "#6F5E8B",
  Z9: "#0284c7",
  Z10: "#795548",
  Z11: "#9333ea",
  Z12: "#52525b",
  Black: "#111111",
  NPC: "#111111",
};

const DIE_SWATCH_COLORS = {
  Ruby: "#d62839",
  Red: "#d62839",
  Cobalt: "#2563eb",
  Blue: "#2563eb",
  Emerald: "#10b981",
  Green: "#10b981",
  Gold: "#f59e0b",
  Yellow: "#f59e0b",
  Amethyst: "#9333ea",
  Purple: "#9333ea",
  Sapphire: "#06b6d4",
  Cyan: "#06b6d4",
  Z1: "#4A5FD4",
  Z2: "#D4FF5E",
  Z3: "#EBA439",
  Z4: "#D89CB0",
  Z5: "#9CA14B",
  Z6: "#862D25",
  Z7: "#49884B",
  Z8: "#6F5E8B",
  Z9: "#5BC8FA",
  Z10: "#795548",
  Z11: "#C589CF",
  Z12: "#9E9E9E",
  Black: "#111111",
  NPC: "#111111",
};

function getSUVColorLabel(colorId) {
  const found = SUV_COLOR_PALETTE.find((c) => c.id === colorId);
  return found ? found.label : colorId || "Cobalt";
}

function getPlayerHexColor(colorId) {
  if (!colorId) return "#EBA439";
  if (typeof colorId === "string" && colorId.startsWith("#")) return colorId;
  const found = SUV_COLOR_PALETTE.find((c) => c.id === colorId || c.label === colorId);
  if (found && found.hex) return found.hex;
  if (DIE_SWATCH_COLORS[colorId]) return DIE_SWATCH_COLORS[colorId];
  if (DIE_SYMBOL_COLORS[colorId]) return DIE_SYMBOL_COLORS[colorId];
  return "#EBA439";
}

/**
 * Renders an SUV token SVG icon colored with the player's SUV color.
 * Replaces the old Roman cart token across the UI.
 */
function renderSUVIconNode(colorName, extraClass = "", titleText = "") {
  const safeColor = colorName || "Z1";
  const wrap = document.createElement("span");
  wrap.className = `suv-icon-wrap color-${safeColor}${extraClass ? " " + extraClass : ""}`;
  if (titleText) {
    wrap.setAttribute("title", titleText);
  }
  const svgNS = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(svgNS, "svg");
  svg.setAttribute("viewBox", "0 0 28 20");
  svg.setAttribute("class", "suv-icon-svg");
  svg.setAttribute("aria-hidden", "true");

  // Roof rack rail
  const rack = document.createElementNS(svgNS, "path");
  rack.setAttribute("d", "M4.5 3.6 L16.8 3.6 M6.5 3.6 L6.5 4.8 M14.8 3.6 L14.8 4.8");
  rack.setAttribute("stroke", "#fff9ec");
  rack.setAttribute("stroke-width", "1.1");
  rack.setAttribute("stroke-linecap", "round");
  svg.appendChild(rack);

  // Boxy SUV body silhouette (rear tailgate -> roof -> angled windshield -> hood -> front bumper -> chassis)
  const body = document.createElementNS(svgNS, "path");
  body.setAttribute(
    "d",
    "M2.2 14.2 L2.2 6.2 C2.2 5.3 2.8 4.8 3.7 4.8 L17.4 4.8 C18.2 4.8 18.8 5.2 19.2 5.9 L21.4 9.5 L25.4 10.1 C26.3 10.2 26.8 10.8 26.8 11.7 L26.8 14.2 C26.8 14.7 26.4 15.1 25.8 15.1 L2.8 15.1 C2.4 15.1 2.2 14.7 2.2 14.2 Z"
  );
  body.setAttribute("fill", "currentColor");
  body.setAttribute("stroke", "#fff9ec");
  body.setAttribute("stroke-width", "1.25");
  body.setAttribute("stroke-linejoin", "round");
  svg.appendChild(body);

  // Tinted SUV windows (rear cargo window, passenger window, front driver/windshield window)
  const windows = document.createElementNS(svgNS, "path");
  windows.setAttribute(
    "d",
    "M3.8 6.2 L8.2 6.2 L8.2 9.4 L3.8 9.4 Z M9.4 6.2 L13.8 6.2 L13.8 9.4 L9.4 9.4 Z M15.0 6.2 L17.5 6.2 L19.5 9.4 L15.0 9.4 Z"
  );
  windows.setAttribute("fill", "rgba(18, 20, 26, 0.78)");
  windows.setAttribute("stroke", "rgba(255, 249, 236, 0.45)");
  windows.setAttribute("stroke-width", "0.55");
  windows.setAttribute("stroke-linejoin", "round");
  svg.appendChild(windows);

  // Headlight & taillight accents
  const headlight = document.createElementNS(svgNS, "rect");
  headlight.setAttribute("x", "25.0");
  headlight.setAttribute("y", "11.0");
  headlight.setAttribute("width", "1.5");
  headlight.setAttribute("height", "1.7");
  headlight.setAttribute("rx", "0.4");
  headlight.setAttribute("fill", "#fef08a");
  svg.appendChild(headlight);

  // Front and rear SUV wheels
  for (const cx of ["7.2", "21.0"]) {
    const wheelOuter = document.createElementNS(svgNS, "circle");
    wheelOuter.setAttribute("cx", cx);
    wheelOuter.setAttribute("cy", "15.0");
    wheelOuter.setAttribute("r", "3.6");
    wheelOuter.setAttribute("fill", "#18181b");
    wheelOuter.setAttribute("stroke", "#fff9ec");
    wheelOuter.setAttribute("stroke-width", "1.2");
    svg.appendChild(wheelOuter);

    const wheelRim = document.createElementNS(svgNS, "circle");
    wheelRim.setAttribute("cx", cx);
    wheelRim.setAttribute("cy", "15.0");
    wheelRim.setAttribute("r", "2.0");
    wheelRim.setAttribute("fill", "currentColor");
    svg.appendChild(wheelRim);

    const wheelHub = document.createElementNS(svgNS, "circle");
    wheelHub.setAttribute("cx", cx);
    wheelHub.setAttribute("cy", "15.0");
    wheelHub.setAttribute("r", "0.85");
    wheelHub.setAttribute("fill", "#fff9ec");
    svg.appendChild(wheelHub);
  }

  wrap.appendChild(svg);
  return wrap;
}

function renderGoogleLogoSvg() {
  const svgNS = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(svgNS, "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("width", "18");
  svg.setAttribute("height", "18");
  const paths = [
    {
      fill: "#EA4335",
      d: "M12 5c1.6 0 3 .6 4.1 1.7l3.1-3.1C17.3 1.8 14.8 1 12 1 7.4 1 3.5 3.6 1.6 7.4l3.7 2.8C6.2 7.2 8.9 5 12 5z",
    },
    {
      fill: "#4285F4",
      d: "M23.5 12.3c0-.8-.1-1.6-.2-2.3H12v4.5h6.5c-.3 1.5-1.1 2.8-2.4 3.6l3.7 2.9c2.2-2 3.7-5 3.7-8.7z",
    },
    {
      fill: "#FBBC05",
      d: "M5.3 14.8c-.2-.8-.4-1.8-.4-2.8s.2-2 .4-2.8L1.6 6.4C.6 8.4 0 10.6 0 12s.6 3.6 1.6 5.6l3.7-2.8z",
    },
    {
      fill: "#34A853",
      d: "M12 23c3.2 0 6-1.1 8-3l-3.7-2.9c-1.1.7-2.5 1.2-4.3 1.2-3.1 0-5.8-2.1-6.7-5l-3.7 2.8C3.5 19.9 7.4 23 12 23z",
    },
  ];
  for (const p of paths) {
    const pathEl = document.createElementNS(svgNS, "path");
    pathEl.setAttribute("fill", p.fill);
    pathEl.setAttribute("d", p.d);
    svg.appendChild(pathEl);
  }
  return svg;
}

const ROME_DIE_ROMAN_FACES = ["0", "0", "I", "I", "II", "III"];

const appState = {
  user: null,
  csrfToken: null,
  googleClientId: "",
  activeTab: "portal", // "portal" | "tabletop" | "rulebook" | "profile" | "completed_games"
  authMode: "login", // "login" | "register"
  games: [],
  leaderboard: [],
  completedGames: [],
  completedGamesLoading: false,
  shownFinishModalGameIds: new Set(),
  botPersonas: [],
  referenceCatalog: [],
  rulebookSection: "overview",
  rulebookSearch: "",
  currentGameId: null,
  gameSummary: null,
  gameState: null,
  boardViewMode: "auto", // "auto" | "rome" | "market" | "both"
  suvPanelTab: "suv", // "suv" | "navigate"
  inspectedCell: "C3",
  setupDiscardMissions: new Set(),
  setupDiscardInfluence: new Set(),
  cleanupKeepHenchmen: new Set(),
  cleanupInitializedNight: null,
  promptedCargoPickups: new Set(),
  promptedCargoDeliveries: new Set(),
  promptedTop3Id: null,
  promptedNpcOfferId: null,
  promptedSUVOverflowId: null,
  promptedMarketRewardId: null,
  highlightedMarketTrack: null,
  swappedMissionStackIds: new Set(),
  shownScoutIds: new Set(),
  pollTimer: null,
  lastSeenDiceSeq: null,
  diceRollQueue: [],
  activeDiceOverlay: null,
  isDiceRolling: false,
  diceTickCount: 0,
  diceAnimTimer: null,
  lastSeenMissionEventSeq: null,
  missionModalQueue: [],
  lastSyncedGameId: null,
  lastSyncedPhase: null,
  lastSyncedNight: null,
  chronicleScrollTop: 0,
  chronicleUserScrolled: false,
  chronicleLastLogSig: null,
  chronicleLastGameId: null,
  armedDieAction: null,
  lastAutoScrolledEncounterKey: null,
  portalDraftName: "",
  portalMaxPlayers: 3,
  portalBotCount: 2,
  portalInviteMode: "open",
  portalInvitedUsernames: "",
  pendingInviteGameId: null,
  highlightedLobbyId: null,
  portalBotStrategies: ["balanced", "luxury", "aggressive", "faction", "opportunist"],
  lastSeenNpcEventSeq: null,
  npcPacingQueue: [],
  activeNpcEvent: null,
  npcPacingTimer: null,
  npcPacingTotal: 0,
  npcPacingIndex: 0,
  _wasViewerTurn: false,
  marketBoardScrollLeft: 0,
  marketBoardScrollTop: 0,
  climateBoardScrollLeft: 0,
};

/**
 * Normalizes currency tokens like "60(d)", "60d", or "60𐆖" so the Roman Denarius symbol "𐆖"
 * is placed at the front of the price (e.g. "𐆖60", "+𐆖100", "<𐆖15").
 */
const DENARIUS_SYM = "𐆖";

/**
 * InstantGram SF currency: the engine keeps integer amounts where 1 unit = 1 Denarius = 0.1 Bitcoin.
 * Every displayed amount is shown in Bitcoin (e.g. 14 -> ₿1.4, 30 -> ₿3).
 */
const BTC_SYM = "₿";

function formatBtc(units) {
  const n = Number(units);
  if (!Number.isFinite(n)) return String(units);
  const v = Math.round(n) / 10;
  return Number.isInteger(v) ? String(v) : v.toFixed(1);
}

function replaceDenariiTokens(rawStr) {
  const toBtcList = (nums) => nums.split("/").map((x) => formatBtc(x)).join("/");
  return String(rawStr)
    .replace(/𐆖\s?(\d+(?:\/\d+)*)/g, (_m, nums) => `${BTC_SYM}${toBtcList(nums)}`)
    .replace(
      /(\b|[+\-<>]=?)(\d+)(\s*[x×*]\s*)?(\(R\)|\(r\)|®|🅁)(?:\(d\)|d\b|𐆖)/g,
      (_m, pre, num, x, die) => `${pre}${BTC_SYM}${formatBtc(num)}${x || ""}${die}`
    )
    .replace(/(\b|[+\-<>]=?)(\d+(?:\/\d+)*)(?:\(d\)|d\b|𐆖)/gi, (_m, pre, nums) => `${pre}${BTC_SYM}${toBtcList(nums)}`)
    .replace(/\(d\)/gi, BTC_SYM)
    .replace(/\bDenarii\b/g, "Bitcoin")
    .replace(/\bDenarius\b/g, "Bitcoin");
}

/**
 * Appends text to a DOM node, replacing:
 * - (d) or <num>d with the Roman Denarius symbol (𐆖)
 * - (R), (r), ®, or 🅁 with an inline square-enclosed 'R' symbol (<span class="rome-die-box">R</span>)
 */
const GAME_TOKEN_REGEX =
  /(\(SELL_SYM\)|\(BUY_SYM\)|\(COMBAT_ICON\)|\(DECK_ICON\)|\(QUEST_ICON\)|\(R\)|\(r\)|®|🅁|𐆖)/g;

/**
 * Builds an inline SVG vector Roman Denarius monogram (X with crossbar: 𐆖)
 * using createElementNS so it renders identically on mobile (iOS/Android) and desktop
 * without relying on missing U+10196 system font glyphs.
 */
function createDenariusSvgNode(extraClass = "") {
  const btc = document.createElement("span");
  btc.className = `btc-sym ${extraClass}`.trim();
  btc.setAttribute("aria-hidden", "true");
  btc.textContent = BTC_SYM;
  return btc;
}

function createSellPriceSymbolNode(isFence = false) {
  const span = document.createElement("span");
  span.className = "price-sym-sell";
  span.setAttribute("title", isFence ? "Fence Price (+₿)" : "Retail Price (+₿)");
  span.setAttribute("aria-label", isFence ? "Fence Price" : "Retail Price");
  span.appendChild(document.createTextNode("+"));
  span.appendChild(createDenariusSvgNode("price-sym-denarius-svg"));
  return span;
}

/**
 * Builds an italic Red -₿ symbol representing Wholesale Price (or Hire Cost) on Goods & Henchman cards.
 */
function createBuyPriceSymbolNode(isHenchman = false) {
  const span = document.createElement("span");
  span.className = "price-sym-buy";
  span.setAttribute("title", isHenchman ? "Hire Cost (-₿)" : "Wholesale Price (-₿)");
  span.setAttribute("aria-label", isHenchman ? "Hire Cost" : "Wholesale Price");
  span.appendChild(document.createTextNode("-"));
  span.appendChild(createDenariusSvgNode("price-sym-denarius-svg"));
  return span;
}

/**
 * Builds an inline Combat icon node using the game's Pistol artwork (/assets/icons/combat.png).
 */
function createCombatInlineIconNode(extraClass = "") {
  const img = document.createElement("img");
  img.className = `enc-tier-inline-icon combat-tier-icon ${extraClass}`.trim();
  img.src = resolveAssetUrl("/assets/icons/combat.png");
  img.alt = "Combat";
  img.title = "Combat";
  img.width = 18;
  img.height = 18;
  img.style.width = "1.2em";
  img.style.height = "1.2em";
  img.style.maxWidth = "22px";
  img.style.maxHeight = "22px";
  img.style.objectFit = "contain";
  img.style.verticalAlign = "-0.2em";
  return img;
}

/**
 * Builds an inline Computer/Laptop icon representing the Top Mission Deck symbol ([computer]).
 */
function createDeckOfCardsIconNode(extraClass = "") {
  const img = document.createElement("img");
  img.className = `enc-tier-inline-icon deck-cards-icon-svg ${extraClass}`.trim();
  img.src = resolveAssetUrl("/assets/icons/laptop.png");
  img.alt = "Job Deck ([computer])";
  img.title = "Top Card of Job Deck";
  img.width = 18;
  img.height = 18;
  img.style.width = "1.2em";
  img.style.height = "1.2em";
  img.style.maxWidth = "22px";
  img.style.maxHeight = "22px";
  img.style.objectFit = "contain";
  img.style.verticalAlign = "-0.2em";
  return img;
}

/**
 * Builds an inline Isometric Cash Stack icon representing the Job symbol ([cash]).
 */
function createAncientRomanChestIconNode(extraClass = "") {
  const img = document.createElement("img");
  img.className = `enc-tier-inline-icon roman-chest-icon-svg ${extraClass}`.trim();
  img.src = resolveAssetUrl("/assets/icons/cash.png");
  img.alt = "Job ([cash])";
  img.title = "Job";
  img.width = 18;
  img.height = 18;
  img.style.width = "1.2em";
  img.style.height = "1.2em";
  img.style.maxWidth = "22px";
  img.style.maxHeight = "22px";
  img.style.objectFit = "contain";
  img.style.verticalAlign = "-0.2em";
  return img;
}

/**
 * Builds a SUV-in-a-Circle symbol representing a Move action.
 */
function createMoveActionCircleNode(titleText = "Unused Move Action") {
  const wrap = document.createElement("span");
  wrap.className = "action-symbol-circle move-action-circle";
  wrap.setAttribute("title", titleText);

  const svgNS = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(svgNS, "svg");
  svg.setAttribute("viewBox", "0 0 24 20");
  svg.setAttribute("aria-hidden", "true");

  const body = document.createElementNS(svgNS, "path");
  body.setAttribute("d", "M2.5 13.5 V6.2 H15.2 L17.8 9.6 L21.5 10.2 V13.5 H2.5 Z M8.5 6.2 V9.6 M14.8 9.6 H2.5");
  body.setAttribute("fill", "none");
  body.setAttribute("stroke", "currentColor");
  body.setAttribute("stroke-width", "1.9");
  body.setAttribute("stroke-linecap", "round");
  body.setAttribute("stroke-linejoin", "round");
  svg.appendChild(body);

  for (const cx of [6.8, 17.5]) {
    const wheel = document.createElementNS(svgNS, "circle");
    wheel.setAttribute("cx", String(cx));
    wheel.setAttribute("cy", "15.2");
    wheel.setAttribute("r", "2.3");
    wheel.setAttribute("fill", "currentColor");
    svg.appendChild(wheel);
  }
  wrap.appendChild(svg);
  return wrap;
}

/**
 * Builds a Denarius-in-a-Circle symbol representing a Transaction action.
 */
function createTransactionActionCircleNode(titleText = "Unused Transaction Action") {
  const wrap = document.createElement("span");
  wrap.className = "action-symbol-circle transaction-action-circle";
  wrap.setAttribute("title", titleText);
  wrap.appendChild(createDenariusSvgNode());
  return wrap;
}

/**
 * InstantGram SF display reskin. Internal ids (goods tracks, deck keys) stay the
 * Night Merchant ones so the shared engine keeps working; every visible string
 * passes through here to show the San Francisco names instead.
 */
const SF_RESKIN_RULES = [
  [/\bGladiator's Intervention\b/g, "Backup Arrives"],
  [/\bHenchman's Intervention\b/g, "Backup Arrives"],
  [/\bFriend In The City (?:Guard|Henchman)\b/g, "City Hall Fixer"],
  [/\bFlying Chamber Pot\b/g, "Pepper Spray"],
  [/\bMercenary Ambush\b/g, "Drive-By"],
  [/\bWine Forger\b/g, "Fentanyl Press"],
  [/\bOpiates Forger\b/g, "Fentanyl Press"],
  [/\bCartwright\b/g, "Body Shop"],
  [/\bSUVwright\b/g, "Body Shop"],
  [/\bCasus Belli\b/g, "Doxxing"],
  [/\bProphecy\b/g, "Bad Trip"],
  [/\bProcurer\b/g, "Dark Web Plug"],
  [/\bSupplicant\b/g, "VIP Vouch"],
  [/\bDramaturge\b/g, "Viral Heckler"],
  [/\bMake Haste\b/g, "Floor It"],
  [/\bPuffery\b/g, "Market Hype"],
  [/\bPatron\b/g, "Sponsor"],
  [/\bExotic Animals?\b/g, "Powder Uppers"],
  [/\bExotic A\b/g, "Powder Uppers"],
  [/\bExotic Beasts?\b/g, "Powder Uppers"],
  [/\bMeat Animals?\b/g, "Pill Uppers"],
  [/\bMeat A\b/g, "Pill Uppers"],
  [/\bCheap Wine\b/g, "Street Opiates"],
  [/\bCheap W\b/g, "Street Opiates"],
  [/\b(?:Fine|Fancy) Wine\b/g, "Pharma Opiates"],
  [/\b(?:Fine|Fancy) W\b/g, "Pharma Opiates"],
  [/\bParty Drugs\b/g, "Party"],
  [/\bAnimals\b/g, "Uppers"],
  [/\bAnimal\b/g, "Upper"],
  [/\bWines?\b/g, "Opiates"],
  [/\bGrain\b/g, "Weed"],
  [/\bMarble\b/g, "Party"],
  [/\bGuards\b/g, "Henchmen"],
  [/\bGuard\b/g, "Henchman"],
  [/\bguards\b/g, "henchmen"],
  [/\bguard\b/g, "henchman"],
  [/\bHenchmen\b/g, "Henchmen"],
  [/\bHenchman\b/g, "Henchman"],
  [/\bhenchmen\b/g, "henchmen"],
  [/\bhenchman\b/g, "henchman"],
  [/\bSUV Mat\b/g, "SUV"],
  [/\bSUVs\b/g, "SUVs"],
  [/\bSUV\b/g, "SUV"],
  [/\bsuvs\b/g, "SUVs"],
  [/\bsuv\b/g, "SUV"],
  [/\bCelebrities\b/g, "Celebrities"],
  [/\bPatricii\b/gi, "Celebrities"],
  [/\bPatricius\b/g, "Celebrity"],
  [/\bCops\b/g, "Cops"],
  [/\bLegionnaires\b/gi, "Cops"],
  [/\bLegionnaire\b/gi, "Cop"],
  [/\bLegiones\b/gi, "Cops"],
  [/\bLegionar(?:y|ies)\b/g, "Cop"],
  [/\bCriminals\b/g, "Criminals"],
  [/\bNefarii\b/gi, "Criminals"],
  [/\bNefarius\b/g, "Criminal"],
  [/\bMission Deck\b/gi, "Job Deck"],
  [/\bMission Cargo\b/gi, "Job Cargo"],
  [/\bMissiones\b/gi, "Jobs"],
  [/\bMissions\b/g, "Jobs"],
  [/\bmissions\b/g, "jobs"],
  [/\bMission\b/g, "Job"],
  [/\bmission\b/g, "job"],
  [/\bMissio\b/g, "Job"],
  [/\bDeck Quests?\b/gi, "Deck Job"],
  [/\bQuests\b/g, "Jobs"],
  [/\bQuest\b/g, "Job"],
  [/\bPolitical Climate\b/g, "Ballot Initiatives"],
  [/\bDecrees\b/g, "Ballot Initiatives"],
  [/\bDecree\b/g, "Ballot Initiative"],
  [/\bProtesterss?\b/g, "Protesters"],
  [/\bTheat(?:er|re) Troupes?\b/g, "Stand-Up Comic"],
  [/\bSchizophrenics?\b/g, "Schizophrenic"],
  [/\bMerchants\b/g, "Dealers"],
  [/\bMerchant\b/g, "Dealer"],
  [/\bmerchants\b/g, "dealers"],
  [/\bmerchant\b/g, "dealer"],
  [/\bPortus Ostiae\b/g, "the Stash House"],
  [/\bOstia\b/g, "Stash House"],
  [/\bImperial Forums?\b/g, "Open-Air Market"],
  [/\bForums?\b/g, "Open-Air Market"],
  [/\bVia (?:City )?Gates?\b/g, "Entry Point"],
  [/\bThursday\b/g, "Thursday"],
  [/\bFriday\b/g, "Friday"],
  [/\bFall\b/g, "Saturday"],
  [/\bSunday Reckoning\b/g, "Sunday Morning Reckoning"],
  [/\bDecember 211(?: A\.D\.)?(?: Purge)?/g, "Sunday Morning"],
  [/\bnights\b/g, "nights"],
  [/\bnight\b/g, "night"],
  [/\bNights\b/g, "Nights"],
  [/\bNight\b/g, "Night"],
  [/\b(?:the )?end of 211 A\.D\./g, "the end of the year"],
  [/\b211 A\.D\./g, "2026"],
  [/\bProcession\b/g, "Street Fair"],
  [/\bSalve!/g, "Shout-Out!"],
  [/\bUshered Along\b/g, "Move Along"],
  [/\bBrutta Figura\b/g, "Bad Look"],
  [/\bRoad Blocked\b/g, "Road Closed"],
  [/\bRome's\b/g, "San Francisco's"],
  [/\bRome\b/g, "San Francisco"],
  [/\bRoman\b/g, "SF"],
];

function sfReskinText(rawValue) {
  let out = String(rawValue);
  if (out.trim() === "Mission") return out;
  const NEIGHBORHOOD_MISSION = "__SF_D4_MISSION_NEIGHBORHOOD__";
  out = out
    .replace(/\bMission District\b/g, `${NEIGHBORHOOD_MISSION} District`)
    .replace(/\b(D4\s*(?:—|–|-|:|\()\s*)Mission\b/g, `$1${NEIGHBORHOOD_MISSION}`)
    .replace(/\bMission(\s*\(D4\))/g, `${NEIGHBORHOOD_MISSION}$1`)
    .replace(/\(Mission\)/g, `(${NEIGHBORHOOD_MISSION})`)
    .replace(/\b(Move to|Scout|Enter|Leave|at|in|to|from|near|into|around|The|the)\s+Mission\b/g, `$1 ${NEIGHBORHOOD_MISSION}`)
    .replace(/(—|–)\s*Mission\b/g, `$1 ${NEIGHBORHOOD_MISSION}`);
  for (const [re, rep] of SF_RESKIN_RULES) out = out.replace(re, rep);
  return out.replaceAll(NEIGHBORHOOD_MISSION, "Mission");
}

function appendTextWithRomeDice(parentNode, rawValue, isOptionTag = false) {
  const str = replaceDenariiTokens(sfReskinText(rawValue));
  if (!GAME_TOKEN_REGEX.test(str)) {
    parentNode.appendChild(document.createTextNode(str));
    return;
  }
  GAME_TOKEN_REGEX.lastIndex = 0;
  if (isOptionTag) {
    const optSafe = str
      .replace(/\(SELL_SYM\)/g, "+d")
      .replace(/\(BUY_SYM\)/g, "-d")
      .replace(/\(COMBAT_ICON\)/g, "Combat")
      .replace(/\(DECK_ICON\)/g, "Deck ")
      .replace(/\(QUEST_ICON\)/g, "Quest")
      .replace(/(\(R\)|\(r\)|®)/g, "🅁")
      .replace(/𐆖(\d+)/g, "$1d")
      .replace(/𐆖/g, "d");
    parentNode.appendChild(document.createTextNode(optSafe));
    return;
  }
  const parts = str.split(GAME_TOKEN_REGEX);
  for (const part of parts) {
    if (!part) continue;
    if (part === "(SELL_SYM)") {
      parentNode.appendChild(createSellPriceSymbolNode(false));
    } else if (part === "(BUY_SYM)") {
      parentNode.appendChild(createBuyPriceSymbolNode(false));
    } else if (part === "(COMBAT_ICON)") {
      parentNode.appendChild(createCombatInlineIconNode());
    } else if (part === "(DECK_ICON)") {
      parentNode.appendChild(createDeckOfCardsIconNode());
    } else if (part === "(QUEST_ICON)") {
      parentNode.appendChild(createAncientRomanChestIconNode());
    } else if (part === "(R)" || part === "(r)" || part === "®" || part === "🅁") {
      const dieBox = document.createElement("span");
      dieBox.className = "rome-die-box";
      dieBox.setAttribute("title", "Rome Die");
      dieBox.textContent = "R";
      parentNode.appendChild(dieBox);
    } else if (part === DENARIUS_SYM) {
      const denSpan = document.createElement("span");
      denSpan.className = "denarius-sym";
      denSpan.setAttribute("title", "Denarii");
      denSpan.setAttribute("aria-label", "Denarii");
      denSpan.appendChild(createDenariusSvgNode());
      parentNode.appendChild(denSpan);
    } else {
      parentNode.appendChild(document.createTextNode(part));
    }
  }
}

function resolveGoodTrackClass(itemOrTrack) {
  const raw =
    typeof itemOrTrack === "string"
      ? itemOrTrack
      : (itemOrTrack && (itemOrTrack.track || itemOrTrack.category || itemOrTrack.subcategory)) || "";
  const s = String(raw).toLowerCase();
  if (s.includes("grain") || s.includes("weed")) return "good-track-grain";
  if (s.includes("animal") || s.includes("upper")) return "good-track-animals";
  if (s.includes("wine") || s.includes("opiate")) return "good-track-wine";
  if (s.includes("weapon")) return "good-track-weapons";
  if (s.includes("marble") || s.includes("stone") || s.includes("party")) return "good-track-marble";
  if (s.includes("henchm") || s.includes("guard")) return "good-track-henchmen";
  return "good-track-weapons";
}

/**
 * Safe DOM element builder using createElement, textContent, and addEventListener.
 */
function el(tag, attrs = {}, ...children) {
  const node = document.createElement(tag);
  const isOption = String(tag).toLowerCase() === "option";
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v === undefined || v === null || v === false) continue;
    if (k === "className") {
      node.className = String(v);
    } else if (k === "text") {
      appendTextWithRomeDice(node, v, isOption);
    } else if (k === "style" && typeof v === "object") {
      for (const [sk, sv] of Object.entries(v)) {
        const sVal = String(sv);
        node.style[sk] = sVal.includes("/assets/") ? sVal.replace(/\/assets\//g, "./assets/") : sVal;
      }
    } else if (k.startsWith("on") && typeof v === "function") {
      node.addEventListener(k.slice(2).toLowerCase(), v);
    } else if (k === "disabled" || k === "checked" || k === "selected") {
      if (v) node[k] = true;
    } else if (k === "src" || k === "href") {
      node.setAttribute(k, resolveAssetUrl(String(v)));
    } else if (k === "title") {
      const safeTitle = replaceDenariiTokens(sfReskinText(String(v)))
        .replace(/(\(R\)|\(r\)|®)/g, "🅁")
        .replace(/𐆖(\d+)/g, "$1d")
        .replace(/𐆖/g, "d");
      node.setAttribute("title", safeTitle);
    } else {
      node.setAttribute(k, String(v));
    }
  }
  for (const child of children.flat()) {
    if (child === undefined || child === null || child === false) continue;
    if (child instanceof Node) {
      node.appendChild(child);
    } else {
      appendTextWithRomeDice(node, child, isOption);
    }
  }
  return node;
}

const TILE_MODIFIER_MAP = {
  "<<": "++",
  "<": "+",
  "=": "=",
  ">": "-",
  ">>": "--",
  "++": "++",
  "+": "+",
  "-": "-",
  "--": "--",
};

function formatTileModifier(mod) {
  const s = String(mod ?? "=").trim();
  return TILE_MODIFIER_MAP[s] || s;
}

function getTileModifierClass(mod) {
  const f = formatTileModifier(mod);
  if (f === "++" || f === "+") return "mod-positive";
  if (f === "--" || f === "-") return "mod-negative";
  return "mod-neutral";
}

/**
 * Renders the back side of an unrevealed tile card (matching the underlying Rome map board square).
 */
function resolveGoodCardArtUrl(cardOrItem, trackName = "") {
  const c = cardOrItem || {};
  const combined = `${trackName} ${c.track || ""} ${c.category || ""} ${c.subcategory || ""} ${c.subtitle || ""} ${c.name || ""}`.toLowerCase();
  if (combined.includes("henchman") || combined.includes("henchmen") || combined.includes("muscle") || combined.includes("enforcer") || combined.includes("bouncer")) {
    return "/assets/fp/goods_art/art_henchmen.jpg?v=35";
  }
  if (
    combined.includes("weapon") ||
    combined.includes("glock") ||
    combined.includes("nuke") ||
    combined.includes("rifle") ||
    combined.includes("uzi") ||
    combined.includes("gun") ||
    combined.includes("taser") ||
    combined.includes("knife") ||
    combined.includes("sword") ||
    combined.includes("spear") ||
    combined.includes("shield") ||
    combined.includes("armor") ||
    combined.includes("blade")
  ) {
    return "/assets/fp/goods_art/art_weapons.jpg?v=35";
  }
  if (
    combined.includes("opiate") ||
    combined.includes("heroin") ||
    combined.includes("fent") ||
    combined.includes("oxy") ||
    combined.includes("perc") ||
    combined.includes("morphine") ||
    combined.includes("marble") ||
    combined.includes("stone")
  ) {
    return "/assets/fp/goods_art/art_opiates.jpg?v=35";
  }
  if (
    combined.includes("upper") ||
    combined.includes("coke") ||
    combined.includes("cocaine") ||
    combined.includes("adderall") ||
    combined.includes("meth") ||
    combined.includes("speed") ||
    combined.includes("exotic")
  ) {
    return "/assets/fp/goods_art/art_uppers.jpg?v=35";
  }
  if (
    combined.includes("party") ||
    combined.includes("molly") ||
    combined.includes("mdma") ||
    combined.includes("ketamine") ||
    combined.includes("shroom") ||
    combined.includes("lsd") ||
    combined.includes("acid") ||
    combined.includes("wine") ||
    combined.includes("animal") ||
    combined.includes("meat")
  ) {
    return "/assets/fp/goods_art/art_party.jpg?v=35";
  }
  if (
    combined.includes("weed") ||
    combined.includes("kush") ||
    combined.includes("cannabis") ||
    combined.includes("pre-roll") ||
    combined.includes("edible") ||
    combined.includes("hash") ||
    combined.includes("grain") ||
    combined.includes("wheat")
  ) {
    return "/assets/fp/goods_art/art_weed.jpg?v=35";
  }
  return "/assets/fp/goods_art/art_weed.jpg?v=35";
}

const GOODS_NAME_TO_ID = {
  "pineapple express": "grn_1", "golden teacher": "grn_2", "brick weed": "grn_3", "granddaddy purple": "grn_4",
  "mescaline": "grn_5", "northern lights": "grn_6", "guerilla glue #4": "grn_7", "wedding cake": "grn_8",
  "blue dream": "grn_9", "feline the cat": "grn_10", "sour diesel": "grn_11", "og kush": "grn_12",
  "apache": "cw_1", "china white": "cw_2", "brown sugar": "cw_3", "reds": "cw_4", "number 4": "cw_5",
  "tranq": "cw_6", "chiva": "cw_7", "purple drank": "cw_8", "blues": "cw_9",
  "tussin": "fw_1", "trammies": "fw_2", "vikes": "fw_3", "percs": "fw_4", "juice": "fw_5",
  "red devils": "fw_6", "miss emma": "fw_7", "oc 80s": "fw_8", "hospital heroin": "fw_9",
  "mini-thins": "ma_1", "bennies": "ma_2", "black beauties": "ma_3", "abu hilalain": "ma_4", "blue addys": "ma_5",
  "dexies": "ma_6", "kiddie coke": "ma_7", "addys": "ma_8", "moda": "ma_9",
  "crank": "ea_1", "flakka": "ea_2", "shake-n-bake": "ea_3", "yayo": "ea_4", "stepped-on blow": "ea_5",
  "rock": "ea_6", "glass": "ea_7", "peruvian flake": "ea_8", "fish scale": "ea_9",
  "brass knuckles": "wpn_1", "riot shield": "wpn_2", "switchblade": "wpn_3", "glawk 19": "wpn_4",
  "ar-15": "wpn_5", "desert eagle": "wpn_6", "stab vest": "wpn_7", "ballistic helmet": "wpn_8",
  "hunting rifle": "wpn_9", "molotov cocktail": "wpn_10", "pipe bomb": "wpn_11", "ballistic vest": "wpn_12",
  "mac-10": "wpn_13", "mavberg 500": "wpn_14", "draco ak": "wpn_15", "bearcat .50 cal": "wpn_16",
  "rush": "mrb_1", "liquid g": "mrb_2", "whippets": "mrb_3", "tusi": "mrb_4", "bunk molly": "mrb_5",
  "blue punishas": "mrb_6", "pink tezlas": "mrb_7", "red mitsubushis": "mrb_8", "special k": "mrb_9",
  "blue dolphins": "mrb_10", "nexus": "mrb_11", "champagne molly": "mrb_12",
  "big mike": "grd_1", "big tina": "grd_2", "rosa \"la flaca\"": "grd_3", "tank": "grd_4",
  "doc": "grd_5", "skinny pete": "grd_6", "twins": "grd_7", "dre": "grd_8",
  "ex-marine gus": "grd_9", "bouncer sal": "grd_10", "nurse keisha": "grd_11", "felicia": "grd_12",
};

const JOBS_NAME_TO_ID = {
  "community pricing": "mis_45", "vip list": "mis_48", "bottle service": "mis_53", "markup": "mis_42",
  "dead drop": "mis_55", "paparazzi": "mis_7", "mutual aid drop": "mis_35", "make an example": "mis_37",
  "hit job": "mis_39", "take out the trash": "mis_52", "copwatch": "mis_26", "last mile": "mis_30",
  "silence a witness": "mis_54", "curbside pickup": "mis_50", "harm reduction": "mis_33", "regime change": "mis_34",
  "neighborhood watch": "mis_41", "witness protection": "mis_51", "influencer": "mis_56",
};

const INF_NAME_TO_ID = {
  "twist of fate": "inf_1", "patron": "inf_2", "sponsor": "inf_2",
  "flying chamber pot": "inf_3", "pepper spray": "inf_3",
  "procurer": "inf_5", "dark web plug": "inf_5",
  "change of plans": "inf_8", "lucky break": "inf_11",
  "prophecy": "inf_12", "bad trip": "inf_12",
  "shortcut": "inf_14",
  "supplicant": "inf_15", "vip vouch": "inf_15",
  "dsa favor": "inf_16", "plea": "inf_17", "ms13 favor": "inf_18",
  "make haste": "inf_20", "floor it": "inf_20",
  "suvwright": "inf_22", "cartwright": "inf_22", "body shop": "inf_22",
  "friend in the city henchman": "inf_23", "friend in the city guard": "inf_23", "city hall fixer": "inf_23",
  "isis favor": "inf_26", "informants": "inf_27", "thug": "inf_28", "muscle": "inf_28",
  "match fixing": "inf_29", "man of the people": "inf_34", "surprise shipment": "inf_35",
  "distraction": "inf_37",
  "dramaturge": "inf_43", "viral heckler": "inf_43",
  "gladiator's intervention": "inf_45", "henchman's intervention": "inf_45", "backup arrives": "inf_45",
  "puffery": "inf_46", "market hype": "inf_46",
  "wine forger": "inf_50", "opiates forger": "inf_50", "fentanyl press": "inf_50", "stepped on": "inf_50",
  "tech favor": "inf_52", "maga favor": "inf_53",
  "mercenary ambush": "inf_56", "drive-by": "inf_56",
  "trained dog": "inf_57", "attack dog": "inf_57",
  "casus belli": "inf_58", "doxxing": "inf_58",
};

const ENC_NAME_TO_ID = {
  "procession": "pat_1", "mark zuckerberg": "pat_2", "salve!": "nef_3", "donald trump": "pat_4",
  "elon musk": "pat_5", "peter thiel": "pat_6", "ushered along": "leg_29", "brian chesky": "pat_8",
  "dario amodei": "pat_9", "daniela amodei": "pat_10", "steph curry": "pat_11", "chesa boudin": "pat_12",
  "alice huang": "pat_13", "dr. oz": "pat_14", "jensen huang": "pat_16", "bernie sanders": "pat_17",
  "cornel west": "pat_18", "drag queen": "pat_19", "tenured professor": "pat_20", "indie podcaster": "pat_21",
  "burning guy artist": "pat_22", "muralist": "pat_23", "climate activist": "pat_24", "crypto influencer": "pat_25",
  "startup founder": "pat_26", "ai ethicist": "pat_27", "edgelord streamer": "pat_28", "brutta figura": "nef_17",
  "radicalized youtoober": "pat_30", "mayor lurie": "leg_1", "scott wiener": "leg_2", "paul graham": "leg_3",
  "fbi": "leg_4", "cia": "leg_5", "meter maid": "leg_6", "traffic cop": "leg_7", "rookie": "leg_8",
  "nayib bukele": "leg_9", "dirty cop": "leg_10", "jared kushner": "leg_11", "ocasio-cortez": "leg_12",
  "dean preston": "leg_13", "firefighters": "leg_14", "harmeet dhillon": "leg_15", "vivek ramaswamy": "leg_16",
  "rudy giuliani": "leg_17", "sfpd": "leg_18", "dea": "leg_19", "ice": "leg_20", "homeland security": "leg_21", "atf": "leg_21",
  "sfpd narcotics unit": "leg_22", "dea task force": "leg_23", "ice raid team": "leg_24", "border patrol": "leg_25",
  "road blocked": "nef_27", "chp trooper": "leg_27", "sheriff’s deputy": "leg_28", "sheriff's deputy": "leg_28",
  "muni fare inspector": "leg_30", "sam altman": "nef_1", "palmer luckey": "nef_2", "vc capitalist": "nef_4",
  "crypto scammer": "nef_5", "kkk": "nef_6", "pot farmers": "nef_7", "international terrorist": "nef_8",
  "domestic terrorist": "nef_9", "hamas": "nef_10", "hezbollah": "nef_11", "houthis": "nef_12", "iran": "nef_13",
  "bashar al-assad": "nef_14", "abu bakr al-baghdadi": "nef_15", "pimp": "nef_16", "london breed": "nef_18",
  "homeless": "nef_19", "illegal": "nef_20", "unhoused": "nef_21", "undocumented": "nef_22",
  "elmer rodriguez": "nef_23", "clique enforcer": "nef_24", "sicario": "nef_25", "gang banger": "nef_26",
  "bad hombre": "nef_28", "coyote": "nef_29",
};

function resolveFullGoodCardFaceUrl(cardOrItem, trackName = "") {
  const c = cardOrItem || {};
  const rawId = String(c.id || "").trim();
  const mStd = rawId.match(/^((?:grn|mrb|ma|ea|cw|fw|wpn|grd)_\d+)/i);
  if (mStd) {
    return `/assets/fp/cards/goods/${mStd[1].toLowerCase()}.jpg?v=111`;
  }
  const mCargo = rawId.match(/^mcargo_(?:enc_)?((?:mis|pat|leg|nef)_\d+)/i);
  if (mCargo) {
    return `/assets/fp/cards/goods/mcargo_${mCargo[1].toLowerCase()}.jpg?v=111`;
  }
  if (c.missionId) {
    const mMid = String(c.missionId).match(/(?:enc_)?((?:mis|pat|leg|nef)_\d+)/i);
    if (mMid) {
      return `/assets/fp/cards/goods/mcargo_${mMid[1].toLowerCase()}.jpg?v=111`;
    }
  }
  const lowerName = String(c.name || "").trim().toLowerCase();
  if (GOODS_NAME_TO_ID[lowerName]) {
    return `/assets/fp/cards/goods/${GOODS_NAME_TO_ID[lowerName]}.jpg?v=111`;
  }
  const tr = String(c.track || c.category || trackName || "").toLowerCase();
  if (tr.includes("hench") || tr.includes("guard")) return "/assets/fp/cards/goods/grd_1.jpg?v=111";
  if (tr.includes("weapon")) return "/assets/fp/cards/goods/wpn_4.jpg?v=111";
  if (tr.includes("opiate") || tr.includes("wine")) return "/assets/fp/cards/goods/cw_2.jpg?v=111";
  if (tr.includes("upper") || tr.includes("animal")) return "/assets/fp/cards/goods/ea_8.jpg?v=111";
  if (tr.includes("party") || tr.includes("marble")) return "/assets/fp/cards/goods/mrb_12.jpg?v=111";
  return "/assets/fp/cards/goods/grn_1.jpg?v=111";
}

function renderFullGoodCardFaceNode(cardOrItem, trackName = "") {
  const c = cardOrItem || {};
  return el(
    "div",
    { className: "market-good-card-full-wrap" },
    el("img", {
      className: "market-good-card-full-img",
      src: resolveFullGoodCardFaceUrl(c, trackName),
      alt: c.name || trackName || "SF Good",
      loading: "lazy",
    })
  );
}

function resolveFullJobCardFaceUrl(m) {
  if (!m) return "/assets/fp/cards/jobs/mis_1.jpg?v=111";
  if (m.source === "encounter" && m.encounterCard && !m.hasDrawnMissionCard) {
    return resolveFullEncounterCardFaceUrl(m.encounterCard);
  }
  const rawId = String(m.id || "").trim();
  const mJob = rawId.match(/^(mis_\d+)/i);
  if (mJob) {
    return `/assets/fp/cards/jobs/${mJob[1].toLowerCase()}.jpg?v=111`;
  }
  const mEnc = rawId.match(/^enc_((?:pat|leg|nef)_\d+)/i);
  if (mEnc) {
    return `/assets/fp/cards/encounters/${mEnc[1].toLowerCase()}.jpg?v=111`;
  }
  const lowerName = String(m.name || "").trim().toLowerCase();
  if (JOBS_NAME_TO_ID[lowerName]) {
    return `/assets/fp/cards/jobs/${JOBS_NAME_TO_ID[lowerName]}.jpg?v=111`;
  }
  return "/assets/fp/cards/jobs/mis_1.jpg?v=111";
}

function resolveFullInfluenceCardFaceUrl(c) {
  if (!c) return "/assets/fp/cards/influence/inf_1.jpg?v=111";
  const rawId = String(c.id || "").trim();
  const mInf = rawId.match(/^(inf_\d+)/i);
  if (mInf) {
    return `/assets/fp/cards/influence/${mInf[1].toLowerCase()}.jpg?v=111`;
  }
  const lowerName = String(c.name || "").trim().toLowerCase();
  if (INF_NAME_TO_ID[lowerName]) {
    return `/assets/fp/cards/influence/${INF_NAME_TO_ID[lowerName]}.jpg?v=111`;
  }
  return "/assets/fp/cards/influence/inf_1.jpg?v=111";
}

function resolveFullEncounterCardFaceUrl(card, deckKey = "") {
  if (!card) return "/assets/fp/cards/encounters/pat_2.jpg?v=111";
  const rawId = String(card.id || "").trim();
  const mEnc = rawId.match(/^((?:pat|leg|nef)_\d+)/i);
  if (mEnc) {
    return `/assets/fp/cards/encounters/${mEnc[1].toLowerCase()}.jpg?v=111`;
  }
  const lowerName = String(card.name || "").trim().toLowerCase();
  if (ENC_NAME_TO_ID[lowerName]) {
    return `/assets/fp/cards/encounters/${ENC_NAME_TO_ID[lowerName]}.jpg?v=111`;
  }
  const dk = String(deckKey || card.deck || "").toLowerCase();
  if (dk === "cops" || dk === "legionaries") return "/assets/fp/cards/encounters/leg_22.jpg?v=111";
  if (dk === "criminals" || dk === "nefarious") return "/assets/fp/cards/encounters/nef_24.jpg?v=111";
  return "/assets/fp/cards/encounters/pat_2.jpg?v=111";
}

const FACTION_FAVOR_INFLUENCE_SPECS = {
  "DSA Favor": {
    effectText:
      "Receive 6(d), gain 1 DSA Favor (Sapphire), and lose 1 MAGA Favor (Ruby) (can be played after encounter is revealed)",
    gems: ["DSA", "-MAGA"],
  },
  "MS13 Favor": {
    effectText:
      "Receive 6(d), gain 1 MS13 Favor (Amethyst), and lose 1 MAGA Favor (Ruby) (can be played after encounter is revealed)",
    gems: ["MS13", "-MAGA"],
  },
  "ISIS Favor": {
    effectText:
      "Receive 5(d), gain 1 ISIS Favor (Emerald), and lose 1 MAGA Favor (Ruby) (can be played after encounter is revealed)",
    gems: ["ISIS", "-MAGA"],
  },
  "TECH Favor": {
    effectText:
      "Receive 6(d), gain 1 TECH Favor (Diamond), and lose 1 DSA Favor (Sapphire) and 1 MS13 Favor (Amethyst) (can be played after encounter is revealed)",
    gems: ["TECH", "-DSA", "-MS13"],
  },
  "MAGA Favor": {
    effectText:
      "Receive 5(d), gain 1 MAGA Favor (Ruby), and lose 1 ISIS Favor (Emerald) and 1 DSA Favor (Sapphire) (can be played after encounter is revealed)",
    gems: ["MAGA", "-ISIS", "-DSA"],
  },
};

function getInfluenceCardEffectText(c) {
  if (!c) return "";
  const cname = String(c.name || "").trim();
  if (FACTION_FAVOR_INFLUENCE_SPECS[cname]) {
    return FACTION_FAVOR_INFLUENCE_SPECS[cname].effectText;
  }
  if (cname === "Patron") {
    if (c.id === "inf_2") {
      return "Receive 8(d), and lose 1 MAGA Favor (Ruby) and 1 TECH Favor (Diamond)";
    }
    if (c.id === "inf_39") {
      return "Receive 8(d), and lose 1 ISIS Favor (Emerald) and 1 DSA Favor (Sapphire)";
    }
  }
  return String(c.effectText || "");
}

const INFLUENCE_SOCIAL_PLATFORMS = [
  { label: "INSTANTGRAM • SPONSORED POST", art: "/assets/fp/influence_art/art_instantgram.jpg?v=35", cls: "face-social-ig" },
  { label: "CLOCKTOK • VIRAL FOR YOU", art: "/assets/fp/influence_art/art_clocktok.jpg?v=35", cls: "face-social-tiktok" },
  { label: "YOUTOOB • TRENDING CLIP", art: "/assets/fp/influence_art/art_youtoob.jpg?v=35", cls: "face-social-yt" },
  { label: "FACESPACE • BOOSTED FEED", art: "/assets/fp/influence_art/art_facespace.jpg?v=35", cls: "face-social-fb" },
  { label: "LINKEDOUT • THOUGHT LEADER", art: "/assets/fp/influence_art/art_linkedout.jpg?v=35", cls: "face-social-li" },
];

function formatReactionCondition(cond) {
  const s = String(cond || "").trim();
  return s
    .replace("-1..0", "-1 to 0")
    .replace("0..1", "0-1")
    .replace("<=", "≤ ")
    .replace(">=", "≥ ")
    .replace(/\s+/g, " ");
}

function formatReactionTypeSymbol(rOrType) {
  if (!rOrType) return "!";
  const t = typeof rOrType === "object" ? String(rOrType.type || rOrType.effect || "") : String(rOrType);
  if (t === "combat" && typeof rOrType === "object" && rOrType.ifCarrying) {
    return `${sfReskinText(String(rOrType.ifCarrying))} (COMBAT_ICON)`;
  }
  if (t === "combat") return "(COMBAT_ICON)";
  if (t === "no_contraband") return "✓";
  if (t === "demand_strict") return "!!";
  if (t === "mission_strict") return "(QUEST_ICON)!!";
  if (t === "mission_request") return "(QUEST_ICON)!";
  if (t === "mission_offer" || t === "mission_bonus") return "(QUEST_ICON)?";
  if (t === "deck_quest_strict") return "(DECK_ICON)(QUEST_ICON)!!";
  if (t === "deck_quest_demand") return "(DECK_ICON)(QUEST_ICON)!";
  if (t === "deck_quest_offer") return "(DECK_ICON)(QUEST_ICON)?";
  if (t === "demand") return "!";
  if (t === "offer" || t === "quest_optional") return "?";
  if (t === "payoff") return "💰(d)";
  if (t === "cash_reward") {
    return typeof rOrType === "object" && rOrType.reward ? String(rOrType.reward) : "(d)";
  }
  return t;
}

function formatHostileFavorPenaltyText(cardOrMission) {
  const raw =
    Array.isArray(cardOrMission?.hostileFavor) && cardOrMission.hostileFavor.length > 0
      ? cardOrMission.hostileFavor
      : cardOrMission?.faction
        ? [`-${cardOrMission.faction}`]
        : [];
  if (raw.length === 0) return "No Favor Penalty";
  const counts = {};
  for (const entry of raw) {
    const s = String(entry || "").trim();
    if (!s) continue;
    const isNeg = s.startsWith("-");
    const fac = isNeg ? s.slice(1) : s.replace(/^\+/, "");
    if (!fac) continue;
    counts[fac] = (counts[fac] || 0) + (isNeg ? -1 : 1);
  }
  const parts = Object.entries(counts)
    .filter(([, delta]) => delta !== 0)
    .map(([fac, delta]) => `${delta > 0 ? `+${delta}` : delta} ${fac} Favor`);
  return parts.length > 0 ? parts.join(" and ") : "No Favor Penalty";
}

const ENCOUNTER_FACE_ARCHETYPES = {
  cops: [
    { cls: "face-police-id", label: "SFPD • OFFICIAL CREDENTIAL" },
    { cls: "face-news-chronicle", label: "THE SF CHRONICLER" },
    { cls: "face-news-standard", label: "THE SF STANDPOINT" },
    { cls: "face-news-calpost", label: "CALIFORNIAC POST" },
    { cls: "face-news-examiner", label: "THE SF INQUIRER" },
    { cls: "face-social-fb", label: "SFPD • FACESPACE PAGE" },
    { cls: "face-social-ig", label: "SFPD • INSTANTGRAM" },
  ],
  celebrities: [
    { cls: "face-wikibio", label: "WIKIBIO • ENCYCLOPEDIA" },
    { cls: "face-news-nyt", label: "THE NEW YORK CHIMES" },
    { cls: "face-news-wapo", label: "THE WASHINGTON ROAST" },
    { cls: "face-news-wsj", label: "STALL STREET JOURNAL" },
    { cls: "face-social-li", label: "LINKEDOUT • EXECUTIVE BIO" },
    { cls: "face-social-yt", label: "YOUTOOB • CHANNEL" },
    { cls: "face-social-fb", label: "FACESPACE • PROFILE" },
    { cls: "face-social-ig", label: "INSTANTGRAM • VERIFIED" },
  ],
  criminals: [
    { cls: "face-snapchat", label: "SNATCHTAP • PROFILE" },
    { cls: "face-pay-venmo", label: "VENDMO • P2P PROFILE" },
    { cls: "face-pay-cashnet", label: "$CASHNET • P2P ESCROW" },
    { cls: "face-pay-square", label: "CUBEPAY • MERCHANT" },
    { cls: "face-pay-paypal", label: "PAYPALS • TRANSFER" },
    { cls: "face-craigslist", label: "GREG'S LIST • SFBAY > GIGS" },
    { cls: "face-social-ig", label: "INSTANTGRAM • BURNER" },
    { cls: "face-social-tiktok", label: "CLOCKTOK • CREATOR" },
    { cls: "face-social-onlyfans", label: "ONLYSTANS • VIP PROFILE" },
  ],
};

function getEncounterCardFaceArchetype(card, deckKey) {
  const list = ENCOUNTER_FACE_ARCHETYPES[deckKey] || ENCOUNTER_FACE_ARCHETYPES.celebrities;
  const rawId = String((card && (card.id || card.name)) || "0");
  let hash = 0;
  for (let i = 0; i < rawId.length; i += 1) {
    hash = (hash * 31 + rawId.charCodeAt(i)) >>> 0;
  }
  return list[hash % list.length];
}

function showToast(message, isError = false) {
  const root = document.getElementById("toast-root");
  if (!root) return;
  root.className = "toast-container";
  const item = el("div", { className: `toast ${isError ? "error" : ""}`, text: message });
  root.appendChild(item);
  setTimeout(() => {
    item.remove();
  }, 4200);
}

function closeModal() {
  const root = document.getElementById("modal-root");
  if (root) root.replaceChildren();
}

function showModal(titleText, bodyNode, options = {}) {
  const root = document.getElementById("modal-root");
  if (!root) return;
  const backdrop = el(
    "div",
    {
      className: "modal-backdrop",
      onClick: (e) => {
        if (e.target === backdrop) closeModal();
      },
    },
    el(
      "div",
      { className: options && options.wide ? "modal-box modal-box-wide" : "modal-box" },
      el(
        "div",
        { className: "panel-title" },
        el("span", { text: titleText }),
        el("button", {
          id: "modal-close-btn",
          type: "button",
          className: "btn btn-sm",
          title: "Close window",
          text: "Close ✕",
          onClick: closeModal,
        })
      ),
      bodyNode
    )
  );
  root.replaceChildren(backdrop);
}

const NUMPAD_CODE_TO_DIR = {
  Numpad7: "NW",
  Numpad8: "N",
  Numpad9: "NE",
  Numpad4: "W",
  Numpad6: "E",
  Numpad1: "SW",
  Numpad2: "S",
  Numpad3: "SE",
};

const NUMPAD_DIGIT_TO_DIR = {
  "7": "NW",
  "8": "N",
  "9": "NE",
  "4": "W",
  "6": "E",
  "1": "SW",
  "2": "S",
  "3": "SE",
};

export { getNightMerchantRuntimeConfig, getNightMerchantApiBaseUrl, resolveAssetUrl, maskEmailClient, getStoredSessionToken, setStoredSessionToken, _fbAuthModule, _fbAuthInstance, _fbInitPromise, getEffectiveFirebaseConfig, isFirebaseClientConfigured, initFirebaseClientIfConfigured, getFirebaseIdToken, signInWithFirebaseCustomToken, signInWithFirebaseEmailPassword, signInWithFirebaseGooglePopup, signOutFirebaseClient, COLS, ROWS, TRACK_NAMES, COL_SYMBOLS, MARKET_COLUMNS_META, ROME_LANDMARKS, FACTION_META, DEFAULT_POLITICAL_CLIMATE_FACTORS, DEFAULT_POLITICAL_CLIMATE_OPTIONS, hasActiveClimateOption, EDGE_LABELS, parseTollAmount, formatEdgeLabel, WEST_BANK_CELLS, TIBER_BRIDGES, getTiberBridgeName, isTiberCrossingBlocked, DIR_DELTAS_8, getNeighborCoordInDir, SUV_COLOR_PALETTE, DIE_SYMBOL_COLORS, DIE_SWATCH_COLORS, getSUVColorLabel, getPlayerHexColor, renderSUVIconNode, renderGoogleLogoSvg, ROME_DIE_ROMAN_FACES, appState, DENARIUS_SYM, BTC_SYM, formatBtc, replaceDenariiTokens, GAME_TOKEN_REGEX, createDenariusSvgNode, createSellPriceSymbolNode, createBuyPriceSymbolNode, createCombatInlineIconNode, createDeckOfCardsIconNode, createAncientRomanChestIconNode, createMoveActionCircleNode, createTransactionActionCircleNode, SF_RESKIN_RULES, sfReskinText, appendTextWithRomeDice, resolveGoodTrackClass, el, TILE_MODIFIER_MAP, formatTileModifier, getTileModifierClass, resolveGoodCardArtUrl, GOODS_NAME_TO_ID, JOBS_NAME_TO_ID, INF_NAME_TO_ID, ENC_NAME_TO_ID, resolveFullGoodCardFaceUrl, renderFullGoodCardFaceNode, resolveFullJobCardFaceUrl, resolveFullInfluenceCardFaceUrl, resolveFullEncounterCardFaceUrl, FACTION_FAVOR_INFLUENCE_SPECS, getInfluenceCardEffectText, INFLUENCE_SOCIAL_PLATFORMS, formatReactionCondition, formatReactionTypeSymbol, formatHostileFavorPenaltyText, ENCOUNTER_FACE_ARCHETYPES, getEncounterCardFaceArchetype, showToast, closeModal, showModal, NUMPAD_CODE_TO_DIR, NUMPAD_DIGIT_TO_DIR };
