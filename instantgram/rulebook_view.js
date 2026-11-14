import { appState, createDenariusSvgNode, createSellPriceSymbolNode, createBuyPriceSymbolNode, createDeckOfCardsIconNode, createAncientRomanChestIconNode, createMoveActionCircleNode, createTransactionActionCircleNode, appendTextWithRomeDice, el } from "./core_ui.js?v=110";
import { renderApp } from "./app.js?v=110";

const RULEBOOK_SECTIONS = [
  {
    id: "overview",
    title: "1. Overview & Historical Setting (211 A.D.)",
    paragraphs: [
      "Welcome to Night Merchant: All Roads Lead to Rome! The year is 211 A.D. Emperor Septimius Severus has died in Eboracum, leaving Rome in the volatile hands of his feuding sons Bassianus (known to history as MAGA) and ISIS. Under Julius Caesar's Lex Iulia Municipalis (45 B.C.), heavy merchant wagons are barred from Rome's streets by day (historically exempting only imperial public-works stone haulers, while private nocturnal marble consignments must still roll by night). Only at dusk (8:00 P.M.) do the six Via entrances open to the Collegium Mercatorum.",
      "Across 3 Seasons (Spring, Summer, and Fall), 2 to 6 merchants buy Goods and hire Guards at Portus Ostiae by day, then navigate 36 nocturnal neighborhoods of Rome (A1–F6) across 10 hourly turns (8:00 P.M. to 5:00 A.M.) before the 6:00 A.M. Sunrise Curfew. After Fall Clean-Up, the December 211 Purge (Winter Reckoning) settles unfinished contracts, cart inventory, loans, and imperial faction alliances—crowning the wealthiest merchant in Denarii (d)!",
    ],
    bullets: [
      "Game Boards: The Portus Ostiae Market Board (6 tracks: Grain, Animals, Wine, Weapons, Marble, and Guards × 6 scarcity bays), the 6×3 Political Climate Board, and the Nocturnal Rome City Board (6×6 grid A1–F6, 36 neighborhoods including Mausoleum Hadriani at A1, Thermae Neronianae at B2, Saepta Julia at C2, and Mons Testaceus at A6, plus 6 Via Entrances, 3 Imperial Forums, and the Tiber River crossed by 5 Stone Bridges).",
      "Neighborhood Tiles: 432 square tiles (12 per neighborhood across 36 stacks) featuring streets, barricades, 2(d) road tolls, encounters, Stadium gambling, and nocturnal buyers.",
      "Decks & Mats: Market Cards, Missiones (Starting & Encounter Missions), Influence Cards, Patricii / Legiones / Nefarii Encounter Decks, Merchant Cart Mats (6■ Cargo Blocks in 2×3 grid, 2▲ Guard Slots in 2×1 column, 5 Uncapped Faction Favor tracks), and 6-sided Roman Numeral Dice (0, 0, I, I, II, III).",
    ],
  },
  {
    id: "factions",
    title: "2. The Five Factions of San Francisco (Uncapped Favor)",
    paragraphs: [
      "Five factions fight over the city after dark. Favor gems you earn or lose from Missions, Encounters, and Influence cards are UNCAPPED (they can reach ±5 or more). Your favor decides whether a faction's people treat you as a Friendly ally or a Hostile target, and it powers the Ballot Initiatives you draft:",
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
    title: "3. Game Setup, Initial Discard, & Political Climate Draft",
    bullets: [
      "Starting Treasury & Market: Each merchant begins Spring with 12(d) and 0 Favor across all five factions. 24 Goods/Guards are dealt onto the Portus Ostiae Market Board and left-aligned toward Precious (<<).",
      "Initial Hand & Speed Discard: Each merchant is dealt 5 distinct Starting Missions and 5 distinct Influence cards, then discards 2 Missions and 2 Influence cards (keeping 3 of each).",
      "Political Climate Draft (6×3 Board): The FIRST merchant to finish discarding claims First Pick on the 6-column Political Climate Board (MAGA, ISIS, TECH, DSA, MS13, Missions — at most 1 Decree may be enacted per column).",
      "2-Player vs. 3+ Player Draft: In a 2-player game, 4 modifiers are enacted via snake draft (First Discarder → Rival → Rival → First Discarder — first pick and last pick!). In 3–6 player games, each merchant enacts 1 modifier in discard-completion order (up to all 6 columns).",
      "Normal Game Turn Order & 5th/6th Player Stipend: Once the Political Climate is set, the First Player Token goes to the merchant seated AFTER the First Discarder—so the merchant who claimed First Pick on the Political Climate acts LAST in normal turn order! In 5–6 player games, to offset late Spring Market position, the 5th merchant in Spring turn order receives +1(d) (starting at 13(d)) and the 6th merchant receives +2(d) (starting at 14(d)).",
    ],
  },
  {
    id: "market",
    title: "4. Phase I: The Ostia Market Phase & Goods Card Symbols",
    paragraphs: [
      "During daylight at Portus Ostiae, merchants take turns in turn order performing 1 Market Action per turn until all merchants pass consecutively. Every Good and Guard card features a 5-column Price Board (from << Precious to >> Abundant) and compact symbols:",
    ],
    iconGrid: [
      {
        symbolType: "sell_sym",
        title: "Bold Green +𐆖 (Sell / Fence Row)",
        desc: "The top price row on a Good Card. Shows the Denarii you RECEIVE when selling that Good in Rome (or Fencing Encounter Mission Cargo) at each Scarcity column (<< to >>).",
      },
      {
        symbolType: "buy_sym",
        title: "Italic Red -𐆖 (Buy / Hire Row)",
        desc: "The bottom price row on a Good or Guard Card. Shows the Denarii you PAY to buy that Good at Portus Ostiae (or a Rome Forum) or to hire/retain a Guard.",
      },
      {
        symbolType: "denarius",
        title: "Denarius (𐆖)",
        desc: "Imperial silver coin (U+10196) used for all Market purchases, nocturnal sales, road tolls, Stadium wagers, Guard upkeep, and final victory scoring.",
      },
      {
        badgeText: "<<  <  =  >  >>",
        title: "5 Scarcity Columns",
        desc: "From left to right: << Precious (0 cards left on track), < Rare (1 card), = Uncommon (2–3 cards), > Common (4 cards), and >> Abundant (5–6 cards).",
      },
      {
        badgeText: "■  ■■  ■■■",
        badgeClass: "rulebook-badge-cargo",
        title: "Cart Space Cubes (■)",
        desc: "Brown squares showing how many of your Cart Mat's 6 Cargo slots (6■) a Good occupies (1■, 2■, or 3■). Heavier Goods yield higher profit margins.",
      },
      {
        badgeText: "▲  ▲▲",
        badgeClass: "rulebook-badge-guard",
        title: "Guard Seat Triangles (▲)",
        desc: "Gold triangles showing how many of your Cart Mat's 2 Guard seats (2▲) a hired Guard occupies (1▲ or 2▲).",
      },
    ],
    bullets: [
      "Buy a Good or Hire a Guard: Pay the card's italic Red (BUY_SYM) Buy/Hire price for its current column (<<, <, =, >, >>). Goods occupy ■ blocks on your Cart Mat (max 6■); Guards occupy ▲ slots (max 2▲). A replacement card is drawn onto the leftmost column of its category.",
      "Source a Good (Discard 1 Influence): Discard 1 Influence card to select a Good from the deck onto the leftmost column of its track (sliding existing cards right).",
      "Pass: Step out of the Market Round. Once a full round passes with no Market purchases, pass the First Player Token clockwise and enter Rome at dusk.",
    ],
    table: {
      headers: ["Cards Remaining on Track", "Scarcity Symbol", "Market Supply State", "Base Rome Selling Column ((SELL_SYM))"],
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
    title: "5. Phase II: Nocturnal Rome Delivery, Tile Icons, & The Tiber River",
    paragraphs: [
      "At 8:00 P.M. (Turn 1), each dealer may take 1 Initial Scout (tile or deck card) and then enters San Francisco through one of the 5 road entry points: B1 (Golden Gate Bridge), F1 (Bay Bridge), F5 (US-101), D6 (I-280), or A5 (Route 1). Entering uses your Turn 1 movement. Leaving is different: the Pacific (west) edge has almost no way out except rare, expensive Speedboats; the Bay (north and east) edges offer cheaper boat escapes (Sailboat 1(d), Ferry 2(d), Cargo Ship 3(d)); and the Peninsula (south) edge has the most exits, usually free.",
      "Across Turns 1–10 (8:00 P.M. to 5:00 A.M.), each active merchant resolves their hourly turn in strict sequence:",
    ],
    iconGrid: [
      {
        symbolType: "move_sym",
        title: "Move Action Circle (M)",
        desc: "Represents 1 Cart Movement action along an open green street edge (or granted as a bonus Move by Influence cards).",
      },
      {
        symbolType: "tx_sym",
        title: "Transaction Action Circle (T)",
        desc: "Represents 1 hourly Transaction: Sell 1 Good (or Bulk-Sell all Grain!), Buy 1 Good at a Forum, or Gamble at a Stadium.",
      },
      {
        badgeText: "++  +  =  -  --",
        title: "Tile Buyer & Forum Modifiers",
        desc: "Shifts a Good's current Ostia Scarcity column 1 or 2 steps toward << Precious (+ / ++) or >> Abundant (- / --) when buying or selling on that tile.",
      },
      {
        img: "./assets/icons/persist.png",
        title: "Persistent Tile Icon",
        desc: "Landmarks marked with the Persistent icon stay face-up on the Rome board between Seasons instead of returning to their stack at Dawn.",
      },
      {
        img: "./assets/icons/refresh.png",
        title: "Refresh Tile Icon",
        desc: "Volatile streets marked with the Refresh icon discard after their encounter resolves, immediately revealing the next tile beneath.",
      },
      {
        img: "./assets/icons/fleur_de_lis_gold.png",
        title: "Imperial Forum / First Player",
        desc: "Marks Rome's 3 central Imperial Forums (C3, D3, D4) where Goods are sold to merchants, as well as the seasonal First Player emblem.",
      },
    ],
    bullets: [
      "Step 1 — Optional Trash: Discard 1 Influence card to bury the top unexposed tile of any neighborhood or the top card of any deck to the bottom.",
      "Step 2 — Movement (1 Step (M)): Move along a passable outgoing edge to an adjacent neighborhood (revealing its top tile if face-down) or out an exterior perimeter edge to Exit Rome.",
      "Step 3 — Edge Cost / Hazard: Pay any 2(d) road toll or resolve any Edge Encounter crossed.",
      "Step 4 — Mission Cargo Pickup & Delivery: Upon arriving in a neighborhood—BEFORE any Center Tile Encounter triggers—you may load or deliver matching Mission Cargo!",
      "Step 5 — Center Tile Encounter: Resolve any Center Encounter on the tile (Patricii, Legiones, Nefarii, Angry Mob, Theater Troupe, or Soothsayer).",
      "Step 6 — One Transaction (1 Good/Hr (T), or Bulk Grain!): Sell AT MOST 1 Good card matching a buyer ('Buys:') on your current tile (or an active Sell Mission here) at its bold Green (SELL_SYM) price—EXCEPT for non-fenced GRAIN, where 1 hourly Transaction may sell ANY NUMBER (or all!) of your Grain cards together at the current Grain scarcity modifier! Alternatively, Purchase 1 Good at a Forum ('Sells:' at C3, D3, or D4) at its italic Red (BUY_SYM) price, OR Gamble once at a Stadium tile (up to 20(d) wager).",
      "Step 7 — End-of-Turn Scout: After completing your Move and Transaction actions, you may Scout one time at the end of your turn by peeking at the top unrevealed tile of any neighborhood stack or the top card of any deck. Committing to your Scout action immediately advances the turn so the next merchant in sequence can begin their turn while you finish examining the scouted tile or card (though the next merchant may choose to wait if they want to see whether you react or move toward that area).",
      "Tiber River & 5 Stone Bridges: The Tiber divides the West Bank (A1, A4, B4, A5) from the East Bank. All diagonal crossings over the Tiber and unbridged orthogonal river borders are completely impassable (even with Shortcut). Carts may cross ONLY via Rome's 5 intra-urban Stone Bridges (in use in 211 A.D.): Pons Aelius (A1↔B1), Pons Neronianus (A1↔A2), Pons Agrippae (A3↔A4), Pons Fabricius (B4↔C4), and Pons Aemilius (B4↔B5).",
    ],
  },
  {
    id: "missions",
    title: "6. Missions, Mission Cargo, & Regicide",
    bullets: [
      "Starting Missions: Kept during Setup (3 per merchant). Can be canceled voluntarily without Favor penalty (unless Surge Pricing is active, which fines -10(d) on any failed/canceled/unfinished mission!). Starting Mission Cargo can NEVER be sold or fenced.",
      "Encounter Missions: Drawn from NPC encounters. Encounter Mission Cargo displays a bold Green (SELL_SYM) Fence price row—fencing it to a matching buyer sells 1 card for quick Denarii, applies Patron Hostile Favor, and FAILS the mission (unless Clique Fence is active, which boosts Fence Scarcity by +1 step and prevents fencing from counting as a Failed Mission!).",
      "Soothsayer Missions: Mandatory prophecies with 1(R) face-down Influence cards sealed underneath until completed. Cannot be voluntarily canceled unless holding 6 Soothsayer Missions simultaneously.",
      "Regicide & Regime Change ('Any Player' Clauses): Two high-stakes Encounter Missions—Regicide (defeating Emperor MAGA in combat) and Regime Change (defeating Co-Emperor ISIS in combat)—trigger if ANY Player defeats that Emperor in combat while you hold the Mission! Completing Regicide immediately ends the game in an instant assassination victory for the Regicide holder; completing Regime Change awards 100(d) and +2 Rubies (+1 Diamond) while continuing the year.",
    ],
  },
  {
    id: "combat",
    title: "7. Encounters, Combat, Charts, & Stadium Gambling",
    paragraphs: [
      "As your cart rolls through Rome's nocturnal streets and alleys, tile edges and centers trigger encounters with Rome's three major NPC decks, street hazards, and amphitheater games:",
    ],
    iconGrid: [
      {
        img: "./assets/icons/patricii_icon.png",
        title: "Patricii Encounter",
        desc: "Wealthy senators and aristocrats. Friendly Patricii offer lucrative Missions or trade deals; Hostile Patricii demand bribes, wine, or marble.",
      },
      {
        img: "./assets/icons/legiones_icon.png",
        title: "Legiones Encounter",
        desc: "Praetorian guards and urban cohorts. Heavily aligned with MAGA; gain +2 CP when Back the Blue is active.",
      },
      {
        imgs: ["./assets/icons/nefarii_icon.png", "./assets/icons/nefarii_3_icon.png"],
        title: "Nefarii & 3× Syndicate",
        desc: "Cutthroats, thieves, and nocturnal syndicates. A 3-Dagger icon draws 3 Nefarii cards in succession!",
      },
      {
        img: "./assets/icons/angry_mob.png",
        title: "Angry Mob (1R Chart)",
        desc: "Roll 1(R): 0 = Lose all Wine; I = Lose all Grain; II = Lose your most expensive Good; III = Escape unharmed.",
      },
      {
        img: "./assets/icons/theater_masks.png",
        title: "Theater Troupe (1R Chart)",
        desc: "Roll 1(R): 0 = Lose all positive Favor; I = Lose all negative Favor; II = Lose rest of turn & next turn; III = Draw 1(R) Influence.",
      },
      {
        img: "./assets/icons/soothsayer_icon.png",
        title: "Soothsayer Prophecy",
        desc: "Draws a mandatory Soothsayer Mission and seals 1(R) face-down Influence cards beneath it until you fulfill the prophecy.",
      },
      {
        img: "./assets/icons/combat.png",
        title: "Combat & Combat Power (CP)",
        desc: "Crossed gladius swords mark street combat and hostile Combat tiers on Encounter cards. Compare total Player CP vs. Opponent CP.",
      },
      {
        symbolType: "enc_deck_quest",
        title: "Encounter Deck & Quest Chest",
        desc: "Mid-card Encounter tier icons: the Fanned Deck + Roman Arca Chest ((DECK_ICON)(QUEST_ICON)! / ?) draws an unseen Missiones card; the Arca Chest alone ((QUEST_ICON)! / ?) assigns the card's printed Mission.",
      },
      {
        symbolType: "rome_die",
        title: "Roman Numeral Die (R)",
        desc: "6-sided custom die with faces 0, 0, I, I, II, III (mean roll = 1.0). Rolled for Combat, Charts, and Stadium wagers.",
      },
      {
        imgs: ["./assets/icons/dice.png", "./assets/icons/chest.png"],
        title: "Stadium Wager & Loot Chest",
        desc: "Dice icon lets you spend your Transaction to wager 1–20(d) (win Wager × 1(R) roll). Chest icon marks special cargo/treasure rewards.",
      },
    ],
    bullets: [
      "Friendly vs. Hostile Encounters: Determined by your uncapped net Favor with the NPC's Faction. If you refuse a Demand to Fight and lose Combat, the NPC enforces their original Demand AND your turn ends immediately!",
      "Combat Power (CP) & Cargo Gear: Both sides roll Rome Dice (R) plus Guards, Weapons, mandatory Exotic Animals (including Ostrich or negative-die beasts!), and Influence modifiers (plus +1 CP per positive Ruby & +2 CP to Legiones if Back the Blue is active). Note that crated Loricae body armor carries 0 CP in street ambushes (too slow to don mid-attack, compensated by lucrative trade margins). If Player CP ≥ Opponent CP against an NPC, you win!",
      "Armor, Guards, & Driver Fate (Damage Deficit Note): If Opponent CP > Player CP, suffer Raw Wounds = (Opponent CP − Player CP). Note that wounds from combat are always determined by the signed damage deficit between the two sides—even when one or both CP totals are negative (for example, if your overall CP is -2 and your opponent's CP is -1, you suffer 1 Wound). Shields/Helmets reduce Wounds first; each remaining Wound kills 1 Guard. If an unblocked Wound reaches your Driver, roll 1(R) on the Driver Fate Chart: 0 = Dead (lose all Goods & your night ends); I = Left for dead (lose all Goods); II = Beaten & mugged (lose all Denarii); III = Begged for mercy (lose all Influence cards).",
      "1(R) Street Charts: Angry Mob (0: lose all Wine; I: lose all Grain; II: lose most expensive Good; III: safe), Theater Troupe (0: undo all Positive-outcome gem changes; I: undo all Hostile-outcome gem changes; II: lose rest of turn & next turn; III: draw 1(R) Influence), Soothsayer (take mandatory Mission + seal 1(R) Influence cards).",
      "Stadium Gambling: On a tile with the Dice icon, wager 1(d) to 20(d) (capped at 20(d) per gamble action) and roll 1(R) to win Wager × Roll!",
    ],
  },
  {
    id: "cleanup",
    title: "8. Phase III: Dawn Clean-Up, Curfew Fines, & Loans",
    bullets: [
      "6:00 A.M. Dawn Curfew Fine: Any merchant still inside Rome after Turn 10 (5:00 A.M.) pays a seasonal curfew fine—Spring 12(d), Summer 20(d), Fall 32(d)—halved to 6(d) / 10(d) / 16(d) if standing on one of the 6 Via Gate tiles!",
      "Tile Cleanup: Persistent tiles (⤹) stay face-up for future seasons; Refresh tiles (↻) discard after encounters; ordinary revealed tiles return to the bottom of their stacks at Dawn.",
      "Buy Influence Cards: Cost scales by your current Influence hand size (including face-down Soothsayer cards): 0–1 cards = 2(d), 2–3 cards = 4(d), 4 cards = 6(d), 5+ cards = 8(d).",
      "Collegium Loans: Spring Loan grants +20(d) (repay 30(d) at end of Summer, or 45(d) at end of Fall / Winter Reckoning). Summer Loan grants +40(d) (repay 60(d) at end of Fall / Winter Reckoning).",
      "Guard Upkeep & Winter Tie-Breaker Policy: Pay each retained Guard's current Market hiring cost (or release them to the bottom of the Market deck). During Fall Clean-Up, you may also toggle whether your Driver is authorized to expend Combat Influence cards during Winter Reckoning PvP tie-breakers.",
    ],
  },
  {
    id: "winter",
    title: "9. Winter Reckoning & The 6×3 Political Climate Matrix",
    paragraphs: [
      "Unless a merchant achieves instant victory via Regicide earlier in the year, the game concludes after Fall Clean-Up with Winter Reckoning, governed by the Political Climate modifiers drafted during Setup:",
    ],
    bullets: [
      "Step 1 — Unfinished Missions Fail: Incomplete Missions fail first (applying Encounter Hostile Favor and -10(d) each if Surge Pricing is active); remaining mission cargo is discarded.",
      "Step 2 — Cart Liquidation & Loans: Remaining non-mission Goods liquidate at Abundant (>>) (SELL_SYM) Sell Price, then unpaid Spring (-45(d)) and Summer (-60(d)) Loans are deducted.",
      "Step 3 — Mass Deportation FIRST, Then Political Climate Settlement: If Mass Deportation (MAGA Option 1) is enacted, it resolves FIRST—eliminating the merchant with Least MAGA Favor BEFORE any other Most/Least awards, penalties, steals, or percentages! Eliminated merchants cannot win or suffer subsequent Most/Least awards and rank below all survivors. Then resolve Flat Gem/Mission Modifiers & Least Penalties → Billionaire Tax Steal → TECH +20% Wealth.",
      "Step 4 — PvP Combat Tie-Breakers (Strictly One Winner/Loser!): Every 'Most' and 'Least' modifier—as well as Final Score ties—awards its bonus or penalty to STRICTLY ONE merchant, even if tied at 0! Tied merchants fight PvP Combat: pre-roll cards (Mercenary Ambush, Distraction removing 1 positive die) apply before rolling, all dice roll simultaneously, and reactive post-roll cards (Twist Of Fate, Flying Chamber Pot, Gladiator's Intervention) trigger when they can overturn a deficit. For 'Most' awards, the combat winner claims the prize; for 'Least' penalties/elimination, the combat winner escapes and the combat LOSER suffers the penalty!",
    ],
    table: {
      headers: ["MAGA", "ISIS", "Julia TECH", "DSA", "MS13", "Missions"],
      rows: [
        [
          "Mass Deportation: End of game (FIRST): Least MAGA favor is eliminated.",
          "Fatwa: End of game: Least ISIS favor loses 25(d).",
          "Series A: End of game: Most TECH favor gains +20% wealth.",
          "Billionaire Tax: End of game: Most DSA favor steals 15(d) from the wealthiest rival.",
          "Protection Racket: End of game: Most MS13 favor gains 25(d).",
          "Five-Star Courier: End of game: Most completed Missions gains 30(d).",
        ],
        [
          "Recall Election: End of game: Lose 10(d) per +Ruby; gain 5(d) per -Ruby.",
          "Fatwa: End of game: +15(d) per +Emerald if MAGA ≤ 0, or -10(d) if ≥ +1; -5(d) per -Emerald.",
          "Conflict of Interest: End of game: Lose 15(d) per +Diamond and 15(d) per -Diamond.",
          "Mutual Aid: End of game: Gain 10(d) per completed Mission with +Sapphire or a DSA patron.",
          "Plata o Plomo: End of game: Gain 10(d) per +Amethyst and 10(d) per -Amethyst.",
          "Full Time Employee: End of game: receive A × B Bitcoin (A = your gems of one faction, B = missions completed for that faction).",
        ],
        [
          "Back the Blue: Legiones gain +2 CP. Each +Ruby gives your Cart +1 CP.",
          "Sanctuary City: When enacted, every player gains a free Emerald (+1 ISIS).",
          "Lobbying Blitz: Exchange +Diamonds 1-for-1 into +Rubies or +Emeralds anytime.",
          "Clique Fence: Fenced cargo sells +1 Scarcity step higher and does not fail the Mission.",
          "Rent Control: Spend +Amethysts when selling Goods (including Bulk Grain) for +1 Scarcity step per gem.",
          "Surge Pricing: Completed Missions pay 2× Denarii; failed or unfinished Missions fine 10(d).",
        ],
      ],
    },
  },
  {
    id: "symbols",
    title: "10. Complete Symbol Key & Strategy Overlays",
    paragraphs: [
      "Use this quick-reference table to decode every symbol on Goods Cards, Encounter Cards, Cart Mats, and Rome Neighborhood Tiles (keyboard shortcuts can be viewed and customized on your Profile page):",
    ],
    table: {
      headers: ["Feature / Symbol", "Where Shown", "Meaning"],
      rows: [
        [
          "(SELL_SYM) (Bold Green +𐆖)",
          "Goods Cards & Mission Cargo",
          "Sell Price Row (or Fence Price Row on Encounter Mission Cargo) — the Denarii you earn when selling that Good at each scarcity level (<< to >>).",
        ],
        [
          "(BUY_SYM) (Italic Red -𐆖)",
          "Goods & Guards Cards",
          "Buy / Hire Price Row — the Denarii you pay to purchase that Good at Portus Ostiae / Imperial Forums or to hire/retain a Guard.",
        ],
        [
          "(d) Denarius Symbol",
          "Treasury, Cards, & Tiles",
          "Roman Silver Denarius coin — the currency of Night Merchant.",
        ],
        [
          "<<  <  =  >  >>",
          "Ostia Market & Price Tables",
          "The 5 Market Scarcity columns: Precious (<<), Rare (<), Uncommon (=), Common (>), and Abundant (>>).",
        ],
        [
          "++  +  =  -  --",
          "Rome Tiles & Forums",
          "Neighborhood Buyer / Forum price modifier — shifts the active Scarcity column 1 or 2 steps toward << (+ / ++) or >> (- / --).",
        ],
        [
          "■ Cargo / ▲ Guard Slots",
          "Goods, Guards, & Cart Mat",
          "Each ■ occupies 1 Cargo block on your Cart (max 6■); each ▲ occupies 1 Guard seat (max 2▲).",
        ],
        [
          "(R) Roman Die / (M) Move / (T) Tx",
          "Cards, Tiles, & Rules",
          "(R) rolls a 6-sided Roman die (0, 0, I, I, II, III); (M) grants/uses a Move step; (T) grants/uses an hourly Transaction.",
        ],
        [
          "(COMBAT_ICON) / ! / ?",
          "Encounter Reputation Tiers",
          "(COMBAT_ICON) initiates immediate Combat; ! is a mandatory Demand (comply or fight); ? is an optional Friendly Offer or Gift.",
        ],
        [
          "(QUEST_ICON)! / (QUEST_ICON)?",
          "Encounter Reputation Tiers",
          "Ancient Roman Arca Chest — mandatory ((QUEST_ICON)!) or optional ((QUEST_ICON)?) Mission prescribed directly on the Encounter card.",
        ],
        [
          "(DECK_ICON)(QUEST_ICON)! / (DECK_ICON)(QUEST_ICON)?",
          "Encounter Reputation Tiers",
          "Fanned Card Deck + Roman Arca Chest — mandatory (!) or optional (?) unseen Mission drawn from the top of the Missiones deck.",
        ],
        [
          "Green / Red Bar",
          "Tile Edge",
          "Open Street (free movement) / Barricaded Alley (impassable without Shortcut).",
        ],
        [
          "2(d) Badge",
          "Tile Edge",
          "Road Toll — pay 2 Denarii to cross (unless waived by Shortcut or Pass).",
        ],
        [
          "🌊 Tiber / 🌉 Pons",
          "Rome Map Borders",
          "Unbridged Tiber borders & river diagonals are impassable; cross only at the 5 Stone Bridges.",
        ],
        [
          "🌾 Bulk Sell Grain",
          "Cart & Navigate Panel",
          "Spend 1 hourly Transaction to sell ALL non-fenced Grain cards in your Cart at once.",
        ],
        [
          "👁️ Scouted Badge",
          "Unrevealed Rome Cell",
          "Hover over any tile you have Scouted (or click any face-up tile) to inspect its zoomed street layout.",
        ],
        [
          "Paid (d)X • Net ±(d)Y",
          "Loaded Cart Cards & Sell Buttons",
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
        `No rulebook sections matched "${searchQuery}". Try searching for Tiber, Grain, Favor,Sell, Buy, Loan, Curfew, or Winter.`
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
    placeholder: "Search rules (e.g. Tiber, Grain, Favor, Cargo, Loan, Winter)...",
    value: appState.rulebookSearch || "",
    onInput: (e) => {
      appState.rulebookSearch = e.target.value;
      sectionsContainer.replaceChildren(...buildRulebookSectionNodes(appState.rulebookSearch));
    },
  });

  const tocSidebar = el(
    "aside",
    { className: "panel rulebook-toc" },
    el("h3", { className: "panel-title", text: "📜 Codex Regulae" }),
    !appState.user
      ? el(
        "button",
        {
          type: "button",
          className: "btn btn-primary",
          style: { width: "100%", marginBottom: "0.75rem" },
          onClick: () => {
            appState.activeTab = "portal";
            renderApp();
          },
        },
        "← Back to Welcome & Sign In"
      )
      : null,
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
          tocSidebar.querySelectorAll(".rulebook-toc-btn").forEach((btn, idx) => {
            btn.classList.toggle("active", RULEBOOK_SECTIONS[idx] && RULEBOOK_SECTIONS[idx].id === sec.id);
          });
          const targetEl = document.getElementById(`rulebook-sec-${sec.id}`);
          if (targetEl) targetEl.scrollIntoView({ behavior: "smooth", block: "start" });
        },
      })
    )
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
