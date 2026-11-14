import { maskEmailClient, isFirebaseClientConfigured, signInWithFirebaseCustomToken, signInWithFirebaseEmailPassword, signInWithFirebaseGooglePopup, FACTION_META, SUV_COLOR_PALETTE, renderSUVIconNode, renderGoogleLogoSvg, appState, el, showToast, closeModal, showModal } from "./core_ui.js?v=110";
import { apiRequest, applyUserDefaultBoardView, syncGameUiTransitions, refreshPortalOverview, seedSeenScoutIds, openGame, renderApp } from "./app.js?v=110";
import { stopNpcTurnPacing, enqueueNewNpcEvents } from "./dice_and_sfx.js?v=110";

function buildFallbackFinalStandings(state) {
  if (!state || !Array.isArray(state.players)) return [];
  const winnerName = state.winner || null;
  const sorted = [...state.players].sort((a, b) => {
    const aElim = a.eliminated ? 1 : 0;
    const bElim = b.eliminated ? 1 : 0;
    if (aElim !== bElim) return aElim - bElim;
    const aWon = winnerName && a.name === winnerName ? 1 : 0;
    const bWon = winnerName && b.name === winnerName ? 1 : 0;
    if (aWon !== bWon) return bWon - aWon;
    const cashDiff = (Number(b.cash) || 0) - (Number(a.cash) || 0);
    if (cashDiff !== 0) return cashDiff;
    return (Number(a.index) || 0) - (Number(b.index) || 0);
  });
  let prevCash = null;
  let prevWon = false;
  let prevElim = null;
  let prevRank = 1;
  return sorted.map((p, idx) => {
    const isElim = Boolean(p.eliminated);
    const won = !isElim && (winnerName ? p.name === winnerName : idx === 0);
    const cashVal = Number(p.cash) || 0;
    let rank = idx + 1;
    if (idx === 0) {
      rank = 1;
    } else if (!won && !prevWon && prevElim === isElim && prevCash !== null && cashVal === prevCash) {
      rank = prevRank;
    }
    prevCash = cashVal;
    prevWon = won;
    prevElim = isElim;
    prevRank = rank;
    const summary = p.statsSummary || {};
    const favorSnap = summary.endingFactionStandings || p.favor || {};
    return {
      rank,
      playerIndex: Number(p.index ?? idx),
      userId: p.userId ?? null,
      name: p.name || `Player ${idx + 1}`,
      color: p.color || "Z3",
      isBot: Boolean(p.isBot),
      won,
      eliminated: isElim,
      eliminationReason: p.eliminationReason || null,
      cash: cashVal,
      sundayReckoning: p.sundayReckoning || summary.sundayReckoning || null,
      endingFactionStandings: favorSnap,
      stats: summary,
    };
  });
}

function openFinalScoringModal(standings, meta = {}) {
  const list = Array.isArray(standings) ? standings : [];
  const gameTitle = meta.gameName || (appState.gameSummary && appState.gameSummary.name) || "Roman Expedition";
  const winnerEntry = list.find((s) => s && s.won) || list.find((s) => s && !s.eliminated) || list[0] || null;
  const winnerName = meta.winnerName || (winnerEntry ? winnerEntry.name : "Unknown Merchant");
  const factionOrder = ["MAGA", "ISIS", "TECH", "DSA", "MS13"];

  const formatSignedDenarii = (n) => {
    const v = Number(n) || 0;
    return v > 0 ? `+${v}(d)` : `${v}(d)`;
  };

  const rankingCards = list.map((entry, idx) => {
    const rankNum = Number(entry.rank) || idx + 1;
    const stats = entry.stats || {};
    const enc = stats.encounters || {};
    const favorMap = entry.endingFactionStandings || stats.endingFactionStandings || {};
    const totalCells = Number(stats.totalNeighborhoods) || 36;
    const wr = entry.sundayReckoning || stats.sundayReckoning || null;
    const isEliminated = Boolean(entry.eliminated || (wr && wr.eliminated));
    const elimReason = entry.eliminationReason || (wr && wr.eliminationReason) || "Mass Deportation";
    const rankClass = !isEliminated && rankNum <= 3 ? `rank-${rankNum}` : "";

    const factionChips = factionOrder.map((fKey) => {
      const fMeta = FACTION_META.find((f) => f.key === fKey) || {
        gem: "/assets/icons/ruby.png",
        color: "#38bdf8",
      };
      const val = Number(favorMap[fKey]) || 0;
      const signed = val > 0 ? `+${val}` : String(val);
      const valColor = val > 0 ? "#15803d" : val < 0 ? "#b91c1c" : "var(--text-muted)";
      const fDelta =
        wr && wr.factionBreakdown && typeof wr.factionBreakdown[fKey] === "number"
          ? wr.factionBreakdown[fKey]
          : null;
      return el(
        "span",
        {
          className: "final-faction-chip",
          style: { borderColor: val !== 0 ? fMeta.color : "rgba(133, 94, 52, 0.35)" },
        },
        el("img", { src: fMeta.gem, alt: fKey }),
        el("span", { style: { color: "var(--text-main)" }, text: `${fKey}:` }),
        el("span", { style: { color: valColor }, text: signed }),
        fDelta !== null && fDelta !== 0
          ? el("span", {
            style: {
              fontSize: "0.72rem",
              marginLeft: "0.18rem",
              color: fDelta > 0 ? "#15803d" : "#b91c1c",
            },
            text: `(${formatSignedDenarii(fDelta)})`,
          })
          : null
      );
    });

    let sundayNode = null;
    if (wr) {
      const hasClimateBreakdown = Array.isArray(wr.climateBreakdown);
      const mComp = Number(wr.missionsCompleted ?? stats.missionsCompleted) || 0;
      const mFail = Number(wr.missionsFailed ?? stats.missionsFailed) || 0;
      const mNet = typeof wr.netMissions === "number" ? wr.netMissions : mComp - mFail;
      const mNetStr = mNet > 0 ? `+${mNet}` : String(mNet);

      if (hasClimateBreakdown) {
        const step1Fines = Number(wr.step1MissionFines) || 0;
        const cDelta = Number(wr.climateDelta) || 0;
        const wrCells = [
          ["Saturday Cash", `${Number(wr.preReckoningCash) || 0}(d)`, "var(--text-main)"],
          ...(step1Fines !== 0
            ? [["Step 1 Mission Fines", formatSignedDenarii(step1Fines), "#b91c1c"]]
            : []),
          [
            "SUV Goods (>>)",
            `+${Number(wr.goodsLiquidated) || 0}(d)`,
            Number(wr.goodsLiquidated) > 0 ? "#15803d" : "var(--text-muted)",
          ],
          [
            "Unpaid Loans",
            Number(wr.loansDeducted) > 0 ? `-${Number(wr.loansDeducted)}(d)` : "0(d)",
            Number(wr.loansDeducted) > 0 ? "#b91c1c" : "var(--text-muted)",
          ],
          [
            "Political Climate",
            isEliminated ? `☠️ ELIMINATED (${formatSignedDenarii(cDelta)})` : formatSignedDenarii(cDelta),
            isEliminated ? "#b91c1c" : cDelta > 0 ? "#15803d" : cDelta < 0 ? "#b91c1c" : "var(--text-muted)",
          ],
          [
            `Missions (✓${mComp}/✕${mFail})`,
            `Net ${mNetStr}`,
            mNet > 0 ? "#15803d" : mNet < 0 ? "#b91c1c" : "var(--text-muted)",
          ],
          [
            "Final Treasury",
            isEliminated
              ? `☠️ ${Number(wr.finalCash ?? entry.cash) || 0}(d) (Proscribed)`
              : `${Number(wr.finalCash ?? entry.cash) || 0}(d)`,
            isEliminated ? "#b91c1c" : "#754208",
          ],
        ];
        sundayNode = el(
          "div",
          { className: "sunday-reckoning-box" },
          el("div", {
            className: "final-section-label",
            style: { color: "#ff6ec7" },
            text: "⚔️ December 211 Purge — Political Climate & Sunday Reckoning",
          }),
          el(
            "div",
            { className: "sunday-reckoning-grid" },
            ...wrCells.map(([lbl, val, clr]) =>
              el(
                "div",
                { className: "final-stat-cell" },
                el("span", { className: "final-stat-lbl", text: lbl }),
                el("span", { className: "final-stat-val", style: { color: clr }, text: val })
              )
            )
          ),
          wr.climateBreakdown.length > 0
            ? el(
              "div",
              { className: "climate-reckoning-breakdown" },
              ...wr.climateBreakdown.map((cb) => {
                const cbElim = Boolean(cb.eliminated);
                const cbDelta = Number(cb.delta) || 0;
                const valText = cbElim ? "☠️ ELIMINATED" : formatSignedDenarii(cbDelta);
                const valClr = cbElim
                  ? "#b91c1c"
                  : cbDelta > 0
                    ? "#15803d"
                    : cbDelta < 0
                      ? "#b91c1c"
                      : "var(--text-muted)";
                return el(
                  "div",
                  { className: "climate-reckoning-row" },
                  el(
                    "span",
                    { className: "climate-reckoning-title" },
                    el("strong", { text: `${cb.factor || "Climate"} — ${cb.title || cb.id}: ` }),
                    el("span", { style: { color: "var(--text-muted)" }, text: cb.detail || "" })
                  ),
                  el("span", {
                    className: "climate-reckoning-delta",
                    style: { color: valClr, fontWeight: "800" },
                    text: valText,
                  })
                );
              })
            )
            : null
        );
      } else {
        const leaderNotes = [];
        if (Number(wr.magaLeaderBonus) > 0) {
          leaderNotes.push(`+${wr.magaLeaderBonus}(d) Imperial Contract (MAGA)`);
        }
        if (Number(wr.ms13LeaderBonus) > 0) {
          leaderNotes.push(`+${wr.ms13LeaderBonus}(d) Senatorial Patronage (MS13)`);
        }
        if (Number(wr.dsaLeaderBonus) > 0) {
          leaderNotes.push(`+${wr.dsaLeaderBonus}(d) Smuggler Ring (DSA)`);
        }
        if (Number(wr.missionBonus) > 0 && wr.missionRankLabel) {
          leaderNotes.push(`+${wr.missionBonus}(d) Five-Star Courier (${wr.missionRankLabel})`);
        }
        const mBonus = Number(wr.missionBonus) || 0;
        const wrCells = [
          ["Saturday Cash", `${Number(wr.preReckoningCash) || 0}(d)`, "var(--text-main)"],
          [
            "SUV Goods (>>)",
            `+${Number(wr.goodsLiquidated) || 0}(d)`,
            Number(wr.goodsLiquidated) > 0 ? "#15803d" : "var(--text-muted)",
          ],
          [
            "Unpaid Loans",
            Number(wr.loansDeducted) > 0 ? `-${Number(wr.loansDeducted)}(d)` : "0(d)",
            Number(wr.loansDeducted) > 0 ? "#b91c1c" : "var(--text-muted)",
          ],
          [
            "Faction Purge",
            formatSignedDenarii(wr.factionDelta),
            Number(wr.factionDelta) > 0
              ? "#15803d"
              : Number(wr.factionDelta) < 0
                ? "#b91c1c"
                : "var(--text-muted)",
          ],
          [
            `Missions (Net ${mNetStr})`,
            `+${mBonus}(d)`,
            mBonus > 0 ? "#15803d" : mNet < 0 ? "#b91c1c" : "var(--text-muted)",
          ],
          ["Final Treasury", `${Number(wr.finalCash ?? entry.cash) || 0}(d)`, "#754208"],
        ];
        sundayNode = el(
          "div",
          { className: "sunday-reckoning-box" },
          el("div", {
            className: "final-section-label",
            style: { color: "#ff6ec7" },
            text: "⚔️ December 211 Purge — Sunday Reckoning",
          }),
          el(
            "div",
            { className: "sunday-reckoning-grid" },
            ...wrCells.map(([lbl, val, clr]) =>
              el(
                "div",
                { className: "final-stat-cell" },
                el("span", { className: "final-stat-lbl", text: lbl }),
                el("span", { className: "final-stat-val", style: { color: clr }, text: val })
              )
            )
          ),
          leaderNotes.length > 0
            ? el("div", {
              style: { fontSize: "0.76rem", color: "#754208", fontWeight: "700" },
              text: `🏛️ Reckoning Honors: ${leaderNotes.join(" • ")}`,
            })
            : null
        );
      }
    }

    const netMissionsStat = (Number(stats.missionsCompleted) || 0) - (Number(stats.missionsFailed) || 0);
    const coreStats = [
      ["Combats Engaged", String(Number(stats.combats) || 0)],
      ["Items Purchased", String(Number(stats.itemsPurchased) || 0)],
      ["Items Sold", String(Number(stats.itemsSold) || 0)],
      ["Neighborhoods Traversed", String(Number(stats.neighborhoodsTraversed) || 0)],
      ["Neighborhoods Visited", `${Number(stats.neighborhoodsVisited) || 0} / ${totalCells}`],
      ["Missions Completed", String(Number(stats.missionsCompleted) || 0)],
      ["Missions Failed", String(Number(stats.missionsFailed) || 0)],
      ["Net Missions", netMissionsStat > 0 ? `+${netMissionsStat}` : String(netMissionsStat)],
      ["Influence Cards Played", String(Number(stats.influencePlayed) || 0)],
    ];

    const encounterStats = [
      ["Celebrities", Number(enc.celebrities) || 0],
      ["Criminals", Number(enc.criminals) || 0],
      ["Legionnaires", Number(enc.cops) || 0],
      ["Protesterss", Number(enc.angryMobs) || 0],
      ["Open Mics", Number(enc.theaterTroupes) || 0],
      ["Schizophrenics", Number(enc.schizophrenics) || 0],
    ];

    return el(
      "div",
      { className: `final-ranking-card ${entry.won ? "rank-winner" : ""} ${isEliminated ? "rank-eliminated" : ""}` },
      el(
        "div",
        { className: "final-ranking-header" },
        el(
          "div",
          { className: "final-ranking-identity" },
          el("span", { className: `final-rank-badge ${rankClass}`, text: isEliminated ? "☠️" : `#${rankNum}` }),
          renderSUVIconNode(entry.color, "", `${entry.name}'s SUV`),
          el("strong", {
            style: {
              fontFamily: "Cinzel, Georgia, serif",
              fontSize: "1.02rem",
              color: isEliminated ? "#991b1b" : entry.won ? "#6e2119" : "var(--text-main)",
            },
            text: entry.name,
          }),
          entry.isBot
            ? el("span", { className: "badge", text: "AI Persona" })
            : null,
          isEliminated
            ? el("span", {
              className: "eliminated-badge",
              text: `☠️ Eliminated (${elimReason})`,
            })
            : null,
          entry.won && !isEliminated
            ? el("span", {
              className: "badge",
              style: { borderColor: "#b45309", color: "#7dd3fc", background: "rgba(14, 42, 84, 0.92)" },
              text: "👑 Victorious Night Merchant",
            })
            : null
        ),
        el("div", {
          className: "final-score-pill",
          style: isEliminated ? { borderColor: "#dc2626", color: "#ff6ec7", background: "rgba(68, 12, 48, 0.92)" } : {},
          text: isEliminated ? `☠️ ${Number(entry.cash) || 0}d (Eliminated)` : `${Number(entry.cash) || 0} Denarii (d)`,
        })
      ),
      sundayNode,
      el(
        "div",
        { style: { display: "flex", flexDirection: "column", gap: "0.3rem" } },
        el("div", { className: "final-section-label", text: "Ending Faction Standings" }),
        el("div", { className: "final-faction-strip" }, ...factionChips)
      ),
      el(
        "div",
        { style: { display: "flex", flexDirection: "column", gap: "0.3rem" } },
        el("div", { className: "final-section-label", text: "Expedition & Trade Ledger" }),
        el(
          "div",
          { className: "final-stats-grid" },
          ...coreStats.map(([lbl, val]) =>
            el(
              "div",
              { className: "final-stat-cell" },
              el("span", { className: "final-stat-lbl", text: lbl }),
              el("span", { className: "final-stat-val", text: val })
            )
          )
        )
      ),
      el(
        "div",
        { style: { display: "flex", flexDirection: "column", gap: "0.3rem" } },
        el("div", { className: "final-section-label", text: "Nocturnal Encounters in Rome" }),
        el(
          "div",
          { className: "final-encounters-row" },
          ...encounterStats.map(([lbl, count]) =>
            el(
              "span",
              { className: "final-encounter-chip" },
              el("span", { text: `${lbl}:` }),
              el("strong", { text: String(count) })
            )
          )
        )
      )
    );
  });

  const body = el(
    "div",
    { style: { display: "flex", flexDirection: "column", gap: "0.85rem" } },
    el(
      "div",
      { className: "final-scoring-banner" },
      el("img", {
        className: "final-scoring-mori-thumb",
        src: "/assets/rome_art/mosaic_memento_mori.jpg?v=30",
        alt: "Pompeii Fortune's Wheel Memento Mori Mosaic",
      }),
      el(
        "div",
        {},
        el("div", {
          className: "final-scoring-banner-title",
          text: `🏛️ Victory in Rome — ${winnerName} Triumphs!`,
        }),
        el("div", {
          className: "final-scoring-banner-sub",
          text: `${gameTitle}${meta.night ? ` • Concluded in ${meta.night}, 211 A.D.` : " • December 211 A.D. Reckoning"}`,
        })
      )
    ),
    rankingCards.length > 0
      ? el("div", { className: "final-rankings-list" }, ...rankingCards)
      : el("p", { style: { color: "var(--text-muted)", textAlign: "center" }, text: "No final player rankings recorded for this game." }),
    el(
      "div",
      {
        style: {
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          gap: "0.75rem",
          flexWrap: "wrap",
          marginTop: "0.35rem",
        },
      },
      el("button", {
        type: "button",
        className: "btn btn-sm",
        text: "📜 View All Completed Games",
        onClick: () => {
          closeModal();
          openCompletedGamesPage();
        },
      }),
      el("button", {
        type: "button",
        className: "btn btn-primary",
        text: "Close Final Ledger",
        onClick: closeModal,
      })
    )
  );

  showModal(`🏆 Final Scoring & Sunday Reckoning — ${gameTitle}`, body, { wide: true });
}

async function loadCompletedGames() {
  if (!appState.user) return;
  appState.completedGamesLoading = true;
  renderApp();
  try {
    const res = await apiRequest("/api/profile/completed-games");
    appState.completedGames = Array.isArray(res.completedGames) ? res.completedGames : [];
    if (res.user) {
      appState.user = { ...(appState.user || {}), ...res.user };
    }
  } catch (err) {
    showToast(err.message || "Failed to load completed games.", true);
  } finally {
    appState.completedGamesLoading = false;
    renderApp();
  }
}

function openCompletedGamesPage() {
  if (!appState.user) return;
  appState.activeTab = "completed_games";
  loadCompletedGames();
}

function renderCompletedGamesView() {
  const user = appState.user || {};
  const games = Array.isArray(appState.completedGames) ? appState.completedGames : [];

  const headerPanel = el(
    "div",
    { className: "panel" },
    el(
      "div",
      { className: "panel-title" },
      el("span", { text: `🏆 Completed Games & Final Scores — ${user.displayName || "Merchant"}` }),
      el(
        "div",
        { style: { display: "flex", gap: "0.5rem", flexWrap: "wrap" } },
        el("button", {
          type: "button",
          className: "btn btn-sm",
          text: "👤 Profile",
          onClick: () => {
            appState.activeTab = "profile";
            renderApp();
          },
        }),
        el("button", {
          type: "button",
          className: "btn btn-sm btn-primary",
          text: "← Back to Members Portal",
          onClick: async () => {
            appState.activeTab = "portal";
            await refreshPortalOverview();
            renderApp();
          },
        })
      )
    ),
    el("p", {
      style: { fontSize: "0.85rem", color: "var(--text-muted)", margin: "0.2rem 0 0.65rem" },
      text: "Every unique Roman expedition you have completed is recorded below with all participating merchants and their final Denarii scores. Each unique game counts at most once toward your total victories and expeditions played.",
    }),
    el(
      "div",
      { className: "completed-games-summary-grid" },
      el(
        "div",
        { className: "profile-stat-box" },
        el("div", { className: "stat-val", text: String(user.gamesPlayed || 0) }),
        el("div", { className: "stat-lbl", text: "Unique Games Completed" })
      ),
      el(
        "div",
        { className: "profile-stat-box" },
        el("div", { className: "stat-val", text: String(user.gamesWon || 0) }),
        el("div", { className: "stat-lbl", text: "Imperial Victories" })
      ),
      el(
        "div",
        { className: "profile-stat-box" },
        el("div", { className: "stat-val", text: `${user.bestWealth || 0}(d)` }),
        el("div", { className: "stat-lbl", text: "Best Final Score" })
      )
    )
  );

  let listContent = null;
  if (appState.completedGamesLoading && games.length === 0) {
    listContent = el(
      "div",
      { className: "panel", style: { textAlign: "center", padding: "2rem" } },
      el("p", { style: { color: "var(--gold-bright)" }, text: "Consulting the Imperial Tabularium..." })
    );
  } else if (games.length === 0) {
    listContent = el(
      "div",
      { className: "panel", style: { textAlign: "center", padding: "2rem" } },
      el("p", {
        style: { color: "var(--text-muted)", marginBottom: "0.85rem" },
        text: "You have not completed any expeditions yet. Finish a game through Saturday Clean-Up or Regicide to record your final standings!",
      }),
      el("button", {
        type: "button",
        className: "btn btn-primary",
        text: "🏛️ Return to Lobbies",
        onClick: async () => {
          appState.activeTab = "portal";
          await refreshPortalOverview();
          renderApp();
        },
      })
    );
  } else {
    listContent = el(
      "div",
      { style: { display: "flex", flexDirection: "column", gap: "0.85rem" } },
      ...games.map((g) => {
        const dateStr =
          g.completedAt && Number(g.completedAt) > 0
            ? new Date(Number(g.completedAt) * 1000).toLocaleDateString(undefined, {
              year: "numeric",
              month: "short",
              day: "numeric",
            })
            : "Anno Domini 211";
        const hasDetailedStats = Array.isArray(g.standings) && g.standings.length > 0;
        const players = Array.isArray(g.players) ? g.players : [];

        return el(
          "div",
          { className: `completed-game-card ${g.userWon ? "user-won-card" : ""}` },
          el(
            "div",
            { className: "completed-game-card-header" },
            el(
              "div",
              { style: { display: "flex", flexDirection: "column", gap: "0.2rem" } },
              el(
                "div",
                { style: { display: "flex", alignItems: "center", gap: "0.55rem", flexWrap: "wrap" } },
                el("strong", {
                  style: { fontFamily: "Cinzel, Georgia, serif", fontSize: "1.02rem", color: "var(--gold-bright)" },
                  text: g.gameName || "Roman Expedition",
                }),
                g.userWon
                  ? el("span", {
                    className: "badge",
                    style: { borderColor: "#b45309", color: "#7dd3fc", background: "rgba(14, 42, 84, 0.92)" },
                    text: "🏆 Victory",
                  })
                  : el("span", {
                    className: "badge",
                    text: g.userRank ? `Rank #${g.userRank}` : "Completed",
                  })
              ),
              el("div", {
                style: { fontSize: "0.78rem", color: "var(--text-muted)" },
                text: `Completed ${dateStr}${g.night ? ` • Ended in ${g.night}` : ""}${g.winnerName ? ` • Winner: ${g.winnerName}` : ""
                  }`,
              })
            ),
            el(
              "div",
              { style: { display: "flex", gap: "0.45rem", flexWrap: "wrap" } },
              hasDetailedStats
                ? el("button", {
                  type: "button",
                  className: "btn btn-sm btn-primary",
                  text: "📊 Full Stats & Rankings",
                  onClick: () =>
                    openFinalScoringModal(g.standings, {
                      gameName: g.gameName,
                      winnerName: g.winnerName,
                      night: g.night,
                    }),
                })
                : null,
              g.canReopenBoard
                ? el("button", {
                  type: "button",
                  className: "btn btn-sm",
                  text: "⚔️ Open Board",
                  onClick: () => openGame(g.gameId),
                })
                : null
            )
          ),
          el(
            "div",
            { className: "completed-game-players-list" },
            ...players.map((p, pIdx) => {
              const rk = Number(p.rank) || pIdx + 1;
              return el(
                "div",
                { className: `completed-game-player-row ${p.won ? "winner-row" : ""}` },
                el(
                  "div",
                  { style: { display: "flex", alignItems: "center", gap: "0.45rem", minWidth: "0" } },
                  el("strong", {
                    style: { color: p.won ? "#6e2119" : "var(--gold-bright)", fontSize: "0.82rem" },
                    text: `#${rk}`,
                  }),
                  renderSUVIconNode(p.color || "Z3", "", `${p.name}'s SUV`),
                  el("span", {
                    style: {
                      fontWeight: p.userId === user.id ? "800" : "600",
                      color: p.won ? "#6e2119" : "var(--text-main)",
                      fontSize: "0.86rem",
                    },
                    text: `${p.won ? "👑 " : ""}${p.name}${p.isBot ? " (AI)" : ""}`,
                  })
                ),
                el("strong", {
                  style: { color: "#754208", fontSize: "0.9rem", whiteSpace: "nowrap" },
                  text: `${Number(p.finalScore) || 0}(d)`,
                })
              );
            })
          )
        );
      })
    );
  }

  return el("div", { className: "completed-games-container" }, headerPanel, listContent);
}

async function handlePendingInviteDeepLink() {
  const targetGameId = String(appState.pendingInviteGameId || "").trim();
  if (!targetGameId || !appState.user || appState.user.needsUsernameSetup) return;
  appState.pendingInviteGameId = null;

  try {
    const urlObj = new URL(window.location.href);
    if (urlObj.searchParams.has("game")) {
      urlObj.searchParams.delete("game");
      window.history.replaceState({}, "", urlObj.pathname + urlObj.search + urlObj.hash);
    }
  } catch (_e) { }

  const matching = (appState.games || []).find((g) => String(g.id) === targetGameId);
  if (matching) {
    const alreadySeated = (matching.seats || []).some(
      (s) => !s.isBot && s.userId !== null && s.userId !== undefined && String(s.userId) === String(appState.user.id)
    );
    if (alreadySeated && matching.status !== "lobby") {
      await openGame(matching.id);
      return;
    }
    appState.activeTab = "portal";
    appState.highlightedLobbyId = matching.id;
    renderApp();
    setTimeout(() => {
      const cardEl = document.getElementById(`lobby-card-${matching.id}`);
      if (cardEl && typeof cardEl.scrollIntoView === "function") {
        cardEl.scrollIntoView({ behavior: "smooth", block: "center" });
      }
    }, 60);
    if (alreadySeated) {
      showToast(`Opened lobby for "${matching.name}".`);
    } else if (matching.canViewerJoin) {
      showToast(`Invited expedition "${matching.name}" is ready — click Claim Invited Seat to join!`);
    } else if (matching.status !== "lobby") {
      showToast(`Expedition "${matching.name}" has already started and is closed to new players.`, true);
    } else {
      showToast(
        `Expedition "${matching.name}" is Invite-Only. Sign in with your invited username (@handle) to claim a seat.`,
        true
      );
    }
  } else {
    showToast(`Expedition #${targetGameId} could not be found.`, true);
  }
}

async function handleGoogleSignInClick() {
  if (isFirebaseClientConfigured()) {
    try {
      const idToken = await signInWithFirebaseGooglePopup();
      const res = await apiRequest("/api/auth/firebase", "POST", { idToken });
      appState.user = res.user;
      appState.csrfToken = res.csrfToken || null;
      applyUserDefaultBoardView(res.user.settings);
      appState.activeTab = "portal";
      if (res.user && res.user.needsUsernameSetup) {
        showToast("Google account verified! Choose your permanent Collegium username to finish joining.");
        renderApp();
        return;
      }
      await refreshPortalOverview();
      showToast(`Signed in with Google as ${res.user.displayName} (${maskEmailClient(res.user.email)})!`);
      renderApp();
      await handlePendingInviteDeepLink();
    } catch (err) {
      showToast(err.message || "Google sign-in was cancelled or failed.", true);
    }
    return;
  }

  // Local offline development saturdayback when Firebase OAuth is not configured
  const emailInput = el("input", {
    className: "form-input",
    type: "email",
    placeholder: "e.g. mercator.romanus@gmail.com",
    value: "",
    autocomplete: "email",
  });
  const submitLocalGoogle = async () => {
    const emailVal = emailInput.value.trim();
    if (!emailVal || !emailVal.includes("@")) {
      showToast("Please enter a valid Google email address.", true);
      return;
    }
    try {
      const res = await apiRequest("/api/auth/google", "POST", {
        email: emailVal,
        displayName: emailVal.split("@")[0].replace(/\./g, " "),
        googleSub: `google_${emailVal.toLowerCase()}`,
      });
      appState.user = res.user;
      appState.csrfToken = res.csrfToken;
      applyUserDefaultBoardView(res.user.settings);
      appState.activeTab = "portal";
      closeModal();
      if (res.user && res.user.needsUsernameSetup) {
        showToast("Google account verified! Choose your permanent Collegium username to finish joining.");
        renderApp();
        return;
      }
      await refreshPortalOverview();
      showToast(`Signed in with Google as ${res.user.displayName} (${maskEmailClient(res.user.email)})!`);
      renderApp();
      await handlePendingInviteDeepLink();
    } catch (err) {
      showToast(err.message, true);
    }
  };
  showModal(
    "Local Dev — Simulate Google Sign-In",
    el(
      "div",
      {},
      el("div", { className: "form-group" }, el("label", { text: "Simulated Google Email Address" }), emailInput),
      el(
        "div",
        { style: { display: "flex", gap: "0.6rem", justifyContent: "flex-end", marginTop: "1rem" } },
        el("button", { type: "button", className: "btn", text: "Cancel", onClick: closeModal }),
        el("button", { type: "button", className: "btn btn-primary", text: "Continue", onClick: submitLocalGoogle })
      )
    )
  );
}

function renderGoogleUsernameSetupView() {
  const user = appState.user || {};
  const previewNode = el("div", {
    style: {
      fontSize: "0.84rem",
      color: "var(--gold-bright)",
      fontWeight: "700",
      marginTop: "0.35rem",
    },
    text: "Preview: @your_username",
  });
  const errorBox = el("div", {
    style: {
      display: "none",
      padding: "0.55rem 0.75rem",
      marginBottom: "0.85rem",
      borderRadius: "4px",
      background: "rgba(153, 27, 27, 0.12)",
      border: "1px solid #b91c1c",
      color: "#ff6ec7",
      fontSize: "0.84rem",
      fontWeight: "600",
    },
  });

  const unameInput = el("input", {
    className: "form-input",
    type: "text",
    placeholder: "e.g. marcus_ms13",
    maxLength: 34,
    autocomplete: "username",
    onInput: (e) => {
      const cleaned = String(e.target.value || "")
        .replace(/^@+/, "")
        .trim()
        .toLowerCase();
      previewNode.textContent = cleaned
        ? `Other players will invite you as: @${cleaned}`
        : "Preview: @your_username";
      errorBox.style.display = "none";
    },
  });

  let submitting = false;
  const submitBtn = el("button", {
    type: "submit",
    className: "btn btn-primary",
    style: { width: "100%", padding: "0.68rem", fontWeight: "700" },
    text: "Confirm Permanent Username & Enter Portal",
  });

  const handleConfirm = async (e) => {
    e.preventDefault();
    if (submitting) return;
    const rawVal = String(unameInput.value || "")
      .replace(/^@+/, "")
      .trim()
      .toLowerCase();
    if (rawVal.length < 3 || rawVal.length > 32) {
      errorBox.textContent = "Username must be between 3 and 32 characters.";
      errorBox.style.display = "block";
      return;
    }
    if (!/^[a-z0-9][a-z0-9_.-]*$/.test(rawVal)) {
      errorBox.textContent =
        "Username must start with a letter or number and contain only letters, numbers, underscores (_), hyphens (-), or periods (.).";
      errorBox.style.display = "block";
      return;
    }
    submitting = true;
    submitBtn.disabled = true;
    submitBtn.textContent = "Confirming Username…";
    try {
      const res = await apiRequest("/api/profile/set-username", "POST", { username: rawVal });
      appState.user = res.user;
      applyUserDefaultBoardView(res.user.settings);
      await refreshPortalOverview();
      showToast(`Salve, @${res.user.username}! Your permanent Collegium username is set.`);
      renderApp();
      await handlePendingInviteDeepLink();
    } catch (err) {
      submitting = false;
      submitBtn.disabled = false;
      submitBtn.textContent = "Confirm Permanent Username & Enter Portal";
      errorBox.textContent = err.message || "Could not save username.";
      errorBox.style.display = "block";
    }
  };

  return el(
    "div",
    { className: "portal-container" },
    el(
      "div",
      {
        className: "auth-card",
        style: { maxWidth: "520px", margin: "2rem auto" },
      },
      el("h2", {
        className: "panel-title fresco-banner-header fresco-merchants",
        text: "🏛️ Welcome — Choose Your Permanent Username",
      }),
      el("p", {
        style: { fontSize: "0.9rem", color: "var(--text-main)", marginTop: "0" },
        text: `Signed in with Google as ${user.displayName || "Merchant"} (${maskEmailClient(user.email)}).`,
      }),
      el(
        "div",
        {
          style: {
            padding: "0.65rem 0.85rem",
            marginBottom: "1rem",
            borderRadius: "4px",
            background: "rgba(34, 13, 62, 0.94)",
            border: "1px solid var(--gold)",
            boxShadow: "var(--bevel-sunken)",
            fontSize: "0.84rem",
            color: "var(--text-main)",
            lineHeight: "1.45",
          },
        },
        el("strong", { text: "Permanent Invite Handle: " }),
        el("span", {
          text: "Choose the permanent @username that other players will use to invite you to games. Once confirmed, your username cannot be changed (you can still customize your Display Name and SUV Color anytime in Player Profile).",
        })
      ),
      errorBox,
      el(
        "form",
        { onSubmit: handleConfirm },
        el(
          "div",
          { className: "form-group" },
          el("label", { text: "Permanent Collegium Username (3–32 characters)" }),
          unameInput,
          previewNode
        ),
        submitBtn
      )
    )
  );
}

function renderAuthView() {
  const isLogin = appState.authMode === "login";
  const usernameInput = el("input", {
    className: "form-input",
    type: "text",
    placeholder: isLogin ? "Username or email (e.g. marcus@ostia.it)" : "e.g. marcus_ms13",
    autocomplete: "username",
  });
  const emailInput = el("input", {
    className: "form-input",
    type: "email",
    placeholder: "e.g. marcus@collegium-ostia.org",
    autocomplete: "email",
  });
  const displayInput = el("input", {
    className: "form-input",
    type: "text",
    placeholder: "e.g. Marcus of Ostia",
  });
  const passwordInput = el("input", {
    className: "form-input",
    type: "password",
    placeholder: "Minimum 8 characters",
    autocomplete: isLogin ? "current-password" : "new-password",
  });

  let selectedColor = "Z3";
  const colorBtns = [];
  const colorPickerGrid = el(
    "div",
    { className: "color-swatch-grid" },
    ...SUV_COLOR_PALETTE.slice(0, 6).map((c) => {
      const btn = el(
        "button",
        {
          type: "button",
          className: `color-swatch-option ${c.id === selectedColor ? "selected" : ""}`,
          onClick: () => {
            selectedColor = c.id;
            colorBtns.forEach((item) => item.node.classList.toggle("selected", item.id === selectedColor));
          },
        },
        renderSUVIconNode(c.id, "", c.label),
        el("span", { text: c.label })
      );
      colorBtns.push({ id: c.id, node: btn });
      return btn;
    })
  );

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const endpoint = isLogin ? "/api/auth/login" : "/api/auth/register";
      const payload = {
        username: usernameInput.value.trim(),
        password: passwordInput.value,
      };
      if (!isLogin) {
        payload.email = emailInput.value.trim();
        payload.displayName = displayInput.value.trim() || usernameInput.value.trim();
        payload.preferredColor = selectedColor;
      }
      const res = await apiRequest(endpoint, "POST", payload);
      if (isFirebaseClientConfigured()) {
        if (res.firebaseCustomToken) {
          await signInWithFirebaseCustomToken(res.firebaseCustomToken);
        } else if (res.user && res.user.email && payload.password) {
          await signInWithFirebaseEmailPassword(res.user.email, payload.password);
        }
      }
      appState.user = res.user;
      appState.csrfToken = res.csrfToken || null;
      applyUserDefaultBoardView(res.user.settings);
      await refreshPortalOverview();
      showToast(`Salve, ${res.user.displayName}! Welcome to the Collegium Mercatorum.`);
      renderApp();
      await handlePendingInviteDeepLink();
    } catch (err) {
      showToast(err.message, true);
    }
  };

  const handleQuickDemo = async () => {
    try {
      const res = await apiRequest("/api/auth/demo", "POST", {});
      appState.user = res.user;
      appState.csrfToken = res.csrfToken || null;
      applyUserDefaultBoardView(res.user.settings);
      await refreshPortalOverview();
      showToast(`Signed in to local sandbox as ${res.user.displayName}!`);
      renderApp();
      await handlePendingInviteDeepLink();
    } catch (err) {
      showToast(err.message, true);
    }
  };

  const pajouHoverTitle =
    "ISIS Dying in his Mother's Arms, Jacques-Augustin-Catherine Pajou, 1766–1828 (Staatsgalerie Stuttgart)";

  const showcaseCard = el(
    "section",
    { className: "panel landing-showcase-card" },
    el(
      "div",
      { className: "panel-title fresco-banner-header fresco-griffin" },
      el("span", { text: "🚙 San Francisco, After Dark — InstantGram SF" }),
      el("span", { style: { fontSize: "0.78rem", color: "#fde6b0" }, text: "2–6 Merchants • Strategy Board Game" })
    ),
    el(
      "figure",
      {
        className: "landing-pajou-figure",
        title: pajouHoverTitle,
      },
      el("img", {
        className: "landing-pajou-img",
        src: "/assets/rome_art/isis_dying_pajou.jpg",
        alt: pajouHoverTitle,
        title: pajouHoverTitle,
      }),
      el(
        "figcaption",
        { className: "landing-pajou-caption" },
        el("em", { text: "ISIS Dying in his Mother's Arms" }),
        el("span", {
          text: " — Jacques-Augustin-Catherine Pajou, 1766–1828 (Staatsgalerie Stuttgart)",
        })
      )
    ),
    el(
      "div",
      { className: "landing-blurb-body" },
      el("p", {
        className: "landing-blurb-lead",
        text: "Emperor Septimius Severus is dead in Britain, leaving Rome in the volatile grip of his feuding sons, MAGA and ISIS. By day, Julius Caesar's Lex Iulia Municipalis bars heavy freight wagons from the capital's streets. Only when dusk saturdays at 8:00 P.M. do the city gates swing open—and the Night Merchants roll in.",
      }),
      el("p", {
        className: "landing-blurb-text",
        text: "Bid for Grain, Wine, Marble, Weapons, and Exotic Beasts at Portus Ostiae, hire gladiators and henchmen, and thread 36 torchlit neighborhoods across five ancient stone bridges of the Tiber before the 6:00 A.M. sunrise curfew. Court five rival Severan factions—Empress Julia TECH, exiled DSA, the old MS13 Senate, and the warring co-emperors—before December 211's bloody Sunday Reckoning crowns Rome's wealthiest purveyor.",
      }),
      el(
        "div",
        { className: "landing-cta-row" },
        el("button", {
          type: "button",
          className: "btn btn-primary",
          text: "📜 Read the Official Rulebook",
          onClick: () => {
            appState.activeTab = "rulebook";
            renderApp();
          },
        }),
        el("span", {
          className: "landing-cta-note",
          text: "Play solo against 5 distinct Roman AI personas or host live & async 2–6 player games.",
        })
      )
    )
  );

  const authCard = el(
    "div",
    { className: "auth-card landing-auth-card" },
    el("h2", {
      className: "panel-title fresco-banner-header fresco-merchants",
      text: "🏛️ Collegium Mercatorum — Members Portal",
    }),
    appState.pendingInviteGameId
      ? el(
        "div",
        {
          style: {
            padding: "0.6rem 0.8rem",
            marginBottom: "0.85rem",
            borderRadius: "4px",
            background: "rgba(180, 83, 9, 0.12)",
            border: "1px solid var(--gold)",
            fontSize: "0.84rem",
            color: "var(--text-main)",
          },
          text: `✉️ Expedition Invitation (#${appState.pendingInviteGameId}): Sign in with your invited Collegium account to claim your seat.`,
        }
      )
      : null,
    el("p", {
      style: { color: "var(--text-muted)", fontSize: "0.88rem", marginTop: "0" },
      text: "Sign in with your Email, Username, or Google Account to host multiplayer games, challenge AI merchants, customize your suv, and climb the Imperial Leaderboard.",
    }),
    el(
      "div",
      { style: { display: "flex", gap: "0.5rem", marginBottom: "1rem", flexWrap: "wrap" } },
      el("button", {
        className: `btn ${isLogin ? "btn-primary" : ""}`,
        style: { flex: "1 1 140px" },
        text: "Member Sign In",
        onClick: () => {
          appState.authMode = "login";
          renderApp();
        },
      }),
      el("button", {
        className: `btn ${!isLogin ? "btn-primary" : ""}`,
        style: { flex: "1 1 140px" },
        text: "Register New Member",
        onClick: () => {
          appState.authMode = "register";
          renderApp();
        },
      })
    ),
    el(
      "button",
      {
        type: "button",
        className: "btn-google",
        onClick: handleGoogleSignInClick,
      },
      renderGoogleLogoSvg(),
      el("span", { text: "Sign in with Google" })
    ),
    el("div", { className: "auth-divider", text: "or continue with email & password" }),
    el(
      "form",
      { onSubmit: handleSubmit },
      el(
        "div",
        { className: "form-group" },
        el("label", { text: isLogin ? "Username or Email Address" : "Username" }),
        usernameInput
      ),
      !isLogin
        ? el("div", { className: "form-group" }, el("label", { text: "Email Address (Required)" }), emailInput)
        : null,
      !isLogin
        ? el("div", { className: "form-group" }, el("label", { text: "Roman Merchant Title / Display Name" }), displayInput)
        : null,
      !isLogin
        ? el("div", { className: "form-group" }, el("label", { text: "Preferred Merchant SUV" }), colorPickerGrid)
        : null,
      el("div", { className: "form-group" }, el("label", { text: "Password (8+ characters)" }), passwordInput),
      el(
        "button",
        { type: "submit", className: "btn btn-primary", style: { width: "100%", padding: "0.65rem" } },
        isLogin ? "Enter the Port of Ostia" : "Register Account & Enter Portal"
      )
    ),
    !isFirebaseClientConfigured()
      ? el(
        "div",
        { style: { marginTop: "1rem", paddingTop: "1rem", borderTop: "1px solid var(--border-subtle)", textAlign: "center" } },
        el("button", {
          type: "button",
          className: "btn btn-crimson",
          style: { width: "100%" },
          text: "⚡ Instant One-Click Local Sandbox Login",
          onClick: handleQuickDemo,
        })
      )
      : null
  );

  return el(
    "div",
    { className: "portal-container" },
    el("div", { className: "landing-hero-grid" }, authCard, showcaseCard)
  );
}

const DEFAULT_BOT_PERSONAS = [
  { strategy: "balanced", name: "Marcus Mercator", title: "Ostia Grain & Wine Syndic" },
  { strategy: "luxury", name: "Cornelia Severa", title: "Palatine Marble Purveyor" },
  { strategy: "aggressive", name: "Titus Valerius", title: "Gladiator & Beasts Contractor" },
  { strategy: "missions", name: "Julia Lucilla", title: "Senatorial Courier" },
  { strategy: "opportunist", name: "Gaius Fulvius", title: "Subura Night Runner" },
];

function getBotPersonasCatalog() {
  return Array.isArray(appState.botPersonas) && appState.botPersonas.length > 0
    ? appState.botPersonas
    : DEFAULT_BOT_PERSONAS;
}

function buildPortalGamesListNodes() {
  if (!Array.isArray(appState.games) || appState.games.length === 0) {
    return [
      el("p", {
        style: { color: "var(--text-muted)" },
        text: "No games created yet. Use the panel on the left to launch a match!",
      }),
    ];
  }
  return appState.games.map((g) => renderLobbyItem(g));
}

function buildPortalLeaderboardNodes() {
  if (!Array.isArray(appState.leaderboard) || appState.leaderboard.length === 0) {
    return [
      el("p", {
        style: { color: "var(--text-muted)", fontSize: "0.82rem", margin: "0.35rem 0" },
        text: "No multiplayer expeditions (2+ human merchants) completed yet. Solo vs. AI games remain recorded in your personal Completed Games ledger.",
      }),
    ];
  }
  return appState.leaderboard.map((row, idx) => {
    const isCurrentUser = Boolean(
      appState.user &&
      ((row.userId !== undefined && row.userId === appState.user.id) ||
        row.displayName === appState.user.displayName)
    );
    const scoreLabel = `${row.gamesWon}W / ${row.gamesPlayed}G | Best: ${row.bestWealth}(d)`;
    return el(
      "div",
      { className: "item-row" },
      el(
        "div",
        { style: { display: "flex", alignItems: "center", gap: "0.5rem" } },
        el("strong", { style: { color: "var(--gold-bright)" }, text: `#${idx + 1}` }),
        renderSUVIconNode(row.preferredColor, "", `${row.displayName}'s SUV`),
        el("span", { text: row.displayName })
      ),
      isCurrentUser
        ? el("button", {
          type: "button",
          className: "wins-best-inline-link",
          title: "Click to view your completed games & final scores",
          text: scoreLabel,
          onClick: () => openCompletedGamesPage(),
        })
        : el(
          "div",
          { style: { fontSize: "0.78rem", color: "var(--text-muted)" } },
          scoreLabel
        )
    );
  });
}

function parseUsernameTokensClient(rawStr) {
  if (!rawStr || typeof rawStr !== "string") return [];
  const seen = new Set();
  const out = [];
  for (const part of rawStr.split(/[\s,;]+/)) {
    const clean = part.replace(/^@+/, "").trim().toLowerCase();
    if (clean && !seen.has(clean)) {
      seen.add(clean);
      out.push(clean);
    }
  }
  return out;
}

function renderPortalView() {
  const personas = getBotPersonasCatalog();
  if (!Array.isArray(appState.portalBotStrategies) || appState.portalBotStrategies.length < 5) {
    appState.portalBotStrategies = ["balanced", "luxury", "aggressive", "faction", "opportunist"];
  }
  if (!appState.portalInviteMode) {
    appState.portalInviteMode = "open";
  }
  const initialMaxP = appState.portalMaxPlayers || 3;
  const initialBots = typeof appState.portalBotCount === "number" ? appState.portalBotCount : 1;

  const nameInput = el("input", {
    className: "form-input",
    type: "text",
    value: appState.portalDraftName || `${appState.user.displayName}'s Expedition`,
    onInput: (e) => {
      appState.portalDraftName = e.target.value;
    },
  });
  const maxPlayersSelect = el(
    "select",
    {
      className: "form-input",
      onChange: (e) => {
        appState.portalMaxPlayers = Number(e.target.value) || 3;
      },
    },
    ...[2, 3, 4, 5, 6].map((n) =>
      el("option", { value: String(n), selected: n === initialMaxP, text: `${n} Merchants (Max Seats)` })
    )
  );

  const botStrategiesBox = el("div", { style: { display: "flex", flexDirection: "column", gap: "0.38rem" } });

  const rebuildBotPersonaRows = (count) => {
    if (count <= 0) {
      botStrategiesBox.replaceChildren();
      return;
    }
    const rows = [];
    rows.push(
      el("label", {
        style: { fontSize: "0.76rem", fontWeight: "700", color: "var(--gold-bright)", marginTop: "0.15rem" },
        text: "AI Bot Personas & Playstyles:",
      })
    );
    for (let i = 0; i < count; i++) {
      const currStrat = appState.portalBotStrategies[i] || personas[i % personas.length].strategy;
      appState.portalBotStrategies[i] = currStrat;
      const sel = el(
        "select",
        {
          className: "form-input",
          style: { padding: "0.3rem 0.5rem", fontSize: "0.78rem" },
          onChange: (e) => {
            appState.portalBotStrategies[i] = e.target.value;
          },
        },
        ...personas.map((p) =>
          el("option", {
            value: p.strategy,
            selected: p.strategy === currStrat,
            text: `${p.name} — ${p.title || p.strategy}`,
          })
        )
      );
      rows.push(
        el(
          "div",
          { className: "bot-persona-row" },
          el("span", {
            style: { fontSize: "0.76rem", fontWeight: "700", color: "var(--text-muted)", minWidth: "46px" },
            text: `Bot ${i + 1}:`,
          }),
          sel
        )
      );
    }
    botStrategiesBox.replaceChildren(...rows);
  };

  const botCountSelect = el(
    "select",
    {
      className: "form-input",
      onChange: (e) => {
        const cnt = Math.max(0, Math.min(5, Number(e.target.value) || 0));
        appState.portalBotCount = cnt;
        rebuildBotPersonaRows(cnt);
      },
    },
    ...[0, 1, 2, 3, 4, 5].map((n) =>
      el("option", { value: String(n), selected: n === initialBots, text: `${n} AI Bot Opponent${n === 1 ? "" : "s"}` })
    )
  );
  rebuildBotPersonaRows(initialBots);

  const ensureHumanSeatCapacity = (neededHumanGuests = 1) => {
    let currBots = Math.max(0, Math.min(5, Number(botCountSelect.value) || 0));
    let currMax = Number(maxPlayersSelect.value) || 3;
    const minNeededMax = Math.min(6, 1 + currBots + Math.max(1, neededHumanGuests));
    if (currMax < minNeededMax) {
      currMax = minNeededMax;
      maxPlayersSelect.value = String(currMax);
      appState.portalMaxPlayers = currMax;
    }
    if (1 + currBots >= currMax) {
      currBots = Math.max(0, currMax - 2);
      botCountSelect.value = String(currBots);
      appState.portalBotCount = currBots;
      rebuildBotPersonaRows(currBots);
    }
  };

  const invitePillsSlot = el("div", { className: "invite-pill-row" });
  const refreshInvitePreviewPills = () => {
    const parsed = parseUsernameTokensClient(appState.portalInvitedUsernames || "");
    if (parsed.length === 0) {
      invitePillsSlot.replaceChildren(
        el("span", {
          style: { fontSize: "0.7rem", color: "var(--text-muted)" },
          text: "Enter one or more registered Night Merchant usernames above.",
        })
      );
      return;
    }
    invitePillsSlot.replaceChildren(
      ...parsed.map((uname) => el("span", { className: "invite-user-pill", text: `@${uname}` }))
    );
    ensureHumanSeatCapacity(parsed.length);
  };

  const invitedUsernamesInput = el("input", {
    className: "form-input",
    type: "text",
    placeholder: "e.g. marcus_ms13, cornelia_severa",
    value: appState.portalInvitedUsernames || "",
    onInput: (e) => {
      appState.portalInvitedUsernames = e.target.value;
      refreshInvitePreviewPills();
    },
  });
  refreshInvitePreviewPills();

  const inviteUsernamesContainer = el(
    "div",
    {
      className: "invite-usernames-box",
      style: { display: appState.portalInviteMode === "invite_only" ? "block" : "none" },
    },
    el("label", {
      style: { display: "block", fontSize: "0.75rem", fontWeight: "700", marginBottom: "0.25rem", color: "var(--crimson)" },
      text: "Invited Player Username(s):",
    }),
    invitedUsernamesInput,
    invitePillsSlot,
    el("div", {
      style: { fontSize: "0.69rem", color: "var(--text-muted)", marginTop: "0.35rem", lineHeight: "1.3" },
      text: "An invitation email is sent to each invited player's email on file. Only invited players can claim empty seats, and joining closes once you start the game.",
    })
  );

  const openLobbyBtn = el("button", {
    className: "btn",
    text:
      appState.portalInviteMode === "invite_only"
        ? "✉️ Create Invite-Only Lobby & Email Invites"
        : "🌐 Open Multiplayer Lobby (Open Invitation)",
    onClick: () => createGame(false),
  });

  const openModeBtn = el(
    "button",
    {
      type: "button",
      className: `invite-mode-card ${appState.portalInviteMode === "open" ? "selected" : ""}`,
      onClick: () => {
        appState.portalInviteMode = "open";
        openModeBtn.classList.add("selected");
        inviteOnlyModeBtn.classList.remove("selected");
        inviteUsernamesContainer.style.display = "none";
        openLobbyBtn.textContent = "🌐 Open Multiplayer Lobby (Open Invitation)";
      },
    },
    el("span", { className: "invite-mode-card-title", text: "🌐 Open Invitation" }),
    el("span", {
      className: "invite-mode-card-sub",
      text: "Any logged-in player can claim an empty seat until you start.",
    })
  );

  const inviteOnlyModeBtn = el(
    "button",
    {
      type: "button",
      className: `invite-mode-card ${appState.portalInviteMode === "invite_only" ? "selected" : ""}`,
      onClick: () => {
        appState.portalInviteMode = "invite_only";
        inviteOnlyModeBtn.classList.add("selected");
        openModeBtn.classList.remove("selected");
        inviteUsernamesContainer.style.display = "block";
        openLobbyBtn.textContent = "✉️ Create Invite-Only Lobby & Email Invites";
        const parsed = parseUsernameTokensClient(appState.portalInvitedUsernames || "");
        ensureHumanSeatCapacity(Math.max(1, parsed.length));
      },
    },
    el("span", { className: "invite-mode-card-title", text: "🔒 Invite Only" }),
    el("span", {
      className: "invite-mode-card-sub",
      text: "Email specific username(s); only invited players can claim seats.",
    })
  );

  const createGame = async (startImmediately) => {
    try {
      if (!startImmediately) {
        const parsedGuests =
          appState.portalInviteMode === "invite_only"
            ? parseUsernameTokensClient(invitedUsernamesInput.value)
            : [];
        if (appState.portalInviteMode === "invite_only" && parsedGuests.length === 0) {
          showToast("Please enter at least one username to invite for an Invite-Only game.", true);
          invitedUsernamesInput.focus();
          return;
        }
        ensureHumanSeatCapacity(Math.max(1, parsedGuests.length));
      }
      const bCount = Math.max(0, Math.min(5, Number(botCountSelect.value) || 0));
      const modeToSend = startImmediately ? "open" : appState.portalInviteMode || "open";
      const res = await apiRequest("/api/games/create", "POST", {
        name: nameInput.value.trim(),
        maxPlayers: Number(maxPlayersSelect.value),
        botCount: bCount,
        botStrategies: appState.portalBotStrategies.slice(0, bCount),
        startImmediately,
        inviteMode: modeToSend,
        invitedUsernames: modeToSend === "invite_only" ? invitedUsernamesInput.value.trim() : "",
      });
      await refreshPortalOverview();
      if (startImmediately && res.state) {
        appState.currentGameId = res.summary.id;
        appState.gameSummary = res.summary;
        appState.gameState = res.state;
        stopNpcTurnPacing();
        enqueueNewNpcEvents(res.state, true);
        seedSeenScoutIds(res.state);
        appState.activeTab = "tabletop";
        showToast("Expedition launched! Select 2 Missions & 2 Influence cards to discard.");
      } else if (modeToSend === "invite_only") {
        appState.portalInvitedUsernames = "";
        invitedUsernamesInput.value = "";
        refreshInvitePreviewPills();
        const sentCnt = res.emailDispatch ? Number(res.emailDispatch.sentCount || 0) : 0;
        if (sentCnt > 0) {
          showToast(`Invite-Only lobby created! Sent ${sentCnt} invitation email${sentCnt === 1 ? "" : "s"}.`);
        } else {
          showToast("Invite-Only lobby created! Only your invited players can claim empty seats.");
        }
      } else {
        showToast("Open Invitation lobby created! Any logged-in player can claim an empty seat until you start.");
      }
      renderApp();
    } catch (err) {
      showToast(err.message, true);
    }
  };

  const createPanel = el(
    "div",
    { className: "panel" },
    el("h3", { className: "panel-title fresco-banner-header fresco-merchants", text: "⚓ Launch New Game / Lobby" }),
    el("div", { className: "form-group" }, el("label", { text: "Convivium / Table Name" }), nameInput),
    el("div", { className: "form-group" }, el("label", { text: "Maximum Players (2–6)" }), maxPlayersSelect),
    el("div", { className: "form-group" }, el("label", { text: "Initial AI Bot Opponents" }), botCountSelect),
    botStrategiesBox,
    el(
      "div",
      { className: "form-group", style: { marginTop: "0.75rem" } },
      el("label", { text: "Human Opponent Lobby Access" }),
      el("div", { className: "invite-mode-grid" }, openModeBtn, inviteOnlyModeBtn),
      inviteUsernamesContainer
    ),
    el(
      "div",
      { style: { display: "flex", flexDirection: "column", gap: "0.55rem", marginTop: "1rem" } },
      openLobbyBtn,
      el("button", {
        className: "btn btn-primary",
        text: "⚔️ Start Match Immediately (Solo vs. AI Bots)",
        onClick: () => createGame(true),
      })
    ),
    el(
      "div",
      { style: { marginTop: "1.1rem", fontSize: "0.8rem", color: "var(--text-muted)", lineHeight: "1.4" } },
      el("strong", { style: { color: "var(--gold-bright)" }, text: "211 A.D. Overview: " }),
      "Each game spans 3 Nights (Thursday, Friday, Saturday) plus the December 211 Purge. Buy Goods & Henchmen at Portus Ostiae, enter Rome at dusk to navigate 36 nocturnal neighborhoods, fulfill Missions, court 5 Severan Factions, and exit before Sunrise!"
    )
  );

  const gamesList = el(
    "div",
    { className: "panel" },
    el(
      "h3",
      { className: "panel-title fresco-banner-header fresco-suv" },
      el("span", { text: "🗺️ Active Games & Open Lobbies" }),
      el("button", {
        className: "btn btn-sm",
        text: "↻ Refresh",
        onClick: async () => {
          await refreshPortalOverview();
          renderApp();
        },
      })
    ),
    el("div", { id: "portal-games-list-slot" }, ...buildPortalGamesListNodes())
  );

  const leaderboardPanel = el(
    "div",
    { className: "panel" },
    el("h3", { className: "panel-title fresco-banner-header fresco-griffin", text: "🏆 Imperial Merchant Leaderboard" }),
    el("div", {
      style: { fontSize: "0.74rem", color: "var(--text-muted)", marginBottom: "0.55rem" },
      text: "Multiplayer standings across completed games with 2+ human merchants.",
    }),
    el(
      "div",
      { id: "portal-leaderboard-slot", className: "item-list" },
      ...buildPortalLeaderboardNodes()
    )
  );

  return el(
    "div",
    { className: "portal-container" },
    el("div", { className: "portal-grid" }, createPanel, gamesList, leaderboardPanel)
  );
}

function openTerminateGameModal(g) {
  let isDeleting = false;
  const confirmBtn = el("button", {
    type: "button",
    className: "btn btn-crimson",
    text: "🗑️ Confirm Terminate Game",
    onClick: async () => {
      if (isDeleting) return;
      isDeleting = true;
      confirmBtn.disabled = true;
      try {
        const res = await apiRequest(`/api/games/${g.id}/terminate`, "POST", {});
        closeModal();
        if (appState.currentGameId === g.id) {
          appState.currentGameId = null;
          appState.gameSummary = null;
          appState.gameState = null;
          stopNpcTurnPacing();
          if (appState.activeTab === "tabletop") {
            appState.activeTab = "portal";
          }
        }
        await refreshPortalOverview();
        showToast(res.message || `Terminated '${g.name}'.`);
        renderApp();
      } catch (err) {
        isDeleting = false;
        confirmBtn.disabled = false;
        showToast(err.message, true);
      }
    },
  });

  showModal(
    `🗑️ Terminate Game — ${g.name}?`,
    el(
      "div",
      {},
      el("p", {
        style: { fontSize: "0.9rem", color: "var(--text-main)", marginTop: "0" },
        text: `Are you sure you want to permanently terminate "${g.name}"? This will immediately end and remove the game for all seated players.`,
      }),
      el(
        "div",
        {
          style: {
            padding: "0.55rem 0.75rem",
            borderRadius: "4px",
            background: "rgba(68, 12, 48, 0.92)",
            border: "1.5px solid #dc2626",
            fontSize: "0.82rem",
            color: "#fbcfe8",
            marginBottom: "0.9rem",
            boxShadow: "var(--bevel-sunken)",
          },
        },
        `Status: ${g.status === "lobby" ? "Lobby" : `${g.night} • ${g.phase} • Turn ${g.turn}`} • Seated Merchants: ${(g.seats || [])
          .map((s) => s.name)
          .join(", ") || "None"}`
      ),
      el(
        "div",
        { style: { display: "flex", gap: "0.6rem", justifyContent: "flex-end" } },
        el("button", { type: "button", className: "btn", text: "Keep Game", onClick: closeModal }),
        confirmBtn
      )
    )
  );
}

function renderLobbyItem(g) {
  const isHost = g.hostUserId === appState.user.id;
  const isAdmin = Boolean(appState.user && appState.user.isAdmin);
  const canTerminate = isHost || isAdmin;
  const isSeated = (g.seats || []).some((s) => s.userId === appState.user.id);
  const isLobby = g.status === "lobby";
  const inviteMode = g.inviteMode === "invite_only" ? "invite_only" : "open";
  const canJoinSeat = Boolean(g.canViewerJoin !== undefined ? g.canViewerJoin : inviteMode === "open");
  const personas = getBotPersonasCatalog();

  const seatNodes = (g.seats || []).map((s) =>
    el(
      "span",
      { className: "seat-pill" },
      renderSUVIconNode(s.color, "", `${s.name}'s SUV`),
      isLobby && isHost && s.isBot
        ? el(
          "select",
          {
            className: "form-input",
            style: { padding: "0.1rem 0.35rem", fontSize: "0.74rem", width: "auto" },
            title: "Change AI Bot Persona",
            onChange: async (e) => {
              try {
                await apiRequest(`/api/games/${g.id}/update-bot`, "POST", {
                  seatIndex: s.seatIndex,
                  strategy: e.target.value,
                });
                await refreshPortalOverview();
                renderApp();
              } catch (err) {
                showToast(err.message, true);
              }
            },
          },
          ...personas.map((p) =>
            el("option", {
              value: p.strategy,
              selected: p.strategy === s.botStrategy,
              text: `${p.name} [${p.strategy}]`,
            })
          )
        )
        : el("span", { text: `${s.name}${s.isBot ? ` [AI: ${s.botStrategy}]` : ""}` }),
      isLobby && isHost && s.seatIndex > 0
        ? el("button", {
          className: "btn btn-sm",
          style: { padding: "0.05rem 0.35rem", marginLeft: "0.2rem" },
          text: "✕",
          onClick: async () => {
            try {
              await apiRequest(`/api/games/${g.id}/remove-seat`, "POST", { seatIndex: s.seatIndex });
              await refreshPortalOverview();
              renderApp();
            } catch (err) {
              showToast(err.message, true);
            }
          },
        })
        : null
    )
  );

  let inviteListRow = null;
  if (inviteMode === "invite_only" && Array.isArray(g.invites) && g.invites.length > 0) {
    inviteListRow = el(
      "div",
      { className: "invite-pill-row", style: { marginTop: "0.4rem" } },
      el("span", {
        style: { fontSize: "0.72rem", fontWeight: "700", color: "var(--text-muted)" },
        text: "Invited:",
      }),
      ...g.invites.map((inv) =>
        el("span", {
          className: `invite-user-pill ${inv.seated ? "seated" : ""}`,
          title: inv.displayName || inv.username,
          text: inv.seated ? `@${inv.username} ✓` : `@${inv.username}`,
        })
      )
    );
  }

  let hostExtraInviteRow = null;
  if (isLobby && isHost && inviteMode === "invite_only" && (g.seats || []).length < g.maxPlayers) {
    const extraInput = el("input", {
      className: "form-input",
      type: "text",
      placeholder: "Invite @username...",
      style: { padding: "0.2rem 0.45rem", fontSize: "0.75rem", width: "160px" },
    });
    const sendExtraInvite = async () => {
      const val = extraInput.value.trim();
      if (!val) return;
      try {
        const res = await apiRequest(`/api/games/${g.id}/invite`, "POST", { usernames: val });
        extraInput.value = "";
        await refreshPortalOverview();
        const sentCnt = res.emailDispatch ? Number(res.emailDispatch.sentCount || 0) : 0;
        showToast(sentCnt > 0 ? `${res.message} (Email invite sent!)` : res.message || "Invite added.");
        renderApp();
      } catch (err) {
        showToast(err.message, true);
      }
    };
    extraInput.addEventListener("keydown", (ev) => {
      if (ev.key === "Enter") {
        ev.preventDefault();
        sendExtraInvite();
      }
    });
    hostExtraInviteRow = el(
      "div",
      { style: { display: "flex", gap: "0.35rem", alignItems: "center", marginTop: "0.4rem" } },
      extraInput,
      el("button", {
        type: "button",
        className: "btn btn-sm",
        text: "✉️ Send Invite",
        onClick: sendExtraInvite,
      })
    );
  }

  const actionBtns = [];
  if (isLobby) {
    if (!isSeated && (g.seats || []).length < g.maxPlayers) {
      if (canJoinSeat) {
        actionBtns.push(
          el("button", {
            className: "btn btn-sm btn-primary",
            text: inviteMode === "invite_only" ? "✉️ Claim Invited Seat" : "Join Seat",
            onClick: async () => {
              try {
                await apiRequest(`/api/games/${g.id}/join`, "POST", {});
                if (appState.highlightedLobbyId === g.id) {
                  appState.highlightedLobbyId = null;
                }
                await refreshPortalOverview();
                showToast("Claimed your merchant seat in the lobby!");
                renderApp();
              } catch (err) {
                showToast(err.message, true);
              }
            },
          })
        );
      } else {
        actionBtns.push(
          el("span", {
            style: { fontSize: "0.74rem", fontWeight: "700", color: "var(--text-muted)" },
            text: "🔒 Invite-Only (Invited Players Only)",
          })
        );
      }
    }
    if (isHost && (g.seats || []).length < g.maxPlayers) {
      const defaultAddPersona = personas[(g.seats || []).length % personas.length];
      const addBotStratSelect = el(
        "select",
        {
          className: "form-input",
          style: { padding: "0.2rem 0.45rem", fontSize: "0.75rem", width: "auto" },
          title: "Select AI Bot Persona to Add",
        },
        ...personas.map((p) =>
          el("option", {
            value: p.strategy,
            selected: p.strategy === defaultAddPersona.strategy,
            text: `${p.name} (${p.strategy})`,
          })
        )
      );
      actionBtns.push(
        addBotStratSelect,
        el("button", {
          className: "btn btn-sm",
          text: "+ Add AI Bot",
          onClick: async () => {
            try {
              await apiRequest(`/api/games/${g.id}/add-bot`, "POST", {
                strategy: addBotStratSelect.value,
                personaIndex: (g.seats || []).length,
              });
              await refreshPortalOverview();
              renderApp();
            } catch (err) {
              showToast(err.message, true);
            }
          },
        })
      );
    }
    if (isHost && (g.seats || []).length >= 2) {
      actionBtns.push(
        el("button", {
          className: "btn btn-sm btn-crimson",
          text: "Start Game ⚔️",
          onClick: async () => {
            try {
              const res = await apiRequest(`/api/games/${g.id}/start`, "POST", {});
              appState.currentGameId = g.id;
              appState.gameSummary = res.summary;
              appState.gameState = res.state;
              stopNpcTurnPacing();
              enqueueNewNpcEvents(res.state, true);
              seedSeenScoutIds(res.state);
              syncGameUiTransitions(res.state, true);
              appState.activeTab = "tabletop";
              renderApp();
            } catch (err) {
              showToast(err.message, true);
            }
          },
        })
      );
    }
  } else {
    actionBtns.push(
      el("button", {
        className: "btn btn-sm btn-primary",
        text: g.status === "finished" ? "View Final Scoreboard" : "Enter Tabletop ⚔️",
        onClick: () => openGame(g.id),
      })
    );
  }

  if (canTerminate) {
    actionBtns.push(
      el("button", {
        className: "btn btn-sm",
        style: {
          borderColor: "#dc2626",
          color: "#ff6ec7",
          marginLeft: "auto",
        },
        title: isAdmin && !isHost ? "Terminate Game (Admin)" : "Terminate Game (Creator)",
        text: "🗑️ Terminate Game",
        onClick: () => openTerminateGameModal(g),
      })
    );
  }

  let accessBadge = null;
  if (isLobby) {
    if (inviteMode === "invite_only") {
      if (g.viewerIsInvited && !isHost && !isSeated) {
        accessBadge = el("span", { className: "invite-access-badge invited-me", text: "✉️ You're Invited!" });
      } else {
        accessBadge = el("span", { className: "invite-access-badge invite-only", text: "🔒 Invite Only" });
      }
    } else {
      accessBadge = el("span", { className: "invite-access-badge open", text: "🌐 Open Invitation" });
    }
  }

  return el(
    "div",
    {
      id: `lobby-card-${g.id}`,
      className: `lobby-card ${appState.highlightedLobbyId === g.id ? "lobby-highlighted" : ""}`,
    },
    el(
      "div",
      { className: "lobby-header" },
      el(
        "div",
        { style: { display: "flex", alignItems: "center", gap: "0.45rem", flexWrap: "wrap" } },
        el("strong", { style: { fontSize: "1rem", color: "var(--gold-bright)" }, text: g.name }),
        accessBadge
      ),
      el("span", {
        className: "badge",
        text:
          g.status === "lobby"
            ? `Lobby (${(g.seats || []).length}/${g.maxPlayers})`
            : g.status === "finished"
              ? `Finished — Winner: ${g.winnerName || "N/A"}`
              : `${g.night} • ${g.phase} • Turn ${g.turn}`,
      })
    ),
    el("div", { className: "seat-pills" }, ...seatNodes),
    inviteListRow,
    hostExtraInviteRow,
    el("div", { style: { display: "flex", gap: "0.5rem", marginTop: "0.5rem", flexWrap: "wrap", alignItems: "center" } }, ...actionBtns)
  );
}

/* =========================================================================
   INTERACTIVE TABLETOP VIEW
   ========================================================================= */

const DEFAULT_HOTKEYS = {
  moveToTile: "v",
  scoutTile: "s",
  scoutDeck: "d",
  endTurn: "e",
  closeModal: "x",
  toggleCartNav: "n",
  viewRomeBoard: "r",
  viewMarketBoard: "m",
  viewClimateBoard: "c",
  viewAllBoards: "b",
};

const HOTKEY_SPECS = [
  {
    key: "moveToTile",
    label: "Move Cart to Selected Tile",
    desc: "Moves your Cart into the selected adjacent neighborhood (or opens the Move/Scout action prompt).",
  },
  {
    key: "scoutTile",
    label: "Scout Neighborhood Tile Stack",
    desc: "Peeks at the top unrevealed tile of the selected neighborhood stack (ends turn).",
  },
  {
    key: "scoutDeck",
    label: "Scout Encounter Deck Card",
    desc: "Opens or triggers the Encounter Deck Scout picker (Patricii, Legiones, Nefarii).",
  },
  {
    key: "endTurn",
    label: "End Nocturnal Turn",
    desc: "Ends your current hourly Delivery turn in Rome.",
  },
  {
    key: "closeModal",
    label: "Close Active Popup / Window",
    desc: "Closes the currently open modal window (Esc also always closes modals).",
  },
  {
    key: "toggleCartNav",
    label: "Toggle Cart Mat / Navigate Tab",
    desc: "Switches between your Cart Mat and the 8-direction Compass / Tile Inspector (Numpad 5 also toggles).",
  },
  {
    key: "viewRomeBoard",
    label: "Focus Rome Night Board",
    desc: "Switches the tabletop view between Rome Night Board Only and Auto view.",
  },
  {
    key: "viewMarketBoard",
    label: "Focus Ostia Market Board",
    desc: "Switches the tabletop view between Ostia Market Board Only and Auto view.",
  },
  {
    key: "viewClimateBoard",
    label: "Focus Political Climate Board",
    desc: "Switches the tabletop view between Political Climate Senate Board and Auto view.",
  },
  {
    key: "viewAllBoards",
    label: "Show All Boards Stacked",
    desc: "Toggles showing all tabletop boards stacked simultaneously.",
  },
];

function getCustomHotkeys() {
  const merged = Object.assign({}, DEFAULT_HOTKEYS);
  try {
    const rawLocal = localStorage.getItem("nm_custom_hotkeys");
    if (rawLocal) {
      const parsed = JSON.parse(rawLocal);
      if (parsed && typeof parsed === "object") {
        for (const k of Object.keys(DEFAULT_HOTKEYS)) {
          if (typeof parsed[k] === "string") {
            merged[k] = parsed[k].trim().toLowerCase().slice(0, 1);
          }
        }
      }
    }
  } catch (_e) {
    // Ignore localStorage parse errors
  }
  const userHotkeys = appState.user && appState.user.settings && appState.user.settings.hotkeys;
  if (userHotkeys && typeof userHotkeys === "object") {
    for (const k of Object.keys(DEFAULT_HOTKEYS)) {
      if (typeof userHotkeys[k] === "string") {
        merged[k] = userHotkeys[k].trim().toLowerCase().slice(0, 1);
      }
    }
  }
  return merged;
}

function saveCustomHotkeysLocal(hotkeysMap) {
  const clean = Object.assign({}, DEFAULT_HOTKEYS);
  if (hotkeysMap && typeof hotkeysMap === "object") {
    for (const k of Object.keys(DEFAULT_HOTKEYS)) {
      if (typeof hotkeysMap[k] === "string") {
        clean[k] = hotkeysMap[k].trim().toLowerCase().slice(0, 1);
      }
    }
  }
  try {
    localStorage.setItem("nm_custom_hotkeys", JSON.stringify(clean));
  } catch (_e) {
    // Ignore localStorage write errors
  }
  if (appState.user && appState.user.settings) {
    appState.user.settings.hotkeys = Object.assign({}, clean);
  }
  return clean;
}

function renderProfileView() {
  const user = appState.user;
  if (!user) return renderAuthView();

  const userSettings = user.settings || {};
  let selectedColor = user.preferredColor || "Z3";
  const currentHotkeys = getCustomHotkeys();
  const hotkeyInputsByKey = {};

  const displayNameInput = el("input", {
    className: "form-input",
    type: "text",
    value: user.displayName || "",
    placeholder: "Your Roman Merchant Title",
  });
  const emailInput = el("input", {
    className: "form-input",
    type: "email",
    value: user.email || "",
    placeholder: "merchant@collegium-ostia.org",
  });
  const defaultBoardSelect = el(
    "select",
    { className: "form-input" },
    el("option", { value: "auto", selected: (userSettings.defaultBoardView || "auto") === "auto", text: "Auto-Switch by Game Phase (Market / Rome)" }),
    el("option", { value: "both", selected: userSettings.defaultBoardView === "both", text: "Show Both Boards Stacked" }),
    el("option", { value: "rome", selected: userSettings.defaultBoardView === "rome", text: "Rome Night Board Only" }),
    el("option", { value: "market", selected: userSettings.defaultBoardView === "market", text: "Ostia Market Board Only" })
  );
  const autoPromptCargoCheckbox = el("input", {
    type: "checkbox",
    checked: userSettings.autoPromptCargoLoad !== false,
  });
  const animateDiceCheckbox = el("input", {
    type: "checkbox",
    checked: userSettings.animateDice !== false,
  });
  const paceBotTurnsCheckbox = el("input", {
    type: "checkbox",
    checked: userSettings.paceBotTurns !== false,
  });
  const soundEffectsCheckbox = el("input", {
    type: "checkbox",
    checked: userSettings.soundEffects !== false,
  });
  const allowUndoByDefaultCheckbox = el("input", {
    type: "checkbox",
    checked: Boolean(userSettings.allowUndoByDefault),
  });
  const skipMissionPopupsCheckbox = el("input", {
    type: "checkbox",
    checked: Boolean(userSettings.skipMissionCompletionPopups),
  });
  const currentPasswordInput = el("input", {
    className: "form-input",
    type: "password",
    placeholder: "Current password (only required if changing password)",
    autocomplete: "current-password",
  });
  const newPasswordInput = el("input", {
    className: "form-input",
    type: "password",
    placeholder: "New password (8+ characters, leave blank to keep current)",
    autocomplete: "new-password",
  });

  const colorButtons = [];
  const previewIconSlot = el(
    "div",
    { style: { display: "flex", alignItems: "center", gap: "0.75rem" } },
    renderSUVIconNode(selectedColor, "suv-icon-lg", `${user.displayName}'s SUV`)
  );

  const colorGrid = el(
    "div",
    { className: "color-swatch-grid" },
    ...SUV_COLOR_PALETTE.map((c) => {
      const btn = el(
        "button",
        {
          type: "button",
          className: `color-swatch-option ${c.id === selectedColor ? "selected" : ""}`,
          onClick: () => {
            selectedColor = c.id;
            colorButtons.forEach((b) => b.node.classList.toggle("selected", b.id === selectedColor));
            previewIconSlot.replaceChildren(
              renderSUVIconNode(selectedColor, "suv-icon-lg", `${user.displayName}'s SUV`)
            );
          },
        },
        renderSUVIconNode(c.id, "", c.label),
        el("span", { text: c.label })
      );
      colorButtons.push({ id: c.id, node: btn });
      return btn;
    })
  );

  const hotkeyRows = HOTKEY_SPECS.map((spec) => {
    const hkInput = el("input", {
      className: "form-input",
      type: "text",
      maxLength: "1",
      value: (currentHotkeys[spec.key] || "").toUpperCase(),
      title: `Click and press a key to bind "${spec.label}"`,
      style: {
        width: "54px",
        textAlign: "center",
        fontWeight: "800",
        fontFamily: "Cinzel, Georgia, serif",
        fontSize: "0.92rem",
        padding: "0.3rem 0.25rem",
        textTransform: "uppercase",
        flexShrink: "0",
      },
      onKeyDown: (ev) => {
        if (ev.key === "Tab") return;
        ev.preventDefault();
        if (ev.key === "Backspace" || ev.key === "Delete") {
          hkInput.value = "";
          currentHotkeys[spec.key] = "";
          saveCustomHotkeysLocal(currentHotkeys);
          return;
        }
        if (ev.key && ev.key.length === 1 && !ev.ctrlKey && !ev.metaKey && !ev.altKey) {
          const cleanChar = ev.key.toLowerCase();
          hkInput.value = cleanChar.toUpperCase();
          currentHotkeys[spec.key] = cleanChar;
          saveCustomHotkeysLocal(currentHotkeys);
        }
      },
      onInput: () => {
        const cleanChar = (hkInput.value || "").trim().toLowerCase().slice(-1);
        hkInput.value = cleanChar.toUpperCase();
        currentHotkeys[spec.key] = cleanChar;
        saveCustomHotkeysLocal(currentHotkeys);
      },
    });
    hotkeyInputsByKey[spec.key] = hkInput;

    return el(
      "div",
      {
        style: {
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: "0.75rem",
          padding: "0.45rem 0.65rem",
          borderRadius: "6px",
          background: "rgba(34, 13, 62, 0.94)",
          border: "1px solid #c9b18c",
        },
      },
      el(
        "div",
        { style: { minWidth: "0" } },
        el("div", {
          style: { fontWeight: "700", fontSize: "0.84rem", color: "#ffffff" },
          text: spec.label,
        }),
        el("div", {
          style: { fontSize: "0.74rem", color: "var(--text-muted)", lineHeight: "1.25" },
          text: spec.desc,
        })
      ),
      hkInput
    );
  });

  const handleSaveProfile = async (e) => {
    e.preventDefault();
    try {
      const savedHotkeys = saveCustomHotkeysLocal(currentHotkeys);
      const payload = {
        displayName: displayNameInput.value.trim(),
        email: emailInput.value.trim(),
        preferredColor: selectedColor,
        settings: {
          defaultBoardView: defaultBoardSelect.value,
          autoPromptCargoLoad: autoPromptCargoCheckbox.checked,
          animateDice: animateDiceCheckbox.checked,
          paceBotTurns: paceBotTurnsCheckbox.checked,
          soundEffects: soundEffectsCheckbox.checked,
          allowUndoByDefault: allowUndoByDefaultCheckbox.checked,
          skipMissionCompletionPopups: skipMissionPopupsCheckbox.checked,
          hotkeys: savedHotkeys,
        },
      };
      if (newPasswordInput.value) {
        payload.currentPassword = currentPasswordInput.value;
        payload.newPassword = newPasswordInput.value;
      }
      const res = await apiRequest("/api/profile/update", "POST", payload);
      appState.user = res.user;
      applyUserDefaultBoardView(res.user.settings);
      currentPasswordInput.value = "";
      newPasswordInput.value = "";
      showToast("Player profile, hotkeys, and merchant cart settings saved!");
      renderApp();
    } catch (err) {
      showToast(err.message, true);
    }
  };

  const summaryPanel = el(
    "div",
    { className: "panel" },
    el("h3", { className: "panel-title", text: "🏛️ Merchant Dossier" }),
    el(
      "div",
      {
        style: {
          display: "flex",
          alignItems: "center",
          gap: "1rem",
          padding: "0.85rem",
          borderRadius: "6px",
          background: "rgba(34, 13, 62, 0.94)",
          border: "1.5px solid #a88d6b",
          boxShadow: "var(--bevel-sunken)",
          marginBottom: "1rem",
        },
      },
      previewIconSlot,
      el(
        "div",
        {},
        el("div", { style: { fontSize: "1.15rem", fontWeight: "700", color: "var(--gold-bright)" }, text: user.displayName }),
        el("div", { style: { fontSize: "0.8rem", color: "var(--text-muted)" }, text: `@${user.username} • ${maskEmailClient(user.email)}` }),
        el(
          "div",
          { style: { display: "flex", gap: "0.4rem", flexWrap: "wrap", marginTop: "0.35rem" } },
          el(
            "span",
            { className: "badge" },
            user.authProvider === "google" ? "🔗 Linked with Google" : "🔑 Collegium Password Account"
          ),
          user.isAdmin
            ? el("span", {
              className: "badge",
              style: { borderColor: "var(--gold-bright)", color: "var(--gold-bright)" },
              text: "🦅 Collegium Admin",
            })
            : null
        )
      )
    ),
    el(
      "div",
      { className: "profile-stat-grid" },
      el(
        "div",
        {
          className: "profile-stat-box profile-stat-box-clickable",
          title: "View all completed games & final scores",
          onClick: () => openCompletedGamesPage(),
        },
        el("div", { className: "stat-val", text: String(user.gamesPlayed || 0) }),
        el("div", { className: "stat-lbl", text: "Expeditions Played" })
      ),
      el(
        "div",
        {
          className: "profile-stat-box profile-stat-box-clickable",
          title: "View all completed games & final scores",
          onClick: () => openCompletedGamesPage(),
        },
        el("div", { className: "stat-val", text: String(user.gamesWon || 0) }),
        el("div", { className: "stat-lbl", text: "Imperial Victories" })
      ),
      el(
        "div",
        {
          className: "stat-box profile-stat-box profile-stat-box-clickable",
          title: "View all completed games & final scores",
          onClick: () => openCompletedGamesPage(),
        },
        el("div", { className: "stat-val", text: `${user.bestWealth || 0}(d)` }),
        el("div", { className: "stat-lbl", text: "Highest Treasury" })
      )
    ),
    el(
      "div",
      { style: { marginTop: "0.75rem", display: "flex", justifyContent: "flex-end" } },
      el("button", {
        type: "button",
        className: "btn btn-sm",
        text: "📜 View Completed Games & Final Scores →",
        onClick: () => openCompletedGamesPage(),
      })
    )
  );

  const settingsFormPanel = el(
    "div",
    { className: "panel" },
    el("h3", { className: "panel-title", text: "⚙️ Account & Game Settings" }),
    el(
      "form",
      { onSubmit: handleSaveProfile },
      el(
        "div",
        { className: "form-group" },
        el("label", { text: "Permanent Collegium Username (Used for Game Invitations)" }),
        el("input", {
          className: "form-input",
          type: "text",
          value: `@${user.username || ""}`,
          readOnly: true,
          disabled: true,
          style: { opacity: "0.85", fontWeight: "700", cursor: "not-allowed" },
        })
      ),
      el("div", { className: "form-group" }, el("label", { text: "Roman Merchant Title / Display Name" }), displayNameInput),
      el("div", { className: "form-group" }, el("label", { text: "Account Email Address (Required)" }), emailInput),
      el("div", { className: "form-group" }, el("label", { text: "Merchant Cart Icon & Token Color" }), colorGrid),
      el("div", { className: "form-group" }, el("label", { text: "Default Tabletop Board View" }), defaultBoardSelect),
      el(
        "div",
        { className: "form-group" },
        el("label", { text: "Tabletop Gameplay Preferences" }),
        el(
          "label",
          { style: { display: "flex", alignItems: "center", gap: "0.5rem", fontWeight: "400", cursor: "pointer", marginBottom: "0.4rem" } },
          autoPromptCargoCheckbox,
          el("span", { text: "Ask via popup when Delivery Mission cargo can be loaded at my current neighborhood" })
        ),
        el(
          "label",
          { style: { display: "flex", alignItems: "center", gap: "0.5rem", fontWeight: "400", cursor: "pointer", marginBottom: "0.4rem" } },
          animateDiceCheckbox,
          el("span", { text: "Show 3D Roman numeral dice roll overlay animations" })
        ),
        el(
          "label",
          { style: { display: "flex", alignItems: "center", gap: "0.5rem", fontWeight: "400", cursor: "pointer", marginBottom: "0.4rem" } },
          paceBotTurnsCheckbox,
          el("span", { text: "Show step-by-step AI Bot Turn Replay banner (with Skip option)" })
        ),
        el(
          "label",
          { style: { display: "flex", alignItems: "center", gap: "0.5rem", fontWeight: "400", cursor: "pointer", marginBottom: "0.4rem" } },
          soundEffectsCheckbox,
          el("span", { text: "Play subtle tabletop sound effects (dice, coins, combat, turn chime)" })
        ),
        el(
          "label",
          { style: { display: "flex", alignItems: "center", gap: "0.5rem", fontWeight: "400", cursor: "pointer", marginBottom: "0.4rem" } },
          allowUndoByDefaultCheckbox,
          el("span", { text: "Allow undo by default (automatically approve Undo Turn requests in multiplayer games)" })
        ),
        el(
          "label",
          { style: { display: "flex", alignItems: "center", gap: "0.5rem", fontWeight: "400", cursor: "pointer" } },
          skipMissionPopupsCheckbox,
          el("span", { text: 'Skip mission completion notification popups ("Do not show this again")' })
        )
      ),
      el(
        "div",
        {
          style: {
            marginTop: "1rem",
            paddingTop: "0.85rem",
            borderTop: "1px solid var(--border-subtle)",
          },
        },
        el(
          "div",
          {
            style: {
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              gap: "0.5rem",
              flexWrap: "wrap",
              marginBottom: "0.45rem",
            },
          },
          el("div", {
            style: { fontWeight: "700", fontSize: "0.88rem", color: "var(--gold-bright)" },
            text: "⌨️ Keyboard Shortcuts (Hotkeys)",
          }),
          el("button", {
            type: "button",
            className: "btn btn-sm",
            text: "↺ Reset Hotkeys to Defaults",
            onClick: () => {
              Object.assign(currentHotkeys, DEFAULT_HOTKEYS);
              for (const [k, inp] of Object.entries(hotkeyInputsByKey)) {
                inp.value = (DEFAULT_HOTKEYS[k] || "").toUpperCase();
              }
              saveCustomHotkeysLocal(currentHotkeys);
              showToast("Hotkeys reset to defaults!");
            },
          })
        ),
        el("p", {
          style: { fontSize: "0.76rem", color: "var(--text-muted)", margin: "0 0 0.6rem 0", lineHeight: "1.35" },
          text: "Click any shortcut box below and press a key to customize it. Built-in directional & overlay keys: Numpad 1–9 steers your Cart in 8 compass directions (7=NW, 8=N, 9=NE, 4=W, 6=E, 1=SW, 2=S, 3=SE; 5 toggles Cart/Navigate), Space/Enter advances settled Dice & AI Turn overlays, and Esc always closes open windows.",
        }),
        el(
          "div",
          { style: { display: "flex", flexDirection: "column", gap: "0.4rem" } },
          ...hotkeyRows
        )
      ),
      el(
        "div",
        {
          style: {
            marginTop: "1rem",
            paddingTop: "0.85rem",
            borderTop: "1px solid var(--border-subtle)",
          },
        },
        el("div", { style: { fontWeight: "700", fontSize: "0.85rem", color: "var(--gold-bright)", marginBottom: "0.55rem" }, text: "🔐 Change Password (Optional)" }),
        el("div", { className: "form-group" }, el("label", { text: "Current Password" }), currentPasswordInput),
        el("div", { className: "form-group" }, el("label", { text: "New Password (8+ characters)" }), newPasswordInput)
      ),
      el(
        "div",
        { style: { display: "flex", justifyContent: "flex-end", gap: "0.6rem", marginTop: "1rem" } },
        el(
          "button",
          { type: "submit", className: "btn btn-primary" },
          "💾 Save Profile & Settings"
        )
      )
    )
  );

  return el(
    "div",
    { className: "portal-container" },
    el("div", { className: "profile-grid" }, summaryPanel, settingsFormPanel)
  );
}

/* =========================================================================
   OFFICIAL HTML RULEBOOK VIEW (REPLACING ORIGINAL BOARDS GALLERY)
   ========================================================================= */

export { buildFallbackFinalStandings, openFinalScoringModal, loadCompletedGames, openCompletedGamesPage, renderCompletedGamesView, handlePendingInviteDeepLink, handleGoogleSignInClick, renderGoogleUsernameSetupView, renderAuthView, DEFAULT_BOT_PERSONAS, getBotPersonasCatalog, buildPortalGamesListNodes, buildPortalLeaderboardNodes, parseUsernameTokensClient, renderPortalView, openTerminateGameModal, renderLobbyItem, DEFAULT_HOTKEYS, HOTKEY_SPECS, getCustomHotkeys, saveCustomHotkeysLocal, renderProfileView };
