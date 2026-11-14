import { appState, createDenariusSvgNode, createSellPriceSymbolNode, createBuyPriceSymbolNode, createDeckOfCardsIconNode, createAncientRomanChestIconNode, createMoveActionCircleNode, createTransactionActionCircleNode, appendTextWithRomeDice, el } from "./core_ui.js?v=112";
import { renderApp } from "./app.js?v=112";

const RULEBOOK_SECTIONS = [
  {
    id: "overview",
    title: "1. Overview & San Francisco Night Setting",
    paragraphs: [
      "Welcome to Night Merchant: InstantGram SF! Five ideological factions—MAGA, ISIS, TECH Bros, the DSA, and MS-13—battle for control of San Francisco's streets and social feeds after dark. By day, 2 to 6 dealers stock up on contraband and hire Henchmen out of an open suitcase at the Safe House Motel. At 8:00 P.M., the five highway and bridge entry points into San Francisco open for business.",
      "Across 3 Nights (Thursday, Friday, and Saturday), dealers load up their SUVs by day, then navigate 36 nocturnal neighborhoods of San Francisco (A1–F6) across 10 hourly turns (8:00 P.M. to 5:00 A.M.) before the 6:00 A.M. Sunrise Curfew. After Saturday Clean-Up, the Sunday Reckoning settles unfinished Jobs, remaining SUV inventory, loans, and Ballot Initiatives—crowning the wealthiest dealer in Bitcoin (₿)!",
    ],
    bullets: [
      "Game Boards: The Safe House Suitcase Market Board (6 tracks: Party, Opiates, Uppers, Weapons, Weed, and Henchmen × 6 scarcity bays), the 6×3 Ballot Initiatives Board, and the San Francisco Night City Board (6×6 grid A1–F6, 36 neighborhoods including the Presidio at A1, Chinatown at D2, Civic Center at C3, Tenderloin at D3, Mission at D4, and Bayview at E6, plus 5 Highway/Bridge Entrances and 3 Wholesale Spots).",
      "Neighborhood Tiles: 432 square tiles (12 per neighborhood across 36 stacks) featuring open streets, roadblocks, ₿0.2 road tolls, street encounters, Dice Game gambling, and neighborhood buyers.",
      "Decks & Mats: Market Cards, Job Cards (Starting & Encounter Jobs), Social Media Influence Cards, Celebrities / Cops / Criminals Encounter Decks, Dealer SUV Mats (6■ Cargo Blocks in 2×3 grid, 2▲ Henchman Slots in 2×1 column, 5 Uncapped Faction Favor tracks), and 6-sided Custom Action Dice (0, 0, 1, 1, 2, 3).",
    ],
  },
  {
    id: "factions",
    title: "2. The Five Factions of San Francisco (Uncapped Favor)",
    paragraphs: [
      "Five factions fight over the city after dark. Favor gems you earn or lose from Jobs, Encounters, and Influence cards are UNCAPPED (they can reach ±5 or more). Your favor decides whether a faction's people treat you as a Friendly ally or a Hostile target, and it powers the Ballot Initiatives you draft:",
    ],
    iconGrid: [
      { img: "./assets/icons/ruby.png", title: "Ruby — MAGA", desc: "Huge among the Cops. With Back the Blue enacted, Cops gain +2 CP and each +Ruby gives your SUV +1 CP." },
      { img: "./assets/icons/emerald.png", title: "Emerald — ISIS", desc: "Poor, violent, and rare. With Sanctuary City enacted, every player starts with a free Emerald." },
      { img: "./assets/icons/diamond.png", title: "Diamond — Tech Bros", desc: "Rich, vulnerable, and influential. With Lobbying Blitz enacted, +Diamonds trade 1-for-1 into +Rubies or +Sapphires." },
      { img: "./assets/icons/sapphire.png", title: "Sapphire — DSA", desc: "Strongest among the Celebrities. With Rent Control enacted, spend +Sapphires to raise a sale's scarcity by 1 step per gem." },
      { img: "./assets/icons/amethyst.png", title: "Amethyst — MS-13", desc: "Lives among the Criminals. Always attacks at -1 favor or lower, and always fights hard." },
      {
        imgs: ["./assets/icons/thumb_up.png", "./assets/icons/thumbs.png", "./assets/icons/thumb_down.png"],
        title: "Friendly / Neutral / Hostile",
        desc: "Thumbs Up (Friendly, positive net Favor), Neutral (0 Favor), and Thumbs Down (Hostile, negative net Favor) decide how NPCs react.",
      },
    ],
    table: {
      headers: ["Faction & Gem", "Where They Show Up", "Alignments"],
      rows: [
        ["MAGA (Ruby)", "Huge in Cops; few in Criminals and Celebrities", "Aligned with TECH. Primarily against MS-13 and hugely against the DSA. On-and-off with ISIS."],
        ["ISIS (Emerald)", "The rarest faction. Mostly Criminals, then Celebrities, then Cops", "Hates every faction except MS-13."],
        ["TECH (Diamond)", "Equally among Celebrities, Criminals, and Cops", "Somewhat aligned with the DSA and MAGA, somewhat averse to ISIS, indifferent to MS-13."],
        ["DSA (Sapphire)", "Most among Celebrities; some Criminals; very few Cops (the Firefighters)", "Primarily averse to MAGA, sort of averse to TECH, aligned with ISIS and MS-13."],
        ["MS-13 (Amethyst)", "Mostly Criminals; rarely Celebrities or Cops", "The most indifferent faction. Somewhat opposed to MAGA, a little averse to TECH, slightly aligned with the DSA and ISIS."],
      ],
    },
    bullets: [],
  },
  {
    id: "setup",
    title: "3. Game Setup, Initial Discard, & Ballot Initiatives Draft",
    bullets: [
      "Starting Wallet & Market: Each dealer begins Thursday with ₿1.2 and 0 Favor across all five factions. 24 Goods/Henchmen are dealt onto the Safe House Market Board and left-aligned toward Precious (<<).",
      "Initial Hand & Speed Discard: Each dealer is dealt 5 distinct Starting Jobs and 5 distinct Influence cards, then discards 2 Jobs and 2 Influence cards (keeping 3 of each).",
      "Ballot Initiatives Draft (6×3 Board): The FIRST dealer to finish discarding claims First Pick on the 6-column Ballot Initiatives Board (MAGA, ISIS, TECH, DSA, MS13, Jobs — at most 1 Initiative may be enacted per column).",
      "2-Player vs. 3+ Player Draft: In a 2-player game, 4 modifiers are enacted via snake draft (First Discarder → Rival → Rival → First Discarder — first pick and last pick!). In 3–6 player games, each dealer enacts 1 modifier in discard-completion order (up to all 6 columns).",
      "Normal Game Turn Order & 5th/6th Player Stipend: Once the Ballot Initiatives are set, the First Player Token goes to the dealer seated AFTER the First Discarder—so the dealer who claimed First Pick on the Ballot Initiatives acts LAST in normal turn order! In 5–6 player games, to offset late Thursday Market position, the 5th dealer in Thursday turn order receives +₿0.1 (starting at ₿1.3) and the 6th dealer receives +₿0.2 (starting at ₿1.4).",
    ],
  },
  {
    id: "market",
    title: "4. Phase I: The Safe House Market Phase & Goods Card Symbols",
    paragraphs: [
      "Before nightfall at the Safe House Motel, dealers take turns in turn order performing 1 Market Action per turn until all dealers pass consecutively. Every Good and Henchman card features a 5-column Price Board (from << Precious to >> Abundant) and compact symbols:",
    ],
    iconGrid: [
      {
        symbolType: "sell_sym",
        title: "Bold Green +₿ Retail (Sell / Fence Row)",
        desc: "The top price row on a Good Card. Shows the Bitcoin you RECEIVE when selling that Good in San Francisco (or Fencing Encounter Job Cargo) at each Scarcity column (<< to >>).",
      },
      {
        symbolType: "buy_sym",
        title: "Italic Red -₿ Wholesale (Buy / Hire Row)",
        desc: "The bottom price row on a Good or Henchman Card. Shows the Bitcoin you PAY to buy that Good at the Safe House Market (or a Wholesale Spot) or to hire/retain a Henchman.",
      },
      {
        symbolType: "denarius",
        title: "Bitcoin (₿)",
        desc: "Crypto currency used for all Market purchases, street sales, road tolls, Dice Game wagers, Henchman upkeep, and final victory scoring.",
      },
      {
        badgeText: "<<  <  =  >  >>",
        title: "5 Scarcity Columns",
        desc: "From left to right: << Precious (0 cards left on track), < Rare (1 card), = Uncommon (2–3 cards), > Common (4 cards), and >> Abundant (5–6 cards).",
      },
      {
        badgeText: "■  ■■  ■■■",
        badgeClass: "rulebook-badge-cargo",
        title: "SUV Space Cubes (■)",
        desc: "Squares showing how many of your SUV Mat's 6 Cargo slots (6■) a Good occupies (1■, 2■, or 3■). Bulkier Goods yield higher profit margins.",
      },
      {
        badgeText: "▲  ▲▲",
        badgeClass: "rulebook-badge-guard",
        title: "Henchman Seat Triangles (▲)",
        desc: "Triangles showing how many of your SUV Mat's 2 Henchman seats (2▲) a hired Henchman occupies (1▲ or 2▲).",
      },
    ],
    bullets: [
      "Buy a Good or Hire a Henchman: Pay the card's italic Red (BUY_SYM) Buy/Hire price for its current column (<<, <, =, >, >>). Goods occupy ■ blocks on your SUV Mat (max 6■); Henchmen occupy ▲ slots (max 2▲). A replacement card is drawn onto the leftmost column of its category.",
      "Source a Good (Discard 1 Influence): Discard 1 Influence card to select a Good from the deck onto the leftmost column of its track (sliding existing cards right).",
      "Pass: Step out of the Market Round. Once a full round passes with no Market purchases, pass the First Player Token clockwise and enter San Francisco at 8:00 P.M.",
    ],
    table: {
      headers: ["Cards Remaining on Track", "Scarcity Symbol", "Market Supply State", "Base SF Selling Column ((SELL_SYM))"],
      rows: [
        ["0 Cards", "<<", "Precious (Depleted)", "Sells at << (highest (SELL_SYM) column) by default."],
        ["1 Card", "<", "Rare (Low Supply)", "Sells at < by default (+ shifts to <<)."],
        ["2–3 Cards", "=", "Uncommon (Balanced)", "Sells at = by default."],
        ["4 Cards", ">", "Common (High Supply)", "Sells at > by default."],
        ["5–6 Cards", ">>", "Abundant (Flooded)", "Sells at >> (lowest (SELL_SYM) column) by default."],
      ],
    },
  },
  {
    id: "delivery",
    title: "5. Phase II: Night Delivery in San Francisco & Tile Icons",
    paragraphs: [
      "At 8:00 P.M. (Turn 1), each dealer may take 1 Initial Scout (tile or deck card) and then enters San Francisco through one of the 5 road entry points: B1 (Golden Gate Bridge), F1 (Bay Bridge), F5 (US-101), D6 (I-280), or A5 (Route 1). Entering uses your Turn 1 movement. Leaving is different: the Pacific (west) edge has almost no way out except rare, expensive Speedboats; the Bay (north and east) edges offer cheaper boat escapes (Sailboat 1(d), Ferry 2(d), Cargo Ship 3(d)); and the Peninsula (south) edge has the most exits, usually free.",
      "Across Turns 1–10 (8:00 P.M. to 5:00 A.M.), each active dealer resolves their hourly turn in strict sequence:",
    ],
    iconGrid: [
      {
        symbolType: "move_sym",
        title: "Move Action Circle (M)",
        desc: "Represents 1 SUV Movement action along an open green street edge (or granted as a bonus Move by Influence cards).",
      },
      {
        symbolType: "tx_sym",
        title: "Transaction Action Circle (T)",
        desc: "Represents 1 hourly Transaction: Sell 1 Good (or Bulk-Sell all Weed!), Buy 1 Good at a Wholesale Spot, or Gamble at a Dice Game.",
      },
      {
        badgeText: "++  +  =  -  --",
        title: "Tile Buyer & Wholesale Modifiers",
        desc: "Shifts a Good's current Safe House Scarcity column 1 or 2 steps toward << Precious (+ / ++) or >> Abundant (- / --) when buying or selling on that tile.",
      },
      {
        img: "./assets/icons/persist.png",
        title: "Persistent Tile Icon",
        desc: "Landmarks marked with the Persistent icon stay face-up on the SF board between Nights instead of returning to their stack at Dawn.",
      },
      {
        img: "./assets/icons/refresh.png",
        title: "Refresh Tile Icon",
        desc: "Volatile streets marked with the Refresh icon discard after their encounter resolves, immediately revealing the next tile beneath.",
      },
      {
        img: "./assets/icons/sf_logo_icon.png?v=112",
        title: "Wholesale Spot / First Player",
        desc: "Marks San Francisco's 3 central Wholesale Spots (C3 Civic Center, D3 Tenderloin, D4 Mission) where Goods are sold to dealers, as well as the First Player emblem.",
      },
    ],
    bullets: [
      "Step 1 — Optional Trash: Discard 1 Influence card to bury the top unexposed tile of any neighborhood or the top card of any deck to the bottom.",
      "Step 2 — Movement (1 Step (M)): Move along a passable outgoing edge to an adjacent neighborhood (revealing its top tile if face-down) or out an exterior perimeter edge to Exit San Francisco.",
      "Step 3 — Edge Cost / Hazard: Pay any 2(d) road toll or resolve any Edge Encounter crossed.",
      "Step 4 — Job Cargo Pickup & Delivery: Upon arriving in a neighborhood—BEFORE any Center Tile Encounter triggers—you may load or deliver matching Job Cargo!",
      "Step 5 — Center Tile Encounter: Resolve any Center Encounter on the tile (Celebrities, Cops, Criminals, Protesters, Open Mic, or Schizophrenic).",
      "Step 6 — One Transaction (1 Good/Hr (T), or Bulk Weed!): Sell AT MOST 1 Good card matching a buyer ('Buys:') on your current tile (or an active Sell Job here) at its bold Green (SELL_SYM) price—EXCEPT for non-fenced WEED, where 1 hourly Transaction may sell ANY NUMBER (or all!) of your Weed cards together at the current Weed scarcity modifier! Alternatively, Purchase 1 Good at a Wholesale Spot ('Sells:' at C3, D3, or D4) at its italic Red (BUY_SYM) price, OR Gamble once at a Dice Game tile (up to 20(d) wager).",
      "Step 7 — End-of-Turn Scout: After completing your Move and Transaction actions, you may Scout one time at the end of your turn by peeking at the top unrevealed tile of any neighborhood stack or the top card of any deck. Committing to your Scout action immediately advances the turn so the next dealer in sequence can begin their turn while you finish examining the scouted tile or card.",
    ],
  },
  {
    id: "missions",
    title: "6. Jobs (Max 5 Active), Job Cargo, & High-Value Targets",
    bullets: [
      "5-Active-Job Limit: A dealer can hold at most 5 active Jobs at a time. If an NPC threatens you with a Job (!!) while you already hold 5 Jobs, you must choose one of your active Jobs to fail (taking that failed Job's favor penalty) to make room for the new Job—or else face the NPC in Combat!",
      "Starting Jobs: Kept during Setup (3 per dealer). Can be canceled voluntarily without Favor penalty (unless Surge Pricing is active, which fines -10(d) on any failed/canceled/unfinished job!). Starting Job Cargo can NEVER be sold or fenced.",
      "Encounter Jobs: Drawn from NPC encounters or assigned directly by an NPC. Encounter Job Cargo displays a bold Green (SELL_SYM) Fence price row—fencing it to a matching buyer sells 1 card for quick Bitcoin, applies Patron Hostile Favor, and FAILS the job (unless Clique Fence is active, which boosts Fence Scarcity by +1 step and prevents fencing from counting as a Failed Job!).",
      "Schizophrenic Jobs: Mandatory side-quests with 1(R) face-down Influence cards sealed underneath until completed. Cannot be voluntarily canceled unless holding 6 Schizophrenic Jobs simultaneously.",
      "Most Wanted & Cancel Culture ('Any Player' Clauses): Two high-stakes Encounter Jobs—Most Wanted (defeating Donald Trump in combat) and Cancel Culture (defeating Osama bin Laden in combat)—trigger if ANY Player defeats that target in combat while you hold the Job! Completing Most Wanted immediately ends the game in an instant victory for the holder; completing Cancel Culture awards 100(d) and +2 Rubies (+1 Diamond) while continuing the weekend.",
    ],
  },
  {
    id: "combat",
    title: "7. Encounters, Combat, Charts, & Street Dice Gambling",
    paragraphs: [
      "As your SUV rolls through San Francisco's nocturnal streets and alleys, tile edges and centers trigger encounters with the city's three major NPC decks, street hazards, and dice games:",
    ],
    iconGrid: [
      {
        img: "./assets/icons/celebrities_icon.png?v=112",
        title: "Celebrities Encounter (Always 1×)",
        desc: "Tech founders, politicians, and influencers (gold hoodie icon). Always singular (X=1). Friendly Celebrities offer lucrative Jobs or trade deals; Hostile Celebrities make demands.",
      },
      {
        img: "./assets/icons/cops_icon.png?v=112",
        title: "Cops Encounter (1–4× Icons)",
        desc: "SFPD, DEA, CHP, and federal agents (cobalt blue police hat icon). Has 1–4 icons on the tile/edge, setting X for the card's combat formula. Heavily aligned with MAGA.",
      },
      {
        img: "./assets/icons/criminals_icon.png?v=112",
        title: "Criminals Encounter (1–4× Icons)",
        desc: "Stick-up crews, cartel enforcers, and street gangs (white A-shirt icon). Has 1–4 icons on the tile/edge, setting X for the card's combat formula.",
      },
      {
        img: "./assets/icons/angry_mob.png?v=112",
        title: "Protesters (1R Chart)",
        desc: "Orange megaphone icon. Roll 1(R): 0 = Lose all Opiates; 1 = Lose all Weed; 2 = Lose your most expensive Good; 3 = Escape unharmed.",
      },
      {
        img: "./assets/icons/theater_masks.png?v=112",
        title: "Open Mic (1R Chart)",
        desc: "Dark gray microphone icon. Roll 1(R): 0 = Lose all positive Favor; 1 = Lose all negative Favor; 2 = Lose rest of turn & next turn; 3 = Draw 1(R) Influence.",
      },
      {
        img: "./assets/icons/schizophrenic_icon.png?v=112",
        title: "Schizophrenic Encounter",
        desc: "Purple silhouette icon. Draws a mandatory Schizophrenic Job and seals 1(R) face-down Influence cards beneath it until you finish the Job.",
      },
      {
        img: "./assets/icons/combat.png",
        title: "Combat & Combat Power (CP)",
        desc: "Pistol icon marks street combat and hostile Combat tiers on Encounter cards. Compare total Player CP vs. Opponent CP.",
      },
      {
        symbolType: "enc_deck_quest",
        title: "Job Deck & Bespoke Job Icons",
        desc: "Mid-card Encounter tier icons: Laptop + Cash Stack ((DECK_ICON)(QUEST_ICON)! / !! / ?) draws an unseen Job card from the deck; Cash Stack alone ((QUEST_ICON)! / !! / ?) assigns the card's printed Job.",
      },
      {
        symbolType: "rome_die",
        title: "Rome Die (R)",
        desc: "6-sided custom die with faces 0, 0, 1, 1, 2, 3 (mean roll = 1.0). Rolled for Combat, Charts, and Dice Game wagers.",
      },
      {
        imgs: ["./assets/icons/dice.png", "./assets/icons/chest.png"],
        title: "Street Dice Wager & Loot",
        desc: "Dice icon lets you spend your Transaction to wager 1–20(d) (win Wager × 1(R) roll). Cash icon marks special cargo/bounty rewards.",
      },
    ],
    bullets: [
      "Friendly vs. Hostile Encounters & Reputation Tiers: Determined by your uncapped net Favor with the NPC's Faction. There are three interaction tiers: !! means comply or fight; ! means comply or accept hostile encounter consequences with no fight; and ? means comply or decline with no penalty for rejecting the offer (if you accept a ? Job and later fail or abandon that Job, you suffer the encounter's hostile Favor consequences).",
      "Combat Power (CP) & Cargo Gear: Both sides roll Action Dice (R) plus Henchmen, Weapons, mandatory Uppers (stimulants in your SUV always add/roll their CP in combat!), and Influence modifiers (plus +1 CP per positive Ruby & +2 CP to Cops if Back the Blue is active). Note that Body Armor carries 0 CP in street ambushes (it absorbs wounds instead). If Player CP ≥ Opponent CP against an NPC, you win!",
      "Armor, Henchmen, & Dealer Fate (Damage Deficit Note): If Opponent CP > Player CP, suffer Raw Wounds = (Opponent CP − Player CP). Body Armor/Shields reduce Wounds first; each remaining Wound kills 1 Henchman. If an unblocked Wound reaches you, roll 1(R) on the Dealer Fate Chart: 0 = Wasted (lose all Goods & your night ends); 1 = Left for dead (lose all Goods); 2 = Jumped & robbed (lose all Bitcoin); 3 = Begged for mercy (lose all Influence cards).",
      "1(R) Street Charts: Protesters (0: lose all Opiates; 1: lose all Weed; 2: lose most expensive Good; 3: safe), Open Mic (0: undo all Positive-outcome gem changes; 1: undo all Hostile-outcome gem changes; 2: lose rest of turn & next turn; 3: draw 1(R) Influence), Schizophrenic (take mandatory Job + seal 1(R) Influence cards).",
      "Street Dice Gambling: On a tile with the Dice icon, wager 1(d) to 20(d) (capped at 20(d) per gamble action) and roll 1(R) to win Wager × Roll!",
    ],
  },
  {
    id: "cleanup",
    title: "8. Phase III: Dawn Clean-Up, Curfew Fines, & Loans",
    bullets: [
      "6:00 A.M. Dawn Curfew Fine: Any dealer still inside San Francisco after Turn 10 (5:00 A.M.) pays a nightly curfew fine—Thursday 12(d), Friday 20(d), Saturday 32(d)—halved to 6(d) / 10(d) / 16(d) if standing on one of the 5 Entry Point tiles (B1, F1, F5, D6, A5)!",
      "Tile Cleanup: Persistent tiles (⤹) stay face-up for future nights; Refresh tiles (↻) discard after encounters; ordinary revealed tiles return to the bottom of their stacks at Dawn.",
      "Buy Influence Cards: Cost scales by your current Influence hand size (including face-down Schizophrenic cards): 0–1 cards = 2(d), 2–3 cards = 4(d), 4 cards = 6(d), 5+ cards = 8(d).",
      "Loans: Thursday Loan grants +20(d) (repay 30(d) at end of Friday, or 45(d) at end of Saturday / Sunday Reckoning). Friday Loan grants +40(d) (repay 60(d) at end of Saturday / Sunday Reckoning).",
      "Henchmen Salaries & Sunday Tie-Breaker Policy: Pay each retained Henchman's current Market hiring cost (or release them to the bottom of the Market deck). During Saturday Clean-Up, you may also toggle whether your crew is authorized to expend Combat Influence cards during Sunday Reckoning PvP tie-breakers.",
    ],
  },
  {
    id: "winter",
    title: "9. Sunday Reckoning & The 6×3 Ballot Initiatives Matrix",
    paragraphs: [
      "Unless a dealer achieves instant victory via Most Wanted earlier in the weekend, the game concludes after Saturday Clean-Up with the Sunday Reckoning, governed by the Ballot Initiatives drafted during Setup:",
    ],
    bullets: [
      "Step 1 — Unfinished Jobs Fail: Incomplete Jobs fail first (applying Encounter Hostile Favor and -10(d) each if Surge Pricing is active); remaining job cargo is discarded.",
      "Step 2 — SUV Liquidation & Loans: Remaining non-job Goods liquidate at Abundant (>>) (SELL_SYM) Sell Price, then unpaid Thursday (-45(d)) and Friday (-60(d)) Loans are deducted.",
      "Step 3 — Mass Deportation FIRST, Then Ballot Initiative Settlement: If Mass Deportation (MAGA Option 1) is enacted, it resolves FIRST—eliminating the dealer with Least MAGA Favor BEFORE any other Most/Least awards, penalties, steals, or percentages! Eliminated dealers cannot win or suffer subsequent Most/Least awards and rank below all survivors. Then resolve Flat Gem/Job Modifiers & Least Penalties → Billionaire Tax Steal → TECH +20% Wealth.",
      "Step 4 — PvP Combat Tie-Breakers (Strictly One Winner/Loser!): Every 'Most' and 'Least' modifier—as well as Final Score ties—awards its bonus or penalty to STRICTLY ONE dealer, even if tied at 0! Tied dealers fight PvP Combat: pre-roll cards (Drive-By, Distraction removing 1 positive die) apply before rolling, all dice roll simultaneously, and reactive post-roll cards (Plot Twist, Pepper Spray, Bodyguard's Intervention) trigger when they can overturn a deficit. For 'Most' awards, the combat winner claims the prize; for 'Least' penalties/elimination, the combat winner escapes and the combat LOSER suffers the penalty!",
    ],
    table: {
      headers: ["MAGA", "ISIS", "TECH", "DSA", "MS13", "Jobs"],
      rows: [
        [
          "Mass Deportation: End of game (FIRST): Least MAGA favor is eliminated.",
          "Fatwa: End of game: Least ISIS favor loses 25(d).",
          "Series A: End of game: Most TECH favor gains +20% wealth.",
          "Billionaire Tax: End of game: Most DSA favor steals 15(d) from the wealthiest rival.",
          "Protection Racket: End of game: Most MS13 favor gains 25(d).",
          "Five-Star Courier: End of game: Most net completed Jobs (completed minus failed) gains 30(d).",
        ],
        [
          "Recall Election: End of game: Lose 10(d) per +Ruby; gain 5(d) per -Ruby.",
          "Jihad: End of game: +15(d) per +Emerald if MAGA ≤ 0, or -10(d) if ≥ +1; -5(d) per -Emerald.",
          "Conflict of Interest: End of game: Lose 15(d) per +Diamond and 15(d) per -Diamond.",
          "Mutual Aid: End of game: Gain 10(d) per net completed Job with +Sapphire or a DSA patron.",
          "Plata o Plomo: End of game: Gain 10(d) per +Amethyst and 10(d) per -Amethyst.",
          "Full Time Employee: End of game: receive A × B Bitcoin (A = your gems of one faction, B = net positive jobs completed for that faction).",
        ],
        [
          "Back the Blue: Cops gain +2 CP. Each +Ruby gives your SUV +1 CP.",
          "Sanctuary City: When enacted, every player gains a free Emerald (+1 ISIS).",
          "Lobbying Blitz: Exchange +Diamonds 1-for-1 into +Rubies or +Sapphires anytime.",
          "Rent Control: Spend +Sapphires when selling Goods (including Bulk Weed) for +1 Scarcity step per gem.",
          "Clique Fence: Fenced cargo sells +1 Scarcity step higher and does not fail the Job.",
          "Surge Pricing: Completed Jobs pay 2× Bitcoin; failed or unfinished Jobs fine 10(d).",
        ],
      ],
    },
  },
  {
    id: "symbols",
    title: "10. Complete Symbol Key & Strategy Overlays",
    paragraphs: [
      "Use this quick-reference table to decode every symbol on Goods Cards, Encounter Cards, SUV Mats, and San Francisco Neighborhood Tiles (keyboard shortcuts can be viewed and customized on your Profile page):",
    ],
    table: {
      headers: ["Feature / Symbol", "Where Shown", "Meaning"],
      rows: [
        [
          "(SELL_SYM) (Bold Green +₿)",
          "Goods Cards & Job Cargo",
          "Sell Price Row (or Fence Price Row on Encounter Job Cargo) — the Bitcoin you earn when selling that Good at each scarcity level (<< to >>).",
        ],
        [
          "(BUY_SYM) (Italic Red -₿)",
          "Goods & Henchmen Cards",
          "Buy / Hire Price Row — the Bitcoin you pay to purchase that Good at the Safe House Market / Wholesale Spots or to hire/retain a Henchman.",
        ],
        [
          "(d) Bitcoin Symbol",
          "Wallet, Cards, & Tiles",
          "Bitcoin (₿) — the currency of Night Merchant: InstantGram SF.",
        ],
        [
          "<<  <  =  >  >>",
          "Safe House Market & Price Tables",
          "The 5 Market Scarcity columns: Precious (<<), Rare (<), Uncommon (=), Common (>), and Abundant (>>).",
        ],
        [
          "++  +  =  -  --",
          "SF Tiles & Wholesale Spots",
          "Neighborhood Buyer / Wholesale price modifier — shifts the active Scarcity column 1 or 2 steps toward << (+ / ++) or >> (- / --).",
        ],
        [
          "■ Cargo / ▲ Henchman Slots",
          "Goods, Henchmen, & SUV Mat",
          "Each ■ occupies 1 Cargo block on your SUV (max 6■); each ▲ occupies 1 Henchman seat (max 2▲).",
        ],
        [
          "(R) Rome Die / (M) Move / (T) Tx",
          "Cards, Tiles, & Rules",
          "(R) rolls a 6-sided Rome die (0, 0, 1, 1, 2, 3); (M) grants/uses a Move step; (T) grants/uses an hourly Transaction.",
        ],
        [
          "(COMBAT_ICON) Immediate Combat",
          "Encounter Reputation Tiers",
          "(COMBAT_ICON) initiates immediate Combat (no negotiation).",
        ],
        [
          "!! (Double Exclamation)",
          "Encounter Reputation Tiers",
          "Threat — Comply or Fight: You must comply with the demand/job or immediately fight the NPC in Combat.",
        ],
        [
          "! (Single Exclamation)",
          "Encounter Reputation Tiers",
          "Demand — Comply or Accept Hostile Consequences (No Fight): You must comply with the demand/job or refuse and suffer the encounter card's hostile Favor consequences with no fight.",
        ],
        [
          "? (Question Mark)",
          "Encounter Reputation Tiers",
          "Offer — Comply or Not (No Refusal Penalty): You may comply or reject the offer with no penalty for declining (if you accept a ? Job and later fail or abandon that Job, you suffer the encounter card's hostile Favor consequences).",
        ],
        [
          "(QUEST_ICON)!! / (QUEST_ICON)! / (QUEST_ICON)?",
          "Encounter Reputation Tiers",
          "Cash Stack — On-Card Job printed in the Encounter card's description box: !! = accept Job or fight; ! = accept Job or suffer hostile Favor consequences with no fight; ? = optional Job with no penalty for declining (failing it later still triggers hostile Favor consequences).",
        ],
        [
          "(DECK_ICON)(QUEST_ICON)!! / (DECK_ICON)(QUEST_ICON)! / (DECK_ICON)(QUEST_ICON)?",
          "Encounter Reputation Tiers",
          "Laptop + Cash Stack — Unseen Job drawn from the top of the Jobs deck: !! = accept Job or fight; ! = accept Job or suffer hostile Favor consequences with no fight; ? = optional Job with no penalty for declining (failing it later still triggers hostile Favor consequences).",
        ],
        [
          "Green / Red Bar",
          "Tile Edge",
          "Open Street (free movement) / Roadblock (impassable without Back Alley).",
        ],
        [
          "2(d) Badge",
          "Tile Edge",
          "Road Toll — pay ₿0.2 to cross (unless waived by Back Alley or Burner Pass).",
        ],
        [
          "🌿 Bulk Sell Weed",
          "SUV & Navigate Panel",
          "Spend 1 hourly Transaction to sell ALL non-fenced Weed cards in your SUV at once.",
        ],
        [
          "👁️ Scouted Badge",
          "Unrevealed SF Cell",
          "Hover over any tile you have Scouted (or click any face-up tile) to inspect its zoomed street layout.",
        ],
        [
          "Paid (d)X • Net ±(d)Y",
          "Loaded SUV Cards & Sell Buttons",
          "Tracks what you paid for each Good and your exact net profit at the current buyer.",
        ],
      ],
    },
  },
];

function renderRulebookIconVisualNode(item) {
  const wrap = el("div", { className: "rulebook-icon-visual" });
  if (item.symbolType === "sell_sym") {
    const badge = el("span", { className: "rulebook-symbol-pill rulebook-symbol-pill-sell" });
    badge.appendChild(createSellPriceSymbolNode(false));
    wrap.appendChild(badge);
  } else if (item.symbolType === "buy_sym") {
    const badge = el("span", { className: "rulebook-symbol-pill rulebook-symbol-pill-buy" });
    badge.appendChild(createBuyPriceSymbolNode(false));
    wrap.appendChild(badge);
  } else if (item.symbolType === "denarius") {
    const badge = el("span", { className: "rulebook-symbol-pill" });
    badge.appendChild(createDenariusSvgNode("1.55em"));
    wrap.appendChild(badge);
  } else if (item.symbolType === "move_sym") {
    wrap.appendChild(createMoveActionCircleNode("1.9em"));
  } else if (item.symbolType === "tx_sym") {
    wrap.appendChild(createTransactionActionCircleNode("1.9em"));
  } else if (item.symbolType === "enc_deck_quest") {
    const badge = el("span", {
      className: "rulebook-symbol-pill",
      style: { display: "inline-flex", alignItems: "center", gap: "0.3rem", padding: "0.2rem 0.45rem" },
    });
    badge.appendChild(createDeckOfCardsIconNode());
    badge.appendChild(createAncientRomanChestIconNode());
    wrap.appendChild(badge);
  } else if (item.symbolType === "rome_die") {
    const dieNode = el(
      "span",
      {
        className: "rome-die-box",
        style: { width: "1.9rem", height: "1.9rem", fontSize: "1.05rem" },
      },
      "R"
    );
    wrap.appendChild(dieNode);
  } else if (item.badgeText) {
    wrap.appendChild(
      el("span", {
        className: `rulebook-symbol-badge ${item.badgeClass || ""}`,
        text: item.badgeText,
      })
    );
  } else if (Array.isArray(item.imgs)) {
    const multiWrap = el("div", { className: "rulebook-icon-multi" });
    item.imgs.forEach((src) => {
      multiWrap.appendChild(
        el("img", {
          src,
          alt: item.title || "Game icon",
          className: "rulebook-icon-img rulebook-icon-img-sm",
          loading: "lazy",
        })
      );
    });
    wrap.appendChild(multiWrap);
  } else if (item.img) {
    wrap.appendChild(
      el("img", {
        src: item.img,
        alt: item.title || "Game icon",
        className: "rulebook-icon-img",
        loading: "lazy",
      })
    );
  }
  return wrap;
}

function renderRulebookFormattedBulletNode(bulletText) {
  const li = el("li", { className: "rulebook-bullet-item" });
  const colonIdx = bulletText.indexOf(": ");
  if (colonIdx > 0 && colonIdx <= 68) {
    const leadText = bulletText.slice(0, colonIdx + 1);
    const bodyText = bulletText.slice(colonIdx + 1);
    const leadStrong = el("strong", { className: "rulebook-bullet-lead" });
    appendTextWithRomeDice(leadStrong, leadText);
    li.appendChild(leadStrong);
    appendTextWithRomeDice(li, bodyText);
  } else {
    appendTextWithRomeDice(li, bulletText);
  }
  return li;
}

function buildRulebookSectionNodes(searchQuery) {
  const q = (searchQuery || "").trim().toLowerCase();
  const filtered = q
    ? RULEBOOK_SECTIONS.filter(
      (sec) =>
        sec.title.toLowerCase().includes(q) ||
        (sec.paragraphs || []).some((p) => p.toLowerCase().includes(q)) ||
        (sec.bullets || []).some((b) => b.toLowerCase().includes(q)) ||
        (sec.iconGrid || []).some(
          (ic) =>
            (ic.title || "").toLowerCase().includes(q) ||
            (ic.desc || "").toLowerCase().includes(q) ||
            (ic.badgeText || "").toLowerCase().includes(q)
        ) ||
        (sec.table && sec.table.rows.some((r) => r.some((cell) => cell.toLowerCase().includes(q))))
    )
    : RULEBOOK_SECTIONS;

  if (filtered.length === 0) {
    return [
      el(
        "p",
        { style: { color: "var(--text-muted)", fontStyle: "italic", padding: "0.75rem 0" } },
        `No rulebook sections matched "${searchQuery}". Try searching for Weed, Favor, Sell, Buy, Loan, Curfew, or Sunday.`
      ),
    ];
  }

  return filtered.map((sec) =>
    el(
      "section",
      { id: `rulebook-sec-${sec.id}`, className: "rulebook-section" },
      el("h3", { text: sec.title }),
      ...(sec.paragraphs || []).map((p) => el("p", { className: "rulebook-paragraph", text: p })),
      sec.iconGrid
        ? el(
          "div",
          { className: "rulebook-icon-grid" },
          ...sec.iconGrid.map((item) =>
            el(
              "div",
              { className: "rulebook-icon-card" },
              renderRulebookIconVisualNode(item),
              el(
                "div",
                { className: "rulebook-icon-copy" },
                el("div", { className: "rulebook-icon-title", text: item.title }),
                el("div", { className: "rulebook-icon-desc", text: item.desc })
              )
            )
          )
        )
        : null,
      sec.bullets
        ? el(
          "ul",
          { className: "rulebook-bullet-list" },
          ...sec.bullets.map((b) => renderRulebookFormattedBulletNode(b))
        )
        : null,
      sec.table
        ? el(
          "div",
          { className: "rulebook-table-wrap" },
          el(
            "table",
            { className: "rulebook-table" },
            el(
              "thead",
              {},
              el("tr", {}, ...sec.table.headers.map((h) => el("th", { text: h })))
            ),
            el(
              "tbody",
              {},
              ...sec.table.rows.map((row) =>
                el("tr", {}, ...row.map((cellText) => el("td", { text: cellText })))
              )
            )
          )
        )
        : null
    )
  );
}

function renderRulebookView() {
  const sectionsContainer = el(
    "div",
    { id: "rulebook-sections-list" },
    ...buildRulebookSectionNodes(appState.rulebookSearch)
  );

  const searchInput = el("input", {
    className: "form-input",
    type: "search",
    placeholder: "Search rules (e.g. Weed, Favor, Cargo, Loan, Curfew, Sunday)...",
    value: appState.rulebookSearch || "",
    onInput: (e) => {
      appState.rulebookSearch = e.target.value;
      sectionsContainer.replaceChildren(...buildRulebookSectionNodes(appState.rulebookSearch));
    },
  });

  if (typeof appState.rulebookTocCollapsed !== "boolean") {
    appState.rulebookTocCollapsed = typeof window !== "undefined" && window.innerWidth <= 980;
  }

  const tocBody = el(
    "div",
    {
      className: `rulebook-toc-body ${appState.rulebookTocCollapsed ? "collapsed" : ""}`,
    },
    el("div", { className: "form-group", style: { marginBottom: "0.75rem" } }, searchInput),
    ...RULEBOOK_SECTIONS.map((sec) =>
      el("button", {
        type: "button",
        className: `rulebook-toc-btn ${appState.rulebookSection === sec.id ? "active" : ""}`,
        text: sec.title,
        onClick: () => {
          appState.rulebookSection = sec.id;
          appState.rulebookSearch = "";
          searchInput.value = "";
          sectionsContainer.replaceChildren(...buildRulebookSectionNodes(""));
          tocBody.querySelectorAll(".rulebook-toc-btn").forEach((btn, idx) => {
            btn.classList.toggle("active", RULEBOOK_SECTIONS[idx] && RULEBOOK_SECTIONS[idx].id === sec.id);
          });
          if (typeof window !== "undefined" && window.innerWidth <= 980) {
            appState.rulebookTocCollapsed = true;
            tocBody.classList.add("collapsed");
            tocToggleBtn.textContent = "▼ Expand Index";
          }
          const targetEl = document.getElementById(`rulebook-sec-${sec.id}`);
          if (targetEl) targetEl.scrollIntoView({ behavior: "smooth", block: "start" });
        },
      })
    )
  );

  const tocToggleBtn = el(
    "button",
    {
      type: "button",
      className: "btn btn-sm rulebook-toc-toggle",
      onClick: () => {
        appState.rulebookTocCollapsed = !appState.rulebookTocCollapsed;
        tocBody.classList.toggle("collapsed", appState.rulebookTocCollapsed);
        tocToggleBtn.textContent = appState.rulebookTocCollapsed ? "▼ Expand Index" : "▲ Collapse Index";
      },
    },
    appState.rulebookTocCollapsed ? "▼ Expand Index" : "▲ Collapse Index"
  );

  const tocSidebar = el(
    "aside",
    { className: "panel rulebook-toc" },
    el(
      "div",
      { className: "rulebook-toc-header" },
      el("h3", { className: "panel-title", style: { marginBottom: "0" }, text: "📜 Rulebook Index" }),
      tocToggleBtn
    ),
    !appState.user
      ? el(
        "button",
        {
          type: "button",
          className: "btn btn-primary",
          style: { width: "100%", marginTop: "0.55rem", marginBottom: "0.55rem" },
          onClick: () => {
            appState.activeTab = "portal";
            renderApp();
          },
        },
        "← Back to Welcome & Sign In"
      )
      : null,
    tocBody
  );

  return el(
    "div",
    { className: "portal-container" },
    el(
      "div",
      { className: "rulebook-layout" },
      tocSidebar,
      el(
        "div",
        { className: "panel rulebook-content" },
        el(
          "div",
          { className: "panel-title fresco-banner-header fresco-merchants" },
          el("span", { text: "📜 Night Merchant: InstantGram SF — Rulebook" }),
          el("span", { style: { fontSize: "0.8rem", color: "#fde6b0" }, text: "Complete HTML Edition" })
        ),
        sectionsContainer
      )
    )
  );
}

/* =========================================================================
   3D DICE ROLL ANIMATION ENGINE (ADAPTED FROM GRAFT SURVIVAL MODE)
   ========================================================================= */

export { RULEBOOK_SECTIONS, renderRulebookIconVisualNode, renderRulebookFormattedBulletNode, buildRulebookSectionNodes, renderRulebookView };
