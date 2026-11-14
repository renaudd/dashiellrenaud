import { getNightMerchantApiBaseUrl, getStoredSessionToken, setStoredSessionToken, initFirebaseClientIfConfigured, getFirebaseIdToken, signOutFirebaseClient, COLS, ROWS, TRACK_NAMES, COL_SYMBOLS, MARKET_COLUMNS_META, ROME_LANDMARKS, FACTION_META, DEFAULT_POLITICAL_CLIMATE_FACTORS, DEFAULT_POLITICAL_CLIMATE_OPTIONS, hasActiveClimateOption, parseTollAmount, formatEdgeLabel, getTiberBridgeName, isTiberCrossingBlocked, getNeighborCoordInDir, getSUVColorLabel, renderSUVIconNode, appState, replaceDenariiTokens, resolveGoodTrackClass, el, formatTileModifier, getTileModifierClass, renderFullGoodCardFaceNode, resolveFullJobCardFaceUrl, resolveFullInfluenceCardFaceUrl, resolveFullEncounterCardFaceUrl, INFLUENCE_SOCIAL_PLATFORMS, formatReactionCondition, formatReactionTypeSymbol, formatHostileFavorPenaltyText, getEncounterCardFaceArchetype, showToast, closeModal, showModal, NUMPAD_CODE_TO_DIR, NUMPAD_DIGIT_TO_DIR } from "./core_ui.js?v=111";
import { buildFallbackFinalStandings, openFinalScoringModal, openCompletedGamesPage, renderCompletedGamesView, handlePendingInviteDeepLink, renderGoogleUsernameSetupView, renderAuthView, buildPortalGamesListNodes, buildPortalLeaderboardNodes, renderPortalView, getCustomHotkeys, renderProfileView } from "./views_auth_portal.js?v=111";
import { openFaceUpTileUpCloseModal, openConfirmScoutNeighborhoodModal, openNpcOfferModal, openMarketRewardModal, openScoutResultModal, openLoadCargoPromptModal, openDeliverCargoPromptModal, openCancelMissionConfirmModal, openProcurerGoodModal, doesItemFitWithoutSwap, openSUVReplacementModal, triggerMissionCargoLoadWithOverflow, triggerInfluenceCardPlay, openPendingSUVOverflowModal, openProphecyTargetModal, openSurpriseShipmentModal, openInformantsTargetModal, openTop3ReorderModal, openMarketSourceModal, openGambleModal, openScoutModal, openTrashModal } from "./modals_tabletop.js?v=111";
import { renderRulebookView } from "./rulebook_view.js?v=111";
import { toRomanDieSymbol, resolveDieSwatchColor, clearDiceOverlayState, enqueueNewDiceEvents, dismissDiceOverlay, buildArmedDieBannerNode, renderDiceOverlay, playSfx, computeNpcReplayPositions, renderRomeNpcAnimationLayer, renderMarketNpcSpeechBubble, updateTabTurnTitle, stopNpcTurnPacing, enqueueNewNpcEvents, stepNextNpcPacingEvent, renderNpcPacingBanner, hideRomeHoverTooltip } from "./dice_and_sfx.js?v=111";

function navigateToMarketBoardForCategory(category) {
  appState.highlightedMarketTrack = category || null;
  appState.boardViewMode = "market";
  renderApp();
  const marketEl = document.querySelector(".market-board");
  if (marketEl && typeof marketEl.scrollIntoView === "function") {
    marketEl.scrollIntoView({ behavior: "smooth", block: "start" });
  }
}

const FACTION_GEM_MAP = {
  MAGA: "/assets/icons/ruby.png",
  ISIS: "/assets/icons/emerald.png",
  TECH: "/assets/icons/diamond.png",
  DSA: "/assets/icons/sapphire.png",
  MS13: "/assets/icons/amethyst.png",
};

function renderFactionGemNodes(favorList) {
  if (!Array.isArray(favorList) || favorList.length === 0) return [];
  const nodes = [];
  for (const raw of favorList) {
    const str = String(raw || "").trim();
    if (!str) continue;
    const isNeg = str.startsWith("-") || str.toLowerCase().includes("not ") || str.toLowerCase().includes("hostile");
    const cleanName = str.replace(/^[-+!]/, "").trim();
    const gemSrc = FACTION_GEM_MAP[cleanName];
    if (gemSrc) {
      nodes.push(
        el(
          "span",
          {
            className: `phys-gem-badge ${isNeg ? "phys-gem-slash" : ""}`,
            title: `${isNeg ? "Opposes / -1 " : "+1 "}${cleanName}`,
          },
          el("img", { src: gemSrc, alt: cleanName })
        )
      );
    }
  }
  return nodes;
}

function getSellCategoryClass(cat) {
  const c = String(cat || "").toLowerCase();
  if (c.includes("wine") || c.includes("opiate")) return "sell-cat-wine";
  if (c.includes("grain") || c.includes("weed")) return "sell-cat-grain";
  if (c.includes("meat") || c.includes("pill")) return "sell-cat-meat";
  if (c.includes("animal") || c.includes("upper")) return "sell-cat-animals";
  if (c.includes("weapon")) return "sell-cat-weapons";
  if (c.includes("marble") || c.includes("party")) return "sell-cat-marble";
  if (c.includes("henchm") || c.includes("guard")) return "sell-cat-henchmen";
  return "";
}

function buildEncounterFigureNodes(encStr, iconClass) {
  if (!encStr || encStr === "None") return [];
  const s = String(encStr);
  if (s === "mob") {
    return [el("img", { className: iconClass, src: "/assets/icons/angry_mob.png?v=111", alt: "Protesters" })];
  }
  if (s === "theater") {
    return [el("img", { className: iconClass, src: "/assets/icons/theater_masks.png?v=111", alt: "Open Mic" })];
  }
  if (s === "schizophrenic") {
    return [el("img", { className: iconClass, src: "/assets/icons/schizophrenic_icon.png?v=111", alt: "Schizophrenic" })];
  }
  const [deckType, countRaw] = s.split("_");
  const isMultiIconDeck = deckType === "cops" || deckType === "criminals" || deckType === "legionaries" || deckType === "nefarious";
  const count = isMultiIconDeck ? Math.max(1, Math.min(4, Number(countRaw) || 1)) : 1;
  let iconUrl = "/assets/icons/celebrities_icon.png?v=111";
  if (deckType === "cops" || deckType === "legionaries") iconUrl = "/assets/icons/cops_icon.png?v=111";
  else if (deckType === "criminals" || deckType === "nefarious") iconUrl = "/assets/icons/criminals_icon.png?v=111";

  const figs = [];
  for (let i = 0; i < count; i++) {
    figs.push(el("img", { className: iconClass, src: iconUrl, alt: s }));
  }
  return figs;
}

function renderDynamicEdgeSlotNode(dir, edgeVal) {
  if (!edgeVal) return null;
  let inner = null;
  const tollAmt = parseTollAmount(edgeVal);
  if (edgeVal === "green") {
    inner = el("span", { className: "dyn-edge-bar edge-green" });
  } else if (edgeVal === "red") {
    inner = el("span", { className: "dyn-edge-bar edge-red" });
  } else if (tollAmt > 0) {
    inner = el("span", { className: "dyn-edge-toll", text: `${tollAmt}(d)` });
  } else {
    const figs = buildEncounterFigureNodes(edgeVal, "dyn-edge-enc-icon");
    if (figs.length > 0) {
      inner = el("span", { className: "dyn-edge-enc-group" }, ...figs);
    }
  }
  if (!inner) return null;
  return el("div", { className: `dyn-edge-slot dyn-edge-${dir}` }, inner);
}

/**
 * Dynamically renders a revealed Rome Tile Card face from its JSON features
 * (edges, sells, buys, encounter, gamble, persistent, refresh, id, coord).
 * Only the isolated monument illustration is placed in the center background.
 */
function renderDynamicTileCardNode(tile, coord, mode = "board") {
  if (!tile) return null;
  const tileCoord = coord || tile.coord || "B1";
  const edges = tile.edges || {};
  const sells = tile.sells || [];
  const buys = tile.buys || [];
  const dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];

  const edgeNodes = dirs.map((d) => renderDynamicEdgeSlotNode(d, edges[d])).filter(Boolean);

  const tradeBannerNodes = [];
  if (buys.length > 0) {
    tradeBannerNodes.push(
      el(
        "div",
        {
          className: "dyn-tile-buys-banner clickable-forum-sells",
          onClick: (e) => {
            e.stopPropagation();
            navigateToMarketBoardForCategory(buys[0].category);
          },
        },
        "Sells: ",
        ...buys.map((b, idx) => {
          const modText = formatTileModifier(b.modifier);
          return el(
            "span",
            {},
            idx > 0 ? ", " : "",
            el("span", { className: getSellCategoryClass(b.category), text: b.category }),
            el("span", { className: `sell-mod-symbol ${getTileModifierClass(modText)}`, text: modText })
          );
        })
      )
    );
  }
  if (sells.length > 0) {
    tradeBannerNodes.push(
      el(
        "div",
        { className: "dyn-tile-sells-banner" },
        el("span", { className: "dyn-tile-buys-prefix", text: "Buys:" }),
        ...sells.map((s) => {
          const shortCat =
            s.category === "Exotic Animals"
              ? "Exotic"
              : s.category === "Meat Animals"
                ? "Meat"
                : s.category;
          const modText = formatTileModifier(s.modifier);
          return el(
            "span",
            {},
            el("span", { className: getSellCategoryClass(s.category), text: shortCat }),
            el("span", { className: `sell-mod-symbol ${getTileModifierClass(modText)}`, text: modText })
          );
        })
      )
    );
  }

  const centerFigures = buildEncounterFigureNodes(tile.encounter, "dyn-center-enc-icon");

  let bottomLeftNode = null;
  if (tile.refresh) {
    bottomLeftNode = el(
      "div",
      { className: "dyn-tile-bottom-left" },
      el("img", { className: "dyn-bottom-icon", src: "/assets/icons/refresh.png", alt: "Refresh" })
    );
  } else if (tile.persistent) {
    bottomLeftNode = el(
      "div",
      { className: "dyn-tile-bottom-left" },
      el("img", { className: "dyn-bottom-icon", src: "/assets/icons/persist.png", alt: "Persistent" })
    );
  }

  const bottomRightNode = tile.gamble
    ? el(
      "div",
      { className: "dyn-tile-bottom-right" },
      el("img", { className: "dyn-bottom-icon", src: "/assets/icons/dice.png", alt: "Gamble" })
    )
    : null;

  const colIdx = Math.max(0, COLS.indexOf(tileCoord.slice(0, 1)));
  const rowIdx = Math.max(0, ROWS.indexOf(tileCoord.slice(1)));
  const bgPosX = `${(colIdx / 5) * 100}%`;
  const bgPosY = `${(rowIdx / 5) * 100}%`;

  return el(
    "div",
    {
      className: `dyn-tile-card ${mode === "board" ? "board-overlay" : "inspector-preview"} ${edges.SW ? "has-edge-sw" : ""
        } ${edges.SE ? "has-edge-se" : ""}`.trim(),
      style: {
        backgroundImage: 'url("./assets/icons/rome_211_map_bg_v2.jpg?v=105")',
        backgroundSize: "600% 600%",
        backgroundPosition: `${bgPosX} ${bgPosY}`,
      },
    },
    ...edgeNodes,
    tradeBannerNodes.length > 0 ? el("div", { className: "dyn-tile-trade-stack" }, ...tradeBannerNodes) : null,
    centerFigures.length > 0 ? el("div", { className: "dyn-tile-center-enc" }, ...centerFigures) : null,
    bottomLeftNode,
    bottomRightNode
  );
}

/**
 * Resolves the new Job card artwork (Post-It Note, Manila Dossier, 3-Ring Binder, Legal Contract, Email Printout).
 */
function renderBuriedInfluenceStackCardBackNode(m, buriedCount) {
  const safeCount = Math.max(0, Number(buriedCount) || 0);
  const layerDivs = [];
  const layerDepth = Math.min(4, Math.max(1, safeCount));
  for (let i = 0; i < layerDepth; i++) {
    layerDivs.push(
      el("span", {
        className: "buried-inf-back-layer",
        style: { "--layer-idx": String(i) },
      })
    );
  }
  return el(
    "div",
    {
      className: `phys-card phys-influence-back-card ${safeCount === 0 ? "is-empty-stack" : ""}`,
    },
    ...layerDivs,
    el(
      "div",
      { className: "phys-card-inner phys-inf-back-inner" },
      el(
        "div",
        { className: "phys-card-bar phys-inf-back-bar" },
        el("span", { text: "Face-Down Influence" }),
        el("span", { text: "🔮 Sealed" })
      ),
      el(
        "div",
        { className: "phys-inf-back-body" },
        el("div", { className: "phys-inf-back-crest", text: "🃏" }),
        el("div", { className: "phys-inf-back-count", text: String(safeCount) }),
        el("div", {
          className: "phys-inf-back-title",
          text:
            safeCount === 1
              ? "1 Influence Card Buried"
              : `${safeCount} Influence Cards Buried`,
        }),
        el("div", {
          className: "phys-inf-back-sub",
          text:
            safeCount > 0
              ? `Face-down beneath "${m.name || "Schizophrenic Mission"}". Claimed into your hand upon completion.`
              : `No Influence cards are currently buried beneath "${m.name || "Schizophrenic Mission"}".`,
        })
      ),
      el(
        "div",
        { className: "phys-card-footer phys-inf-back-footer" },
        el("span", { text: "Card identities remain hidden" })
      )
    )
  );
}

function renderPhysicalMissionCardNode(m, opts = {}) {
  const {
    selectable = false,
    selected = false,
    onClick = null,
    showStatusTag = false,
    canCancel = false,
    cancelLabel = "✕ Cancel Mission",
    schizophrenicTotalCount = 0,
  } = opts;
  const reqBlocks = Math.max(1, Number(m.blocks) || 1);
  const buriedCount = Number(
    m.underInfluenceCount !== undefined
      ? m.underInfluenceCount
      : Array.isArray(m.underInfluence)
        ? m.underInfluence.length
        : 0
  );

  const deliveryStatusBadgeNode =
    showStatusTag && m.kind === "delivery"
      ? el("span", {
        style: {
          fontSize: "0.55rem",
          background: m.canDeliverCargo
            ? "#15803d"
            : m.pickedUp
              ? "#16a34a"
              : m.canLoadCargo
                ? "#d97706"
                : "rgba(74, 52, 32, 0.78)",
          color: "#fff",
          padding: "1px 4px",
          borderRadius: "3px",
          fontWeight: "800",
        },
        text: m.canDeliverCargo
          ? `DELIVER @ ${m.deliverCell}`
          : m.pickedUp
            ? `CARGO LOADED → ${m.deliverCell}`
            : m.canLoadCargo
              ? `READY AT ${m.pickupCell}`
              : `PICK UP @ ${m.pickupCell}`,
      })
      : null;

  const externalActions = [];
  if (m.canLoadCargo) {
    externalActions.push(
      el(
        "button",
        {
          type: "button",
          className: "mission-load-cargo-btn",
          title:
            m.hasCargoSpace === false
              ? `SUV full — click to discard Goods on your SUV and load ${m.item || "Cargo"} (${reqBlocks}■)`
              : `Load ${m.item || "Cargo"} (${reqBlocks}■) onto your SUV`,
          onClick: (e) => {
            e.stopPropagation();
            const gsCurr = appState.gameState;
            const viewerCurr =
              gsCurr && Array.isArray(gsCurr.players)
                ? gsCurr.players[gsCurr.viewerPlayerIndex || 0]
                : null;
            triggerMissionCargoLoadWithOverflow(m, viewerCurr);
          },
        },
        m.hasCargoSpace === false
          ? `📦 Load ${m.item || "Cargo"} (${reqBlocks}■ • Swap)`
          : `📦 Load Cargo (${m.item || "Cargo"} • ${reqBlocks}■)`
      )
    );
  }
  if (m.canDeliverCargo) {
    externalActions.push(
      el(
        "button",
        {
          type: "button",
          className: "mission-deliver-cargo-btn",
          title: `Deliver ${m.item || "Cargo"} at ${m.deliverCell} to complete Mission "${m.name}"`,
          onClick: (e) => {
            e.stopPropagation();
            closeModal();
            sendGameAction({ type: "delivery_complete_mission", missionId: m.id });
          },
        },
        `🏛️ Deliver ${m.item || "Cargo"} Here (${m.deliverCell})`
      )
    );
  }
  if (Array.isArray(m.completableSells) && m.completableSells.length > 0) {
    const bulkGrainSells = m.completableSells.filter((s) => s.category === "Grain" || s.category === "Weed");
    if (bulkGrainSells.length >= 2) {
      const relMod = formatTileModifier(bulkGrainSells[0].modifier || m.modifier || "=");
      const totalBulkPrice = bulkGrainSells.reduce((acc, s) => acc + (Number(s.price) || 0), 0);
      externalActions.push(
        el(
          "button",
          {
            type: "button",
            className: "mission-sell-complete-btn",
            title: `Bulk Grain Sale: Sell all ${bulkGrainSells.length} Grain cards in ${m.cell || "this neighborhood"
              } at ${relMod} (${totalBulkPrice} Denarii total) and complete Mission "${m.name}"`,
            onClick: (e) => {
              e.stopPropagation();
              closeModal();
              sendGameAction({
                type: "delivery_sell",
                category: "Grain",
                bulkGrain: true,
                cardIds: bulkGrainSells.map((s) => s.cardId),
                missionId: m.id,
              });
            },
          },
          replaceDenariiTokens(
            `🌾 Bulk Sell All ${bulkGrainSells.length} Grain (${totalBulkPrice}d @ ${relMod}) — Complete!`
          )
        )
      );
    }
    for (const s of m.completableSells) {
      const relMod = formatTileModifier(s.modifier || m.modifier || "=");
      externalActions.push(
        el(
          "button",
          {
            type: "button",
            className: "mission-sell-complete-btn",
            title: `Sell ${s.cardName} in ${m.cell || "this neighborhood"} at ${relMod} (${s.price} Denarii) and complete Mission "${m.name}"`,
            onClick: (e) => {
              e.stopPropagation();
              closeModal();
              sendGameAction({
                type: "delivery_sell",
                category: s.category,
                cardIds: [s.cardId],
                missionId: m.id,
              });
            },
          },
          replaceDenariiTokens(`💰 Sell ${s.cardName} (${s.price}d @ ${relMod}) — Complete!`)
        )
      );
      if (Array.isArray(s.amethystBoostOptions) && s.amethystBoostOptions.length > 0) {
        for (const boost of s.amethystBoostOptions) {
          externalActions.push(
            el(
              "button",
              {
                type: "button",
                className: "mission-sell-amethyst-btn",
                title: `Spend ${boost.spend} DSA Sapphire(s) to boost sale price to ${boost.price} Denarii and complete Mission "${m.name}"`,
                onClick: (e) => {
                  e.stopPropagation();
                  closeModal();
                  sendGameAction({
                    type: "delivery_sell",
                    category: s.category,
                    cardIds: [s.cardId],
                    missionId: m.id,
                    spendAmethysts: boost.spend,
                  });
                },
              },
              replaceDenariiTokens(
                `🔮 Sell ${s.cardName} (-${boost.spend} Sapphire → ${boost.price}d)`
              )
            )
          );
        }
      }
    }
  }
  if (m.canClaimExpose) {
    externalActions.push(
      el(
        "button",
        {
          type: "button",
          className: "mission-deliver-cargo-btn",
          title: `Claim completed Expose Mission "${m.name}"`,
          onClick: (e) => {
            e.stopPropagation();
            closeModal();
            sendGameAction({ type: "delivery_complete_mission", missionId: m.id });
          },
        },
        `✓ Complete Mission (${m.name})`
      )
    );
  }
  if (m.canFightEncounter) {
    const useCb = Boolean(m.canFightEncounter.useCasusBelli);
    const targetLabel = m.canFightEncounter.npcName || "Target";
    externalActions.push(
      el(
        "button",
        {
          type: "button",
          className: "mission-fight-complete-btn",
          title: useCb
            ? `Play Casus Belli to initiate combat against ${targetLabel} for Mission "${m.name}"`
            : `Initiate combat against ${targetLabel} for Mission "${m.name}"`,
          onClick: (e) => {
            e.stopPropagation();
            closeModal();
            sendGameAction({
              type: "resolve_encounter",
              decision: useCb ? "use_casus_belli" : "fight",
            });
          },
        },
        `⚔️ Fight ${targetLabel}${useCb ? " (Casus Belli)" : ""} — Advance!`
      )
    );
  }
  if (canCancel) {
    externalActions.push(
      el(
        "button",
        {
          type: "button",
          className: `mission-cancel-btn ${m.source === "encounter" ? "penalty" : "free"}`,
          onClick: (e) => {
            e.stopPropagation();
            openCancelMissionConfirmModal(m, schizophrenicTotalCount);
          },
        },
        cancelLabel
      )
    );
  }

  const cardFace = el(
    "div",
    {
      className: `phys-card phys-mission-card phys-full-bleed-card ${selectable ? "selectable" : ""} ${selected ? "selected-discard" : ""}`,
      onClick,
    },
    selected ? el("div", { className: "phys-card-discard-ribbon", text: "DISCARD" }) : null,
    deliveryStatusBadgeNode
      ? el("div", { className: "enc-mission-floating-status" }, deliveryStatusBadgeNode)
      : null,
    el("img", {
      className: "phys-full-bleed-card-img",
      src: resolveFullJobCardFaceUrl(m),
      alt: m.name || "Job",
      loading: "lazy",
    })
  );

  let visualCardNode = cardFace;
  if (showStatusTag && m.source === "encounter" && m.encounterCard) {
    if (!m.hasDrawnMissionCard) {
      // Embedded Encounter Mission: remains a physical Encounter card on the Mission Board
      const encNode = renderPhysicalEncounterCardNode(m.encounterCard, null, { interactive: false });
      visualCardNode = el(
        "div",
        { className: "enc-on-mission-board-wrap" },
        deliveryStatusBadgeNode
          ? el("div", { className: "enc-mission-floating-status" }, deliveryStatusBadgeNode)
          : null,
        encNode
      );
    } else {
      // Deck Quest: Drawn Mission card sits on top of the Encounter card, with clickable protruding side edge
      const stackKey = String(m.id || m.name || "enc_stack");
      const isSwapped = appState.swappedMissionStackIds.has(stackKey);
      const toggleStackSwap = (e) => {
        e.stopPropagation();
        if (appState.swappedMissionStackIds.has(stackKey)) {
          appState.swappedMissionStackIds.delete(stackKey);
        } else {
          appState.swappedMissionStackIds.add(stackKey);
        }
        renderApp();
      };
      const encDeckKey = String(m.encounterCard.deck || "celebrities").toLowerCase();
      const patronLabel = m.encounterCard.name || m.patronName || "Encounter";
      const topNode = isSwapped
        ? renderPhysicalEncounterCardNode(m.encounterCard, null, { interactive: false })
        : cardFace;
      const edgeNode = el(
        "button",
        {
          type: "button",
          className: `mission-stack-protruding-edge ${isSwapped ? "edge-mission" : `edge-encounter deck-${encDeckKey}`
            }`,
          title: isSwapped
            ? `Click side edge to bring Mission "${m.name || "Quest"}" to the top`
            : `Click protruding Encounter edge to inspect "${patronLabel}"`,
          onClick: toggleStackSwap,
        },
        el("span", { className: "protruding-edge-swap-icon", text: "⇄" }),
        el("span", {
          className: "protruding-edge-label",
          text: isSwapped ? `Missio: ${m.name || "Quest"}` : patronLabel,
        })
      );
      visualCardNode = el(
        "div",
        { className: "mission-card-stack-wrap" },
        el("div", { className: "mission-card-stack-top" }, topNode),
        edgeNode
      );
    }
  } else if (showStatusTag && m.source === "schizophrenic") {
    // Schizophrenic Mission: sits on top of a face-down stack of Influence cards with clickable protruding side edge
    const stackKey = String(m.id || m.name || "sooth_stack");
    const isSwapped = appState.swappedMissionStackIds.has(stackKey);
    const toggleStackSwap = (e) => {
      e.stopPropagation();
      if (appState.swappedMissionStackIds.has(stackKey)) {
        appState.swappedMissionStackIds.delete(stackKey);
      } else {
        appState.swappedMissionStackIds.add(stackKey);
      }
      renderApp();
    };
    const topNode = isSwapped ? renderBuriedInfluenceStackCardBackNode(m, buriedCount) : cardFace;
    const edgeSlices = [];
    if (!isSwapped) {
      const sliceCount = Math.min(3, Math.max(1, buriedCount || 1));
      for (let i = 0; i < sliceCount; i++) {
        edgeSlices.push(el("span", { className: "protruding-inf-slice", style: { "--slice-idx": String(i) } }));
      }
    }
    const edgeNode = el(
      "button",
      {
        type: "button",
        className: `mission-stack-protruding-edge ${isSwapped ? "edge-mission" : "edge-influence-stack"
          }`,
        title: isSwapped
          ? `Click side edge to bring Schizophrenic Mission "${m.name || "Mission"}" back to the top`
          : "Click protruding Influence stack edge to check the exact number of buried Influence cards",
        onClick: toggleStackSwap,
      },
      ...edgeSlices,
      el("span", { className: "protruding-edge-swap-icon", text: "⇄" }),
      el("span", {
        className: "protruding-edge-label",
        text: isSwapped ? `Missio: ${m.name || "Schizophrenic"}` : "Influence Stack",
      })
    );
    visualCardNode = el(
      "div",
      { className: "mission-card-stack-wrap" },
      el("div", { className: "mission-card-stack-top" }, topNode),
      edgeNode
    );
  }

  if (externalActions.length === 0) {
    return visualCardNode;
  }
  return el(
    "div",
    { className: "phys-card-slot" },
    visualCardNode,
    el("div", { className: "phys-card-external-actions" }, ...externalActions)
  );
}

/**
 * Renders an Influence card in the new smartphone social media post format.
 */
function renderPhysicalInfluenceCardNode(c, opts = {}) {
  const { selectable = false, selected = false, onClick = null, actionButton = null } = opts;
  const rawArtId = c.id && c.id.startsWith("inf_") ? String(c.id) : "inf_1";
  const artId = rawArtId.replace(/([0-9]+)[a-z]+$/i, "$1");
  const numId = Number(String(artId).replace("inf_", "")) || 1;
  const plat = INFLUENCE_SOCIAL_PLATFORMS[(numId - 1) % INFLUENCE_SOCIAL_PLATFORMS.length];

  const cardFace = el(
    "div",
    {
      className: `phys-card phys-influence-card phys-full-bleed-card ${plat.cls} ${selectable ? "selectable" : ""} ${selected ? "selected-discard" : ""}`,
      onClick,
    },
    selected ? el("div", { className: "phys-card-discard-ribbon", text: "DISCARD" }) : null,
    el("img", {
      className: "phys-full-bleed-card-img",
      src: resolveFullInfluenceCardFaceUrl(c),
      alt: c.name || "Influence",
      loading: "lazy",
    })
  );

  if (!actionButton) {
    return cardFace;
  }
  return el(
    "div",
    { className: "phys-card-slot" },
    cardFace,
    el("div", { className: "phys-card-external-actions" }, actionButton)
  );
}

const WANTED_POSTER_CARD_IDS = new Set(["nef_8", "nef_18", "nef_22", "nef_24", "nef_26", "nef_28"]);
const POLICE_ID_BADGE_CARD_IDS = new Set(["leg_2", "leg_8", "leg_10", "leg_15", "leg_17", "leg_22", "leg_24"]);

function renderPhysicalEncounterCardNode(card, pend, opts = {}) {
  const { interactive = false, onFulfill = null, onFight = null } = opts;
  const deckKey = String(
    (typeof pend === "string" ? pend : pend && pend.deck) || card.deck || "celebrities"
  ).toLowerCase();
  const faceTheme = getEncounterCardFaceArchetype(card, deckKey);
  const canFight = Boolean(pend && typeof pend === "object" && pend.canInitiateCombat);
  const combatMandatory = Boolean(pend && typeof pend === "object" && pend.combatMandatory);

  const fullEncImgSrc = resolveFullEncounterCardFaceUrl(card, deckKey);

  if (card && card.type === "event") {
    const handleEventClick = (e) => {
      if (!interactive || !onFulfill) return;
      e.stopPropagation();
      onFulfill();
    };
    return el(
      "div",
      {
        className: `phys-card phys-encounter-card phys-full-bleed-card deck-${deckKey} ${interactive ? "interactive-large" : ""}`,
        style: interactive && onFulfill ? { cursor: "pointer" } : undefined,
        onClick: interactive && onFulfill ? handleEventClick : null,
      },
      el("img", {
        className: "phys-full-bleed-card-img",
        src: fullEncImgSrc,
        alt: card.name || "Event Encounter",
        loading: "lazy",
      })
    );
  }

  const handleFulfillClick = (e) => {
    if (!interactive || !onFulfill || combatMandatory) return;
    e.stopPropagation();
    onFulfill();
  };

  const handleCombatClick = (e) => {
    if (!interactive) return;
    e.stopPropagation();
    if (!canFight) {
      showToast("Combat is not threatened and you have no cards to trigger combat.", true);
      return;
    }
    if (onFight) onFight();
  };

  const tiers =
    Array.isArray(card.tiers) && card.tiers.length > 0
      ? card.tiers
      : Array.isArray(card.reactions) && card.reactions.length > 0
        ? card.reactions.map((r) => ({
          cond: formatReactionCondition(r.condition),
          effect: formatReactionTypeSymbol(r),
          text: r.actionText || null,
        }))
        : [
          { cond: "≤ -1", effect: "(COMBAT_ICON)" },
          { cond: "≥ 0", effect: formatReactionTypeSymbol(pend ? pend.reaction || pend.reactionType : "demand") },
        ];
  const matchedIdx = pend && typeof pend.matchedTierIndex === "number" ? pend.matchedTierIndex : -1;

  const cid = String((card && card.id) || "");
  const cardLayoutKind = WANTED_POSTER_CARD_IDS.has(cid)
    ? "wanted"
    : POLICE_ID_BADGE_CARD_IDS.has(cid)
      ? "badge"
      : "phone";

  const activeTierObj = matchedIdx >= 0 && matchedIdx < tiers.length ? tiers[matchedIdx] : null;
  const activeTierEff = String((activeTierObj && activeTierObj.effect) || "");
  const isMissionOptionAvailable =
    interactive &&
    !combatMandatory &&
    Boolean(onFulfill) &&
    (Boolean(card && card.mission) ||
      activeTierEff.includes("📦") ||
      activeTierEff.includes("🃏") ||
      activeTierEff.includes("QUEST_ICON") ||
      activeTierEff.includes("DECK_ICON") ||
      (pend && (pend.reaction === "mission" || pend.reaction === "gift")));

  const tierHitCells = tiers.map((t, idx) => {
    const isActive = idx === matchedIdx;
    const rawEff = String(t.effect || "");
    const eff = rawEff
      .replace(/⚔️|⚔/g, "(COMBAT_ICON)")
      .replace(/🃏/g, "(DECK_ICON)")
      .replace(/📦/g, "(QUEST_ICON)");
    const isCombatTier = rawEff.includes("⚔") || eff.includes("(COMBAT_ICON)") || rawEff.toLowerCase() === "combat";
    const isAvailable = isCombatTier ? canFight : (isActive && !combatMandatory);
    const clickCls =
      interactive && isCombatTier
        ? canFight
          ? "enc-clickable-section section-combat"
          : "enc-section-locked"
        : interactive && isActive && !combatMandatory
          ? "enc-clickable-section section-fulfill"
          : interactive
            ? "enc-tier-inactive"
            : "";

    return el("div", {
      className: `phys-enc-hit-tier-cell ${isAvailable ? "tier-available-backlit" : ""} ${isActive ? "tier-active" : ""} ${clickCls}`,
      onClick: isCombatTier
        ? handleCombatClick
        : isActive && !combatMandatory
          ? handleFulfillClick
          : interactive
            ? (e) => {
              e.stopPropagation();
              const effFav = pend && typeof pend.effectiveFavor === "number" ? pend.effectiveFavor : 0;
              showToast(`That section requires Favor ${t.cond} (your current Favor is ${effFav}).`, true);
            }
            : null,
    });
  });

  return el(
    "div",
    {
      className: `phys-card phys-encounter-card phys-full-bleed-card deck-${deckKey} ${faceTheme.cls} layout-${cardLayoutKind} ${interactive ? "interactive-large" : ""}`,
    },
    el("img", {
      className: "phys-full-bleed-card-img",
      src: fullEncImgSrc,
      alt: card.name || "Encounter",
      loading: "lazy",
    }),
    // Interactive / Backlight Overlays: ONLY the individual spectrum sections, top-right cash icon, and bottom-left pistol icon
    interactive || matchedIdx >= 0
      ? el(
        "div",
        { className: `phys-enc-hit-overlay layout-${cardLayoutKind}` },
        isMissionOptionAvailable
          ? el("div", {
            className: "phys-enc-hit-zone zone-top-right-cash enc-clickable-section section-fulfill",
            onClick: handleFulfillClick,
          })
          : null,
        el(
          "div",
          { className: `phys-enc-hit-tiers-row tiers-row-${cardLayoutKind}` },
          ...tierHitCells
        ),
        interactive
          ? el("div", {
            className: `phys-enc-hit-zone zone-bottom-left-pistol ${canFight ? "enc-clickable-section section-combat" : "enc-section-locked"}`,
            onClick: handleCombatClick,
          })
          : null
      )
      : null
  );
}

async function apiRequest(path, method = "GET", body = null) {
  const apiBaseUrl = getNightMerchantApiBaseUrl();
  const fullUrl = apiBaseUrl && String(path).startsWith("/") ? `${apiBaseUrl}${path}` : path;
  const headers = { Accept: "application/json" };
  const idToken = await getFirebaseIdToken();
  const bearerTok = idToken || appState.sessionToken || getStoredSessionToken();
  if (bearerTok) {
    headers["Authorization"] = `Bearer ${bearerTok}`;
  }
  if (method !== "GET" && method !== "HEAD") {
    headers["Content-Type"] = "application/json";
    if (appState.csrfToken) {
      headers["X-CSRF-Token"] = appState.csrfToken;
    }
  }
  let resp;
  try {
    resp = await fetch(fullUrl, {
      method,
      headers,
      credentials: apiBaseUrl ? "include" : "same-origin",
      body: body ? JSON.stringify(body) : null,
    });
  } catch (netErr) {
    throw new Error(
      "Could not reach the Night Merchant server — check your connection or try again in a moment."
    );
  }
  const data = await resp.json().catch(() => {
    if (
      resp.status === 404 &&
      !apiBaseUrl &&
      typeof window !== "undefined" &&
      window.location &&
      /dashiellrenaud\.com$/i.test(window.location.hostname || "")
    ) {
      return {
        ok: false,
        error: "Backend API URL (apiBaseUrl) is not yet configured in public/config.js.",
      };
    }
    return { ok: false, error: "Invalid server response." };
  });
  if (!resp.ok || data.ok === false) {
    throw new Error(data.error || data.message || `Request failed (${resp.status})`);
  }
  if (data && data.sessionToken) {
    setStoredSessionToken(data.sessionToken);
  }
  return data;
}

function applyUserDefaultBoardView(settings) {
  const pref = settings && settings.defaultBoardView ? String(settings.defaultBoardView) : "auto";
  if (["auto", "both", "rome", "market", "climate"].includes(pref)) {
    appState.boardViewMode = pref;
  } else if (pref === "split") {
    appState.boardViewMode = "both";
  } else {
    appState.boardViewMode = "auto";
  }
}

function syncGameUiTransitions(gs, isSwitchingGame = false) {
  if (!gs) return;
  const gameId = appState.currentGameId;
  const prevGameId = appState.lastSyncedGameId;
  const prevPhase = appState.lastSyncedPhase;
  const prevNight = appState.lastSyncedNight;
  const nextPhase = gs.phase || null;
  const nextNight = gs.night || null;

  const gameChanged = isSwitchingGame || prevGameId !== gameId;
  const enteredClimatePhase =
    nextPhase === "setup_climate" && (gameChanged || prevPhase !== "setup_climate");
  const exitedClimatePhase =
    !gameChanged && prevPhase === "setup_climate" && nextPhase !== "setup_climate";
  const enteredMarketPhase =
    !gameChanged &&
    nextPhase === "market" &&
    (prevPhase !== "market" || (prevNight !== null && prevNight !== nextNight));
  const exitedMarketPhase = !gameChanged && prevPhase === "market" && nextPhase !== "market";

  if (enteredClimatePhase) {
    appState.highlightedMarketTrack = null;
    if (appState.boardViewMode !== "both") {
      appState.boardViewMode = "climate";
    }
    appState.pendingScrollToClimate = true;
  } else if (gameChanged || exitedClimatePhase || enteredMarketPhase || exitedMarketPhase) {
    appState.highlightedMarketTrack = null;
    const savedPref =
      appState.user && appState.user.settings && appState.user.settings.defaultBoardView
        ? String(appState.user.settings.defaultBoardView)
        : "auto";
    if (["both", "rome", "market"].includes(savedPref)) {
      appState.boardViewMode = savedPref;
    } else if (savedPref === "split") {
      appState.boardViewMode = "both";
    } else if (appState.boardViewMode !== "both") {
      appState.boardViewMode = "auto";
    }
  }

  appState.lastSyncedGameId = gameId;
  appState.lastSyncedPhase = nextPhase;
  appState.lastSyncedNight = nextNight;

  // Chronicle of Rome scroll stability: keep user's scroll position unless a new log event occurs
  const logs = Array.isArray(gs.logs) ? gs.logs : [];
  const lastLog = logs.length > 0 ? logs[logs.length - 1] : null;
  const logSig = lastLog
    ? `${logs.length}:${lastLog.night || ""}:${lastLog.turn ?? ""}:${lastLog.text || ""}`
    : "0";
  if (gameChanged || appState.chronicleLastGameId !== gameId) {
    appState.chronicleLastGameId = gameId;
    appState.chronicleLastLogSig = logSig;
    appState.chronicleUserScrolled = false;
    appState.chronicleScrollTop = 0;
  } else if (appState.chronicleLastLogSig !== null && appState.chronicleLastLogSig !== logSig) {
    appState.chronicleLastLogSig = logSig;
    appState.chronicleUserScrolled = false;
    appState.chronicleScrollTop = 0;
  } else {
    appState.chronicleLastLogSig = logSig;
  }

  // Clear armed die-card action if encounter ended or card was spent
  if (appState.armedDieAction) {
    const viewer = Array.isArray(gs.players) ? gs.players[gs.viewerPlayerIndex || 0] : null;
    const stillHasCard =
      Boolean(gs.pendingEncounter) &&
      Boolean(viewer && (viewer.influence || []).some((c) => c.id === appState.armedDieAction.cardId));
    if (!stillHasCard) {
      appState.armedDieAction = null;
    }
  }
}

function installChronicleViewportScrollWatcher() {
  if (appState._chronicleWatcherInstalled) return;
  appState._chronicleWatcherInstalled = true;
  window.addEventListener(
    "scroll",
    () => {
      if (!appState.chronicleUserScrolled) return;
      const panelEl = document.getElementById("chronicle-of-rome-panel");
      if (!panelEl || typeof panelEl.getBoundingClientRect !== "function") return;
      const rect = panelEl.getBoundingClientRect();
      if (rect.bottom <= 0 || rect.top >= window.innerHeight) {
        appState.chronicleUserScrolled = false;
        appState.chronicleScrollTop = 0;
        const logBoxEl = document.getElementById("chronicle-log-box");
        if (logBoxEl) {
          logBoxEl.scrollTop = 0;
        }
      }
    },
    { passive: true }
  );
}

async function bootstrap() {
  installChronicleViewportScrollWatcher();
  try {
    const params = new URLSearchParams(window.location.search || "");
    const rawGameParam = (params.get("game") || "").trim();
    if (rawGameParam && /^[A-Za-z0-9_-]{1,40}$/.test(rawGameParam)) {
      appState.pendingInviteGameId = rawGameParam;
    }
  } catch (_e) { }

  await initFirebaseClientIfConfigured();

  try {
    let me = await apiRequest("/api/auth/me");
    appState.googleClientId = me.googleClientId || "";
    if (typeof me.firebaseEnabled === "boolean") {
      appState.serverFirebaseEnabled = me.firebaseEnabled;
    }
    if (me.firebaseConfig && typeof me.firebaseConfig === "object") {
      appState.runtimeFirebaseConfig = me.firebaseConfig;
      await initFirebaseClientIfConfigured();
    }
    if (!me.authenticated && me.firebaseEnabled !== false) {
      const existingToken = await getFirebaseIdToken();
      if (existingToken) {
        try {
          const synced = await apiRequest("/api/auth/firebase", "POST", { idToken: existingToken });
          if (synced && synced.user) {
            me = { authenticated: true, user: synced.user, csrfToken: synced.csrfToken || null };
          }
        } catch (_syncErr) { }
      }
    }
    if (me.authenticated && me.user) {
      appState.user = me.user;
      appState.csrfToken = me.csrfToken || null;
      applyUserDefaultBoardView(me.user.settings);
      if (!me.user.needsUsernameSetup) {
        await refreshPortalOverview();
        await handlePendingInviteDeepLink();
      }
    }
  } catch (err) {
    console.error(err);
  }
  renderApp();
  startPolling();
}

function startPolling() {
  if (appState.pollTimer) clearInterval(appState.pollTimer);
  appState.pollTimer = setInterval(async () => {
    if (!appState.user || appState.user.needsUsernameSetup) return;
    if (appState.activeTab === "tabletop" && appState.currentGameId) {
      try {
        const res = await apiRequest(`/api/games/${appState.currentGameId}`);
        appState.gameSummary = res.summary;
        appState.gameState = res.state;
        syncGameUiTransitions(res.state, false);
        enqueueNewNpcEvents(res.state, false);
        enqueueNewDiceEvents(res.state);
        enqueueNewMissionEvents(res.state);
        renderApp();
        if (!document.getElementById("modal-root")?.hasChildNodes()) {
          checkPostActionModals(res.state);
        }
      } catch (err) {
        if (err && err.message && err.message.includes("Game not found")) {
          appState.currentGameId = null;
          appState.gameSummary = null;
          appState.gameState = null;
          appState.activeTab = "portal";
          await refreshPortalOverview();
          showToast("This game has been terminated.", true);
          renderApp();
        }
      }
    } else if (appState.activeTab === "portal") {
      try {
        await refreshPortalOverview();
        const gamesSlot = document.getElementById("portal-games-list-slot");
        const activeEl = document.activeElement;
        const selectingInsideLobby =
          Boolean(gamesSlot && activeEl && gamesSlot.contains(activeEl)) &&
          activeEl.tagName === "SELECT";
        if (gamesSlot && !selectingInsideLobby) {
          gamesSlot.replaceChildren(...buildPortalGamesListNodes());
        }
        const lbSlot = document.getElementById("portal-leaderboard-slot");
        if (lbSlot) {
          lbSlot.replaceChildren(...buildPortalLeaderboardNodes());
        }
        updateTabTurnTitle();
      } catch (_err) {
        // Ignore transient background portal polling errors
      }
    }
  }, 5000);
}

async function refreshPortalOverview() {
  if (!appState.user) return;
  const data = await apiRequest("/api/portal/overview");
  if (data.user) {
    appState.user = { ...(appState.user || {}), ...data.user };
  }
  appState.games = data.games || [];
  appState.leaderboard = data.leaderboard || [];
  appState.botPersonas = data.botPersonas || [];
  appState.referenceCatalog = data.referenceCatalog || [];
  if (!appState.selectedRefItem && appState.referenceCatalog.length > 0) {
    appState.selectedRefItem = appState.referenceCatalog[0];
  }
}

function seedSeenScoutIds(state) {
  if (!state || !state.players) return;
  const vp = state.players[state.viewerPlayerIndex || 0];
  if (!vp || !Array.isArray(vp.scoutedInfo)) return;
  vp.scoutedInfo.forEach((si) => {
    if (si && si.id) appState.shownScoutIds.add(si.id);
  });
}

function enqueueNewMissionEvents(state) {
  if (!state || !Array.isArray(state.missionEvents)) return;
  if (appState.lastSeenMissionEventSeq === null) {
    appState.lastSeenMissionEventSeq =
      typeof state.lastMissionEventSeq === "number" ? state.lastMissionEventSeq : 0;
    return;
  }
  const viewerIdx = state.viewerPlayerIndex || 0;
  const skipPopups = Boolean(
    appState.user && appState.user.settings && appState.user.settings.skipMissionCompletionPopups
  );
  for (const ev of state.missionEvents) {
    if (ev && typeof ev.seq === "number" && ev.seq > appState.lastSeenMissionEventSeq) {
      appState.lastSeenMissionEventSeq = ev.seq;
      if (ev.playerIndex === viewerIdx && !skipPopups) {
        appState.missionModalQueue.push(ev);
      }
    }
  }
}

function persistSkipMissionCompletionPopups(skipFlag) {
  if (!appState.user) return;
  const nextSettings = {
    ...(appState.user.settings || {}),
    skipMissionCompletionPopups: Boolean(skipFlag),
  };
  appState.user.settings = nextSettings;
  if (skipFlag) {
    appState.missionModalQueue = [];
  }
  apiRequest("/api/profile/update", "POST", { settings: nextSettings })
    .then((res) => {
      if (res && res.user) {
        appState.user = res.user;
      }
    })
    .catch(() => { });
}

function openMissionCompletionModal(ev) {
  if (!ev) return;
  const m = ev.mission || {};
  const rewardNotes = Array.isArray(ev.rewardNotes) && ev.rewardNotes.length > 0
    ? ev.rewardNotes
    : [ev.rewardSummary || m.rewardText || "Mission Reward"];
  const favorNotes = Array.isArray(ev.favorNotes) ? ev.favorNotes : [];
  const favorGems = renderFactionGemNodes(m.favor || []);

  const skipCheckbox = el("input", {
    type: "checkbox",
    checked: Boolean(
      appState.user && appState.user.settings && appState.user.settings.skipMissionCompletionPopups
    ),
    onChange: (e) => {
      persistSkipMissionCompletionPopups(Boolean(e.target.checked));
    },
  });

  const body = el(
    "div",
    { style: { display: "flex", flexDirection: "column", gap: "0.85rem" } },
    el(
      "div",
      {
        style: {
          padding: "0.65rem 0.85rem",
          borderRadius: "4px",
          background: "#ecfdf5",
          border: "1.5px solid #16a34a",
          boxShadow: "var(--bevel-sunken)",
          textAlign: "center",
        },
      },
      el("div", {
        style: { fontFamily: "Cinzel, Georgia, serif", fontSize: "1.02rem", fontWeight: "800", color: "#14532d" },
        text: `✨ Mission Accomplished: "${m.name || "Missio"}"!`,
      }),
      ev.contextDetail
        ? el("div", {
          style: { fontSize: "0.84rem", color: "#38bdf8", marginTop: "0.25rem", fontWeight: "700" },
          text: `Completed by ${ev.contextDetail}`,
        })
        : null
    ),
    el(
      "div",
      { style: { display: "flex", justifyContent: "center", margin: "0.2rem 0" } },
      el("div", { style: { width: "250px" } }, renderPhysicalMissionCardNode(m, { showStatusTag: false }))
    ),
    el(
      "div",
      {
        style: {
          padding: "0.75rem 0.9rem",
          borderRadius: "4px",
          background: "rgba(34, 13, 62, 0.94)",
          border: "1.5px solid #a88d6b",
          boxShadow: "var(--bevel-sunken)",
          display: "flex",
          flexDirection: "column",
          gap: "0.5rem",
        },
      },
      el("div", {
        style: { fontFamily: "Cinzel, Georgia, serif", fontSize: "0.86rem", fontWeight: "800", color: "var(--gold-bright)" },
        text: "🎁 Rewards & Imperial Favor Earned",
      }),
      el(
        "div",
        { style: { display: "flex", alignItems: "center", gap: "0.45rem", fontSize: "0.88rem", color: "#754208", fontWeight: "700" } },
        el("img", { className: "phys-inline-icon", src: "/assets/icons/chest.png", alt: "Reward" }),
        el("span", { text: `Rewards: ${rewardNotes.join(" • ")}` })
      ),
      el(
        "div",
        { style: { display: "flex", alignItems: "center", gap: "0.45rem", fontSize: "0.86rem", color: "#15803d", fontWeight: "700", flexWrap: "wrap" } },
        el("img", { className: "phys-inline-icon", src: "/assets/icons/thumb_up.png", alt: "Favor" }),
        el("span", {
          text: `Faction Favor: ${favorNotes.length > 0 ? favorNotes.join(", ") : ev.favorSummary || "No Faction Favor change"
            }`,
        }),
        ...favorGems
      )
    ),
    el(
      "div",
      {
        style: {
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          gap: "0.75rem",
          flexWrap: "wrap",
          marginTop: "0.25rem",
        },
      },
      el(
        "label",
        {
          style: {
            display: "flex",
            alignItems: "center",
            gap: "0.45rem",
            fontSize: "0.82rem",
            color: "var(--text-muted)",
            cursor: "pointer",
            userSelect: "none",
          },
        },
        skipCheckbox,
        el("span", { text: "Do not show this again" })
      ),
      el("button", {
        type: "button",
        className: "btn btn-primary",
        text: appState.missionModalQueue.length > 0 ? "🏛️ Claim & View Next Completed Mission ▶" : "🏛️ Claim Rewards & Continue",
        onClick: () => {
          if (skipCheckbox.checked) {
            persistSkipMissionCompletionPopups(true);
          }
          closeModal();
          if (appState.gameState) {
            checkPostActionModals(appState.gameState);
          }
        },
      })
    )
  );

  showModal(`🏆 Mission Completed — ${m.name || "Missio"}`, body);
}

function checkPostActionModals(state) {
  if (!state || !state.players) return;
  const vp = state.players[state.viewerPlayerIndex || 0];
  if (!vp) return;

  const finishKey = `${appState.currentGameId || "local"}:finished`;
  if (state.phase !== "finished") {
    appState.shownFinishModalGameIds.delete(finishKey);
  }

  // -1. Check if a Mission was just completed (wait until any active 3D dice overlay is dismissed)
  if (appState.missionModalQueue.length > 0 && !appState.activeDiceOverlay) {
    const nextMissionEv = appState.missionModalQueue.shift();
    openMissionCompletionModal(nextMissionEv);
    return;
  }

  // 0. Check if player has an active Top 3 Peek & Reorder (Informants Influence card)
  if (vp.pendingTop3Reorder && vp.pendingTop3Reorder.id) {
    if (appState.promptedTop3Id !== vp.pendingTop3Reorder.id) {
      appState.promptedTop3Id = vp.pendingTop3Reorder.id;
      openTop3ReorderModal(vp.pendingTop3Reorder);
      return;
    }
  } else {
    appState.promptedTop3Id = null;
  }

  // 0A. Check if player has an incoming Good or Henchman reward exceeding SUV/Henchman capacity
  if (Array.isArray(vp.pendingSUVOverflow) && vp.pendingSUVOverflow.length > 0) {
    if (!appState.activeDiceOverlay) {
      const nextOvf = vp.pendingSUVOverflow[0];
      if (nextOvf && nextOvf.id && appState.promptedSUVOverflowId !== nextOvf.id) {
        appState.promptedSUVOverflowId = nextOvf.id;
        openPendingSUVOverflowModal(state, vp);
        return;
      }
    }
  } else {
    appState.promptedSUVOverflowId = null;
  }

  // 0A2. Check if player has a pending Market Board reward choice (e.g. Vigilante -> Any Meat Animal on Market)
  if (Array.isArray(vp.pendingMarketReward) && vp.pendingMarketReward.length > 0) {
    if (!appState.activeDiceOverlay) {
      const nextMktRwd = vp.pendingMarketReward[0];
      if (nextMktRwd && nextMktRwd.id && appState.promptedMarketRewardId !== nextMktRwd.id) {
        appState.promptedMarketRewardId = nextMktRwd.id;
        openMarketRewardModal(state, vp);
        return;
      }
    }
  } else {
    appState.promptedMarketRewardId = null;
  }

  // 0B. Check if player has an active NPC Purchase/Sale Offer (e.g. Quintus Tineius Sacerdos)
  if (vp.pendingNpcOffer && vp.pendingNpcOffer.id) {
    if (appState.promptedNpcOfferId !== vp.pendingNpcOffer.id) {
      appState.promptedNpcOfferId = vp.pendingNpcOffer.id;
      openNpcOfferModal(state, vp);
      return;
    }
  } else {
    appState.promptedNpcOfferId = null;
  }

  // 1. Check if a new scouted tile/card was just revealed
  if (Array.isArray(vp.scoutedInfo)) {
    for (let i = vp.scoutedInfo.length - 1; i >= 0; i--) {
      const si = vp.scoutedInfo[i];
      if (si && si.id && !appState.shownScoutIds.has(si.id)) {
        appState.shownScoutIds.add(si.id);
        openScoutResultModal(si);
        return;
      }
    }
  }

  // 2. Check if the player has a delivery mission with cargo available to load or deliver at their current cell
  const autoPrompt =
    !appState.user || !appState.user.settings || appState.user.settings.autoPromptCargoLoad !== false;
  if (autoPrompt && state.phase === "delivery" && !state.pendingEncounter && vp.position) {
    const missions = vp.missions || [];
    for (const m of missions) {
      if (m.kind === "delivery" && m.canLoadCargo && !m.pickedUp && !m.completed && !m.failed) {
        const promptKey = `${appState.currentGameId}:pickup:${m.id}:${vp.position}:${state.turn}`;
        if (!appState.promptedCargoPickups.has(promptKey)) {
          appState.promptedCargoPickups.add(promptKey);
          openLoadCargoPromptModal(m, vp);
          return;
        }
      }
      if (m.kind === "delivery" && m.canDeliverCargo && m.pickedUp && !m.completed && !m.failed) {
        const deliverKey = `${appState.currentGameId}:deliver:${m.id}:${vp.position}:${state.turn}`;
        if (!appState.promptedCargoDeliveries.has(deliverKey)) {
          appState.promptedCargoDeliveries.add(deliverKey);
          openDeliverCargoPromptModal(m, vp);
          return;
        }
      }
    }
  }

  // 3. When the game ends, automatically show the Final Scoring & Expedition Statistics pop-up
  if (state.phase === "finished" && !appState.activeDiceOverlay && appState.missionModalQueue.length === 0) {
    if (!appState.shownFinishModalGameIds.has(finishKey)) {
      appState.shownFinishModalGameIds.add(finishKey);
      const standings =
        Array.isArray(state.finalStandings) && state.finalStandings.length > 0
          ? state.finalStandings
          : buildFallbackFinalStandings(state);
      openFinalScoringModal(standings, {
        gameName: appState.gameSummary ? appState.gameSummary.name : "Roman Expedition",
        winnerName: state.winner,
        night: state.night,
      });
      return;
    }
  }
}

async function openGame(gameId) {
  try {
    const isSwitchingGame = appState.currentGameId !== gameId;
    const res = await apiRequest(`/api/games/${gameId}`);
    appState.currentGameId = gameId;
    appState.gameSummary = res.summary;
    appState.gameState = res.state;
    appState.setupDiscardMissions.clear();
    appState.setupDiscardInfluence.clear();
    syncGameUiTransitions(res.state, isSwitchingGame);
    if (isSwitchingGame) {
      appState.marketBoardScrollLeft = 0;
      appState.marketBoardScrollTop = 0;
      appState.climateBoardScrollLeft = 0;
      seedSeenScoutIds(res.state);
      stopNpcTurnPacing();
      enqueueNewNpcEvents(res.state, true);
    } else {
      enqueueNewNpcEvents(res.state, false);
    }
    if (isSwitchingGame || appState.lastSeenDiceSeq === null) {
      clearDiceOverlayState();
      appState.lastSeenDiceSeq =
        res.state && typeof res.state.lastDiceSeq === "number" ? res.state.lastDiceSeq : 0;
    } else {
      enqueueNewDiceEvents(res.state);
    }
    if (isSwitchingGame || appState.lastSeenMissionEventSeq === null) {
      appState.missionModalQueue = [];
      appState.lastSeenMissionEventSeq =
        res.state && typeof res.state.lastMissionEventSeq === "number" ? res.state.lastMissionEventSeq : 0;
    } else {
      enqueueNewMissionEvents(res.state);
    }
    if (res.state && res.state.players) {
      const vp = res.state.players[res.state.viewerPlayerIndex || 0];
      if (vp && vp.position) {
        appState.inspectedCell = vp.position;
      }
    }
    appState.activeTab = "tabletop";
    renderApp();
    checkPostActionModals(res.state);
  } catch (err) {
    showToast(err.message, true);
  }
}

async function sendGameAction(actionPayload) {
  if (!appState.currentGameId) return;
  try {
    const res = await apiRequest(`/api/games/${appState.currentGameId}/action`, "POST", actionPayload);
    if (res.user) {
      appState.user = { ...(appState.user || {}), ...res.user };
    }
    const actType = actionPayload && actionPayload.type ? String(actionPayload.type) : "";
    if (
      [
        "market_buy",
        "delivery_sell",
        "delivery_forum_buy",
        "cleanup_take_loan",
        "cleanup_repay_loan",
        "cleanup_buy_influence",
        "delivery_complete_mission",
        "delivery_gamble",
      ].includes(actType)
    ) {
      playSfx("coin");
    } else if (
      actType === "delivery_trash" ||
      actType === "delivery_attack" ||
      (actType === "resolve_encounter" &&
        (actionPayload.decision === "fight" || actionPayload.decision === "refuse"))
    ) {
      playSfx("combat");
    }
    appState.gameSummary = res.summary;
    appState.gameState = res.state;
    syncGameUiTransitions(res.state, false);
    enqueueNewNpcEvents(res.state, false);
    enqueueNewDiceEvents(res.state);
    enqueueNewMissionEvents(res.state);
    if (res.message) showToast(res.message, false);
    if (actType === "delivery_scout" && actionPayload.targetType === "tile" && actionPayload.targetKey) {
      appState.inspectedCell = actionPayload.targetKey;
    } else if (actType === "initial_scout" && actionPayload.cell) {
      appState.inspectedCell = actionPayload.cell;
    } else if (res.state && res.state.players) {
      const vp = res.state.players[res.state.viewerPlayerIndex || 0];
      if (vp && vp.position) {
        appState.inspectedCell = vp.position;
      }
    }
    renderApp();
    checkPostActionModals(res.state);
  } catch (err) {
    showToast(err.message, true);
  }
}

function renderApp() {
  const root = document.getElementById("app-root");
  if (!root) return;

  const prevMarketMatrixEl = document.querySelector(".ostia-market-board-matrix");
  if (prevMarketMatrixEl) {
    appState.marketBoardScrollLeft = prevMarketMatrixEl.scrollLeft;
    appState.marketBoardScrollTop = prevMarketMatrixEl.scrollTop;
  }
  const prevClimateMatrixEl = document.querySelector(".senate-climate-board-matrix");
  if (prevClimateMatrixEl) {
    appState.climateBoardScrollLeft = prevClimateMatrixEl.scrollLeft;
  }

  hideRomeHoverTooltip();

  const contentNodes = [renderTopbar()];
  if (!appState.user) {
    if (appState.activeTab === "rulebook" || appState.activeTab === "reference") {
      contentNodes.push(renderRulebookView());
    } else {
      contentNodes.push(renderAuthView());
    }
  } else if (appState.user.needsUsernameSetup) {
    if (appState.activeTab === "rulebook" || appState.activeTab === "reference") {
      contentNodes.push(renderRulebookView());
    } else {
      contentNodes.push(renderGoogleUsernameSetupView());
    }
  } else if (appState.activeTab === "tabletop" && appState.gameSummary) {
    contentNodes.push(renderTabletopView());
  } else if (appState.activeTab === "rulebook" || appState.activeTab === "reference") {
    contentNodes.push(renderRulebookView());
  } else if (appState.activeTab === "profile") {
    contentNodes.push(renderProfileView());
  } else if (appState.activeTab === "completed_games") {
    contentNodes.push(renderCompletedGamesView());
  } else {
    contentNodes.push(renderPortalView());
  }
  root.replaceChildren(...contentNodes);

  if (appState.activeTab !== "tabletop") {
    appState.chronicleUserScrolled = false;
    appState.chronicleScrollTop = 0;
  } else {
    const marketMatrixEl = document.querySelector(".ostia-market-board-matrix");
    if (marketMatrixEl) {
      if (typeof appState.marketBoardScrollLeft === "number" && appState.marketBoardScrollLeft > 0) {
        marketMatrixEl.scrollLeft = appState.marketBoardScrollLeft;
      }
      if (typeof appState.marketBoardScrollTop === "number" && appState.marketBoardScrollTop > 0) {
        marketMatrixEl.scrollTop = appState.marketBoardScrollTop;
      }
    }
    const climateMatrixEl = document.querySelector(".senate-climate-board-matrix");
    if (climateMatrixEl && typeof appState.climateBoardScrollLeft === "number" && appState.climateBoardScrollLeft > 0) {
      climateMatrixEl.scrollLeft = appState.climateBoardScrollLeft;
    }
    const logBoxEl = document.getElementById("chronicle-log-box");
    if (logBoxEl) {
      logBoxEl.scrollTop = appState.chronicleUserScrolled ? appState.chronicleScrollTop : 0;
    }
    const gs = appState.gameState;
    const pend = gs && gs.pendingEncounter;
    if (pend) {
      const encKey = `${appState.currentGameId || ""}:${pend.stage || "pre_decision"}:${(pend.card && (pend.card.id || pend.card.name)) || pend.chartType || ""
        }`;
      if (appState.lastAutoScrolledEncounterKey !== encKey) {
        appState.lastAutoScrolledEncounterKey = encKey;
        const encPanelEl = document.getElementById("pending-encounter-panel");
        if (encPanelEl && typeof encPanelEl.getBoundingClientRect === "function") {
          const rect = encPanelEl.getBoundingClientRect();
          if (rect.top < 0 || rect.top > window.innerHeight * 0.7) {
            encPanelEl.scrollIntoView({ behavior: "smooth", block: "start" });
          }
        }
      }
    } else {
      appState.lastAutoScrolledEncounterKey = null;
    }
    if (appState.pendingScrollToClimate) {
      appState.pendingScrollToClimate = false;
      const climateEl = document.querySelector(".senate-climate-board");
      if (climateEl && typeof climateEl.scrollIntoView === "function") {
        climateEl.scrollIntoView({ behavior: "smooth", block: "start" });
      }
    }
  }
  updateTabTurnTitle();
}

function createTopbarSvgIcon(buildFn) {
  const svgNS = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(svgNS, "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("width", "18");
  svg.setAttribute("height", "18");
  svg.setAttribute("class", "topbar-phone-svg");
  svg.setAttribute("aria-hidden", "true");
  buildFn(svg, svgNS);
  return svg;
}

function createTopbarLobbyWirelessIcon() {
  // Simple white Wireless connection signal displaying two bars of service
  return createTopbarSvgIcon((svg, ns) => {
    const bars = [
      { x: "2.5", y: "14.5", w: "3.6", h: "6.5", op: "1" },
      { x: "8.2", y: "10.5", w: "3.6", h: "10.5", op: "1" },
      { x: "13.9", y: "6.5", w: "3.6", h: "14.5", op: "0.28" },
      { x: "19.6", y: "2.5", w: "3.6", h: "18.5", op: "0.28" },
    ];
    for (const b of bars) {
      const r = document.createElementNS(ns, "rect");
      r.setAttribute("x", b.x);
      r.setAttribute("y", b.y);
      r.setAttribute("width", b.w);
      r.setAttribute("height", b.h);
      r.setAttribute("rx", "1.1");
      r.setAttribute("fill", "#ffffff");
      r.setAttribute("fill-opacity", b.op);
      svg.appendChild(r);
    }
  });
}

function createTopbarRulebookMagnifierIcon() {
  // Simple white magnifying glass icon
  return createTopbarSvgIcon((svg, ns) => {
    const c = document.createElementNS(ns, "circle");
    c.setAttribute("cx", "10.5");
    c.setAttribute("cy", "10.5");
    c.setAttribute("r", "6.5");
    c.setAttribute("fill", "none");
    c.setAttribute("stroke", "#ffffff");
    c.setAttribute("stroke-width", "2.5");
    svg.appendChild(c);

    const l = document.createElementNS(ns, "line");
    l.setAttribute("x1", "15.4");
    l.setAttribute("y1", "15.4");
    l.setAttribute("x2", "21.2");
    l.setAttribute("y2", "21.2");
    l.setAttribute("stroke", "#ffffff");
    l.setAttribute("stroke-width", "2.8");
    l.setAttribute("stroke-linecap", "round");
    svg.appendChild(l);
  });
}

function createTopbarProfileCogIcon() {
  // Simple white profile of a person interrupted in the bottom-left corner by a simple white cog
  return createTopbarSvgIcon((svg, ns) => {
    // Person head
    const head = document.createElementNS(ns, "circle");
    head.setAttribute("cx", "14");
    head.setAttribute("cy", "6.2");
    head.setAttribute("r", "3.9");
    head.setAttribute("fill", "#ffffff");
    svg.appendChild(head);

    // Person shoulders interrupted in bottom-left by the cog
    const shoulders = document.createElementNS(ns, "path");
    shoulders.setAttribute(
      "d",
      "M14 11.8 C18.4 11.8 22 14.5 22.4 19.5 L12.8 19.5 C12.9 16.0 11.8 13.5 9.6 12.4 C10.9 12.0 12.4 11.8 14 11.8 Z"
    );
    shoulders.setAttribute("fill", "#ffffff");
    svg.appendChild(shoulders);

    // Simple white cog in bottom-left corner (center at 6.5, 16.8)
    const cogRing = document.createElementNS(ns, "circle");
    cogRing.setAttribute("cx", "6.5");
    cogRing.setAttribute("cy", "16.8");
    cogRing.setAttribute("r", "3.0");
    cogRing.setAttribute("fill", "none");
    cogRing.setAttribute("stroke", "#ffffff");
    cogRing.setAttribute("stroke-width", "2.1");
    svg.appendChild(cogRing);

    const cogTeeth = document.createElementNS(ns, "path");
    cogTeeth.setAttribute(
      "d",
      "M6.5 11.8 V13.2 M6.5 20.4 V21.8 M1.5 16.8 H2.9 M10.1 16.8 H11.5 M3.0 13.3 L4.0 14.3 M9.0 19.3 L10.0 20.3 M10.0 13.3 L9.0 14.3 M4.0 19.3 L3.0 20.3"
    );
    cogTeeth.setAttribute("stroke", "#ffffff");
    cogTeeth.setAttribute("stroke-width", "1.9");
    cogTeeth.setAttribute("stroke-linecap", "round");
    svg.appendChild(cogTeeth);
  });
}

function createTopbarSignOutIcon() {
  // Simple white rectangle interrupted on its left side by an arrow sticking out of it
  return createTopbarSvgIcon((svg, ns) => {
    const rectPath = document.createElementNS(ns, "path");
    rectPath.setAttribute(
      "d",
      "M10 7.8 V4.2 C10 3.5 10.6 3 11.3 3 H19.7 C20.4 3 21 3.5 21 4.2 V19.8 C21 20.5 20.4 21 19.7 21 H11.3 C10.6 21 10 20.5 10 19.8 V16.2"
    );
    rectPath.setAttribute("fill", "none");
    rectPath.setAttribute("stroke", "#ffffff");
    rectPath.setAttribute("stroke-width", "2.4");
    rectPath.setAttribute("stroke-linecap", "round");
    svg.appendChild(rectPath);

    const arrowPath = document.createElementNS(ns, "path");
    arrowPath.setAttribute("d", "M15.8 12 H2.4 M2.4 12 L6.4 8.2 M2.4 12 L6.4 15.8");
    arrowPath.setAttribute("fill", "none");
    arrowPath.setAttribute("stroke", "#ffffff");
    arrowPath.setAttribute("stroke-width", "2.4");
    arrowPath.setAttribute("stroke-linecap", "round");
    arrowPath.setAttribute("stroke-linejoin", "round");
    svg.appendChild(arrowPath);
  });
}

function createTopbarReturnGameIcon() {
  // Simple white phone/play icon for returning to active game
  return createTopbarSvgIcon((svg, ns) => {
    const poly = document.createElementNS(ns, "polygon");
    poly.setAttribute("points", "6,4 20,12 6,20");
    poly.setAttribute("fill", "#ffffff");
    svg.appendChild(poly);
  });
}

function renderTopbar() {
  const navButtons = [];
  if (appState.user && appState.user.needsUsernameSetup) {
    navButtons.push(
      el(
        "button",
        {
          className: `nav-btn topbar-icon-btn ${appState.activeTab !== "rulebook" && appState.activeTab !== "reference" ? "active" : ""}`,
          title: "Choose Username",
          "aria-label": "Choose Username",
          onClick: () => {
            appState.activeTab = "portal";
            renderApp();
          },
        },
        createTopbarProfileCogIcon()
      ),
      el(
        "button",
        {
          className: `nav-btn topbar-icon-btn ${appState.activeTab === "rulebook" || appState.activeTab === "reference" ? "active" : ""}`,
          title: "Rulebook",
          "aria-label": "Rulebook",
          onClick: () => {
            appState.activeTab = "rulebook";
            renderApp();
          },
        },
        createTopbarRulebookMagnifierIcon()
      )
    );
  } else if (appState.user) {
    navButtons.push(
      el(
        "button",
        {
          className: `nav-btn topbar-icon-btn ${appState.activeTab === "portal" ? "active" : ""}`,
          title: "Lobby",
          "aria-label": "Lobby",
          onClick: async () => {
            appState.activeTab = "portal";
            await refreshPortalOverview();
            renderApp();
          },
        },
        createTopbarLobbyWirelessIcon()
      )
    );
    if (appState.gameSummary && appState.activeTab !== "tabletop") {
      navButtons.push(
        el(
          "button",
          {
            className: "nav-btn topbar-icon-btn",
            title: "Return to Game",
            "aria-label": "Return to Game",
            onClick: () => {
              appState.activeTab = "tabletop";
              renderApp();
            },
          },
          createTopbarReturnGameIcon()
        )
      );
    }
    navButtons.push(
      el(
        "button",
        {
          className: `nav-btn topbar-icon-btn ${appState.activeTab === "rulebook" || appState.activeTab === "reference" ? "active" : ""}`,
          title: "Rulebook",
          "aria-label": "Rulebook",
          onClick: () => {
            appState.activeTab = "rulebook";
            renderApp();
          },
        },
        createTopbarRulebookMagnifierIcon()
      ),
      el(
        "button",
        {
          className: `nav-btn topbar-icon-btn ${appState.activeTab === "profile" ? "active" : ""}`,
          title: "Profile",
          "aria-label": "Profile",
          onClick: () => {
            appState.activeTab = "profile";
            renderApp();
          },
        },
        createTopbarProfileCogIcon()
      )
    );
  } else {
    navButtons.push(
      el(
        "button",
        {
          className: `nav-btn topbar-icon-btn ${appState.activeTab !== "rulebook" && appState.activeTab !== "reference" ? "active" : ""}`,
          title: "Sign In / Lobby",
          "aria-label": "Sign In / Lobby",
          onClick: () => {
            appState.activeTab = "portal";
            renderApp();
          },
        },
        createTopbarLobbyWirelessIcon()
      ),
      el(
        "button",
        {
          className: `nav-btn topbar-icon-btn ${appState.activeTab === "rulebook" || appState.activeTab === "reference" ? "active" : ""}`,
          title: "Rulebook",
          "aria-label": "Rulebook",
          onClick: () => {
            appState.activeTab = "rulebook";
            renderApp();
          },
        },
        createTopbarRulebookMagnifierIcon()
      )
    );
  }

  const userStripChildren = [];
  if (appState.user) {
    if (appState.activeTab === "portal" && !appState.user.needsUsernameSetup) {
      userStripChildren.push(
        el("button", {
          type: "button",
          className: "wins-best-btn",
          title: "View completed games & final scores",
          text: `Wins: ${appState.user.gamesWon} | Best: ${appState.user.bestWealth}(d)`,
          onClick: () => openCompletedGamesPage(),
        })
      );
    }
    userStripChildren.push(
      el(
        "button",
        {
          className: "nav-btn topbar-icon-btn topbar-signout-btn",
          title: "Sign Out",
          "aria-label": "Sign Out",
          onClick: async () => {
            try {
              await apiRequest("/api/auth/logout", "POST", {});
            } catch (_e) { }
            await signOutFirebaseClient();
            appState.user = null;
            appState.csrfToken = null;
            appState.gameSummary = null;
            appState.gameState = null;
            appState.completedGames = [];
            appState.activeTab = "portal";
            renderApp();
          },
        },
        createTopbarSignOutIcon()
      )
    );
  }

  return el(
    "header",
    { className: "topbar" },
    el(
      "div",
      {
        className: "brand brand-night-merchant-box",
        style: { cursor: "pointer" },
        onClick: () => {
          appState.activeTab =
            appState.user && !appState.user.needsUsernameSetup && appState.gameSummary ? "tabletop" : "portal";
          renderApp();
        },
      },
      el(
        "div",
        { className: "brand-title" },
        el("span", { className: "brand-title-main", text: "NIGHT MERCHANT" }),
        el("span", { className: "brand-title-sub", text: "INSTANTGRAM SF" })
      )
    ),
    el("div", { className: "topbar-right-icons" }, ...navButtons, ...userStripChildren)
  );
}

function renderPendingUndoBanner(gs) {
  const pend = gs.pendingUndoRequest;
  if (!pend) return null;
  const myUid = appState.user ? appState.user.id : null;
  const reqUids = Array.isArray(pend.requiredUserIds) ? pend.requiredUserIds : [];
  const reqNames = Array.isArray(pend.requiredNames) ? pend.requiredNames : [];
  const autoNames = Array.isArray(pend.autoApprovedNames) ? pend.autoApprovedNames : [];
  const needsMyApproval = myUid !== null && reqUids.includes(myUid);
  const isRequester = myUid !== null && pend.requesterUserId === myUid;
  const whichTurnText =
    pend.targetType === "current_turn" ? "beginning of the current turn" : "beginning of the previous turn";

  return el(
    "div",
    {
      className: "panel",
      style: {
        borderColor: "#d97706",
        background: "rgba(14, 42, 84, 0.92)",
        marginBottom: "0.75rem",
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        flexWrap: "wrap",
        gap: "0.75rem",
      },
    },
    el(
      "div",
      {},
      el("div", {
        style: { fontWeight: "800", color: "#7dd3fc", fontSize: "0.95rem", marginBottom: "0.2rem" },
        text: `↩️ Undo Turn Requested by ${pend.requesterName}`,
      }),
      el("div", {
        style: { fontSize: "0.84rem", color: "var(--text-main)" },
        text: `Target: Revert to the ${whichTurnText} (${pend.targetLabel || "Start of Turn"}).`,
      }),
      el("div", {
        style: { fontSize: "0.78rem", color: "#92400e", marginTop: "0.2rem", fontWeight: "600" },
        text: `Awaiting approval from: ${reqNames.join(", ") || "Other players"}${autoNames.length > 0 ? ` • Auto-approved by profile setting: ${autoNames.join(", ")}` : ""
          }`,
      })
    ),
    el(
      "div",
      { style: { display: "flex", gap: "0.5rem", flexWrap: "wrap" } },
      needsMyApproval
        ? el("button", {
          className: "btn btn-sm btn-primary",
          text: "✓ Approve Undo",
          onClick: () => sendGameAction({ type: "respond_undo_turn", decision: "approve" }),
        })
        : null,
      needsMyApproval
        ? el("button", {
          className: "btn btn-sm btn-crimson",
          text: "✕ Decline Undo",
          onClick: () => sendGameAction({ type: "respond_undo_turn", decision: "reject" }),
        })
        : null,
      isRequester
        ? el("button", {
          className: "btn btn-sm",
          text: "✕ Cancel Undo Request",
          onClick: () => sendGameAction({ type: "cancel_undo_turn" }),
        })
        : null
    )
  );
}

function renderTabletopView() {
  const gs = appState.gameState;
  if (!gs) {
    return el("div", { className: "portal-container" }, el("p", { text: "Loading game state..." }));
  }

  const viewer = gs.players[gs.viewerPlayerIndex] || gs.players[0];
  const activePlayer = gs.players[gs.activePlayerIndex] || gs.players[0];

  // Determine which board(s) to display
  let effectiveView = appState.boardViewMode;
  if (effectiveView === "auto") {
    if (appState.activeNpcEvent && appState.activeNpcEvent.phase === "market") {
      effectiveView = "market";
    } else if (
      appState.activeNpcEvent &&
      (appState.activeNpcEvent.phase === "delivery" || appState.activeNpcEvent.phase === "delivery_entry")
    ) {
      effectiveView = "rome";
    } else {
      effectiveView =
        gs.phase === "setup_climate"
          ? "climate"
          : gs.phase === "market"
            ? "market"
            : "rome";
    }
  }

  const mainBoards = [];
  if (gs.phase === "setup_discard") {
    if (!viewer.setupDiscarded) {
      mainBoards.push(renderSetupDiscardPanel(viewer));
    } else {
      const pendingPlayers = (gs.players || []).filter((p) => !p.setupDiscarded).map((p) => p.name);
      mainBoards.push(
        el(
          "div",
          { className: "panel", style: { borderColor: "var(--gold-bright)" } },
          el("h3", { className: "panel-title", text: "⏳ Starting Hand Confirmed — Awaiting Rival Merchants" }),
          el("p", {
            style: { fontSize: "0.86rem", color: "var(--text-muted)", margin: "0" },
            text:
              pendingPlayers.length > 0
                ? `Waiting for ${pendingPlayers.join(", ")} to finish discarding 2 Missions & 2 Influence cards before the Political Climate Draft begins.`
                : "Entering Political Climate Draft...",
          })
        )
      );
    }
  }
  if (gs.pendingEncounter) {
    mainBoards.push(renderPendingEncounterPanel(gs, viewer));
  }
  if ((viewer.pendingSUVOverflow || []).length > 0) {
    mainBoards.push(renderPendingSUVOverflowPanel(gs, viewer));
  }
  if ((viewer.pendingMarketReward || []).length > 0) {
    mainBoards.push(renderPendingMarketRewardPanel(gs, viewer));
  }
  if (viewer.pendingNpcOffer) {
    mainBoards.push(renderPendingNpcOfferPanel(gs, viewer));
  }
  if (gs.phase === "cleanup" && !viewer.cleanupDone) {
    mainBoards.push(renderCleanupPhasePanel(gs, viewer));
  }

  if (effectiveView === "climate" || effectiveView === "both") {
    mainBoards.push(renderPoliticalClimateBoard(gs, viewer));
  }
  if (effectiveView === "market" || effectiveView === "both") {
    mainBoards.push(renderOstiaMarketBoard(gs, viewer));
  }
  if (effectiveView === "rome" || effectiveView === "both") {
    mainBoards.push(renderRomeNightBoard(gs, viewer));
  }

  return el(
    "div",
    { className: "tabletop-wrapper" },
    renderClockAndTurnBanner(gs, viewer, activePlayer),
    renderNpcPacingBanner(),
    renderPendingUndoBanner(gs),
    renderContextualPromptBanner(gs, viewer, activePlayer),
    renderActiveClimateStrip(gs, viewer),
    el(
      "div",
      { className: "tabletop-main" },
      el("div", { style: { display: "flex", flexDirection: "column", gap: "1rem" } }, ...mainBoards),
      renderPlayerSidebar(gs, viewer)
    )
  );
}

function renderClockAndTurnBanner(gs, viewer, activePlayer) {
  const firstPlayer = gs.players[gs.firstPlayerIndex] || gs.players[0];
  const phaseNames = {
    setup_discard: "Preparation: Select Starting Contracts",
    setup_climate: "Preparation: Political Climate Draft",
    market: "Phase I: Ostia Port Market",
    delivery_entry: "Phase II: Dusk Gate Entry & Initial Scout",
    delivery: "Phase II: Rome Night Delivery",
    cleanup: "Phase III: Dawn Clean-Up & Upkeep",
    finished: "December 211 A.D. — Sunday Reckoning Complete",
  };
  const activeClimateCount =
    gs.politicalClimate && Array.isArray(gs.politicalClimate.activeIds) ? gs.politicalClimate.activeIds.length : 0;

  const canUndo = Boolean(gs.canUndoTurn);
  const undoPending = Boolean(gs.pendingUndoRequest);
  const undoTooltip = undoPending
    ? "An Undo Turn request is currently awaiting approval."
    : !canUndo
      ? "Nothing to undo yet — game is at the beginning of the initial turn."
      : gs.undoTargetType === "current_turn"
        ? `Revert to the beginning of the current turn (${gs.undoTargetLabel || ""})`
        : `No actions taken yet this turn — revert to the beginning of the previous turn (${gs.undoTargetLabel || ""})`;

  return el(
    "div",
    { className: "clock-banner" },
    el(
      "div",
      { className: "clock-badges" },
      el("span", { className: "badge badge-night", text: `🏛️ Night: ${gs.night} 211 A.D.` }),
      el("span", { className: "badge badge-phase", text: phaseNames[gs.phase] || gs.phase }),
      gs.phase === "delivery" ? el("span", { className: "badge badge-hour", text: `🕰️ ${gs.turnHourLabel}` }) : null,
      el("span", { className: "badge", text: `🦅 1st Player: ${firstPlayer.name}` }),
      el("span", {
        className: "badge",
        style: { borderColor: "#16a34a", color: "#14532d", background: "#ecfdf5" },
        text: `▶ Active Turn: ${activePlayer.name}`,
      })
    ),
    el(
      "div",
      { style: { display: "flex", gap: "0.4rem", flexWrap: "wrap" } },
      el("button", {
        className: "btn btn-sm",
        style: canUndo ? { borderColor: "#8c5612", color: "#ff6ec7" } : {},
        disabled: !canUndo || undoPending,
        title: undoTooltip,
        text: undoPending
          ? "⏳ Undo Pending..."
          : canUndo && gs.undoTargetType === "previous_turn"
            ? "↩️ Undo Turn (Prev)"
            : "↩️ Undo Turn",
        onClick: () => sendGameAction({ type: "request_undo_turn" }),
      }),
      ...["auto", "rome", "market", "climate", "both"].map((mode) =>
        el("button", {
          className: `btn btn-sm ${appState.boardViewMode === mode ? "btn-primary" : ""}`,
          title:
            mode === "climate"
              ? "Switch to the 6×3 Roman Senate Political Climate Board"
              : undefined,
          text:
            mode === "auto"
              ? "Auto View"
              : mode === "rome"
                ? "🗺️ Rome 211 A.D. Board"
                : mode === "market"
                  ? "⚓ Ostia Port Market"
                  : mode === "climate"
                    ? `🏛️ Political Climate (${activeClimateCount})`
                    : "All Boards",
          onClick: () => {
            appState.boardViewMode = mode;
            renderApp();
          },
        })
      )
    )
  );
}

function renderContextualPromptBanner(gs, viewer, activePlayer) {
  let promptText = "";
  const extraActions = [];

  if (gs.phase === "setup_discard") {
    promptText =
      "Setup: Discard 2 Starting Missions and 2 Influence cards below. First to confirm drafts Political Climate first and acts last in turn order.";
  } else if (gs.phase === "setup_climate") {
    const pc = gs.politicalClimate || {};
    const stepNum = Math.min((Number(pc.draftStep) || 0) + 1, Math.max(1, (pc.draftOrder || []).length));
    const totalPicks = (pc.draftOrder || []).length || gs.players.length;
    promptText = `Political Climate Draft — Pick ${stepNum} of ${totalPicks} (${activePlayer.name}): Click a decree in an open column below to enact it.`;
  } else if (gs.phase === "market") {
    promptText = `Ostia Market — ${activePlayer.name}'s turn: Buy 1 Good or Henchman, Source a Good, or Pass (${gs.marketConsecutivePasses}/${gs.players.length} passed).`;
    if (gs.activePlayerIndex === viewer.index) {
      extraActions.push(
        el("button", {
          className: "btn btn-sm",
          text: "📦 Source Good (Discard 1 Influence)",
          disabled: viewer.influence.length === 0,
          onClick: () => openMarketSourceModal(gs, viewer),
        }),
        el("button", {
          className: "btn btn-sm btn-crimson",
          text: "Pass Market Turn ⏭️",
          onClick: () => sendGameAction({ type: "market_pass" }),
        })
      );
    }
  } else if (gs.phase === "delivery_entry") {
    promptText =
      "🚙 Start of Night Delivery (8:00 P.M.): You must roll into the city at one of the five road entry points highlighted in gold on the map: B1 (Golden Gate Bridge), F1 (Bay Bridge), F5 (US-101), D6 (I-280), or A5 (Route 1). You may optionally Scout 1 neighborhood stack or deck card first.";
    if (gs.activePlayerIndex === viewer.index) {
      extraActions.push(
        el("button", {
          type: "button",
          className: "btn btn-sm",
          title: "Scout a neighborhood tile or card deck before selecting your Via entrance",
          text: "👁️ Scout",
          disabled: viewer.scoutedThisTurn,
          onClick: () => openScoutModal(gs, viewer),
        })
      );
    }
  } else if (gs.phase === "delivery") {
    const fineBase = gs.night === "Thursday" ? 12 : gs.night === "Friday" ? 20 : 32;
    const fineGate = Math.floor(fineBase / 2);
    if (gs.turn === 1 && viewer.movesRemaining === 0) {
      promptText = `Turn 1 (8:00 P.M.) at ${viewer.position || "Gate"}: ${viewer.transactedThisTurn ? "Transacted ✓" : "1 Transaction available"
        } • Scout (ends turn) or End Turn.`;
    } else {
      promptText = `Night Delivery (${gs.turnHourLabel}): ${viewer.movesRemaining} move left • ${viewer.transactedThisTurn ? "Transacted ✓" : "1 Transaction available"
        }. Exit before Turn 10 ends (${fineBase}d Curfew Fine; ${fineGate}d on a Gate).`;
    }
    if (gs.activePlayerIndex === viewer.index) {
      if (viewer.canReturnShortcut) {
        extraActions.push(
          el("button", {
            type: "button",
            className: "btn btn-sm",
            title: "Return unused Shortcut card to your hand (also returns automatically if you end your turn without crossing a blocked route)",
            text: "↩️ Return Shortcut",
            onClick: () => sendGameAction({ type: "return_shortcut" }),
          })
        );
      }
      const currCell = viewer.position && gs.romeBoard ? gs.romeBoard[viewer.position] : null;
      const currRev = currCell ? currCell.revealed : null;
      if (currCell && currCell.isForum && currRev && Array.isArray(currRev.buys) && currRev.buys.length > 0) {
        const bSpec = currRev.buys[0];
        extraActions.push(
          el("button", {
            type: "button",
            className: "btn btn-sm btn-primary",
            text: `🏛️ Forum Buy (${bSpec.category})`,
            onClick: () => navigateToMarketBoardForCategory(bSpec.category),
          })
        );
      }
      if (currRev && currRev.gamble) {
        const alreadyGambled = Boolean(viewer.gambledThisTurn);
        extraActions.push(
          el("button", {
            type: "button",
            className: "btn btn-sm",
            disabled: alreadyGambled || viewer.transactedThisTurn || viewer.cash <= 0,
            text: alreadyGambled ? "🎲 Gambled ✓" : "🎲 Stadium Gambling",
            onClick: () => openGambleModal(viewer),
          })
        );
      }
      extraActions.push(
        el("button", {
          type: "button",
          className: "btn btn-sm",
          title: "Scout a neighborhood tile or card deck at the end of your turn",
          text: "👁️ Scout",
          disabled: viewer.scoutedThisTurn,
          onClick: () => openScoutModal(gs, viewer),
        }),
        el("button", {
          type: "button",
          className: "btn btn-sm",
          text: "🗑️ Trash Top Tile/Card",
          disabled: viewer.trashedThisTurn || viewer.influence.length === 0,
          onClick: () => openTrashModal(gs, viewer),
        }),
        el("button", {
          type: "button",
          className: "btn btn-sm btn-crimson",
          title: "End your hourly turn",
          text: "End Turn ⏭️",
          onClick: () => sendGameAction({ type: "delivery_end_turn" }),
        })
      );
    }
  } else if (gs.phase === "cleanup") {
    promptText = `Dawn Clean-Up (${gs.night}): Buy Influence (${viewer.influenceBuyCost}d), manage Loans, and pay Henchman upkeep.`;
  } else if (gs.phase === "finished") {
    promptText = `Victory in Rome! ${gs.winner} wins as the wealthiest Night Merchant!`;
    extraActions.push(
      el("button", {
        type: "button",
        className: "btn btn-sm btn-primary",
        text: "🏆 Final Rankings & Sunday Reckoning",
        onClick: () => {
          const standings =
            Array.isArray(gs.finalStandings) && gs.finalStandings.length > 0
              ? gs.finalStandings
              : buildFallbackFinalStandings(gs);
          openFinalScoringModal(standings, {
            gameName: appState.gameSummary ? appState.gameSummary.name : "Roman Expedition",
            winnerName: gs.winner,
            night: gs.night,
          });
        },
      })
    );
  }

  return el("div", { className: "prompt-banner" }, el("span", { text: promptText }), el("div", { style: { display: "flex", gap: "0.45rem", flexWrap: "wrap" } }, ...extraActions));
}

function renderActiveClimateStrip(gs, viewer) {
  const pc = gs && gs.politicalClimate;
  if (!pc || !Array.isArray(pc.activeIds) || pc.activeIds.length === 0 || gs.phase === "setup_climate") {
    return null;
  }
  const allOptions =
    Array.isArray(pc.options) && pc.options.length > 0 ? pc.options : DEFAULT_POLITICAL_CLIMATE_OPTIONS;
  const activeOpts = pc.activeIds
    .map((id) => allOptions.find((o) => o.id === id))
    .filter(Boolean);
  if (activeOpts.length === 0) return null;

  return el(
    "div",
    { className: "active-climate-strip" },
    el("span", { className: "active-climate-strip-label", text: "🏛️ Enacted Decree:" }),
    el(
      "div",
      { className: "active-climate-pills" },
      ...activeOpts.map((opt) => {
        const fm = FACTION_META.find((f) => f.key === opt.factor);
        const isMid = opt.timing === "midgame";
        return el(
          "button",
          {
            type: "button",
            className: `active-climate-pill ${isMid ? "is-midgame" : "is-endgame"}`,
            style: fm ? { borderColor: fm.color } : {},
            title: `${opt.factorLabel || opt.factor} — ${opt.title}: ${opt.description}`,
            onClick: () => {
              appState.boardViewMode = appState.boardViewMode === "climate" ? "auto" : "climate";
              renderApp();
            },
          },
          fm
            ? el("img", { src: fm.gem, alt: opt.factor, className: "climate-pill-gem" })
            : el("span", { text: "📜" }),
          el("strong", { text: `${opt.factorLabel || opt.factor}:` }),
          el("span", { text: opt.shortText || opt.title })
        );
      })
    )
  );
}

function buildPoliticalClimateExplainerNode(_gs) {
  return el(
    "div",
    { className: "climate-explainer-panel" },
    el(
      "div",
      { className: "climate-explainer-title" },
      "📜 How the Political Climate Board Works"
    ),
    el(
      "p",
      { className: "climate-explainer-text" },
      "When you’re done selecting the influence and mission cards you’d like to keep, place your Representative pawn on one of the Decree squares of the Political Climate table. Only one Representative can be placed in each column."
    ),
    el(
      "p",
      { className: "climate-explainer-text" },
      "The decrees on the Political Climate table set rules that will grant bonuses for mission completion or faction alignment at the end of the game (rows 1 & 2) or change the gameplay (row 3)."
    ),
    el(
      "p",
      { className: "climate-explainer-text" },
      "Row 1 rules reward or penalize players based on superlatives (most missions completed, most/least favor with a given faction). Note that ties are decided by combat between the players."
    ),
    el(
      "p",
      { className: "climate-explainer-text" },
      "Row 2 rules reward or penalize players for each unit of faction loyalty/mission completion being measured."
    ),
    el(
      "p",
      { className: "climate-explainer-text" },
      "Row 3 rules change the in-game faction loyalty or mission completion mechanics."
    ),
    el(
      "p",
      { className: "climate-explainer-text" },
      "The last player to place a Representative receives the First Player Token."
    ),
    el(
      "p",
      { className: "climate-explainer-text" },
      "In a two player game, the second player to place a Representative places two Representatives and then the first player places a second Representative (for a total of four)."
    )
  );
}

function buildPoliticalClimateBoardGridNode(gs, viewer, interactiveDraft = false) {
  const pc = (gs && gs.politicalClimate) || {};
  const rawFactors =
    Array.isArray(pc.factors) && pc.factors.length > 0 ? pc.factors : DEFAULT_POLITICAL_CLIMATE_FACTORS;
  const options =
    Array.isArray(pc.options) && pc.options.length > 0 ? pc.options : DEFAULT_POLITICAL_CLIMATE_OPTIONS;
  const activeIds = new Set(Array.isArray(pc.activeIds) ? pc.activeIds : []);
  const activeByFactor = pc.activeByFactor || {};
  const canPickNow =
    Boolean(interactiveDraft) &&
    gs &&
    gs.phase === "setup_climate" &&
    viewer &&
    gs.activePlayerIndex === viewer.index;

  const colColumns = rawFactors.slice(0, 6).map((fac) => {
    const fKey = fac.id || fac.key || "";
    const fm = FACTION_META.find((f) => f.key === fKey);
    const colColor = fm ? fm.color : "#b45309";
    const colOpts = options
      .filter((o) => o.factor === fKey)
      .sort((a, b) => (Number(a.optionNumber) || 0) - (Number(b.optionNumber) || 0));
    const lockedOptId = activeByFactor[fKey] || null;
    return {
      fac,
      fKey,
      fm,
      colColor,
      colOpts,
      lockedOptId,
      headingText: fac.label || fKey,
    };
  });

  const colHeaderNodes = colColumns.map((col) =>
    el(
      "div",
      {
        className: `senate-col-header-box ${col.lockedOptId ? "has-active-option" : ""}`,
        style: { "--senate-col-accent": col.colColor },
      },
      col.fm
        ? el("img", { src: col.fm.gem, alt: col.headingText, className: "climate-factor-gem" })
        : el("span", { className: "climate-factor-scroll", text: "📜" }),
      el("span", { className: "climate-factor-title", text: col.headingText })
    )
  );

  // Strict 6-column x 3-row matrix (each selectable tile is itself the Enact button)
  const matrixCellNodes = [];
  for (let rowIdx = 0; rowIdx < 3; rowIdx++) {
    for (const col of colColumns) {
      const opt = col.colOpts[rowIdx];
      if (!opt) {
        matrixCellNodes.push(el("div", { className: "climate-option-card is-locked" }));
        continue;
      }
      const isSelected = activeIds.has(opt.id);
      const isLockedOut = Boolean(col.lockedOptId && !isSelected);
      const isSelectable = Boolean(canPickNow && !col.lockedOptId);
      const enactOption = () => sendGameAction({ type: "select_climate_option", optionId: opt.id });

      matrixCellNodes.push(
        el(
          "div",
          {
            className: `climate-option-card ${isSelected ? "is-active" : ""} ${isLockedOut ? "is-locked" : ""} ${isSelectable ? "is-selectable" : ""
              }`,
            style: { "--senate-col-accent": col.colColor },
            role: isSelectable ? "button" : undefined,
            tabIndex: isSelectable ? "0" : undefined,
            title: isSelectable ? `Enact ${opt.title}` : undefined,
            onClick: isSelectable ? enactOption : undefined,
            onKeyDown: isSelectable
              ? (e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  enactOption();
                }
              }
              : undefined,
          },
          el("div", { className: "climate-option-title", text: opt.title }),
          el("div", { className: "climate-option-desc", text: opt.description }),
          isSelected
            ? el("div", {
              className: "climate-option-status active",
              text: "✓ Enacted",
            })
            : isLockedOut
              ? el("div", { className: "climate-option-status locked", text: "Locked" })
              : null
        )
      );
    }
  }

  return el(
    "div",
    {
      className: "senate-climate-board-matrix",
      onScroll: (e) => {
        appState.climateBoardScrollLeft = e.currentTarget.scrollLeft;
      },
    },
    el(
      "div",
      { className: "senate-climate-stage" },
      el("div", { className: "senate-col-headers" }, ...colHeaderNodes),
      el("div", { className: "senate-climate-grid" }, ...matrixCellNodes)
    )
  );
}

function renderPoliticalClimateBoard(gs, viewer) {
  const pc = (gs && gs.politicalClimate) || {};
  const isDraftPhase = gs.phase === "setup_climate";
  const activeCount = Array.isArray(pc.activeIds) ? pc.activeIds.length : 0;
  const draftOrder = Array.isArray(pc.draftOrder) ? pc.draftOrder : [];
  const draftStep = Number(pc.draftStep) || 0;
  const isMyPick = isDraftPhase && gs.activePlayerIndex === viewer.index;

  return el(
    "div",
    { className: "senate-climate-board" },
    el(
      "div",
      { className: "panel-title fresco-banner-header fresco-griffin", style: { flexWrap: "wrap", gap: "0.5rem" } },
      el("span", { text: "🏛️ City Hall — Ballot Initiative Board" }),
      el(
        "div",
        { style: { display: "flex", alignItems: "center", gap: "0.45rem", flexWrap: "wrap" } },
        isDraftPhase
          ? el("span", {
            className: "badge",
            style: isMyPick
              ? { borderColor: "#16a34a", color: "#14532d", background: "#ecfdf5" }
              : { borderColor: "#d97706", color: "#7dd3fc", background: "rgba(14, 42, 84, 0.92)" },
            text: isMyPick ? "▶ Your Pick" : `Waiting on ${(gs.players[gs.activePlayerIndex] || {}).name || "Merchant"}`,
          })
          : el("span", {
            className: "badge",
            style: { borderColor: "#deb86c", color: "#fde6b0", background: "rgba(32, 14, 8, 0.72)" },
            text: `${activeCount} Enacted`,
          }),
        !isDraftPhase && appState.boardViewMode === "climate"
          ? el("button", {
            type: "button",
            className: "btn btn-sm",
            text: "↩️ Return to Active Board",
            onClick: () => {
              appState.boardViewMode = "auto";
              renderApp();
            },
          })
          : null
      )
    ),
    buildPoliticalClimateExplainerNode(gs),
    isDraftPhase && draftOrder.length > 0
      ? el(
        "div",
        { className: "climate-draft-order-bar" },
        el("span", { className: "climate-draft-order-lbl", text: "Draft Order:" }),
        ...draftOrder.map((pIdx, idx) => {
          const pl = gs.players[pIdx] || { name: `P${pIdx + 1}`, color: "Z3" };
          const pickDone = idx < draftStep;
          const pickCurr = idx === draftStep;
          const pickInfo = (pc.picks || [])[idx];
          return el(
            "span",
            {
              className: `climate-draft-chip ${pickDone ? "done" : pickCurr ? "current" : "upcoming"}`,
              title: pickInfo ? `Picked ${pickInfo.factor}: ${pickInfo.title}` : `Pick #${idx + 1}`,
            },
            el("strong", { text: `#${idx + 1} ${pl.name}` }),
            pickInfo ? el("span", { text: ` • ${pickInfo.factor}` }) : null
          );
        })
      )
      : null,
    buildPoliticalClimateBoardGridNode(gs, viewer, isDraftPhase)
  );
}

function renderSetupDiscardPanel(viewer) {
  const mDisc = appState.setupDiscardMissions;
  const iDisc = appState.setupDiscardInfluence;

  return el(
    "div",
    { className: "panel", style: { borderColor: "var(--gold-bright)" } },
    el(
      "h3",
      { className: "panel-title" },
      el("span", { text: "📜 Initial Setup: Discard 2 Missions & 2 Influence Cards" }),
      el("button", {
        className: "btn btn-sm",
        text: "Auto-Select 2 & 2",
        onClick: () => {
          mDisc.clear();
          iDisc.clear();
          viewer.missions.slice(-2).forEach((m) => mDisc.add(m.id));
          viewer.influence.slice(-2).forEach((c) => iDisc.add(c.id));
          renderApp();
        },
      })
    ),
    el("h4", { style: { margin: "0.35rem 0 0.5rem 0", color: "var(--gold-bright)" }, text: `Starting Missions (Select 2 to Discard — ${mDisc.size}/2)` }),
    el(
      "div",
      { className: "phys-cards-grid", style: { marginBottom: "1rem" } },
      ...viewer.missions.map((m) => {
        const isSel = mDisc.has(m.id);
        return renderPhysicalMissionCardNode(m, {
          selectable: true,
          selected: isSel,
          onClick: () => {
            if (isSel) mDisc.delete(m.id);
            else if (mDisc.size < 2) mDisc.add(m.id);
            renderApp();
          },
        });
      })
    ),
    el("h4", { style: { margin: "0.5rem 0", color: "var(--gold-bright)" }, text: `Starting Influence Cards (Select 2 to Discard — ${iDisc.size}/2)` }),
    el(
      "div",
      { className: "phys-cards-grid", style: { marginBottom: "1rem" } },
      ...viewer.influence.map((c) => {
        const isSel = iDisc.has(c.id);
        return renderPhysicalInfluenceCardNode(c, {
          selectable: true,
          selected: isSel,
          onClick: () => {
            if (isSel) iDisc.delete(c.id);
            else if (iDisc.size < 2) iDisc.add(c.id);
            renderApp();
          },
        });
      })
    ),
    el("button", {
      className: "btn btn-primary",
      disabled: mDisc.size !== 2 || iDisc.size !== 2,
      text: "✓ Confirm Starting Hand & Enter Political Climate Draft",
      onClick: () =>
        sendGameAction({
          type: "setup_discard",
          discardMissionIds: Array.from(mDisc),
          discardInfluenceIds: Array.from(iDisc),
        }),
    })
  );
}

function formatSignedFlat(val) {
  const n = Number(val) || 0;
  return n >= 0 ? `+${n}` : `${n}`;
}

function armDieCardAction(cardObj, mode = "reroll") {
  if (!cardObj || !cardObj.id) return;
  if (appState.armedDieAction && appState.armedDieAction.cardId === cardObj.id) {
    appState.armedDieAction = null;
  } else {
    appState.armedDieAction = {
      cardId: cardObj.id,
      cardName: cardObj.name || "Influence Card",
      mode,
    };
  }
  renderDiceOverlay();
  renderApp();
}

function handleDieSelectionClick(pend, viewer, targetSide = "player", dieIdx = 0) {
  if (!pend || !viewer) return;
  const hand = viewer.influence || [];
  if (appState.armedDieAction && appState.armedDieAction.cardId) {
    const armedCard = hand.find((c) => c.id === appState.armedDieAction.cardId);
    appState.armedDieAction = null;
    if (armedCard) {
      sendGameAction({
        type: "play_influence",
        cardId: armedCard.id,
        targetSide,
        dieIndex: dieIdx,
        targetIndex: dieIdx,
      });
      return;
    }
  }

  const stage = pend.stage || "pre_decision";
  const twistCard = hand.find((c) => String(c.name || "") === "Twist Of Fate");
  const luckyCard =
    (stage === "driver_fate_post_roll" || stage === "chart_post_roll") && pend.chartType !== "schizophrenic"
      ? hand.find((c) => String(c.name || "") === "Lucky Break")
      : null;

  if (twistCard && luckyCard) {
    showModal(
      "🎲 Modify Rolled Die — Choose Influence Card",
      el(
        "div",
        { style: { display: "flex", flexDirection: "column", gap: "0.65rem" } },
        el("p", {
          style: { margin: "0", fontSize: "0.88rem", color: "var(--text-main)" },
          text: "You hold both 'Twist Of Fate' and 'Lucky Break'. Choose how you want to modify this die:",
        }),
        el("button", {
          type: "button",
          className: "btn btn-primary",
          text: "🍀 Play 'Lucky Break' (+1 to This Die Roll)",
          onClick: () => {
            closeModal();
            sendGameAction({
              type: "play_influence",
              cardId: luckyCard.id,
              targetSide,
              dieIndex: dieIdx,
              targetIndex: dieIdx,
            });
          },
        }),
        el("button", {
          type: "button",
          className: "btn btn-crimson",
          text: "🎲 Play 'Twist Of Fate' (Re-Roll This Die)",
          onClick: () => {
            closeModal();
            sendGameAction({
              type: "play_influence",
              cardId: twistCard.id,
              targetSide,
              dieIndex: dieIdx,
              targetIndex: dieIdx,
            });
          },
        }),
        el("button", { type: "button", className: "btn", text: "Cancel", onClick: closeModal })
      )
    );
    return;
  }

  const chosen = twistCard || luckyCard;
  if (chosen) {
    sendGameAction({
      type: "play_influence",
      cardId: chosen.id,
      targetSide,
      dieIndex: dieIdx,
      targetIndex: dieIdx,
    });
  }
}

function renderInlineClickableDiceRow(pend, viewer, merchantLabel = "Your") {
  const stage = pend.stage || "pre_decision";
  const hand = (viewer && viewer.influence) || [];
  const hasTwist = hand.some((c) => String(c.name || "") === "Twist Of Fate");
  const hasLucky =
    (stage === "driver_fate_post_roll" || stage === "chart_post_roll") &&
    pend.chartType !== "schizophrenic" &&
    hand.some((c) => String(c.name || "") === "Lucky Break");
  const canModifyAny = hasTwist || hasLucky;
  const isArmed = Boolean(appState.armedDieAction);

  let actionHint = "Click to Modify";
  if (appState.armedDieAction) {
    actionHint = appState.armedDieAction.mode === "plus_one" ? "👆 Click for +1!" : "👆 Click to Re-Roll!";
  } else if (hasTwist && !hasLucky) {
    actionHint = "🔄 Click to Re-Roll";
  } else if (hasLucky && !hasTwist) {
    actionHint = "🍀 Click for +1";
  }

  const dieButtons = [];
  if (stage === "combat_post_roll") {
    const pDice = Array.isArray(pend.playerDiceObjs) ? pend.playerDiceObjs : [];
    pDice.forEach((d, idx) => {
      const rom = d.roman !== undefined ? String(d.roman) : toRomanDieSymbol(Number(d.value) || 0);
      const signNote = d.sign === 0 ? "🛡️ Block" : d.sign < 0 ? `-${rom} CP` : `+${rom} CP`;
      dieButtons.push(
        el(
          "button",
          {
            type: "button",
            className: `inline-roman-die-btn ${hasTwist ? "clickable-die" : ""} ${hasTwist && isArmed ? "armed-die" : ""}`,
            disabled: !hasTwist,
            title: hasTwist ? `Click this die to re-roll with 'Twist Of Fate'` : `${merchantLabel} ${d.label || "Die"}`,
            onClick: hasTwist ? () => handleDieSelectionClick(pend, viewer, "player", idx) : null,
          },
          el("span", { className: "inline-roman-die-face", text: rom }),
          el(
            "span",
            { className: "inline-roman-die-meta" },
            el("span", { className: "inline-roman-die-owner", text: `${merchantLabel} • ${d.label || `Die #${idx + 1}`}` }),
            el("span", {
              className: "inline-roman-die-action",
              text: hasTwist ? `${signNote} • ${actionHint}` : signNote,
            })
          )
        )
      );
    });
    const oDice = Array.isArray(pend.oppDiceObjs) ? pend.oppDiceObjs : [];
    oDice.forEach((d, idx) => {
      const rom = d.roman !== undefined ? String(d.roman) : toRomanDieSymbol(Number(d.value) || 0);
      dieButtons.push(
        el(
          "button",
          {
            type: "button",
            className: `inline-roman-die-btn ${hasTwist ? "clickable-die" : ""} ${hasTwist && isArmed ? "armed-die" : ""}`,
            disabled: !hasTwist,
            title: hasTwist ? `Click this opponent die to re-roll with 'Twist Of Fate'` : `Opponent ${d.label || "Die"}`,
            onClick: hasTwist ? () => handleDieSelectionClick(pend, viewer, "opponent", idx) : null,
          },
          el("span", { className: "inline-roman-die-face", text: rom }),
          el(
            "span",
            { className: "inline-roman-die-meta" },
            el("span", { className: "inline-roman-die-owner", text: `Opponent • ${d.label || `Die #${idx + 1}`}` }),
            el("span", {
              className: "inline-roman-die-action",
              text: hasTwist ? `+${rom} CP • ${actionHint}` : `+${rom} CP`,
            })
          )
        )
      );
    });
  } else if (stage === "driver_fate_post_roll" || stage === "chart_post_roll") {
    const rom = toRomanDieSymbol(Number(pend.chartRoll) || 0);
    const labelStr = stage === "driver_fate_post_roll" ? "Death Chart Die" : `${(pend.card && pend.card.name) || "Chart"} Die`;
    dieButtons.push(
      el(
        "button",
        {
          type: "button",
          className: `inline-roman-die-btn ${canModifyAny ? "clickable-die" : ""} ${canModifyAny && isArmed ? "armed-die" : ""}`,
          disabled: !canModifyAny,
          title: canModifyAny ? "Click directly on this die to re-roll or modify it!" : labelStr,
          onClick: canModifyAny ? () => handleDieSelectionClick(pend, viewer, "player", 0) : null,
        },
        el("span", { className: "inline-roman-die-face", text: rom }),
        el(
          "span",
          { className: "inline-roman-die-meta" },
          el("span", { className: "inline-roman-die-owner", text: labelStr }),
          el("span", {
            className: "inline-roman-die-action",
            text: canModifyAny ? actionHint : `Rolled ${rom}`,
          })
        )
      )
    );
  } else if (stage === "demand_post_roll") {
    const rom = toRomanDieSymbol(Number(pend.demandRoll) || 0);
    dieButtons.push(
      el(
        "button",
        {
          type: "button",
          className: `inline-roman-die-btn ${hasTwist ? "clickable-die" : ""} ${hasTwist && isArmed ? "armed-die" : ""}`,
          disabled: !hasTwist,
          title: hasTwist ? "Click directly on this die to re-roll with 'Twist Of Fate'!" : "Demand Die",
          onClick: hasTwist ? () => handleDieSelectionClick(pend, viewer, "player", 0) : null,
        },
        el("span", { className: "inline-roman-die-face", text: rom }),
        el(
          "span",
          { className: "inline-roman-die-meta" },
          el("span", { className: "inline-roman-die-owner", text: `${(pend.card && pend.card.name) || "Demand"} Die` }),
          el("span", {
            className: "inline-roman-die-action",
            text: hasTwist ? actionHint : `Rolled ${rom}`,
          })
        )
      )
    );
  } else if (stage === "gamble_post_roll") {
    const gRolls = Array.isArray(pend.gambleRolls) ? pend.gambleRolls : [];
    gRolls.forEach((val, idx) => {
      const rom = toRomanDieSymbol(Number(val) || 0);
      dieButtons.push(
        el(
          "button",
          {
            type: "button",
            className: `inline-roman-die-btn ${hasTwist ? "clickable-die" : ""} ${hasTwist && isArmed ? "armed-die" : ""}`,
            disabled: !hasTwist,
            title: hasTwist ? "Click directly on this die to re-roll with 'Twist Of Fate'!" : `Gamble Die #${idx + 1}`,
            onClick: hasTwist ? () => handleDieSelectionClick(pend, viewer, "player", idx) : null,
          },
          el("span", { className: "inline-roman-die-face", text: rom }),
          el(
            "span",
            { className: "inline-roman-die-meta" },
            el("span", { className: "inline-roman-die-owner", text: `Gamble Die #${idx + 1}` }),
            el("span", {
              className: "inline-roman-die-action",
              text: hasTwist ? actionHint : `Rolled ${rom}`,
            })
          )
        )
      );
    });
  }

  if (dieButtons.length === 0) return null;
  return el(
    "div",
    { style: { marginBottom: "0.75rem" } },
    canModifyAny
      ? el("div", {
        style: { fontSize: "0.78rem", fontWeight: "700", color: "#38bdf8", marginBottom: "0.35rem" },
        text: "👆 Click Directly on Any Die Below to Re-Roll or Modify It:",
      })
      : null,
    el("div", { className: "inline-clickable-dice-bar" }, ...dieButtons)
  );
}

function buildConsumableWeaponPickerNodes(consumables, selectedSet, onChange) {
  return consumables.map((it) => {
    const c = it.combat || {};
    const effParts = [];
    if (c.dice) effParts.push(`+${c.dice}(R)`);
    if (c.flat) effParts.push(`${formatSignedFlat(c.flat)} CP`);
    const effLabel = effParts.join(" ") || "+1 CP";
    const isChecked = selectedSet.has(it.id);

    return el(
      "div",
      { className: `consumable-weapon-opt-card ${isChecked ? "selected" : ""}` },
      el(
        "div",
        { style: { flex: "1", minWidth: "200px" } },
        el("div", {
          style: { fontWeight: "800", fontSize: "0.9rem", color: isChecked ? "#991b1b" : "var(--text-main)" },
          text: `🗡️ ${it.name || it.item || "Weapon"} (${effLabel} — Destroyed if Used)`,
        }),
        el("div", {
          style: { fontSize: "0.78rem", color: "var(--text-muted)", marginTop: "0.18rem" },
          text: isChecked
            ? `Selected for this combat: Grants ${effLabel}, then is destroyed and removed from your SUV.`
            : "Kept safe on your SUV: Contributes 0 CP in this combat and is NOT destroyed.",
        }),
        it.isMissionCargo
          ? el("div", {
            style: { fontSize: "0.76rem", color: "#b91c1c", fontWeight: "700", marginTop: "0.22rem" },
            text: "⚠️ Mission Cargo: Using & destroying this cargo will require loading replacement cargo at its origin again!",
          })
          : null
      ),
      el(
        "div",
        { style: { display: "flex", gap: "0.4rem", flexWrap: "wrap", flexShrink: "0" } },
        el("button", {
          type: "button",
          className: `btn btn-sm ${isChecked ? "btn-crimson" : ""}`,
          text: `🗡️ Use (${effLabel}, Destroyed)`,
          onClick: () => {
            selectedSet.add(it.id);
            onChange();
          },
        }),
        el("button", {
          type: "button",
          className: `btn btn-sm ${!isChecked ? "btn-primary" : ""}`,
          text: "🛡️ Do Not Use (Keep Safe)",
          onClick: () => {
            selectedSet.delete(it.id);
            onChange();
          },
        })
      )
    );
  });
}

function openConsumableWeaponsPromptModal(viewer, consumables, baseActionPayload) {
  const selectedSet = new Set();
  const listContainer = el("div", { style: { display: "flex", flexDirection: "column", gap: "0.55rem", margin: "0.75rem 0" } });
  const confirmBtn = el("button", {
    type: "button",
    className: "btn btn-crimson",
    text: "🎲 Roll Combat Dice",
    onClick: () => {
      closeModal();
      sendGameAction({
        ...baseActionPayload,
        useConsumableIds: Array.from(selectedSet),
      });
    },
  });

  function refreshView() {
    listContainer.replaceChildren(...buildConsumableWeaponPickerNodes(consumables, selectedSet, refreshView));
    const count = selectedSet.size;
    confirmBtn.textContent =
      count > 0
        ? `⚔️ Use ${count} Weapon${count === 1 ? "" : "s"} (Destroyed) & Roll Combat Dice`
        : "🛡️ Keep Weapon(s) Safe on SUV & Roll Combat Dice";
  }

  refreshView();

  showModal(
    "🗡️ Consumable Weapon(s) on SUV — Decide Before Rolling!",
    el(
      "div",
      {},
      el("p", {
        style: { margin: "0", fontSize: "0.88rem", color: "var(--text-main)" },
        text: "You carry weapon(s) that are destroyed if used in combat. Choose whether to expend them in this fight before rolling the combat dice:",
      }),
      listContainer,
      el(
        "div",
        { style: { display: "flex", justifyContent: "space-between", gap: "0.6rem", flexWrap: "wrap", marginTop: "0.9rem" } },
        el("button", { type: "button", className: "btn", text: "Cancel", onClick: closeModal }),
        confirmBtn
      )
    )
  );
}

function initiateCombatWithConsumablePrompt(viewer, baseActionPayload) {
  const consumables = ((viewer && viewer.suv) || []).filter(
    (it) => it && it.combat && it.combat.consumable
  );
  if (consumables.length === 0) {
    sendGameAction(baseActionPayload);
    return;
  }
  openConsumableWeaponsPromptModal(viewer, consumables, baseActionPayload);
}

function buildCombatInfluenceCardActionNode(rc, encPlayerName, oppName, isOtherPlayerEncounter) {
  const nm = String(rc.name || "");
  if (
    nm === "Mercenary Ambush" ||
    nm === "Distraction" ||
    nm === "Gladiator's Intervention" ||
    nm === "Flying Chamber Pot"
  ) {
    const effectShort =
      nm === "Mercenary Ambush"
        ? "+2(R)"
        : nm === "Distraction"
          ? "-1(R)"
          : nm === "Gladiator's Intervention"
            ? "+1(R)"
            : "+1 CP";
    const defaultMerchantFirst = nm !== "Distraction";
    const btnPlayer = el("button", {
      className: `btn btn-sm ${defaultMerchantFirst ? "btn-primary" : ""}`,
      style: { width: "100%", fontSize: "0.7rem", padding: "0.22rem 0.35rem" },
      text: `🎯 ${effectShort} → ${isOtherPlayerEncounter ? encPlayerName : "Your Side"}`,
      onClick: () => sendGameAction({ type: "play_influence", cardId: rc.id, targetSide: "player" }),
    });
    const btnOpp = el("button", {
      className: `btn btn-sm ${!defaultMerchantFirst ? "btn-primary" : ""}`,
      style: { width: "100%", fontSize: "0.7rem", padding: "0.22rem 0.35rem" },
      text: `🎯 ${effectShort} → ${oppName || "Opponent"}`,
      onClick: () => sendGameAction({ type: "play_influence", cardId: rc.id, targetSide: "opponent" }),
    });
    return el(
      "div",
      { style: { display: "flex", flexDirection: "column", gap: "0.25rem", width: "100%" } },
      defaultMerchantFirst ? btnPlayer : btnOpp,
      defaultMerchantFirst ? btnOpp : btnPlayer
    );
  }
  const gsCurr = appState.gameState;
  const viewerCurr =
    gsCurr && Array.isArray(gsCurr.players) ? gsCurr.players[gsCurr.viewerPlayerIndex || 0] : null;
  const needsThugSwap =
    nm.includes("Thug") && viewerCurr && !doesItemFitWithoutSwap(viewerCurr, { reqHenchmen: 1 });
  return el("button", {
    className: "btn btn-sm btn-primary",
    style: { width: "100%" },
    text:
      nm === "Casus Belli"
        ? "⚔️ Play Casus Belli"
        : needsThugSwap
          ? `Play ${nm} (Fire Henchman)`
          : `Play ${nm}`,
    onClick: () => triggerInfluenceCardPlay(gsCurr, viewerCurr, rc),
  });
}

function renderOpponentPublicSUVSummaryNode(gs, encPlayer, viewer, theme = "light") {
  if (!encPlayer) return null;
  const isDark = theme === "dark";
  const suvItems = Array.isArray(encPlayer.suv) ? encPlayer.suv : [];
  const henchmanItems = Array.isArray(encPlayer.henchmen) ? encPlayer.henchmen : [];
  const usedBlocks = Number(encPlayer.usedBlocks) || 0;
  const maxBlocks = Number(encPlayer.maxBlocks) || 6;
  const usedHenchmen = Number(encPlayer.usedHenchmen) || 0;
  const maxHenchmen = Number(encPlayer.maxHenchmen) || 2;
  const cashVal = Number(encPlayer.cash) || 0;
  const favorObj = encPlayer.favor || {};
  const favorEntries = Object.entries(favorObj)
    .filter(([, v]) => Number(v) !== 0)
    .map(([f, v]) => `${f} ${Number(v) > 0 ? `+${v}` : v}`);

  const pillBg = isDark ? "rgba(255, 248, 232, 0.1)" : "#fffbeb";
  const pillBorder = isDark ? "rgba(212, 175, 55, 0.45)" : "#c4a46b";
  const pillColor = isDark ? "#fef3c7" : "#ffffff";
  const subColor = isDark ? "#fcd34d" : "#7dd3fc";

  const goodPills =
    suvItems.length === 0
      ? [
        el("span", {
          style: { fontSize: "0.78rem", fontStyle: "italic", color: isDark ? "#d6c5ab" : "var(--text-muted)" },
          text: "None (Empty SUV)",
        }),
      ]
      : suvItems.map((it) => {
        const blocks = Math.max(1, Number(it.blocks) || 1);
        const track = it.track || it.category || "Good";
        const sub = it.subcategory && it.subcategory !== track ? `${track} · ${it.subcategory}` : track;
        const baseVal =
          !it.isMissionCargo && Array.isArray(it.sell) && it.sell.length >= 3 ? `= ${it.sell[2]}(d)` : null;
        const metaParts = [sub, `${blocks}■`];
        if (baseVal) metaParts.push(baseVal);
        if (it.isMissionCargo) metaParts.push("Mission Cargo");
        if (it.combatText && it.track === "Weapons" && !String(it.combatText).includes("0 CP")) {
          metaParts.push(it.combatText);
        }
        return el(
          "span",
          {
            style: {
              display: "inline-flex",
              alignItems: "center",
              gap: "0.3rem",
              padding: "0.18rem 0.5rem",
              borderRadius: "4px",
              background: pillBg,
              border: `1px solid ${pillBorder}`,
              color: pillColor,
              fontSize: "0.77rem",
              lineHeight: "1.25",
            },
          },
          el("strong", { text: it.name || it.item || "Good" }),
          el("span", {
            style: { color: subColor, fontSize: "0.72rem", fontWeight: "600" },
            text: `(${metaParts.join(" • ")})`,
          })
        );
      });

  const henchmanPills =
    henchmanItems.length === 0
      ? [
        el("span", {
          style: { fontSize: "0.78rem", fontStyle: "italic", color: isDark ? "#d6c5ab" : "var(--text-muted)" },
          text: "None",
        }),
      ]
      : henchmanItems.map((g) => {
        const cText = g.combatText || "+CP • Absorbs 1 Wound";
        return el(
          "span",
          {
            style: {
              display: "inline-flex",
              alignItems: "center",
              gap: "0.3rem",
              padding: "0.18rem 0.5rem",
              borderRadius: "4px",
              background: pillBg,
              border: `1px solid ${pillBorder}`,
              color: pillColor,
              fontSize: "0.77rem",
              lineHeight: "1.25",
            },
          },
          el("strong", { text: `🛡️ ${g.name || "Henchman"}` }),
          el("span", {
            style: { color: subColor, fontSize: "0.72rem", fontWeight: "600" },
            text: `(${cText})`,
          })
        );
      });

  return el(
    "div",
    {
      className: "opponent-public-suv-inspector",
      style: {
        width: "100%",
        padding: isDark ? "0.55rem 0.75rem" : "0.65rem 0.85rem",
        marginBottom: isDark ? "0.45rem" : "0.85rem",
        borderRadius: "5px",
        background: isDark ? "rgba(24, 13, 8, 0.78)" : "#f9f3e3",
        border: isDark ? "1px solid rgba(212, 175, 55, 0.55)" : "1.5px solid #b58d4c",
        boxShadow: isDark ? "none" : "var(--bevel-sunken)",
        textAlign: "left",
      },
    },
    el(
      "div",
      {
        style: {
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          gap: "0.5rem",
          flexWrap: "wrap",
          marginBottom: "0.38rem",
        },
      },
      el(
        "div",
        {
          style: {
            display: "flex",
            alignItems: "center",
            gap: "0.45rem",
            flexWrap: "wrap",
            fontSize: "0.8rem",
            fontWeight: "700",
            color: isDark ? "#fde68a" : "#5c2d16",
          },
        },
        el("span", { text: `🛒 ${encPlayer.name}'s Public SUV:` }),
        el("span", {
          style: { fontWeight: "600", color: isDark ? "#fef3c7" : "#ffffff" },
          text: `💰 ${cashVal}(d)  •  📦 ${usedBlocks}/${maxBlocks}■ Goods  •  🛡️ ${usedHenchmen}/${maxHenchmen}▲ Henchmen`,
        }),
        favorEntries.length > 0
          ? el("span", {
            style: { fontSize: "0.74rem", fontWeight: "600", color: subColor },
            text: `•  💎 Favor: ${favorEntries.join(", ")}`,
          })
          : null
      ),
      gs
        ? el("button", {
          type: "button",
          className: "btn btn-sm",
          style: { fontSize: "0.72rem", padding: "0.18rem 0.55rem" },
          text: "🔍 Inspect Full SUV Mat",
          onClick: (e) => {
            e.stopPropagation();
            openPlayerSUVModal(gs, encPlayer, viewer);
          },
        })
        : null
    ),
    el(
      "div",
      {
        style: {
          display: "flex",
          alignItems: "center",
          gap: "0.35rem",
          flexWrap: "wrap",
          marginBottom: "0.28rem",
        },
      },
      el("span", {
        style: { fontSize: "0.76rem", fontWeight: "700", color: isDark ? "#fcd34d" : "#ff6ec7" },
        text: "Goods:",
      }),
      ...goodPills
    ),
    el(
      "div",
      {
        style: {
          display: "flex",
          alignItems: "center",
          gap: "0.35rem",
          flexWrap: "wrap",
        },
      },
      el("span", {
        style: { fontSize: "0.76rem", fontWeight: "700", color: isDark ? "#fcd34d" : "#ff6ec7" },
        text: "Henchmen:",
      }),
      ...henchmanPills
    )
  );
}

function renderPendingEncounterPanel(gs, viewer) {
  const panelNode = renderPendingEncounterPanelCore(gs, viewer);
  if (!panelNode || !gs || !gs.pendingEncounter || !viewer) return panelNode;
  const pend = gs.pendingEncounter;
  if (pend.playerIndex !== viewer.index) {
    const encPlayer = (gs.players && gs.players[pend.playerIndex]) || null;
    const summaryNode = renderOpponentPublicSUVSummaryNode(gs, encPlayer, viewer, "light");
    if (summaryNode) {
      const titleEl = panelNode.querySelector && panelNode.querySelector(".panel-title");
      if (titleEl && titleEl.nextSibling) {
        panelNode.insertBefore(summaryNode, titleEl.nextSibling);
      } else {
        panelNode.prepend(summaryNode);
      }
    }
  }
  return panelNode;
}

function getEncounterActiveDemandKind(pend) {
  if (!pend || (pend.stage || "pre_decision") !== "pre_decision") return null;
  if (pend.combatMandatory) return null;
  const cEnc = pend.card;
  if (!cEnc || typeof cEnc !== "object") return null;
  const reaction = String(pend.reaction || "");
  const actionText = String(cEnc.actionText || "").trim();
  if ((reaction !== "demand" && reaction !== "demand_strict") || actionText.startsWith("?")) {
    return null;
  }
  if (cEnc.mission || !actionText) return "other";
  const clauseMatch = actionText.match(/\((?![dDrR]\))/);
  const primaryText = clauseMatch ? actionText.slice(0, clauseMatch.index).trim() : actionText;
  const primaryLow = primaryText.toLowerCase();
  if (primaryLow.includes("influence")) return "influence";
  if (primaryText.includes("(d)") || primaryText.includes("฿") || primaryLow.includes("cash")) return "cash";
  return "goods";
}

function isInfluenceCardPlayableNow(gs, viewer, c) {
  if (!gs || !viewer || !c) return false;
  if (gs.phase === "setup_discard" || gs.phase === "setup_climate" || gs.phase === "finished") return false;
  const cName = String(c.name || "");
  const effCode = String(c.effectCode || "");
  const pend = gs.pendingEncounter;
  const pendStage = pend ? pend.stage || "pre_decision" : null;
  const isViewerInvolvedInPend =
    Boolean(pend) && (pend.playerIndex === viewer.index || pend.interveningPlayerIndex === viewer.index);
  const isViewerOwnPend = Boolean(pend) && pend.playerIndex === viewer.index;
  const isActiveTurnNoPend =
    gs.activePlayerIndex === viewer.index &&
    !pend &&
    !viewer.pendingNpcOffer &&
    !viewer.pendingSUVOverflow &&
    !viewer.pendingMarketReward &&
    !viewer.pendingTop3Reorder;

  if (cName.includes("Distraction") || cName.includes("Mercenary")) {
    return (
      isViewerInvolvedInPend &&
      pendStage === "pre_decision" &&
      Boolean(pend.canInitiateCombat || pend.combatMandatory || pend.combatThreatened)
    );
  }
  if (cName.includes("Gladiator") || cName.includes("Flying Chamber Pot")) {
    return isViewerInvolvedInPend && pendStage === "combat_post_roll";
  }
  if (cName === "Twist Of Fate") {
    return (
      isViewerInvolvedInPend &&
      [
        "combat_post_roll",
        "driver_fate_post_roll",
        "chart_post_roll",
        "demand_post_roll",
        "gamble_post_roll",
      ].includes(pendStage)
    );
  }
  if (cName === "Lucky Break") {
    return (
      isViewerInvolvedInPend &&
      ["driver_fate_post_roll", "chart_post_roll"].includes(pendStage) &&
      ["death", "mob", "theater"].includes(pend.chartType)
    );
  }
  if (cName.includes("Man Of The People")) {
    return (
      isViewerOwnPend &&
      ["chart_pre_roll", "chart_post_roll"].includes(pendStage) &&
      pend.chartType === "mob" &&
      !pend.ignoreMobActive
    );
  }
  if (cName.includes("Dramaturge")) {
    return (
      isViewerOwnPend &&
      ["chart_pre_roll", "chart_post_roll"].includes(pendStage) &&
      pend.chartType === "theater" &&
      !pend.ignoreTheaterActive
    );
  }
  if (cName === "Casus Belli") {
    return isViewerOwnPend && pendStage === "pre_decision" && !pend.canInitiateCombat && !pend.combatMandatory;
  }
  if (cName.includes("Supplicant")) {
    return isViewerOwnPend && pendStage === "pre_decision";
  }
  if (cName.includes("Trained Dog")) {
    return isViewerOwnPend && pendStage === "pre_decision" && getEncounterActiveDemandKind(pend) === "cash";
  }
  if (cName.includes("Plea")) {
    return isViewerOwnPend && pendStage === "pre_decision" && getEncounterActiveDemandKind(pend) === "goods";
  }
  if (cName.includes("Match Fixing")) {
    const revTile =
      viewer.position && gs.romeBoard && gs.romeBoard[viewer.position]
        ? gs.romeBoard[viewer.position].revealed
        : null;
    return (
      gs.phase === "delivery" &&
      isActiveTurnNoPend &&
      !viewer.exitedRome &&
      !viewer.nightEnded &&
      !viewer.transactedThisTurn &&
      !viewer.gambledThisTurn &&
      Number(viewer.cash || 0) > 0 &&
      Boolean(revTile && revTile.gamble) &&
      !(viewer.turnEffects && viewer.turnEffects.matchFixing)
    );
  }
  if (cName.includes("Change Of Plans")) {
    const revTile =
      viewer.position && gs.romeBoard && gs.romeBoard[viewer.position]
        ? gs.romeBoard[viewer.position].revealed
        : null;
    return gs.phase === "delivery" && isActiveTurnNoPend && !viewer.exitedRome && !viewer.nightEnded && Boolean(revTile);
  }
  if (cName.includes("Shortcut") || effCode === "shortcut") {
    return (
      gs.phase === "delivery" &&
      isActiveTurnNoPend &&
      Boolean(viewer.position) &&
      !viewer.exitedRome &&
      !viewer.nightEnded &&
      Number(viewer.movesRemaining || 0) > 0 &&
      !(viewer.turnEffects && viewer.turnEffects.shortcut)
    );
  }
  if (cName.includes("Make Haste")) {
    return gs.phase === "delivery" && isActiveTurnNoPend && Boolean(viewer.position) && !viewer.exitedRome && !viewer.nightEnded;
  }
  if (cName.includes("Favor") || cName.includes("Thug")) {
    return isActiveTurnNoPend || (isViewerOwnPend && pendStage === "pre_decision");
  }
  return isActiveTurnNoPend;
}

function renderPendingEncounterPanelCore(gs, viewer) {
  const pend = gs.pendingEncounter;
  const stage = pend.stage || "pre_decision";
  const card = pend.card || {};
  const encPlayer = (gs.players && gs.players[pend.playerIndex]) || viewer;
  const isOtherPlayerEncounter = pend.playerIndex !== viewer.index;
  const merchantLabel = isOtherPlayerEncounter ? `${encPlayer.name}'s` : "Your";

  // Stage 0A: Non-Person Event Encounter Card (e.g., Salve!, Brutta Figura, Procession, Ushered Along, Road Blocked)
  if (stage === "event_pre_resolve") {
    const deckLabel = String(pend.deck || card.deck || "Encounter").toUpperCase();
    return el(
      "div",
      {
        id: "pending-encounter-panel",
        className: "panel",
        style: { borderColor: "var(--gold-bright)" },
      },
      el(
        "h3",
        { className: "panel-title" },
        el("span", {
          text: `📜 Event Encounter Drawn (${deckLabel} Deck): ${card.name || "Encounter Event"}`,
        }),
        el("span", {
          style: { fontSize: "0.78rem", color: "var(--gold-bright)" },
          text: "👆 Review the Encounter Card & Click to Resolve!",
        })
      ),
      el(
        "div",
        { className: "encounter-interactive-layout" },
        renderPhysicalEncounterCardNode(card, pend, {
          interactive: !isOtherPlayerEncounter,
          onFulfill: () => sendGameAction({ type: "resolve_encounter", decision: "resolve_event" }),
        }),
        el(
          "div",
          {},
          el(
            "div",
            { style: { display: "flex", gap: "0.55rem", flexWrap: "wrap", marginBottom: "0.75rem", fontSize: "0.82rem" } },
            pend.encounterSource
              ? el("span", {
                className: "badge",
                style: { borderColor: "#d97706", color: "#7dd3fc", background: "rgba(14, 42, 84, 0.92)" },
                text: `📍 ${pend.encounterSource}`,
              })
              : null,
            el("span", { className: "badge", text: `Merchant: ${encPlayer.name}` }),
            el("span", { className: "badge", text: `Deck: ${deckLabel}` }),
            el("span", { className: "badge", text: "Event Card (Mandatory Effect)" })
          ),
          el(
            "div",
            {
              style: {
                padding: "0.75rem 0.9rem",
                background: "rgba(14, 42, 84, 0.92)",
                border: "1.5px solid #d97706",
                borderRadius: "4px",
                fontSize: "0.88rem",
                color: "#7dd3fc",
                marginBottom: "0.95rem",
                boxShadow: "var(--bevel-sunken)",
              },
            },
            el("div", {
              style: { fontWeight: "800", marginBottom: "0.3rem", fontSize: "0.94rem" },
              text: `📜 ${card.name || "Event"}:`,
            }),
            el("div", {
              style: { color: "var(--text-main)", lineHeight: "1.45" },
              text: card.actionText || "Resolve this Encounter card's effect.",
            })
          ),
          !isOtherPlayerEncounter
            ? el("button", {
              type: "button",
              className: "btn btn-primary",
              style: { fontSize: "0.95rem", padding: "0.55rem 1.25rem" },
              text: `▶ Resolve Encounter: "${card.name || "Continue"}"`,
              onClick: () => sendGameAction({ type: "resolve_encounter", decision: "resolve_event" }),
            })
            : el("div", {
              style: { fontSize: "0.84rem", color: "var(--text-muted)" },
              text: `Waiting for ${encPlayer.name} to acknowledge and resolve ${card.name}...`,
            })
        )
      )
    );
  }

  // Stage 0B: Table/Chart Encounter Pre-Roll Presentation (Protesters, Open Mic, Schizophrenic)
  if (stage === "chart_pre_roll") {
    const cType = pend.chartType || "mob";
    const iconSrc =
      cType === "mob"
        ? "/assets/icons/angry_mob.png"
        : cType === "theater"
          ? "/assets/icons/theater_masks.png"
          : "/assets/icons/schizophrenic_icon.png";
    const chartTitle =
      cType === "mob" ? "Protesters" : cType === "theater" ? "Open Mic" : "Schizophrenic";
    const chartRows =
      cType === "mob"
        ? [
          { roll: "0", color: "#ff6ec7", bg: "rgba(68, 12, 48, 0.92)", border: "#dc2626", title: "Roll 0 — Wine Looted:", desc: "The mob drinks all Wine on your SUV!" },
          { roll: "I", color: "#92400e", bg: "#fffbeb", border: "#d97706", title: "Roll I — Grain Looted:", desc: "The mob loots all Grain on your SUV!" },
          { roll: "II", color: "#7dd3fc", bg: "rgba(14, 42, 84, 0.92)", border: "#ca8a04", title: "Roll II — Cargo Seized:", desc: "Lose the single most expensive Good on your SUV." },
          { roll: "III", color: "#15803d", bg: "#f0fdf4", border: "#16a34a", title: "Roll III — Clamors Noisily:", desc: "Safe passage! No cargo lost — your turn continues." },
        ]
        : cType === "theater"
          ? [
            { roll: "0", color: "#ff6ec7", bg: "rgba(68, 12, 48, 0.92)", border: "#dc2626", title: "Roll 0 — Roasted:", desc: "Undo every gem change you got from Positive outcomes (satisfying demands, accepting offers, Influence cards, completed missions)." },
            { roll: "I", color: "#15803d", bg: "#f0fdf4", border: "#16a34a", title: "Roll I — The Bit Clears Your Name:", desc: "Undo every gem change you got from Hostile outcomes (refused threats, combat, failed missions)." },
            { roll: "II", color: "#7dd3fc", bg: "rgba(14, 42, 84, 0.92)", border: "#ca8a04", title: "Roll II — Blocked by Revelers:", desc: "Lose the rest of this turn AND skip your next turn." },
            { roll: "III", color: "#14532d", bg: "#ecfdf5", border: "#15803d", title: "Roll III — Inspired Patron:", desc: "Roll 1(R) and draw that many Influence cards!" },
          ]
          : [
            { roll: "0", color: "#ff6ec7", bg: "rgba(68, 12, 48, 0.92)", border: "#dc2626", title: "Roll 0 — Bare Prophecy:", desc: "Accept the mandatory Mission (0 bonus Influence sealed)." },
            { roll: "I–II", color: "#92400e", bg: "#fffbeb", border: "#d97706", title: "Roll I or II — Fated Omen:", desc: "Accept the mandatory Mission + seal 1 or 2 Influence cards unlocked on completion." },
            { roll: "III", color: "#15803d", bg: "#f0fdf4", border: "#16a34a", title: "Roll III — Auspicious Vision:", desc: "Accept the mandatory Mission + seal 3 Influence cards unlocked on completion!" },
          ];

    const preChartCards = !isOtherPlayerEncounter
      ? (viewer.influence || []).filter((c) => {
        const nm = String(c.name || "");
        if (cType === "mob" && nm === "Man Of The People") return true;
        if (cType === "theater" && nm === "Dramaturge") return true;
        return false;
      })
      : [];
    const autoTreatThree =
      (cType === "mob" && pend.ignoreMobActive) || (cType === "theater" && pend.ignoreTheaterActive);

    const visualCardNode = el(
      "div",
      {
        className: `phys-card ${!isOtherPlayerEncounter ? "interactive-large" : ""}`,
        style: {
          width: "235px",
          flexShrink: "0",
          background: "#f4ebd9",
          border: "3px solid #8a6421",
          borderRadius: "10px",
          overflow: "hidden",
          cursor: !isOtherPlayerEncounter ? "pointer" : "default",
          boxShadow: "0 10px 24px rgba(0,0,0,0.45)",
        },
        title: !isOtherPlayerEncounter ? `Click to resolve ${chartTitle}!` : chartTitle,
        onClick: !isOtherPlayerEncounter
          ? () => sendGameAction({ type: "resolve_encounter", decision: "roll_chart_encounter" })
          : null,
      },
      el(
        "div",
        {
          style: {
            background: cType === "mob" ? "#7f1d1d" : cType === "theater" ? "#4c1d95" : "#1e3a8a",
            color: "#fef08a",
            padding: "0.45rem 0.65rem",
            fontFamily: "Cinzel, Georgia, serif",
            fontWeight: "800",
            fontSize: "0.86rem",
            textAlign: "center",
            letterSpacing: "0.05em",
          },
        },
        chartTitle.toUpperCase()
      ),
      el(
        "div",
        {
          style: {
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            padding: "0.85rem 0.7rem",
            gap: "0.5rem",
            color: "#291d12",
          },
        },
        el("img", {
          src: iconSrc,
          alt: chartTitle,
          style: { width: "76px", height: "76px", objectFit: "contain" },
        }),
        el("div", {
          style: {
            fontSize: "0.72rem",
            fontWeight: "800",
            padding: "0.18rem 0.55rem",
            borderRadius: "999px",
            background: "rgba(138, 100, 33, 0.16)",
            border: "1px solid rgba(138, 100, 33, 0.45)",
          },
          text: "ROLL 1 ROME DIE (0–III)",
        }),
        el("div", {
          style: { fontSize: "0.76rem", textAlign: "center", lineHeight: "1.35" },
          text: card.actionText || `Roll 1(R) on the ${chartTitle} Chart.`,
        }),
        !isOtherPlayerEncounter
          ? el("span", {
            className: "enc-click-hint-pill fulfill",
            text: autoTreatThree ? "👆 Click to Resolve as III" : "👆 Click to Roll 1(R)",
          })
          : null
      )
    );

    return el(
      "div",
      {
        id: "pending-encounter-panel",
        className: "panel",
        style: { borderColor: "var(--gold-bright)" },
      },
      el(
        "h3",
        { className: "panel-title" },
        el("span", { text: `🎭 Encounter in Rome: ${chartTitle}` }),
        el("span", {
          style: { fontSize: "0.78rem", color: "var(--gold-bright)" },
          text: "👆 Review the Encounter & Click to Roll!",
        })
      ),
      el(
        "div",
        { className: "encounter-interactive-layout" },
        el(
          "div",
          { style: { display: "flex", gap: "0.75rem", flexWrap: "wrap", alignItems: "flex-start" } },
          visualCardNode,
          cType === "schizophrenic" && pend.schizophrenicMission
            ? el(
              "div",
              { style: { width: "225px" } },
              renderPhysicalMissionCardNode(pend.schizophrenicMission, { showStatusTag: false })
            )
            : null
        ),
        el(
          "div",
          {},
          el(
            "div",
            { style: { display: "flex", gap: "0.55rem", flexWrap: "wrap", marginBottom: "0.75rem", fontSize: "0.82rem" } },
            pend.encounterSource
              ? el("span", {
                className: "badge",
                style: { borderColor: "#d97706", color: "#7dd3fc", background: "rgba(14, 42, 84, 0.92)" },
                text: `📍 ${pend.encounterSource}`,
              })
              : null,
            el("span", { className: "badge", text: `Merchant: ${encPlayer.name}` }),
            el("span", { className: "badge", text: `Encounter Type: ${chartTitle}` })
          ),
          autoTreatThree
            ? el("div", {
              style: {
                padding: "0.55rem 0.8rem",
                background: "#f0fdf4",
                border: "1.5px solid #16a34a",
                borderRadius: "4px",
                color: "#14532d",
                fontSize: "0.84rem",
                fontWeight: "700",
                marginBottom: "0.75rem",
                boxShadow: "var(--bevel-sunken)",
              },
              text: `✨ Active Influence Protection: Your ${chartTitle} encounter will automatically resolve as Roll III!`,
            })
            : null,
          el(
            "div",
            {
              style: {
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(185px, 1fr))",
                gap: "0.5rem",
                marginBottom: "0.85rem",
                fontSize: "0.8rem",
              },
            },
            ...chartRows.map((row) =>
              el(
                "div",
                {
                  style: {
                    padding: "0.5rem 0.6rem",
                    background: row.bg,
                    borderRadius: "4px",
                    border: `1px solid ${row.border}`,
                    boxShadow: "var(--bevel-sunken)",
                  },
                },
                el("strong", { style: { color: row.color }, text: row.title }),
                el("div", { style: { marginTop: "0.15rem", color: "var(--text-main)" }, text: row.desc })
              )
            )
          ),
          preChartCards.length > 0 && !autoTreatThree
            ? el(
              "div",
              { style: { display: "flex", gap: "0.5rem", flexWrap: "wrap", marginBottom: "0.75rem" } },
              ...preChartCards.map((rc) =>
                el("button", {
                  type: "button",
                  className: "btn btn-sm",
                  style: { borderColor: "#15803d", color: "#14532d" },
                  text: `✨ Play '${rc.name}' Before Rolling (Auto-Treat as III)`,
                  onClick: () => sendGameAction({ type: "play_influence", cardId: rc.id }),
                })
              )
            )
            : null,
          !isOtherPlayerEncounter
            ? el("button", {
              type: "button",
              className: "btn btn-primary",
              style: { fontSize: "0.95rem", padding: "0.55rem 1.25rem" },
              text: autoTreatThree
                ? `✨ Resolve ${chartTitle} as Roll III`
                : `🎲 Roll ${chartTitle} Die (1®)`,
              onClick: () => sendGameAction({ type: "resolve_encounter", decision: "roll_chart_encounter" }),
            })
            : el("div", {
              style: { fontSize: "0.84rem", color: "var(--text-muted)" },
              text: `Waiting for ${encPlayer.name} to roll on the ${chartTitle} Chart...`,
            })
        )
      )
    );
  }

  // Stage 0C: Pre-Combat Consumable ("Destroyed if Used") Weapon Choice Before Rolling Combat Dice
  if (stage === "combat_consumable_pre_roll") {
    const consumables = Array.isArray(pend.consumableItems)
      ? pend.consumableItems
      : (encPlayer.suv || []).filter((it) => it && it.combat && it.combat.consumable);
    if (!appState._stageConsumableSelection || appState._stageConsumableEncounterCardId !== card.id) {
      appState._stageConsumableEncounterCardId = card.id;
      appState._stageConsumableSelection = new Set();
    }
    const selectedSet = appState._stageConsumableSelection;

    return el(
      "div",
      {
        id: "pending-encounter-panel",
        className: "panel",
        style: { borderColor: "#b45309" },
      },
      el(
        "h3",
        { className: "panel-title" },
        el("span", { text: `🗡️ Pre-Combat Weapon Choice vs. ${card.name || "Opponent"}` }),
        el("span", {
          style: { fontSize: "0.78rem", color: "var(--gold-bright)" },
          text: "Decide whether to expend destroyed-if-used weapon(s) before rolling!",
        })
      ),
      el(
        "div",
        { className: "encounter-interactive-layout" },
        card && card.id ? renderPhysicalEncounterCardNode(card, pend, { interactive: false }) : null,
        el(
          "div",
          {},
          el("p", {
            style: { marginTop: "0", fontSize: "0.88rem", color: "#7dd3fc", fontWeight: "700" },
            text: "Choose which consumable ('destroyed if used') weapon(s) on your SUV you want to use in this combat before rolling the combat dice:",
          }),
          el(
            "div",
            { style: { display: "flex", flexDirection: "column", gap: "0.55rem", marginBottom: "0.9rem" } },
            ...buildConsumableWeaponPickerNodes(consumables, selectedSet, () => renderApp())
          ),
          !isOtherPlayerEncounter
            ? el("button", {
              type: "button",
              className: "btn btn-crimson",
              style: { fontSize: "0.95rem", padding: "0.55rem 1.25rem" },
              text:
                selectedSet.size > 0
                  ? `⚔️ Use ${selectedSet.size} Weapon${selectedSet.size === 1 ? "" : "s"} (Destroyed) & Roll Combat Dice`
                  : "🛡️ Keep Weapon(s) Safe on SUV & Roll Combat Dice",
              onClick: () => {
                const chosenIds = Array.from(selectedSet);
                appState._stageConsumableSelection = null;
                sendGameAction({
                  type: "resolve_encounter",
                  decision: "confirm_consumables_and_roll",
                  useConsumableIds: chosenIds,
                });
              },
            })
            : el("div", {
              style: { fontSize: "0.84rem", color: "var(--text-muted)" },
              text: `Waiting for ${encPlayer.name} to choose whether to use their consumable weapon(s)...`,
            })
        )
      )
    );
  }

  // Stage 2: Combat Post-Roll Influence Opportunity (Gladiator's Intervention, Mercenary Ambush, Flying Chamber Pot, Twist Of Fate)
  if (stage === "combat_post_roll") {
    const pCP = Number(pend.playerCP) || 0;
    const oCP = Number(pend.oppCP) || 0;
    const isVictory = pCP > oCP;
    const isTie = pCP === oCP;
    const rawWounds = Math.max(0, oCP - pCP);
    const ignoreWounds = Number(pend.ignoreWounds) || 0;
    const netWounds = Math.max(0, rawWounds - ignoreWounds);
    const henchmanCount = (encPlayer.henchmen || []).length;
    const survivesByArmor = !isVictory && !isTie && netWounds <= 0;
    const survivesByHenchman = !isVictory && !isTie && netWounds > 0 && netWounds <= henchmanCount;
    const armorSources = Array.isArray(pend.armorSources) ? pend.armorSources : [];
    const armorLabelStr =
      armorSources.length > 0
        ? armorSources.join(", ")
        : ignoreWounds > 0
          ? `Armor (Ignore ${ignoreWounds} Wound${ignoreWounds === 1 ? "" : "s"})`
          : "None";
    const equipNotes = Array.isArray(pend.equipmentNotes) ? pend.equipmentNotes : [];

    const postCards = (viewer.influence || []).filter((c) => {
      const nm = String(c.name || "");
      return (
        nm === "Gladiator's Intervention" ||
        nm === "Flying Chamber Pot" ||
        nm === "Twist Of Fate"
      );
    });

    const pDiceSummary = (pend.playerDiceObjs || [])
      .map((d) =>
        d.sign === 0
          ? `${d.label}: 🛡️[${d.roman}]`
          : `${d.label}: ${d.sign < 0 ? "-" : ""}[${d.roman}]`
      )
      .join(", ");
    const oDiceSummary = (pend.oppDiceObjs || []).map((d) => `${d.label}: [${d.roman}]`).join(", ");

    const statusLabel = isVictory
      ? "VICTORY"
      : isTie
        ? "TIE (SURVIVED — NO BONUS)"
        : survivesByArmor
          ? `SURVIVED (${armorLabelStr.toUpperCase()} BLOCKED WOUNDS)`
          : survivesByHenchman
            ? "DEFEAT — SURVIVED (HENCHMAN ABSORBED WOUND)"
            : "DEFEAT (ROLL ON DEFEAT CHART)";

    const statusBorderColor = isVictory
      ? "#16a34a"
      : isTie || survivesByArmor
        ? "#ca8a04"
        : survivesByHenchman
          ? "#ea580c"
          : "#dc2626";

    let outcomeSummaryText = "";
    if (isVictory) {
      outcomeSummaryText = `🏆 Current Outcome for ${encPlayer.name}: Victory (${pCP} CP vs. ${oCP} CP)!`;
    } else if (isTie) {
      outcomeSummaryText = `⚖️ Current Outcome for ${encPlayer.name}: Tie (${pCP} CP vs. ${oCP} CP) — ${encPlayer.name} survives combat unharmed (no roll on the Defeat Chart), but does not receive the bonus for winning combat.`;
    } else if (survivesByArmor) {
      outcomeSummaryText = `🛡️ Current Outcome for ${encPlayer.name}: Lost by ${rawWounds} point${rawWounds === 1 ? "" : "s"
        } (${pCP} CP vs. ${oCP} CP), but ${armorLabelStr} blocked all ${rawWounds} Wound${rawWounds === 1 ? "" : "s"
        }! ${encPlayer.name} survives combat and will NOT proceed to a roll on the Defeat Chart.`;
    } else if (survivesByHenchman) {
      outcomeSummaryText = `🛡️ Current Outcome for ${encPlayer.name}: Defeat (${pCP} CP vs. ${oCP} CP) — ${rawWounds} Raw Wound(s), ${ignoreWounds} Blocked by ${armorLabelStr}, ${netWounds} Absorbed by Hired Henchman(s). Your Driver survives and will NOT proceed to a roll on the Defeat Chart!`;
    } else {
      outcomeSummaryText = `⚠️ Current Outcome for ${encPlayer.name}: Defeat (${pCP} CP vs. ${oCP} CP) — ${rawWounds} Raw Wound(s), ${ignoreWounds} Blocked by ${armorLabelStr} (${netWounds} Unblocked). Driver will proceed to a roll on the Defeat Chart!`;
    }

    return el(
      "div",
      { id: "pending-encounter-panel", className: "panel", style: { borderColor: statusBorderColor } },
      el(
        "h3",
        { className: "panel-title" },
        el("span", {
          text: `⚔️ Combat Dice Rolled: ${encPlayer.name} (${pCP} CP) vs. ${card.name} (${oCP} CP) — ${statusLabel}${isOtherPlayerEncounter ? " [Your Intervention Window]" : ""
            }`,
        })
      ),
      el(
        "div",
        {
          style: {
            padding: "0.65rem 0.85rem",
            background: isVictory
              ? "#f0fdf4"
              : isTie || survivesByArmor
                ? "rgba(14, 42, 84, 0.92)"
                : "rgba(68, 12, 48, 0.92)",
            border: `1.5px solid ${statusBorderColor}`,
            borderRadius: "4px",
            fontSize: "0.85rem",
            color: isVictory ? "#14532d" : isTie || survivesByArmor ? "#713f12" : "#7f1d1d",
            marginBottom: "0.85rem",
            boxShadow: "var(--bevel-sunken)",
          },
        },
        el("div", {
          style: { fontWeight: "700", marginBottom: "0.25rem" },
          text: outcomeSummaryText,
        }),
        pend.encounterSource
          ? el("div", {
            style: { fontSize: "0.78rem", color: "#92400e", marginBottom: "0.25rem", fontWeight: "700" },
            text: `📍 Triggered By: ${pend.encounterSource}`,
          })
          : null,
        el("div", {
          style: { fontSize: "0.78rem", color: "var(--text-main)" },
          text: `${encPlayer.name} Rolls: ${pDiceSummary || "None"} (Flat ${formatSignedFlat(
            pend.playerFlat
          )})  |  Opponent Rolls: ${oDiceSummary || "None"} (Flat ${formatSignedFlat(pend.oppFlat)})`,
        }),
        equipNotes.length > 0
          ? el("div", {
            style: { fontSize: "0.78rem", color: "#7dd3fc", marginTop: "0.3rem", fontWeight: "700" },
            text: `🛡️⚔️ Active Henchman & Weapon Effects: ${equipNotes.join(" • ")}`,
          })
          : null
      ),
      renderInlineClickableDiceRow(pend, viewer, merchantLabel),
      buildArmedDieBannerNode() ? el("div", { style: { marginBottom: "0.7rem" } }, buildArmedDieBannerNode()) : null,
      postCards.length > 0
        ? el(
          "div",
          { style: { marginBottom: "0.9rem" } },
          el("div", {
            style: { fontSize: "0.84rem", fontWeight: "700", color: "var(--gold-bright)", marginBottom: "0.45rem" },
            text: isOtherPlayerEncounter
              ? `🃏 Intervene in ${encPlayer.name}'s Combat! Click a Die Above or Play a Post-Roll Influence Card:`
              : "🃏 Post-Roll Combat Influence Cards Available (Click a Die Above to Re-Roll or Play a Card):",
          }),
          el(
            "div",
            { className: "phys-cards-grid compact-sidebar-grid" },
            ...postCards.map((rc) => {
              if (rc.name === "Twist Of Fate") {
                const isArmed = Boolean(appState.armedDieAction && appState.armedDieAction.cardId === rc.id);
                return renderPhysicalInfluenceCardNode(rc, {
                  actionButton: el("button", {
                    className: `btn btn-sm ${isArmed ? "btn-crimson" : "btn-primary"}`,
                    style: { width: "100%" },
                    text: isArmed ? "👆 Click Any Die Above!" : "🎲 Click a Die Above to Re-Roll",
                    onClick: () => armDieCardAction(rc, "reroll"),
                  }),
                });
              }
              return renderPhysicalInfluenceCardNode(rc, {
                actionButton: buildCombatInfluenceCardActionNode(
                  rc,
                  encPlayer.name,
                  card.name,
                  isOtherPlayerEncounter
                ),
              });
            })
          )
        )
        : null,
      el(
        "div",
        { style: { display: "flex", gap: "0.65rem", alignItems: "center" } },
        el("button", {
          className: isVictory || isTie || survivesByArmor ? "btn btn-primary" : "btn btn-crimson",
          text: isOtherPlayerEncounter
            ? "✅ Pass Intervention / Confirm Combat Result"
            : isVictory
              ? "✅ Confirm Combat Victory"
              : isTie
                ? "✅ Confirm Combat Tie (Survive, No Bonus)"
                : survivesByArmor
                  ? `🛡️ Confirm Survival (${armorLabelStr} Blocked Wounds — No Defeat Roll)`
                  : survivesByHenchman
                    ? "🛡️ Confirm Survival (Henchman Absorbed Wound — No Defeat Roll)"
                    : "💀 Confirm Combat Result & Proceed to Driver Fate Roll",
          onClick: () => sendGameAction({ type: "resolve_encounter", decision: "finalize_combat" }),
        })
      )
    );
  }

  // Stage 3A: Driver Wounded — Prompt Player to Roll on the Driver Fate (Death) Chart
  if (stage === "driver_fate_pre_roll") {
    const postChartCards = (viewer.influence || []).filter(
      (c) => c.name === "Lucky Break" || c.name === "Twist Of Fate"
    );
    return el(
      "div",
      { id: "pending-encounter-panel", className: "panel", style: { borderColor: "#b91c1c" } },
      el(
        "h3",
        { className: "panel-title" },
        el("span", { text: `💀 Driver Wounded in Combat — Roll on the Driver Fate (Death) Chart!` })
      ),
      el(
        "div",
        {
          style: {
            padding: "0.7rem 0.9rem",
            background: "rgba(68, 12, 48, 0.92)",
            border: "1.5px solid #dc2626",
            borderRadius: "4px",
            fontSize: "0.85rem",
            color: "#fbcfe8",
            marginBottom: "0.8rem",
            boxShadow: "var(--bevel-sunken)",
          },
        },
        el("strong", { text: "⚔️ Unblocked Wound to Driver: " }),
        `${encPlayer.name} lost combat (${pend.playerCP} CP vs. ${card.name}'s ${pend.oppCP} CP), suffering ${pend.rawWounds} wound(s) (${pend.ignoreWounds || 0
        } blocked by Armor${pend.casualties && pend.casualties.length ? `, ${pend.casualties.join(", ")}` : ""
        }). Roll 1 Rome Die (1(R)) on the Death Chart below to determine the Driver's fate!`
      ),
      el(
        "div",
        {
          style: {
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(185px, 1fr))",
            gap: "0.5rem",
            marginBottom: "0.85rem",
            fontSize: "0.8rem",
          },
        },
        el(
          "div",
          { style: { padding: "0.5rem", background: "rgba(68, 12, 48, 0.92)", borderRadius: "4px", border: "1px solid #dc2626" } },
          el("strong", { style: { color: "#ff6ec7" }, text: "Roll 0 — Dead:" }),
          el("div", { style: { color: "var(--text-main)" }, text: "Lose all Goods on SUV; your night ends immediately." })
        ),
        el(
          "div",
          { style: { padding: "0.5rem", background: "rgba(14, 42, 84, 0.92)", borderRadius: "4px", border: "1px solid #d97706" } },
          el("strong", { style: { color: "#92400e" }, text: "Roll I — Left for dead:" }),
          el("div", { style: { color: "var(--text-main)" }, text: "Lose all Goods on SUV; your night continues." })
        ),
        el(
          "div",
          { style: { padding: "0.5rem", background: "rgba(14, 42, 84, 0.92)", borderRadius: "4px", border: "1px solid #ca8a04" } },
          el("strong", { style: { color: "#7dd3fc" }, text: "Roll II — Beaten & mugged:" }),
          el("div", { style: { color: "var(--text-main)" }, text: "Lose all Denarii; your night continues." })
        ),
        el(
          "div",
          { style: { padding: "0.5rem", background: "#f0fdf4", borderRadius: "4px", border: "1px solid #16a34a" } },
          el("strong", { style: { color: "#15803d" }, text: "Roll III — Begged for mercy:" }),
          el("div", { style: { color: "var(--text-main)" }, text: "Lose all Influence cards; your night continues." })
        )
      ),
      postChartCards.length > 0
        ? el("div", {
          style: { fontSize: "0.82rem", color: "var(--gold-bright)", marginBottom: "0.75rem", fontWeight: "600" },
          text: `🃏 You hold ${postChartCards.map((c) => `'${c.name}'`).join(", ")} — after rolling the Death Chart die, click directly on the rolled die to modify or re-roll it!`,
        })
        : null,
      el("button", {
        className: "btn btn-crimson",
        style: { fontSize: "0.95rem", padding: "0.55rem 1.25rem" },
        text: "🎲 Roll Driver Fate Die (1(R)) on Death Chart",
        onClick: () => sendGameAction({ type: "resolve_encounter", decision: "roll_driver_fate" }),
      })
    );
  }

  // Stage 3B / Chart Post-Roll: Modify or Re-Roll Driver Fate / Protesters / Open Mic / Schizophrenic Roll
  if (stage === "driver_fate_post_roll" || stage === "chart_post_roll") {
    const cType = pend.chartType || "death";
    const cRoll = Number(pend.chartRoll) || 0;
    const rom = toRomanDieSymbol(cRoll);
    const postChartCards = (viewer.influence || []).filter((c) => {
      const nm = String(c.name || "");
      if (nm === "Twist Of Fate") return true;
      if (nm === "Lucky Break" && cType !== "schizophrenic") return true;
      if (!isOtherPlayerEncounter && cType === "mob" && nm === "Man Of The People") return true;
      if (!isOtherPlayerEncounter && cType === "theater" && nm === "Dramaturge") return true;
      return false;
    });

    return el(
      "div",
      { id: "pending-encounter-panel", className: "panel", style: { borderColor: "var(--gold-bright)" } },
      el(
        "h3",
        { className: "panel-title" },
        el("span", {
          text:
            stage === "driver_fate_post_roll"
              ? `💀 ${encPlayer.name}'s Driver Fate (Death Chart) Roll: Rolled [${rom}]${isOtherPlayerEncounter ? " [Your Intervention Window]" : ""
              }`
              : `🎲 ${encPlayer.name}'s ${card.name || "Encounter"} Roll: Rolled [${rom}]${isOtherPlayerEncounter ? " [Your Intervention Window]" : ""
              }`,
        })
      ),
      el(
        "div",
        {
          style: {
            padding: "0.65rem 0.85rem",
            background: "rgba(14, 42, 84, 0.92)",
            border: "1.5px solid #d97706",
            borderRadius: "4px",
            fontSize: "0.86rem",
            color: "#7dd3fc",
            marginBottom: "0.85rem",
            boxShadow: "var(--bevel-sunken)",
          },
        },
        el("strong", { text: `Current Outcome for ${encPlayer.name} (Roll = ${rom}): ` }),
        pend.previewText || `Rolled ${rom}`
      ),
      renderInlineClickableDiceRow(pend, viewer, merchantLabel),
      buildArmedDieBannerNode() ? el("div", { style: { marginBottom: "0.7rem" } }, buildArmedDieBannerNode()) : null,
      postChartCards.length > 0
        ? el(
          "div",
          { style: { marginBottom: "0.85rem" } },
          el("div", {
            style: { fontSize: "0.84rem", fontWeight: "700", color: "var(--gold-bright)", marginBottom: "0.45rem" },
            text: isOtherPlayerEncounter
              ? `🃏 Intervene on ${encPlayer.name}'s Roll! Click the Die Above or Play a Card:`
              : "🃏 Post-Roll Influence Cards in Hand (Click the Die Above to Modify / Re-Roll!):",
          }),
          el(
            "div",
            { className: "phys-cards-grid compact-sidebar-grid" },
            ...postChartCards.map((rc) => {
              if (rc.name === "Lucky Break") {
                const isArmed = Boolean(appState.armedDieAction && appState.armedDieAction.cardId === rc.id);
                return renderPhysicalInfluenceCardNode(rc, {
                  actionButton: el("button", {
                    className: `btn btn-sm ${isArmed ? "btn-crimson" : "btn-primary"}`,
                    style: { width: "100%" },
                    text: isArmed ? "👆 Click Die Above for +1!" : "🍀 Click Die Above (+1)",
                    onClick: () => armDieCardAction(rc, "plus_one"),
                  }),
                });
              }
              if (rc.name === "Twist Of Fate") {
                const isArmed = Boolean(appState.armedDieAction && appState.armedDieAction.cardId === rc.id);
                return renderPhysicalInfluenceCardNode(rc, {
                  actionButton: el("button", {
                    className: `btn btn-sm ${isArmed ? "btn-crimson" : "btn-primary"}`,
                    style: { width: "100%" },
                    text: isArmed ? "👆 Click Die Above to Re-Roll!" : "🎲 Click Die Above to Re-Roll",
                    onClick: () => armDieCardAction(rc, "reroll"),
                  }),
                });
              }
              return renderPhysicalInfluenceCardNode(rc, {
                actionButton: el("button", {
                  className: "btn btn-sm btn-primary",
                  style: { width: "100%" },
                  text: `✨ Play ${rc.name} (Treat as III)`,
                  onClick: () => sendGameAction({ type: "play_influence", cardId: rc.id }),
                }),
              });
            })
          )
        )
        : null,
      el("button", {
        className: "btn btn-primary",
        text: isOtherPlayerEncounter ? "✅ Pass Intervention / Confirm Roll Outcome" : "✅ Confirm Roll Outcome",
        onClick: () =>
          sendGameAction({
            type: "resolve_encounter",
            decision: stage === "driver_fate_post_roll" ? "finalize_driver_fate" : "finalize_chart_roll",
          }),
      })
    );
  }

  // Stage 5 / 6: Demand Post-Roll (e.g., Scorpus / Sabinus) or Stadium Gambling Post-Roll
  if (stage === "demand_post_roll" || stage === "gamble_post_roll") {
    const twistCards = (viewer.influence || []).filter((c) => String(c.name || "") === "Twist Of Fate");
    const gambleRolls = Array.isArray(pend.gambleRolls) ? pend.gambleRolls : [];
    const romDisplay =
      stage === "demand_post_roll"
        ? toRomanDieSymbol(Number(pend.demandRoll) || 0)
        : gambleRolls.map((v) => toRomanDieSymbol(Number(v) || 0)).join(" + ");
    const titleStr =
      stage === "demand_post_roll"
        ? `📜 ${encPlayer.name}'s ${card.name || "Encounter"} Demand Roll: Rolled [${romDisplay}]${isOtherPlayerEncounter ? " [Your Intervention Window]" : ""
        }`
        : `🎲 ${encPlayer.name}'s Stadium Gambling (${pend.cell || "Rome"}): Rolled [${romDisplay}]${isOtherPlayerEncounter ? " [Your Intervention Window]" : ""
        }`;

    return el(
      "div",
      { id: "pending-encounter-panel", className: "panel", style: { borderColor: "var(--gold-bright)" } },
      el(
        "h3",
        { className: "panel-title" },
        el("span", { text: titleStr })
      ),
      el(
        "div",
        {
          style: {
            padding: "0.65rem 0.85rem",
            background: "rgba(14, 42, 84, 0.92)",
            border: "1.5px solid #d97706",
            borderRadius: "4px",
            fontSize: "0.86rem",
            color: "#7dd3fc",
            marginBottom: "0.85rem",
            boxShadow: "var(--bevel-sunken)",
          },
        },
        el("strong", { text: `Current Roll Outcome for ${encPlayer.name}: ` }),
        pend.previewText || `Rolled ${romDisplay}`
      ),
      renderInlineClickableDiceRow(pend, viewer, merchantLabel),
      buildArmedDieBannerNode() ? el("div", { style: { marginBottom: "0.7rem" } }, buildArmedDieBannerNode()) : null,
      twistCards.length > 0
        ? el(
          "div",
          { style: { marginBottom: "0.85rem" } },
          el("div", {
            style: { fontSize: "0.84rem", fontWeight: "700", color: "var(--gold-bright)", marginBottom: "0.45rem" },
            text: isOtherPlayerEncounter
              ? `🃏 Intervene on ${encPlayer.name}'s Roll! Click the Die Above to Force a Re-Roll:`
              : "🃏 Click Directly on the Die Above to Re-Roll with Twist Of Fate:",
          }),
          el(
            "div",
            { className: "phys-cards-grid compact-sidebar-grid" },
            ...twistCards.map((rc) => {
              const isArmed = Boolean(appState.armedDieAction && appState.armedDieAction.cardId === rc.id);
              return renderPhysicalInfluenceCardNode(rc, {
                actionButton: el("button", {
                  className: `btn btn-sm ${isArmed ? "btn-crimson" : "btn-primary"}`,
                  style: { width: "100%" },
                  text: isArmed ? "👆 Click a Die Above to Re-Roll!" : "🎲 Click a Die Above to Re-Roll",
                  onClick: () => armDieCardAction(rc, "reroll"),
                }),
              });
            })
          )
        )
        : null,
      el("button", {
        className: "btn btn-primary",
        text: isOtherPlayerEncounter ? "✅ Pass Intervention / Confirm Roll Outcome" : "✅ Confirm Roll Outcome",
        onClick: () =>
          sendGameAction({
            type: "resolve_encounter",
            decision: stage === "demand_post_roll" ? "finalize_demand_roll" : "finalize_gamble_roll",
          }),
      })
    );
  }

  // Stage 1: Pre-Decision (Encounter Drawn — Player can play Pre-Roll Combat or Favor/Plea Influence cards)
  const canFight = Boolean(pend.canInitiateCombat);
  const combatMandatory = Boolean(pend.combatMandatory);
  const activeDemandKind = getEncounterActiveDemandKind(pend);
  const hasDog =
    !isOtherPlayerEncounter &&
    activeDemandKind === "cash" &&
    (viewer.suv.some((c) => c.name === "Trained Dog") || viewer.influence.some((c) => c.name === "Trained Dog"));
  const hasPlea =
    !isOtherPlayerEncounter &&
    activeDemandKind === "goods" &&
    viewer.influence.some((c) => (c.name || "").includes("Plea"));
  const hasCasusBelli =
    !isOtherPlayerEncounter &&
    !canFight &&
    !combatMandatory &&
    (Boolean(pend.hasCasusBelliCard) || viewer.influence.some((c) => c.name === "Casus Belli"));

  const reactionInfluenceCards = (viewer.influence || []).filter((c) =>
    isInfluenceCardPlayableNow(gs, viewer, c)
  );

  const postRollCombatCardsHeld = (viewer.influence || []).filter((c) => {
    const nm = String(c.name || "");
    return nm === "Gladiator's Intervention" || nm === "Flying Chamber Pot" || nm === "Twist Of Fate";
  });

  const te = encPlayer.turnEffects || {};
  const activeCombatMods = [];
  if (te.combatDiceBonus) activeCombatMods.push(`${formatSignedFlat(te.combatDiceBonus)}(R) Merchant Dice`);
  if (te.combatFlatBonus) activeCombatMods.push(`${formatSignedFlat(te.combatFlatBonus)} Merchant Flat CP`);
  if (te.oppDiceMod) activeCombatMods.push(`${formatSignedFlat(te.oppDiceMod)}(R) Opponent Dice`);
  if (te.oppFlatBonus) activeCombatMods.push(`${formatSignedFlat(te.oppFlatBonus)} Opponent Flat CP`);
  if (pend.armyPayHikeActive || hasActiveClimateOption(gs, "maga_3")) {
    const posRubies = Math.max(0, Number(encPlayer.favor && encPlayer.favor.MAGA) || 0);
    if (posRubies > 0) {
      activeCombatMods.push(`+${posRubies} Merchant CP (${posRubies} MAGA Rub${posRubies === 1 ? "y" : "ies"})`);
    }
    if (pend.deck === "cops") {
      activeCombatMods.push(`+2 Opponent CP (Cops Back the Blue)`);
    }
  }

  const gearCombatEffects = [];
  (encPlayer.henchmen || []).forEach((g) => {
    const c = g.combat || {};
    const parts = [];
    if (c.dice) parts.push(`+${c.dice}(R)`);
    if (c.flat) parts.push(formatSignedFlat(c.flat) + " CP");
    if (c.ignoreWoundsFlat) parts.push(`Ignore ${c.ignoreWoundsFlat} Wound${c.ignoreWoundsFlat === 1 ? "" : "s"}`);
    parts.push("Absorbs 1 Wound");
    gearCombatEffects.push(`Henchman ${g.name || "Henchman"} (${parts.join(", ")})`);
  });
  (encPlayer.suv || []).forEach((it) => {
    const c = it.combat;
    if (!c) return;
    const parts = [];
    if (c.dice) parts.push(`+${c.dice}(R)`);
    if (c.negDice) parts.push(`-${c.negDice}(R)`);
    if (c.flat) parts.push(formatSignedFlat(c.flat) + " CP");
    if (c.ignoreWoundsFlat) parts.push(`Ignore ${c.ignoreWoundsFlat} Wound${c.ignoreWoundsFlat === 1 ? "" : "s"}`);
    if (c.ignoreWoundsDice) parts.push(`Ignore ${c.ignoreWoundsDice}(R) Wound(s)`);
    if (c.consumable) parts.push("Optional — Destroyed if Used");
    if (parts.length > 0) {
      gearCombatEffects.push(`${it.item || it.name || "Gear"} (${parts.join(", ")})`);
    }
  });

  let combatRuleBanner = null;
  if (isOtherPlayerEncounter) {
    combatRuleBanner = el(
      "div",
      {
        style: {
          padding: "0.6rem 0.8rem",
          background: "rgba(14, 42, 84, 0.92)",
          border: "1.5px solid var(--gold-bright)",
          borderRadius: "4px",
          fontSize: "0.84rem",
          color: "#7dd3fc",
          marginBottom: "0.75rem",
          boxShadow: "var(--bevel-sunken)",
        },
      },
      el("strong", { text: `⚡ Intervention Window (${encPlayer.name}'s Encounter with ${card.name}): ` }),
      `${encPlayer.name} has encountered ${card.name} and is entering combat! You may play Pre-Roll Combat Influence cards from your hand below to help or hinder either side before the dice are rolled, or click 'Pass Intervention & Roll Combat Dice'.`
    );
  } else if (combatMandatory) {
    combatRuleBanner = el(
      "div",
      {
        style: {
          padding: "0.55rem 0.75rem",
          background: "rgba(68, 12, 48, 0.92)",
          border: "1.5px solid #dc2626",
          borderRadius: "4px",
          fontSize: "0.82rem",
          color: "#fbcfe8",
          marginBottom: "0.75rem",
          boxShadow: "var(--bevel-sunken)",
        },
      },
      el("strong", { text: "⚔️ Hostile Encounter (Mandatory Combat): " }),
      "Your Faction Favor places you in the Combat tier. You may play any Pre-Roll Combat Influence cards below before clicking the Combat section on the Encounter card to roll!"
    );
  } else if (canFight) {
    const reasonLabel =
      pend.combatUnlockReason === "mission"
        ? "Unlocked by your Active Combat Mission!"
        : pend.combatUnlockReason === "casus_belli"
          ? "Unlocked by 'Casus Belli' Influence Card!"
          : "Combat is threatened by this party (!!)";
    combatRuleBanner = el(
      "div",
      {
        style: {
          padding: "0.55rem 0.75rem",
          background: "rgba(14, 42, 84, 0.92)",
          border: "1.5px solid #d97706",
          borderRadius: "4px",
          fontSize: "0.82rem",
          color: "#7dd3fc",
          marginBottom: "0.75rem",
          boxShadow: "var(--bevel-sunken)",
        },
      },
      el("strong", { text: `⚔️ Combat Available (${reasonLabel}): ` }),
      "Click the Middle Action/Tier box on the card to Comply/Accept, OR play Pre-Roll Influence cards below and click the Bottom Combat Bar on the card to Fight!"
    );
  } else {
    combatRuleBanner = el(
      "div",
      {
        style: {
          padding: "0.55rem 0.75rem",
          background: "rgba(14, 42, 84, 0.92)",
          border: "1.5px solid #00f0ff",
          borderRadius: "4px",
          fontSize: "0.82rem",
          color: "#e0f2fe",
          marginBottom: "0.75rem",
          boxShadow: "var(--bevel-sunken)",
        },
      },
      el("strong", { text: "🕊️ Combat Not Threatened: " }),
      "This party is not threatening combat at your current Favor tier. You cannot initiate combat unless required by an active Job or by playing 'Doxxing' (Casus Belli). Click the Action/Tier section on the card to accept/comply, or Refuse below."
    );
  }

  const handleFulfillEncounter = () => {
    const rType = pend.reaction || pend.reactionType || "";
    const actTxtLow = String(card.actionText || "").trim().toLowerCase().replace(/^[?!:\s]+/, "");
    const mRaw = card.mission || null;
    const isNpcBuy =
      (mRaw && mRaw.kind === "buy_from_npc") ||
      String(card.actionText || "").toLowerCase().includes("will sell") ||
      actTxtLow.startsWith("buy ");
    const isNpcSell =
      mRaw &&
      mRaw.kind === "sell" &&
      !mRaw.cell &&
      !mRaw.deliverCell &&
      (String(card.actionText || "").toLowerCase().includes("will buy") ||
        String(card.actionText || "").toLowerCase().includes("on the spot") ||
        (actTxtLow.startsWith("sell ") && !actTxtLow.includes(" in ")));
    const isJobAssignment =
      rType === "deck_quest_strict" ||
      rType === "deck_quest_demand" ||
      rType === "deck_quest_offer" ||
      (rType !== "no_contraband" &&
        rType !== "payoff" &&
        rType !== "cash_reward" &&
        !isNpcBuy &&
        !isNpcSell &&
        (Boolean(mRaw) || !String(card.actionText || "").trim()));
    const activeRegularJobs = (encPlayer.missions || []).filter((m) => m.source !== "schizophrenic");
    if (isJobAssignment && activeRegularJobs.length >= 5) {
      const isStrictThreat =
        rType === "deck_quest_strict" || rType === "mission_strict" || Boolean(pend.combatThreatened);
      openModal(
        "📋 5-Job Limit Reached — Fail an Active Job to Accept",
        el(
          "div",
          {},
          el("p", {
            style: { fontSize: "0.9rem", lineHeight: "1.5", marginBottom: "0.85rem", color: "#ffffff" },
            text: isStrictThreat
              ? `${card.name} is threatening you with a Job (!!), and you already hold the maximum of 5 active Jobs. To accept this Job and avoid Combat, you must choose one of your 5 active Jobs to fail right now (applying its failure penalty), or refuse and fight in Combat!`
              : `You already hold the maximum of 5 active Jobs. To accept this new Job from ${card.name}, select one of your 5 active Jobs below to fail (applying its failure penalty):`,
          }),
          el(
            "div",
            { style: { display: "flex", flexDirection: "column", gap: "0.55rem", marginBottom: "1rem" } },
            ...activeRegularJobs.map((m) => {
              const isEnc = m.source === "encounter";
              const hFav = Array.isArray(m.hostileFavor) && m.hostileFavor.length > 0 ? m.hostileFavor.join(", ") : "None";
              const penLabel = isEnc
                ? `Encounter Job — Failure Penalty: ${hFav} Favor`
                : "Starting / Deck Job — No Favor Penalty";
              return el(
                "div",
                {
                  style: {
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    gap: "0.75rem",
                    padding: "0.6rem 0.75rem",
                    background: "rgba(26, 10, 48, 0.92)",
                    border: "1px solid #ff2e9f",
                    borderRadius: "6px",
                  },
                },
                el(
                  "div",
                  {},
                  el("div", { style: { fontWeight: "700", color: "#00f0ff", fontSize: "0.9rem" }, text: m.name || "Job" }),
                  el("div", { style: { fontSize: "0.82rem", color: "#ffffff" }, text: m.description || m.text || "" }),
                  el("div", { style: { fontSize: "0.75rem", color: "#ff9ed2", marginTop: "0.15rem" }, text: penLabel })
                ),
                el("button", {
                  className: "btn btn-crimson",
                  text: "Fail This Job & Accept New Job",
                  onClick: () => {
                    closeModal();
                    sendGameAction({
                      type: "resolve_encounter",
                      decision: "fulfill",
                      replaceMissionId: m.id,
                    });
                  },
                })
              );
            })
          ),
          el(
            "div",
            { style: { display: "flex", justifyContent: "flex-end", gap: "0.6rem" } },
            isStrictThreat
              ? el("button", {
                  className: "btn btn-crimson",
                  text: "⚔️ Refuse Job Threat & Fight in Combat!",
                  onClick: () => {
                    closeModal();
                    initiateCombatWithConsumablePrompt(viewer, { type: "resolve_encounter", decision: "refuse" });
                  },
                })
              : null,
            el("button", {
              className: "btn",
              text: "Cancel",
              onClick: () => closeModal(),
            })
          )
        )
      );
      return;
    }
    sendGameAction({ type: "resolve_encounter", decision: "fulfill" });
  };

  return el(
    "div",
    { id: "pending-encounter-panel", className: "panel", style: { borderColor: "#991b1b" } },
    el(
      "h3",
      { className: "panel-title" },
      el("span", {
        text: isOtherPlayerEncounter
          ? `⚔️ ${encPlayer.name}'s Encounter in SF: ${card.name} (${(pend.deck || "").toUpperCase()} Deck)`
          : `⚔️ Encounter in SF: ${card.name} (${(pend.deck || "").toUpperCase()} Deck)`,
      }),
      el("span", {
        style: { fontSize: "0.78rem", color: "var(--gold-bright)" },
        text: isOtherPlayerEncounter
          ? "⚡ Intervene with Influence or Roll Combat Dice"
          : "👆 Click directly on the Encounter Card sections to choose your action!",
      })
    ),
    combatRuleBanner,
    el(
      "div",
      { className: "encounter-interactive-layout" },
      renderPhysicalEncounterCardNode(card, pend, {
        interactive: !isOtherPlayerEncounter,
        onFulfill: handleFulfillEncounter,
        onFight: () => initiateCombatWithConsumablePrompt(viewer, { type: "resolve_encounter", decision: "fight" }),
      }),
      el(
        "div",
        {},
        el(
          "div",
          { style: { display: "flex", gap: "0.55rem", flexWrap: "wrap", marginBottom: "0.75rem", fontSize: "0.82rem" } },
          pend.encounterSource
            ? el("span", {
              className: "badge",
              style: { borderColor: "#ff2e9f", color: "#ff9ed2", background: "rgba(255, 46, 159, 0.16)" },
              text: `📍 ${pend.encounterSource}`,
            })
            : null,
          el("span", { className: "badge", text: `Merchant: ${encPlayer.name}` }),
          el("span", { className: "badge", text: `Faction: ${card.faction || "Unaligned"}` }),
          el("span", { className: "badge", text: `Effective Favor: ${pend.favorScore > 0 ? `+${pend.favorScore}` : pend.favorScore}` }),
          el("span", {
            className: "badge",
            text: `Active Tier: ${pend.matchedTier
              ? `${formatReactionCondition(pend.matchedTier.condition || pend.matchedTier.cond)} → ${formatReactionTypeSymbol(pend.matchedTier)}`
              : formatReactionTypeSymbol(pend.reaction || pend.reactionType)
              }`,
          }),
          el("span", { className: "badge", text: `NPC Combat: ${card.combatFormula || "X(R)"} (X=${pend.xCount})` }),
          activeCombatMods.length > 0
            ? el("span", {
              className: "badge",
              style: { borderColor: "#4ade80", color: "#bbf7d0", background: "rgba(34, 197, 94, 0.18)" },
              text: `⚔️ Active Combat Mods: ${activeCombatMods.join(", ")}`,
            })
            : null,
          gearCombatEffects.length > 0
            ? el("span", {
              className: "badge",
              style: { borderColor: "var(--gold-bright)", color: "#ff9ed2", background: "rgba(255, 46, 159, 0.16)" },
              text: `🛡️⚔️ Henchman & Weapon Effects: ${gearCombatEffects.join(" • ")}`,
            })
            : null
        ),
        postRollCombatCardsHeld.length > 0 && canFight
          ? el("div", {
            style: {
              padding: "0.45rem 0.65rem",
              background: "rgba(34, 14, 60, 0.9)",
              border: "1px solid #ff2e9f",
              borderRadius: "4px",
              fontSize: "0.78rem",
              color: "var(--gold-bright)",
              marginBottom: "0.7rem",
            },
            text: `🃏 Post-Roll Combat Cards in Hand (${postRollCombatCardsHeld
              .map((c) => c.name)
              .join(", ")}): You will be prompted with the option to play these AFTER the combat dice are rolled!`,
          })
          : null,
        !isOtherPlayerEncounter
          ? el(
            "div",
            {
              style: {
                padding: "0.7rem",
                background: "rgba(30, 12, 54, 0.92)",
                borderRadius: "4px",
                marginBottom: "0.85rem",
                border: "1px solid var(--border-subtle)",
                boxShadow: "var(--bevel-sunken)",
              },
            },
            el("div", {
              style: { fontWeight: "700", color: "var(--gold-bright)", marginBottom: "0.35rem", fontSize: "0.85rem" },
              text: "Interactive Card Section Guide:",
            }),
            !combatMandatory
              ? el("div", {
                style: { fontSize: "0.8rem", marginBottom: "0.25rem", color: "#4ade80", fontWeight: "600" },
                text: "• Click the Top Bar, Active Tier, or Middle Action Box on the card → Fulfill Demand / Accept Offer or Job",
              })
              : null,
            el("div", {
              style: { fontSize: "0.8rem", marginBottom: "0.25rem", color: canFight ? "#ff6ec7" : "var(--text-muted)", fontWeight: canFight ? "600" : "400" },
              text: canFight
                ? "• Click the Combat Formula or Bottom Combat Bar on the card → Initiate Combat!"
                : "• Combat Section Locked (Combat is not threatened and you have no cards to trigger combat.)",
            })
          )
          : null,
        el(
          "div",
          { style: { display: "flex", gap: "0.55rem", flexWrap: "wrap", marginBottom: "0.85rem" } },
          !isOtherPlayerEncounter && !combatMandatory
            ? el("button", {
              className: "btn btn-primary",
              text: (() => {
                const rType = pend.reaction || pend.reactionType || "";
                if (rType === "deck_quest_strict") {
                  return "(DECK_ICON)(QUEST_ICON)!! Accept Top Missions Card (Unseen)";
                }
                if (rType === "deck_quest_demand") {
                  return "(DECK_ICON)(QUEST_ICON)! Accept Top Missions Card (Unseen)";
                }
                if (rType === "deck_quest_offer") {
                  return "(DECK_ICON)(QUEST_ICON)? Accept Top Missions Card (Unseen)";
                }
                if (
                  (rType === "mission_strict" ||
                    rType === "mission_request" ||
                    rType === "mission_offer" ||
                    rType === "mission_bonus") &&
                  card.mission
                ) {
                  return `📜 Accept Mission: "${card.mission.name}"`;
                }
                if (card.mission && !rType.startsWith("demand")) {
                  return `📜 Accept Mission: "${card.mission.name}"`;
                }
                return "✓ Comply / Accept Terms";
              })(),
              onClick: handleFulfillEncounter,
            })
            : null,
          canFight
            ? el("button", {
              className: "btn btn-crimson",
              text: isOtherPlayerEncounter
                ? `🎲 Pass Intervention & Roll ${encPlayer.name}'s Combat Dice`
                : "⚔️ Fight! (Roll Combat Dice)",
              onClick: () => {
                if (isOtherPlayerEncounter) {
                  sendGameAction({ type: "resolve_encounter", decision: "fight" });
                } else {
                  initiateCombatWithConsumablePrompt(viewer, { type: "resolve_encounter", decision: "fight" });
                }
              },
            })
            : null,
          !isOtherPlayerEncounter && !combatMandatory
            ? el("button", {
              className: "btn",
              text: (() => {
                const rType = pend.reaction || pend.reactionType || "";
                const actTxt = String(card.actionText || "").trim();
                if (
                  rType === "offer" ||
                  rType === "mission_offer" ||
                  rType === "mission_bonus" ||
                  rType === "quest_optional" ||
                  rType === "deck_quest_offer" ||
                  rType === "cash_reward" ||
                  (!rType && actTxt.startsWith("?"))
                ) {
                  return "Decline / Pass Offer (No Penalty)";
                }
                if (rType === "demand_strict" || rType === "mission_strict" || pend.combatThreatened) {
                  return "Refuse Threat (⚔️ Initiates Combat!)";
                }
                return `Refuse Request (Suffer ${formatHostileFavorPenaltyText(card)})`;
              })(),
              onClick: () => {
                const rType = pend.reaction || pend.reactionType || "";
                if (rType === "demand_strict" || rType === "mission_strict" || pend.combatThreatened) {
                  initiateCombatWithConsumablePrompt(viewer, { type: "resolve_encounter", decision: "refuse" });
                } else {
                  sendGameAction({ type: "resolve_encounter", decision: "refuse" });
                }
              },
            })
            : null,
          !isOtherPlayerEncounter && !canFight && hasCasusBelli
            ? el("button", {
              className: "btn btn-crimson",
              text: "⚔️ Play 'Casus Belli' & Initiate Combat!",
              onClick: () =>
                initiateCombatWithConsumablePrompt(viewer, {
                  type: "resolve_encounter",
                  decision: "use_casus_belli",
                }),
            })
            : null,
          hasDog
            ? el("button", {
              className: "btn",
              text: "🐕 Use 'Trained Dog' (Satisfy Denarii Demand / Avoid)",
              onClick: () => sendGameAction({ type: "resolve_encounter", decision: "use_dog" }),
            })
            : null,
          hasPlea
            ? el("button", {
              className: "btn",
              text: "🙏 Play 'Plea' (Cancel Encounter)",
              onClick: () => sendGameAction({ type: "resolve_encounter", decision: "use_plea" }),
            })
            : null
        ),
        reactionInfluenceCards.length > 0
          ? el(
            "div",
            {},
            el("div", {
              style: { fontSize: "0.8rem", fontWeight: "700", color: "var(--gold-bright)", marginBottom: "0.4rem" },
              text: isOtherPlayerEncounter
                ? `🃏 Your Pre-Roll Combat Influence Cards (Target ${encPlayer.name} or ${card.name}):`
                : "🃏 Pre-Roll & Reaction Influence Cards in Hand (Play Before Rolling):",
            }),
            el(
              "div",
              { className: "phys-cards-grid compact-sidebar-grid" },
              ...reactionInfluenceCards.map((rc) => {
                if (rc.name === "Casus Belli" && !canFight) {
                  return renderPhysicalInfluenceCardNode(rc, {
                    actionButton: el("button", {
                      className: "btn btn-sm btn-primary",
                      style: { width: "100%" },
                      text: "⚔️ Play Casus Belli",
                      onClick: () =>
                        initiateCombatWithConsumablePrompt(viewer, {
                          type: "resolve_encounter",
                          decision: "use_casus_belli",
                        }),
                    }),
                  });
                }
                return renderPhysicalInfluenceCardNode(rc, {
                  actionButton: buildCombatInfluenceCardActionNode(
                    rc,
                    encPlayer.name,
                    card.name,
                    isOtherPlayerEncounter
                  ),
                });
              })
            )
          )
          : null
      )
    )
  );
}

function renderPendingNpcOfferPanel(gs, viewer) {
  const offer = viewer.pendingNpcOffer;
  if (!offer) return null;
  const isBuy = (offer.mode || offer.offerType) === "buy_from_npc";
  const npcName = offer.npcName || (offer.npcCard && offer.npcCard.name) || "Patron";
  return el(
    "div",
    { className: "panel", style: { borderColor: "var(--gold-bright)" } },
    el(
      "h3",
      { className: "panel-title" },
      el("span", {
        text: `🤝 Active Offer from ${npcName}: ${isBuy ? `Purchase 1 ${offer.category}` : `Sell 1 ${offer.category}`
          }`,
      }),
      el("button", {
        className: "btn btn-sm btn-primary",
        text: `🔍 Choose ${offer.category} Card`,
        onClick: () => openNpcOfferModal(gs, viewer),
      })
    ),
    el(
      "div",
      {
        style: {
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          gap: "0.75rem",
          flexWrap: "wrap",
          fontSize: "0.85rem",
        },
      },
      el("span", {
        text: `${npcName} (${offer.actionText || ""}) — Select which ${offer.category
          } card to ${isBuy ? "purchase" : "sell"}, or decline the offer.`,
      }),
      el(
        "div",
        { style: { display: "flex", gap: "0.5rem" } },
        el("button", {
          className: "btn btn-sm btn-primary",
          text: `📜 Open ${npcName}'s Offer Selection`,
          onClick: () => openNpcOfferModal(gs, viewer),
        }),
        el("button", {
          className: "btn btn-sm",
          text: "Decline Offer",
          onClick: () => sendGameAction({ type: "resolve_npc_offer", decision: "decline" }),
        })
      )
    )
  );
}

function renderPendingMarketRewardPanel(gs, viewer) {
  const queue = (viewer && Array.isArray(viewer.pendingMarketReward) && viewer.pendingMarketReward) || [];
  const rwd = queue[0];
  if (!rwd) return null;
  const catLabel = rwd.categoryLabel || rwd.subcategory || rwd.track || "Good";
  return el(
    "div",
    { className: "panel", style: { borderColor: "var(--gold-bright)" } },
    el(
      "h3",
      { className: "panel-title" },
      el("span", {
        text: `🎁 Market Board Reward Ready: Choose 1 ${catLabel}${queue.length > 1 ? ` (${queue.length} rewards queued)` : ""
          }`,
      }),
      el("button", {
        className: "btn btn-sm btn-primary",
        text: `🔍 Choose ${catLabel} on Market`,
        onClick: () => openMarketRewardModal(gs, viewer),
      })
    ),
    el(
      "div",
      {
        style: {
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          gap: "0.75rem",
          flexWrap: "wrap",
          fontSize: "0.85rem",
        },
      },
      el("span", {
        text: `${rwd.sourceLabel || "Reward"} (${rwd.rewardLabel || catLabel
          }) — Select which ${catLabel} card on the Ostia Market Board to claim onto your SUV.`,
      }),
      el(
        "div",
        { style: { display: "flex", gap: "0.5rem" } },
        el("button", {
          className: "btn btn-sm btn-primary",
          text: `🎁 Choose ${catLabel} Card`,
          onClick: () => openMarketRewardModal(gs, viewer),
        }),
        el("button", {
          className: "btn btn-sm",
          text: "Decline Reward",
          onClick: () =>
            sendGameAction({
              type: "resolve_market_reward",
              rewardId: rwd.id,
              decision: "decline",
            }),
        })
      )
    )
  );
}

function renderPendingSUVOverflowPanel(gs, viewer) {
  const queue = (viewer && viewer.pendingSUVOverflow) || [];
  if (queue.length === 0) return null;
  const ovf = queue[0];
  const card = ovf.card || {};
  const isHenchman = ovf.itemType === "henchman" || card.track === "Henchmen";
  const reqBlocks = isHenchman ? 0 : Math.max(1, Number(ovf.reqBlocks || card.blocks) || 1);
  return el(
    "div",
    { className: "panel", style: { borderColor: "var(--gold-bright)" } },
    el(
      "h3",
      { className: "panel-title" },
      el("span", {
        text: isHenchman
          ? `🛡️ Henchman Space Full — Resolve Received Henchman: ${card.name}`
          : `🎁 SUV Space Full — Resolve Received Item: ${card.name} (${reqBlocks}■)`,
      }),
      el("button", {
        className: "btn btn-sm btn-primary",
        text: isHenchman ? "🛡️ Fire a Henchman or Refuse" : "🛒 Discard Goods or Refuse",
        onClick: () => openPendingSUVOverflowModal(gs, viewer),
      })
    ),
    el(
      "div",
      {
        style: {
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          gap: "0.75rem",
          flexWrap: "wrap",
          fontSize: "0.85rem",
        },
      },
      el("span", {
        text: isHenchman
          ? `You received "${card.name}" (${ovf.sourceLabel || "Reward"}), and your Henchman slots are full (${viewer.usedHenchmen}/${viewer.maxHenchmen}▲). Choose a Henchman to fire or refuse the new Henchman.`
          : `You received "${card.name}" (${reqBlocks}■ • ${ovf.sourceLabel || "Reward"}), and your SUV has ${viewer.usedBlocks}/${viewer.maxBlocks}■ used. Choose Goods to discard or refuse this item.`,
      }),
      el(
        "div",
        { style: { display: "flex", gap: "0.5rem" } },
        el("button", {
          className: "btn btn-sm btn-primary",
          text: isHenchman ? "🛡️ Choose Henchman to Fire" : "🛒 Choose Goods to Discard",
          onClick: () => openPendingSUVOverflowModal(gs, viewer),
        }),
        el("button", {
          className: "btn btn-sm btn-crimson",
          text: `✕ Refuse ${card.name}`,
          onClick: () =>
            sendGameAction({
              type: "resolve_suv_overflow",
              overflowId: ovf.id,
              decision: "refuse",
            }),
        })
      )
    )
  );
}

function renderCleanupPhasePanel(gs, viewer) {
  if (appState.cleanupInitializedNight !== gs.night) {
    appState.cleanupInitializedNight = gs.night;
    appState.cleanupKeepHenchmen = new Set(viewer.henchmen.map((g) => g.id));
  }

  return el(
    "div",
    { className: "panel", style: { borderColor: "var(--gold-bright)" } },
    el("h3", { className: "panel-title", text: `🌅 Phase III: Dawn Clean-Up (${gs.night})` }),
    el(
      "div",
      { style: { display: "flex", gap: "0.65rem", flexWrap: "wrap", marginBottom: "0.9rem" } },
      el("button", {
        className: "btn btn-primary",
        disabled: viewer.cash < viewer.influenceBuyCost,
        text: `🃏 Buy Influence Card (${viewer.influenceBuyCost}d)`,
        onClick: () => sendGameAction({ type: "cleanup_buy_influence" }),
      }),
      gs.night === "Thursday" && !viewer.loans.thursday
        ? el("button", {
          className: "btn",
          text: "🏦 Take Thursday Loan (+20d now; repay 30d in Friday or 45d in Saturday)",
          onClick: () => sendGameAction({ type: "cleanup_take_loan" }),
        })
        : null,
      gs.night === "Friday" && !viewer.loans.friday
        ? el("button", {
          className: "btn",
          text: "🏦 Take Friday Loan (+40d now; repay 60d at end of Saturday)",
          onClick: () => sendGameAction({ type: "cleanup_take_loan" }),
        })
        : null,
      gs.night === "Friday" && viewer.loans.thursday && viewer.cash >= 30
        ? el("button", {
          className: "btn",
          text: "🏦 Repay Thursday Loan (-30d)",
          onClick: () => sendGameAction({ type: "cleanup_repay_loan", loanType: "thursday" }),
        })
        : null,
      gs.night === "Saturday" && viewer.loans.thursday && viewer.cash >= 45
        ? el("button", {
          className: "btn",
          text: "🏦 Repay Thursday Loan (-45d)",
          onClick: () => sendGameAction({ type: "cleanup_repay_loan", loanType: "thursday" }),
        })
        : null,
      gs.night === "Saturday" && viewer.loans.friday && viewer.cash >= 60
        ? el("button", {
          className: "btn",
          text: "🏦 Repay Friday Loan (-60d)",
          onClick: () => sendGameAction({ type: "cleanup_repay_loan", loanType: "friday" }),
        })
        : null
    ),
    viewer.henchmen.length > 0
      ? el(
        "div",
        { style: { marginBottom: "0.9rem" } },
        el("div", { style: { fontWeight: "700", marginBottom: "0.4rem" }, text: "Select Henchmen to Retain (Pay Nightal Upkeep):" }),
        ...viewer.henchmen.map((g) => {
          const keep = appState.cleanupKeepHenchmen.has(g.id);
          return el(
            "label",
            { style: { display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.3rem", cursor: "pointer" } },
            el("input", {
              type: "checkbox",
              checked: keep,
              onChange: (e) => {
                if (e.target.checked) appState.cleanupKeepHenchmen.add(g.id);
                else appState.cleanupKeepHenchmen.delete(g.id);
              },
            }),
            el("span", { text: `${g.name} (${g.combatText}) — Upkeep: ${g.upkeepCost}(d)` })
          );
        })
      )
      : null,
    gs.night === "Saturday"
      ? el(
        "label",
        {
          style: {
            display: "flex",
            alignItems: "center",
            gap: "0.5rem",
            marginBottom: "0.85rem",
            cursor: "pointer",
            fontSize: "0.86rem",
          },
        },
        el("input", {
          type: "checkbox",
          checked:
            appState.cleanupAllowSundayPvpInfluence !== undefined
              ? Boolean(appState.cleanupAllowSundayPvpInfluence)
              : viewer.allowSundayPvpInfluence !== false,
          onChange: (e) => {
            appState.cleanupAllowSundayPvpInfluence = Boolean(e.target.checked);
          },
        }),
        el("span", {
          text: "⚔️ Authorize Combat Influence cards in Sunday Reckoning PvP Tie-Breakers (uncheck to save cards)",
        })
      )
      : null,
    el("button", {
      className: "btn btn-crimson",
      text:
        gs.night === "Saturday"
          ? "✓ Complete Clean-Up & Enter December 211 Sunday Reckoning"
          : "✓ Complete Clean-Up & Advance to Next Night",
      onClick: () =>
        sendGameAction({
          type: "cleanup_finish",
          keepHenchmanIds: Array.from(appState.cleanupKeepHenchmen),
          allowSundayPvpInfluence:
            appState.cleanupAllowSundayPvpInfluence !== undefined
              ? Boolean(appState.cleanupAllowSundayPvpInfluence)
              : viewer.allowSundayPvpInfluence !== false,
        }),
    })
  );
}

function openSUVGoodDetailModal(item, gs, viewer, readOnly = false) {
  if (!item) return;
  const trackName = item.track || item.category || "Grain";
  const trackClass = resolveGoodTrackClass(item);
  const blocksCount = Math.max(1, Number(item.blocks) || 1);
  const blocksSymbols = "■".repeat(blocksCount);
  const meta = (gs && gs.marketMeta && gs.marketMeta[trackName]) || {
    scarcityIndex: 2,
    scarcityLabel: "Uncommon (=)",
    scarcitySymbol: "=",
  };
  const activeScarcityIdx = typeof meta.scarcityIndex === "number" ? meta.scarcityIndex : 2;
  const scarcitySymbols = ["<<", "<", "=", ">", ">>"];

  const subtitleText = item.isMissionCargo
    ? `Mission Cargo → ${item.deliverCell || "Rome"}`
    : item.subtitle
      ? `(${item.subtitle})`
      : item.subcategory || item.category || trackName;

  let combatLineText = null;
  if (trackName === "Weapons") {
    combatLineText = item.combatText || "0 CP";
  } else if (item.combatText) {
    combatLineText = item.combatText;
  }

  const sellArr = Array.isArray(item.sell) && item.sell.length >= 5 ? item.sell.slice(0, 5) : null;
  const buyArr = Array.isArray(item.buy) && item.buy.length >= 5 ? item.buy.slice(0, 5) : null;
  const hasSellTable = Boolean(sellArr);
  const currentScarcitySellPrice =
    sellArr && sellArr[activeScarcityIdx] !== undefined ? Number(sellArr[activeScarcityIdx]) : null;
  const sellOpt = Array.isArray(item.availableSells) && item.availableSells.length > 0 ? item.availableSells[0] : null;
  const canSellNow = Boolean(
    !readOnly && sellOpt && gs && gs.phase === "delivery" && viewer && gs.activePlayerIndex === viewer.index
  );
  const hasPaidCost = !item.isMissionCargo && typeof item.purchasePrice === "number";
  const refSellPrice =
    sellOpt && !sellOpt.isFencedCargo
      ? Number(sellOpt.price)
      : currentScarcitySellPrice !== null
        ? currentScarcitySellPrice
        : null;
  const netProfit = hasPaidCost && refSellPrice !== null ? refSellPrice - Number(item.purchasePrice) : null;

  const fullCardNode = el(
    "div",
    { className: "suv-good-detail-showcase" },
    el(
      "div",
      { className: `market-good-card ${trackClass} suv-good-detail-card` },
      renderFullGoodCardFaceNode(item, trackName)
    )
  );

  const infoRows = [
    el(
      "div",
      { className: "suv-good-detail-row" },
      el("span", { className: "suv-good-detail-label", text: "Category & Weight:" }),
      el("strong", {
        text: `${item.isMissionCargo ? `Mission Cargo (${trackName})` : trackName} • ${blocksCount}■ (${blocksSymbols})`,
      })
    ),
  ];

  if (!item.isMissionCargo && currentScarcitySellPrice !== null) {
    infoRows.push(
      el(
        "div",
        { className: "suv-good-detail-row" },
        el("span", { className: "suv-good-detail-label", text: "Current Market Scarcity:" }),
        el("strong", {
          style: { color: "var(--gold-bright)" },
          text: `${meta.scarcityLabel || scarcitySymbols[activeScarcityIdx]} — Base Sell Value: ${currentScarcitySellPrice}(d)`,
        })
      )
    );
  } else if (item.isMissionCargo) {
    infoRows.push(
      el(
        "div",
        { className: "suv-good-detail-row" },
        el("span", { className: "suv-good-detail-label", text: "Mission Delivery Target:" }),
        el("strong", {
          style: { color: "var(--gold-bright)" },
          text: `Deliver to ${item.deliverCell || "Target"}${currentScarcitySellPrice !== null ? ` (Fence @ ${meta.scarcitySymbol || "="}: ${currentScarcitySellPrice}(d))` : ""
            }`,
        })
      )
    );
  }

  if (sellArr) {
    infoRows.push(
      el(
        "div",
        { className: "suv-good-detail-row" },
        el("span", {
          className: "suv-good-detail-label",
          text: item.isMissionCargo ? "Fence Values (<< to >>):" : "Sell Values (<< to >>):",
        }),
        el("span", {
          style: { fontWeight: "700" },
          text: sellArr.map((v, idx) => `${scarcitySymbols[idx]} ${v}(d)`).join(" • "),
        })
      )
    );
  }

  if (buyArr && !item.isMissionCargo) {
    infoRows.push(
      el(
        "div",
        { className: "suv-good-detail-row" },
        el("span", { className: "suv-good-detail-label", text: "Buy Values (<< to >>):" }),
        el("span", {
          text: buyArr.map((v, idx) => `${scarcitySymbols[idx]} ${v}(d)`).join(" • "),
        })
      )
    );
  }

  if (hasPaidCost) {
    infoRows.push(
      el(
        "div",
        { className: "suv-good-detail-row" },
        el("span", { className: "suv-good-detail-label", text: "Purchase Price Paid:" }),
        el(
          "strong",
          {},
          el("span", { text: `${item.purchasePrice}(d)` }),
          netProfit !== null
            ? el("span", {
              style: { color: netProfit >= 0 ? "#15803d" : "#b91c1c", marginLeft: "0.35rem" },
              text: `(${netProfit >= 0 ? `+${netProfit}` : netProfit}(d) net at ${sellOpt ? sellOpt.scarcitySymbol || "=" : meta.scarcitySymbol || "="
                })`,
            })
            : null
        )
      )
    );
  }

  if (combatLineText) {
    infoRows.push(
      el(
        "div",
        { className: "suv-good-detail-row" },
        el("span", { className: "suv-good-detail-label", text: "Combat / Effect:" }),
        el("strong", { text: combatLineText })
      )
    );
  }

  const actionBtns = [];
  if (canSellNow && sellOpt) {
    actionBtns.push(
      el("button", {
        type: "button",
        className: `btn ${sellOpt.isFencedCargo ? "btn-crimson" : "btn-primary"}`,
        disabled: viewer.transactedThisTurn,
        text: sellOpt.isFencedCargo
          ? `🕵️ Fence for ${sellOpt.price}(d)`
          : `💰 Sell for ${sellOpt.price}(d) (${sellOpt.scarcitySymbol || "="})`,
        onClick: () => {
          closeModal();
          sendGameAction({
            type: "delivery_sell",
            category: sellOpt.category,
            cardIds: [item.id],
            missionId: sellOpt.missionId || undefined,
          });
        },
      })
    );
  }
  actionBtns.push(
    el("button", {
      type: "button",
      className: "btn btn-primary",
      text: "Close",
      onClick: () => closeModal(),
    })
  );

  const modalBody = el(
    "div",
    { className: "suv-good-detail-modal" },
    fullCardNode,
    el("div", { className: "suv-good-detail-summary" }, ...infoRows),
    el(
      "div",
      { style: { display: "flex", justifyContent: "flex-end", gap: "0.5rem", flexWrap: "wrap", marginTop: "0.4rem" } },
      ...actionBtns
    )
  );

  showModal(`📦 ${item.name} — Cargo Details & Value`, modalBody);
}

function openSUVHenchmanDetailModal(g) {
  if (!g) return;
  const henchmenCount = Math.max(1, Number(g.henchmen) || 1);
  const blocksSymbols = "▲".repeat(henchmenCount);
  const combatLineText = `${g.combatText || ""}${g.abilityText ? ` & ${g.abilityText}` : ""}`;
  const buyArr = Array.isArray(g.buy) && g.buy.length >= 5 ? g.buy.slice(0, 5) : null;
  const scarcitySymbols = ["<<", "<", "=", ">", ">>"];

  const fullCardNode = el(
    "div",
    { className: "suv-good-detail-showcase" },
    el(
      "div",
      { className: "market-good-card good-track-henchmen suv-good-detail-card" },
      renderFullGoodCardFaceNode(g, "Henchmen")
    )
  );

  const infoRows = [
    el(
      "div",
      { className: "suv-good-detail-row" },
      el("span", { className: "suv-good-detail-label", text: "Henchman Seats Occupied:" }),
      el("strong", { text: `${henchmenCount}▲ (${blocksSymbols})` })
    ),
    el(
      "div",
      { className: "suv-good-detail-row" },
      el("span", { className: "suv-good-detail-label", text: "Nightal Upkeep Cost:" }),
      el("strong", { style: { color: "var(--gold-bright)" }, text: `${g.upkeepCost ?? 0}(d)` })
    ),
  ];
  if (combatLineText) {
    infoRows.push(
      el(
        "div",
        { className: "suv-good-detail-row" },
        el("span", { className: "suv-good-detail-label", text: "Combat & Special Ability:" }),
        el("strong", { text: combatLineText })
      )
    );
  }
  if (buyArr) {
    infoRows.push(
      el(
        "div",
        { className: "suv-good-detail-row" },
        el("span", { className: "suv-good-detail-label", text: "Hire Costs (<< to >>):" }),
        el("span", { text: buyArr.map((v, idx) => `${scarcitySymbols[idx]} ${v}(d)`).join(" • ") })
      )
    );
  }

  const modalBody = el(
    "div",
    { className: "suv-good-detail-modal" },
    fullCardNode,
    el("div", { className: "suv-good-detail-summary" }, ...infoRows),
    el(
      "div",
      { style: { display: "flex", justifyContent: "flex-end", marginTop: "0.4rem" } },
      el("button", { type: "button", className: "btn btn-primary", text: "Close", onClick: () => closeModal() })
    )
  );

  showModal(`🛡️ ${g.name} — Henchman Details`, modalBody);
}

function renderLoadedGoodPhysicalCardNode(item, gs, viewer, readOnly = false) {
  const trackName = item.track || item.category || "Grain";
  const trackClass = resolveGoodTrackClass(item);
  const sellOpt = Array.isArray(item.availableSells) && item.availableSells.length > 0 ? item.availableSells[0] : null;
  const canSellNow = Boolean(!readOnly && sellOpt && gs.phase === "delivery" && gs.activePlayerIndex === viewer.index);
  const hasPaidCost = !item.isMissionCargo && typeof item.purchasePrice === "number";
  const netProfit =
    hasPaidCost && sellOpt && !sellOpt.isFencedCargo
      ? Number(sellOpt.price) - Number(item.purchasePrice)
      : null;

  const openDetail = () => openSUVGoodDetailModal(item, gs, viewer, readOnly);

  const cardFace = el(
    "div",
    {
      className: `market-good-card ${trackClass} loaded-good-phys-card is-clickable-suv-card`,
      role: "button",
      tabIndex: "0",
      title: `Click to view ${item.name} details & sell values`,
      onClick: openDetail,
      onKeyDown: (e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          openDetail();
        }
      },
    },
    renderFullGoodCardFaceNode(item, trackName)
  );

  const externalMetaNodes = [];
  if (hasPaidCost) {
    externalMetaNodes.push(
      el(
        "div",
        { className: "cost-basis-pill", title: "Purchase price paid for this Good" },
        el("span", { text: `Paid ${item.purchasePrice}d` }),
        netProfit !== null
          ? el("span", {
            className: netProfit >= 0 ? "profit-pos" : "profit-neg",
            text: ` • Net ${netProfit >= 0 ? `+${netProfit}` : netProfit}d`,
          })
          : null
      )
    );
  }
  if (canSellNow) {
    externalMetaNodes.push(
      el("button", {
        type: "button",
        className: `btn btn-sm ${sellOpt.isFencedCargo ? "btn-crimson" : "btn-primary"}`,
        style: { width: "100%", padding: "0.18rem 0.3rem", fontSize: "0.7rem" },
        disabled: viewer.transactedThisTurn,
        title: sellOpt.isFencedCargo
          ? hasActiveClimateOption(gs, "ms13_3")
            ? "Clique Fence: Sells 1 Scarcity step higher & does NOT count as a Failed Mission (Patron Hostile Favor still applies)!"
            : "Fencing this Mission Cargo sells it for cash but immediately FAILS the Mission!"
          : `Sell ${item.name} in ${viewer.position}`,
        text: sellOpt.isFencedCargo
          ? `🕵️ Fence (${sellOpt.price}d)`
          : `💰 Sell (${sellOpt.price}d @ ${sellOpt.scarcitySymbol || "="})`,
        onClick: () =>
          sendGameAction({
            type: "delivery_sell",
            category: sellOpt.category,
            cardIds: [item.id],
            missionId: sellOpt.missionId || undefined,
          }),
      })
    );
    if (
      (sellOpt.category === "Grain" || sellOpt.category === "Weed") &&
      !sellOpt.isFencedCargo &&
      Number(sellOpt.bulkGrainCount) >= 2 &&
      Array.isArray(sellOpt.bulkGrainCardIds)
    ) {
      externalMetaNodes.push(
        el("button", {
          type: "button",
          className: "btn btn-sm btn-primary",
          style: { width: "100%", padding: "0.16rem 0.26rem", fontSize: "0.66rem" },
          disabled: viewer.transactedThisTurn,
          title: `Bulk Grain Sale: Spend 1 hourly Transaction to sell all ${sellOpt.bulkGrainCount} Grain cards in your SUV for ${sellOpt.bulkGrainTotalPrice} Denarii total!`,
          text: `🌾 Bulk All ${sellOpt.bulkGrainCount} (${sellOpt.bulkGrainTotalPrice}d)`,
          onClick: () =>
            sendGameAction({
              type: "delivery_sell",
              category: "Grain",
              bulkGrain: true,
              cardIds: sellOpt.bulkGrainCardIds,
              missionId: sellOpt.missionId || undefined,
            }),
        })
      );
    }
    if (Array.isArray(sellOpt.amethystBoostOptions) && sellOpt.amethystBoostOptions.length > 0 && !viewer.transactedThisTurn) {
      const boost = sellOpt.amethystBoostOptions[sellOpt.amethystBoostOptions.length - 1];
      externalMetaNodes.push(
        el("button", {
          type: "button",
          className: "btn btn-sm amethyst-boost-btn",
          style: { width: "100%", padding: "0.15rem 0.24rem", fontSize: "0.64rem" },
          title: `Rent Control: Spend ${boost.spend} Sapphire${boost.spend > 1 ? "s" : ""
            } (MS13 Favor) to boost sale to ${boost.scarcitySymbol} (${boost.price}d)`,
          text: `🔮 -${boost.spend} Sapphire → ${boost.price}d (${boost.scarcitySymbol})`,
          onClick: () =>
            sendGameAction({
              type: "delivery_sell",
              category: sellOpt.category,
              cardIds: [item.id],
              missionId: sellOpt.missionId || undefined,
              spendAmethysts: boost.spend,
            }),
        })
      );
    }
  }

  return el(
    "div",
    { className: "good-card-unit" },
    cardFace,
    externalMetaNodes.length > 0 ? el("div", { className: "good-card-external-meta" }, ...externalMetaNodes) : null
  );
}

function renderHiredHenchmanPhysicalCardNode(g) {
  const openDetail = () => openSUVHenchmanDetailModal(g);

  const cardFace = el(
    "div",
    {
      className: "market-good-card good-track-henchmen loaded-good-phys-card is-clickable-suv-card",
      role: "button",
      tabIndex: "0",
      title: `Click to view ${g.name} details & upkeep`,
      onClick: openDetail,
      onKeyDown: (e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          openDetail();
        }
      },
    },
    renderFullGoodCardFaceNode(g, "Henchmen")
  );

  return el(
    "div",
    { className: "good-card-unit" },
    cardFace,
    el(
      "div",
      { className: "good-card-external-meta" },
      el("div", {
        className: "henchman-upkeep-pill",
        text: `Upkeep: ${g.upkeepCost ?? 0}(d)`,
      })
    )
  );
}

function renderPhysicalSUVMatNode(gs, targetPlayer, viewer, readOnly = false) {
  const swatchColor = resolveDieSwatchColor(targetPlayer.color, "player");
  const suvItems = targetPlayer.suv || [];
  const henchmanItems = targetPlayer.henchmen || [];
  const maxHenchmen = Math.max(2, Number(targetPlayer.maxHenchmen) || 2);
  const usedHenchmen = Number(targetPlayer.usedHenchmen) || 0;
  const maxBlocks = Math.max(6, Number(targetPlayer.maxBlocks) || 6);
  const usedBlocks = Number(targetPlayer.usedBlocks) || 0;

  // Left-hand side: 2 vertically aligned Henchman card seats (extends downward if >2 Henchman seats or cards)
  const totalHenchmanRows = Math.max(2, maxHenchmen, henchmanItems.length);
  const henchmenlotNodes = [];
  for (let i = 0; i < totalHenchmanRows; i++) {
    const g = henchmanItems[i];
    if (g) {
      henchmenlotNodes.push(
        el(
          "div",
          {
            className: "suv-mat-occupied-slot",
            style: { gridColumn: "1", gridRow: `${i + 1} / span 1` },
          },
          renderHiredHenchmanPhysicalCardNode(g)
        )
      );
    } else {
      const isBonusHenchmenlot = i >= 2;
      henchmenlotNodes.push(
        el(
          "div",
          {
            className: `suv-mat-empty-slot henchman-empty-slot${isBonusHenchmenlot ? " bonus-empty-slot" : ""}`,
            style: { gridColumn: "1", gridRow: `${i + 1} / span 1` },
            title: isBonusHenchmenlot ? `Bonus Henchman Seat ${i + 1}` : `Henchman Seat ${i + 1}`,
          },
          el("span", { className: "suv-mat-empty-symbol", text: "▲" }),
          el("span", {
            className: "suv-mat-empty-text",
            text: isBonusHenchmenlot ? `Seat ${i + 1}` : `Seat ${i + 1}`,
          })
        )
      );
    }
  }

  // Right-hand side: 2x3 = 6 Goods card spaces (1 card per space regardless of ■ weight; extends by 3-card rows if >6 cards)
  const numCols = 3;
  const numRows = Math.max(2, Math.ceil(suvItems.length / numCols));
  const totalCardSpaces = numRows * numCols;
  const goodSlotNodes = [];

  for (let i = 0; i < totalCardSpaces; i++) {
    const r = Math.floor(i / numCols);
    const c = i % numCols;
    const item = suvItems[i];
    if (item) {
      goodSlotNodes.push(
        el(
          "div",
          {
            className: "suv-mat-occupied-slot",
            style: {
              gridRow: `${r + 1} / span 1`,
              gridColumn: `${c + 1} / span 1`,
            },
          },
          renderLoadedGoodPhysicalCardNode(item, gs, viewer, readOnly)
        )
      );
    } else {
      const isExtraRowSlot = i >= 6;
      goodSlotNodes.push(
        el("div", {
          className: `suv-mat-empty-slot${isExtraRowSlot ? " bonus-empty-slot" : ""}`,
          style: {
            gridRow: `${r + 1} / span 1`,
            gridColumn: `${c + 1} / span 1`,
          },
        })
      );
    }
  }

  const isExtendedMat = totalHenchmanRows > 2 || numRows > 2;

  return el(
    "div",
    {
      className: `physical-suv-mat${isExtendedMat ? " is-extended" : ""}`,
      style: { "--suv-trim-color": swatchColor },
    },
    el(
      "div",
      { className: "physical-suv-mat-inner" },
      el(
        "div",
        { className: "suv-mat-zone" },
        el(
          "div",
          { className: "suv-mat-zone-label" },
          el("span", { text: "🛡️ Henchmen" }),
          el("span", { text: `${usedHenchmen}/${maxHenchmen}▲` })
        ),
        el("div", { className: "suv-mat-henchmen-grid" }, ...henchmenlotNodes)
      ),
      el(
        "div",
        { className: "suv-mat-zone" },
        el(
          "div",
          { className: "suv-mat-zone-label" },
          el("span", { text: "📦 SUV Cargo" }),
          el("span", { text: `${usedBlocks}/${maxBlocks}■` })
        ),
        el("div", { className: "suv-mat-goods-grid" }, ...goodSlotNodes)
      )
    )
  );
}

function openFactionFavorModal(gs, targetPlayer, factionKey) {
  if (!targetPlayer) return;
  const fm = FACTION_META.find((f) => f.key === factionKey) || FACTION_META[0];
  const val = (targetPlayer.favor && targetPlayer.favor[fm.key]) || 0;
  const rawHistory =
    targetPlayer.favorHistory && Array.isArray(targetPlayer.favorHistory[fm.key])
      ? targetPlayer.favorHistory[fm.key]
      : [];

  const historyParts = rawHistory.map((entry) => {
    const d = Number(entry.delta) || 0;
    const absD = Math.abs(d) || 1;
    const gemWord = absD === 1 ? fm.gemSingular : fm.gemPlural;
    const signStr = d >= 0 ? `+${absD}` : `-${absD}`;
    return `${signStr} ${gemWord} from ${entry.reason || "encounter / mission"}`;
  });

  const valStr = val > 0 ? `+${val}` : String(val);
  let summarySentence = "";
  if (historyParts.length > 0) {
    summarySentence = `${valStr} ${fm.label || fm.key} favor: ${historyParts.join(", ")}`;
  } else if (val !== 0) {
    const absV = Math.abs(val);
    const gemWord = absV === 1 ? fm.gemSingular : fm.gemPlural;
    summarySentence = `${valStr} ${fm.label || fm.key} favor: ${val > 0 ? `+${absV}` : `-${absV}`} ${gemWord} recorded prior to ledger`;
  } else {
    summarySentence = `0 ${fm.label || fm.key} favor: No ${fm.label || fm.key} ${fm.gemPlural} gained or negated yet this game`;
  }

  const deckCounts =
    (gs && gs.factionDeckCounts && gs.factionDeckCounts[fm.key]) ||
    fm.defaultDeckCounts || { celebrities: 0, cops: 0, criminals: 0, total: 0 };
  const totalCards =
    deckCounts.total !== undefined
      ? deckCounts.total
      : (Number(deckCounts.celebrities) || 0) + (Number(deckCounts.cops) || 0) + (Number(deckCounts.criminals) || 0);

  const body = el(
    "div",
    { style: { display: "flex", flexDirection: "column", gap: "0.9rem" } },
    // Quick Faction Switcher Tabs
    el(
      "div",
      { style: { display: "flex", gap: "0.4rem", flexWrap: "wrap" } },
      ...FACTION_META.map((tabFm) => {
        const tVal = (targetPlayer.favor && targetPlayer.favor[tabFm.key]) || 0;
        const isCurrent = tabFm.key === fm.key;
        return el(
          "button",
          {
            type: "button",
            className: `btn btn-sm ${isCurrent ? "btn-primary" : ""}`,
            style: {
              display: "inline-flex",
              alignItems: "center",
              gap: "0.3rem",
              borderColor: isCurrent ? tabFm.color : "var(--border-subtle)",
            },
            onClick: () => openFactionFavorModal(gs, targetPlayer, tabFm.key),
          },
          el("img", { src: tabFm.gem, alt: tabFm.key, style: { width: "14px", height: "14px", objectFit: "contain" } }),
          el("span", { text: `${tabFm.key} (${tVal > 0 ? `+${tVal}` : tVal})` })
        );
      })
    ),
    // Header Banner
    el(
      "div",
      {
        style: {
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: "0.75rem",
          padding: "0.75rem 0.9rem",
          borderRadius: "4px",
          background: "rgba(34, 13, 62, 0.94)",
          border: `1.5px solid ${fm.color}`,
          boxShadow: "var(--bevel-sunken)",
        },
      },
      el(
        "div",
        { style: { display: "flex", alignItems: "center", gap: "0.65rem" } },
        el("img", { src: fm.gem, alt: fm.key, style: { width: "36px", height: "36px", objectFit: "contain" } }),
        el(
          "div",
          {},
          el("div", {
            style: { fontFamily: "Cinzel, Georgia, serif", fontSize: "1.05rem", fontWeight: "800", color: fm.color },
            text: `${fm.label || fm.key} — ${fm.title}`,
          }),
          el("div", {
            style: { fontSize: "0.76rem", color: "var(--text-muted)" },
            text: `Faction Gem: ${fm.gemSingular.toUpperCase()} • Favor: Uncapped (±5 or more)`,
          })
        )
      ),
      el(
        "div",
        {
          style: {
            textAlign: "right",
            padding: "0.3rem 0.7rem",
            borderRadius: "4px",
            background: "#f3ead8",
            border: "1px solid var(--border-subtle)",
          },
        },
        el("div", {
          style: {
            fontSize: "1.3rem",
            fontWeight: "800",
            color: val > 0 ? "#15803d" : val < 0 ? "#b91c1c" : "var(--gold-bright)",
          },
          text: valStr,
        }),
        el("div", { style: { fontSize: "0.68rem", color: "var(--text-muted)" }, text: "Current Favor" })
      )
    ),
    fm.key === "TECH" &&
      gs &&
      Array.isArray(gs.players) &&
      targetPlayer.index === (typeof gs.viewerPlayerIndex === "number" ? gs.viewerPlayerIndex : 0)
      ? renderDomnaMediatorExchangeBar(gs, targetPlayer, true)
      : null,
    // Section 1: Exact Favor Breakdown
    el(
      "div",
      {
        style: {
          padding: "0.75rem 0.9rem",
          borderRadius: "4px",
          background: "rgba(34, 13, 62, 0.94)",
          border: "1.5px solid #c29b61",
          boxShadow: "var(--bevel-sunken)",
        },
      },
      el("div", {
        style: { fontFamily: "Cinzel, Georgia, serif", fontSize: "0.86rem", fontWeight: "800", color: "var(--gold-bright)", marginBottom: "0.35rem" },
        text: `📊 ${targetPlayer.name}'s ${fm.label || fm.key} Favor Breakdown`,
      }),
      el("div", {
        style: { fontSize: "0.88rem", fontWeight: "700", color: "var(--text-main)", lineHeight: "1.45" },
        text: summarySentence,
      }),
      rawHistory.length > 0
        ? el(
          "div",
          { style: { marginTop: "0.55rem", display: "flex", flexDirection: "column", gap: "0.3rem" } },
          ...(() => {
            let running = 0;
            return rawHistory.map((entry, idx) => {
              const d = Number(entry.delta) || 0;
              running += d;
              const tot = entry.newTotal !== undefined ? Number(entry.newTotal) : running;
              const absD = Math.abs(d) || 1;
              const gemWord = absD === 1 ? fm.gemSingular : fm.gemPlural;
              return el(
                "div",
                {
                  style: {
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    fontSize: "0.78rem",
                    padding: "0.28rem 0.5rem",
                    borderRadius: "4px",
                    background: d >= 0 ? "#f0fdf4" : "rgba(68, 12, 48, 0.92)",
                    border: d >= 0 ? "1px solid #86efac" : "1px solid #fca5a5",
                  },
                },
                el(
                  "span",
                  { style: { color: d >= 0 ? "#14532d" : "#7f1d1d", fontWeight: "700" } },
                  `${idx + 1}. ${d >= 0 ? `+${absD}` : `-${absD}`} ${gemWord} — ${entry.reason || "Encounter / Mission"}`
                ),
                el("span", {
                  style: { color: "var(--text-muted)", fontSize: "0.72rem", flexShrink: "0", marginLeft: "0.5rem" },
                  text: `→ Favor: ${tot > 0 ? `+${tot}` : tot}`,
                })
              );
            });
          })()
        )
        : null
    ),
    // Section 2: Faction Lore & Alignments
    el(
      "div",
      {
        style: {
          padding: "0.75rem 0.9rem",
          borderRadius: "4px",
          background: "rgba(34, 13, 62, 0.94)",
          border: "1px solid var(--border-subtle)",
          boxShadow: "var(--bevel-sunken)",
          display: "flex",
          flexDirection: "column",
          gap: "0.5rem",
        },
      },
      el("div", {
        style: { fontFamily: "Cinzel, Georgia, serif", fontSize: "0.86rem", fontWeight: "800", color: "var(--gold-bright)" },
        text: "🏛️ Faction Description & Imperial Alignments",
      }),
      el("p", { style: { margin: "0", fontSize: "0.84rem", color: "var(--text-main)", lineHeight: "1.48" }, text: fm.bio }),
      el(
        "div",
        { style: { display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.55rem", marginTop: "0.2rem" } },
        el(
          "div",
          {
            style: {
              padding: "0.45rem 0.6rem",
              borderRadius: "4px",
              background: "#f0fdf4",
              border: "1px solid #86efac",
            },
          },
          el("div", { style: { fontSize: "0.72rem", fontWeight: "800", color: "#15803d", marginBottom: "0.2rem" }, text: "🤝 Aligned With (Allied)" }),
          el("div", { style: { fontSize: "0.82rem", fontWeight: "700", color: "#14532d" }, text: (fm.alignedWith || []).join(", ") || "None" })
        ),
        el(
          "div",
          {
            style: {
              padding: "0.45rem 0.6rem",
              borderRadius: "4px",
              background: "rgba(68, 12, 48, 0.92)",
              border: "1px solid #fca5a5",
            },
          },
          el("div", { style: { fontSize: "0.72rem", fontWeight: "800", color: "#b91c1c", marginBottom: "0.2rem" }, text: "⚔️ Hostile / Averse To" }),
          el("div", { style: { fontSize: "0.82rem", fontWeight: "700", color: "#fbcfe8" }, text: (fm.hostileTo || []).join(", ") || "None" })
        )
      ),
      el("div", {
        style: { fontSize: "0.78rem", color: "var(--text-muted)", fontStyle: "italic" },
        text: fm.alignmentNote || "",
      })
    ),
    // Section 3: Total Aligned Cards in Each Encounter Deck
    el(
      "div",
      {
        style: {
          padding: "0.75rem 0.9rem",
          borderRadius: "4px",
          background: "rgba(34, 13, 62, 0.94)",
          border: "1px solid var(--border-subtle)",
          boxShadow: "var(--bevel-sunken)",
        },
      },
      el("div", {
        style: { fontFamily: "Cinzel, Georgia, serif", fontSize: "0.86rem", fontWeight: "800", color: "var(--gold-bright)", marginBottom: "0.45rem" },
        text: `🃏 Encounter Deck Cards Aligned to ${fm.label || fm.key}`,
      }),
      el(
        "div",
        { style: { display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "0.5rem", textAlign: "center" } },
        el(
          "div",
          { className: "profile-stat-box", style: { borderColor: "#b45309" } },
          el("div", { className: "profile-stat-value", style: { fontSize: "1.1rem", color: "#38bdf8" }, text: String(deckCounts.celebrities ?? 0) }),
          el("div", { className: "profile-stat-label", text: "Celebrities Deck" })
        ),
        el(
          "div",
          { className: "profile-stat-box", style: { borderColor: "#dc2626" } },
          el("div", { className: "profile-stat-value", style: { fontSize: "1.1rem", color: "#b91c1c" }, text: String(deckCounts.cops ?? 0) }),
          el("div", { className: "profile-stat-label", text: "Cops Deck" })
        ),
        el(
          "div",
          { className: "profile-stat-box", style: { borderColor: "#64748b" } },
          el("div", { className: "profile-stat-value", style: { fontSize: "1.1rem", color: "#334155" }, text: String(deckCounts.criminals ?? 0) }),
          el("div", { className: "profile-stat-label", text: "Criminals Deck" })
        ),
        el(
          "div",
          { className: "profile-stat-box", style: { borderColor: fm.color } },
          el("div", { className: "profile-stat-value", style: { fontSize: "1.1rem", color: fm.color }, text: String(totalCards) }),
          el("div", { className: "profile-stat-label", text: "Total Aligned" })
        )
      )
    ),
    el(
      "div",
      { style: { display: "flex", justifyContent: "flex-end" } },
      el("button", { type: "button", className: "btn btn-primary", text: "Close Faction View", onClick: closeModal })
    )
  );

  showModal(`💎 Faction Favor — ${fm.label || fm.key}`, body);
}

function openPlayerSUVModal(gs, targetPlayer, viewer) {
  if (!targetPlayer) return;
  const swatchColor = resolveDieSwatchColor(targetPlayer.color, "player");
  const colorLabel = getSUVColorLabel(targetPlayer.color);
  const suvItems = targetPlayer.suv || [];
  const henchmanItems = targetPlayer.henchmen || [];
  const isViewer = viewer && targetPlayer.index === viewer.index;
  const mDone = Number(targetPlayer.missionsCompleted) || 0;
  const mFail = Number(targetPlayer.missionsFailed) || 0;
  const mNet =
    typeof targetPlayer.netMissions === "number" ? targetPlayer.netMissions : mDone - mFail;

  const node = el(
    "div",
    { className: "modal-card", style: { maxWidth: "740px" } },
    el(
      "div",
      {
        style: {
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: "0.75rem",
          borderBottom: `2px solid ${swatchColor}`,
          paddingBottom: "0.6rem",
          marginBottom: "0.75rem",
        },
      },
      el(
        "div",
        { style: { display: "flex", alignItems: "center", gap: "0.6rem" } },
        renderSUVIconNode(targetPlayer.color, "suv-icon-lg", `${targetPlayer.name}'s SUV`),
        el(
          "div",
          {},
          el("h3", {
            style: { margin: "0", color: "var(--gold-bright)", fontSize: "1.15rem" },
            text: `${targetPlayer.name}'s Merchant SUV${isViewer ? " (You)" : ""}`,
          }),
          el("div", {
            style: { fontSize: "0.75rem", color: swatchColor, fontWeight: "700" },
            text: `${colorLabel} SUV • ${targetPlayer.position
              ? `📍 In Rome at ${targetPlayer.position}`
              : targetPlayer.exitedRome
                ? "✓ Exited Rome Safely"
                : "⚓ At Portus Ostiae"
              }`,
          })
        )
      ),
      el(
        "div",
        {
          className: "player-denarii-pill",
          style: {
            borderColor: swatchColor,
            color: swatchColor,
            fontSize: "1.05rem",
            padding: "0.35rem 0.75rem",
            cursor: "default",
          },
        },
        el("span", { text: `💰 ${targetPlayer.cash}(d)` })
      )
    ),
    el(
      "div",
      {
        style: {
          display: "grid",
          gridTemplateColumns: "repeat(4, 1fr)",
          gap: "0.5rem",
          marginBottom: "0.75rem",
          textAlign: "center",
        },
      },
      el(
        "div",
        { className: "profile-stat-box" },
        el("div", { className: "profile-stat-value", style: { fontSize: "1.05rem" }, text: `${targetPlayer.cash}(d)` }),
        el("div", { className: "profile-stat-label", text: "Denarii" })
      ),
      el(
        "div",
        { className: "profile-stat-box" },
        el(
          "div",
          { className: "profile-stat-value", style: { fontSize: "1.05rem" } },
          `${targetPlayer.usedBlocks}/${targetPlayer.maxBlocks} ■`
        ),
        el("div", { className: "profile-stat-label", text: `Goods (${suvItems.length})` })
      ),
      el(
        "div",
        { className: "profile-stat-box" },
        el(
          "div",
          { className: "profile-stat-value", style: { fontSize: "1.05rem" } },
          `${targetPlayer.usedHenchmen}/${targetPlayer.maxHenchmen} ▲`
        ),
        el("div", { className: "profile-stat-label", text: `Henchmen (${henchmanItems.length})` })
      ),
      el(
        "div",
        { className: "profile-stat-box" },
        el(
          "div",
          {
            className: "profile-stat-value",
            style: { fontSize: "1.05rem", color: mNet > 0 ? "#15803d" : mNet < 0 ? "#b91c1c" : "var(--gold-bright)" },
          },
          `${mNet >= 0 ? `+${mNet}` : mNet}`
        ),
        el("div", { className: "profile-stat-label", text: `Net Missions (✓${mDone}/✕${mFail})` })
      )
    ),
    el("div", {
      style: { fontSize: "0.76rem", color: "var(--text-muted)" },
      text: "Imperial Faction Standings (Uncapped) — Click a Gem for Details:",
    }),
    el(
      "div",
      { className: "favor-row", style: { marginBottom: "0.65rem" } },
      ...FACTION_META.map((fm) => {
        const val = (targetPlayer.favor && targetPlayer.favor[fm.key]) || 0;
        return el(
          "div",
          {
            className: "favor-box clickable-favor-box",
            style: { cursor: "pointer" },
            title: `Click to view ${fm.label || fm.key} Favor breakdown, alignments & deck counts`,
            onClick: () => openFactionFavorModal(gs, targetPlayer, fm.key),
          },
          el("img", { className: "favor-gem-img", src: fm.gem, alt: fm.key }),
          el("div", { style: { fontWeight: "700", color: fm.color }, text: fm.label || fm.key }),
          el("div", { style: { fontWeight: "700" }, text: val > 0 ? `+${val}` : String(val) })
        );
      })
    ),
    isViewer ? renderDomnaMediatorExchangeBar(gs, viewer, true) : null,
    renderPhysicalSUVMatNode(gs, targetPlayer, viewer, true),
    el(
      "div",
      { style: { display: "flex", justifyContent: "flex-end", marginTop: "0.65rem" } },
      el("button", { className: "btn btn-primary", text: "Close", onClick: () => closeModal() })
    )
  );
  showModal(`🛒 ${targetPlayer.name}'s SUV Mat & Holdings`, node);
}

function renderDomnaMediatorExchangeBar(gs, viewer, closeModalOnAction = false) {
  if (!gs || !viewer) return null;
  if (!hasActiveClimateOption(gs, "tech_3")) return null;
  if (gs.phase === "finished" || gs.phase === "setup_discard" || gs.phase === "setup_climate") return null;
  const posDiamonds = Math.max(0, Number(viewer.favor && viewer.favor.TECH) || 0);
  if (posDiamonds < 1) return null;

  const triggerExchange = async (targetFaction) => {
    await sendGameAction({
      type: "exchange_tech_diamond",
      targetFaction,
      count: 1,
    });
    if (closeModalOnAction) {
      closeModal();
    }
  };

  return el(
    "div",
    { className: "tech-mediator-bar" },
    el(
      "div",
      { className: "tech-mediator-lbl" },
      el("strong", { text: `💎 Lobbying Blitz (+${posDiamonds} Diamond${posDiamonds > 1 ? "s" : ""}): ` }),
      el("span", { text: "Exchange 1-for-1 anytime" })
    ),
    el(
      "div",
      { className: "tech-mediator-btns" },
      el("button", {
        type: "button",
        className: "btn btn-sm",
        style: { borderColor: "#b91c1c", color: "#ff6ec7" },
        title: "Spend 1 positive Diamond (-1 TECH) to gain +1 Ruby (+1 MAGA)",
        text: "→ +1 Ruby (MAGA)",
        onClick: () => triggerExchange("MAGA"),
      }),
      el("button", {
        type: "button",
        className: "btn btn-sm",
        style: { borderColor: "#0369a1", color: "#075985" },
        title: "Spend 1 positive Diamond (-1 TECH) to gain +1 Sapphire (+1 DSA)",
        text: "→ +1 Sapphire (DSA)",
        onClick: () => triggerExchange("DSA"),
      })
    )
  );
}

function getActiveForumBuySpec(gs, viewer) {
  if (!gs || !viewer || !viewer.position) return null;
  const cell = gs.romeBoard && gs.romeBoard[viewer.position];
  if (!cell || !cell.isForum || !cell.revealed) return null;
  const buys = cell.revealed.buys || [];
  if (buys.length === 0) return null;
  return {
    cell: viewer.position,
    cellName: cell.name || viewer.position,
    category: buys[0].category,
    modifier: buys[0].modifier || "=",
    canTransactNow:
      gs.phase === "delivery" && gs.activePlayerIndex === viewer.index && !viewer.transactedThisTurn,
  };
}

function computeForumBuyPriceForCard(card, colIndex, modifier) {
  const colToPriceIdx = [0, 1, 2, 2, 3, 4];
  const shift = modifier === ">" || modifier === "-" ? 1 : modifier === "<" || modifier === "+" ? -1 : 0;
  const effCol = Math.min(5, Math.max(0, colIndex + shift));
  const priceIdx = colToPriceIdx[effCol];
  const buyArr = Array.isArray(card.buy) ? card.buy : [];
  if (buyArr[priceIdx] !== undefined) {
    return Number(buyArr[priceIdx]);
  }
  return Number(card.currentBuyPrice) || 4;
}

function renderMarketHeaderDenariiCounts(gs, viewer) {
  const orderedPlayers = [viewer, ...(gs.players || []).filter((p) => p.index !== viewer.index)];
  return el(
    "div",
    { className: "market-header-denarii-strip" },
    ...orderedPlayers.map((p) => {
      const swatchColor = resolveDieSwatchColor(p.color, "player");
      const isMe = p.index === viewer.index;
      return el(
        "button",
        {
          type: "button",
          className: `player-denarii-pill ${isMe ? "is-viewer-pill" : "is-opponent-pill"}`,
          style: {
            borderColor: swatchColor,
            color: swatchColor,
          },
          title: `Click to view ${p.name}'s SUV (${p.usedBlocks}/${p.maxBlocks}■ Goods, ${p.usedHenchmen}/${p.maxHenchmen}▲ Henchmen, 𐆖${p.cash})`,
          onClick: () => openPlayerSUVModal(gs, p, viewer),
        },
        renderSUVIconNode(p.color, "", `${p.name}'s SUV`),
        el("span", {
          className: "denarii-pill-name",
          style: { color: swatchColor },
          text: isMe ? `${p.name} (You):` : `${p.name}:`,
        }),
        el("strong", {
          className: "denarii-pill-amount",
          style: { color: swatchColor },
          text: `${p.cash}(d)`,
        })
      );
    })
  );
}

function renderOstiaMarketBoard(gs, viewer) {
  const isMyMarketTurn = gs.phase === "market" && gs.activePlayerIndex === viewer.index;
  const forumSpec = getActiveForumBuySpec(gs, viewer);

  // Column headings row above the 7-column Market Board (Col 0 Quayside + Cols 1..6 Warehouse Scarcity)
  const colHeadersRow = el(
    "div",
    { className: "market-col-headers" },
    el(
      "div",
      { className: "market-col-header-box" },
      el("div", { className: "col-header-title", text: `Cargo Deck: ${gs.deckCounts.market}` })
    ),
    ...MARKET_COLUMNS_META.map((cm) =>
      el(
        "div",
        { className: "market-col-header-box" },
        el("div", { className: "col-header-symbol", text: cm.symbol }),
        el("div", { className: "col-header-title", text: `Col ${cm.col}: ${cm.title}` }),
        el("div", { className: "col-header-sub", text: cm.note })
      )
    )
  );

  const gridCells = [];
  for (const trackName of TRACK_NAMES) {
    const cards = gs.marketBoard[trackName] || [];
    const meta = gs.marketMeta[trackName] || { count: cards.length, scarcityLabel: "Uncommon (=)", scarcitySymbol: "=" };
    const trackKey = trackName.toLowerCase();
    const trackClass = resolveGoodTrackClass(trackName);
    const isForumSellingTrack = Boolean(forumSpec && forumSpec.category === trackName);
    const isHighlightedTrack = isForumSellingTrack || appState.highlightedMarketTrack === trackName;

    // Leftmost Column (Col 0): sits directly over the overhead Quayside Thoroughfare on the board
    gridCells.push(
      el(
        "div",
        { className: `track-header-cell ${isHighlightedTrack ? "forum-highlighted-track-header" : ""}` },
        el(
          "div",
          { className: `track-header-plaque ${trackClass}` },
          el("div", { className: "track-title", text: trackName }),
          el("div", { style: { fontSize: "0.7rem", color: "#e6d8c0" }, text: `${meta.count}/6 Bays Stocked` }),
          el("span", { className: "scarcity-pill", text: `Sells At: ${meta.scarcityLabel}` }),
          isForumSellingTrack
            ? el("span", {
              className: "scarcity-pill",
              style: {
                background: "rgba(34, 197, 94, 0.28)",
                borderColor: "#4ade80",
                color: "#bbf7d0",
                marginTop: "2px",
              },
              text: `🏛️ Forum ${forumSpec.cell}: Sells @ ${formatTileModifier(forumSpec.modifier)}`,
            })
            : null
        )
      )
    );

    // Columns 1..6: Warehouse Bays faintly colored in the color corresponding to that Good type
    for (let col = 0; col < 6; col++) {
      const card = cards[col];
      if (!card) {
        gridCells.push(
          el(
            "div",
            { className: `market-bay-cell track-row-${trackKey} ${isHighlightedTrack ? "forum-highlighted-bay" : ""}` },
            el(
              "div",
              { className: "market-slot-empty-bay" },
              el("div", { className: "empty-bay-stencil", text: `[ ${COL_SYMBOLS[col]} ]` })
            )
          )
        );
      } else {
        const basePrice = card.currentBuyPrice;
        const forumPrice = isForumSellingTrack
          ? computeForumBuyPriceForCard(card, col, forumSpec.modifier)
          : basePrice;
        const effectivePrice = isForumSellingTrack ? forumPrice : basePrice;

        const isHenchmanTrack = trackName === "Henchmen";
        const reqBlocks = isHenchmanTrack ? 0 : Math.max(1, Number(card.blocks) || 1);
        const reqHenchmen = isHenchmanTrack ? Math.max(1, Number(card.henchmen) || 1) : 0;
        const cardBonusBlocks = Number(card.bonusBlocks) || 0;
        const cardBonusHenchmen = Number(card.bonusHenchmen) || 0;
        const fitsInSUV = doesItemFitWithoutSwap(viewer, {
          reqBlocks,
          reqHenchmen,
          bonusBlocks: cardBonusBlocks,
          bonusHenchmen: cardBonusHenchmen,
        });
        const canSwapToFit =
          fitsInSUV ||
          (isHenchmanTrack
            ? Array.isArray(viewer.henchmen) && viewer.henchmen.length > 0
            : Array.isArray(viewer.suv) && viewer.suv.length > 0);

        const canMarketBuy = isMyMarketTurn && viewer.cash >= basePrice && canSwapToFit;
        const canForumBuy =
          isForumSellingTrack && forumSpec.canTransactNow && viewer.cash >= forumPrice && canSwapToFit;
        const canBuy = canMarketBuy || canForumBuy;

        const swapSuffix = canBuy && !fitsInSUV ? (isHenchmanTrack ? " (Fire 1)" : " (Swap)") : "";
        let buttonLabel = `${isHenchmanTrack ? "Hire" : "Buy"} ${effectivePrice}(d)${swapSuffix}`;
        if (isForumSellingTrack && gs.phase === "delivery") {
          buttonLabel = `🏛️ Forum ${isHenchmanTrack ? "Hire" : "Buy"} ${forumPrice}(d)${swapSuffix}`;
        }

        let buttonTooltip = "";
        if (isForumSellingTrack && gs.phase === "delivery") {
          if (viewer.transactedThisTurn) {
            buttonTooltip = "You have already used your Transaction for this turn.";
          } else if (viewer.cash < forumPrice) {
            buttonTooltip = `Requires ${forumPrice}(d) (You have ${viewer.cash}(d)).`;
          } else if (!fitsInSUV) {
            buttonTooltip = isHenchmanTrack
              ? `Henchman capacity full (${viewer.usedHenchmen}/${viewer.maxHenchmen}▲) — click to fire a Henchman and hire ${card.name} for ${forumPrice}(d).`
              : `SUV space full (${viewer.usedBlocks}/${viewer.maxBlocks}■) — click to discard Goods and buy ${card.name} for ${forumPrice}(d).`;
          } else {
            buttonTooltip = `${isHenchmanTrack ? "Hire" : "Purchase"} ${card.name} at Forum ${forumSpec.cell} for ${forumPrice}(d)!`;
          }
        } else if (isMyMarketTurn && !fitsInSUV && viewer.cash >= basePrice) {
          buttonTooltip = isHenchmanTrack
            ? `Henchman capacity full (${viewer.usedHenchmen}/${viewer.maxHenchmen}▲) — click to fire a Henchman and hire ${card.name} for ${basePrice}(d).`
            : `SUV space full (${viewer.usedBlocks}/${viewer.maxBlocks}■) — click to discard Goods and buy ${card.name} for ${basePrice}(d).`;
        }

        gridCells.push(
          el(
            "div",
            { className: `market-bay-cell track-row-${trackKey} ${isHighlightedTrack ? "forum-highlighted-bay" : ""}` },
            el(
              "div",
              { className: "good-card-unit" },
              el(
                "div",
                {
                  className: `market-good-card ${trackClass} ${canForumBuy ? "forum-buyable-card" : ""}`,
                  style: { cursor: "pointer" },
                  onClick: () => {
                    if (isHenchmanTrack) {
                      openSUVHenchmanDetailModal(card);
                    } else {
                      openSUVGoodDetailModal(Object.assign({ track: trackName }, card), gs, viewer, true);
                    }
                  },
                },
                renderFullGoodCardFaceNode(card, trackName)
              ),
              el(
                "div",
                { className: "good-card-external-meta" },
                el("button", {
                  type: "button",
                  className: `btn btn-sm ${canBuy ? "btn-primary" : ""} ${canForumBuy ? "forum-buy-highlight-btn" : ""
                    }`,
                  style: { width: "100%", padding: "0.18rem 0.3rem", fontSize: "0.7rem" },
                  disabled: !canBuy,
                  title: buttonTooltip,
                  text: buttonLabel,
                  onClick: () => {
                    const actionBase = canForumBuy
                      ? { type: "delivery_forum_buy", colIndex: col }
                      : { type: "market_buy", track: trackName, colIndex: col };
                    const costHere = canForumBuy ? forumPrice : basePrice;
                    if (fitsInSUV) {
                      sendGameAction(actionBase);
                    } else {
                      openSUVReplacementModal(viewer, {
                        itemType: isHenchmanTrack ? "henchman" : "good",
                        incomingCard: card,
                        reqBlocks,
                        reqHenchmen,
                        bonusBlocks: cardBonusBlocks,
                        bonusHenchmen: cardBonusHenchmen,
                        title: isHenchmanTrack
                          ? `🛡️ Henchman Slots Full — Fire a Henchman to Hire ${card.name}?`
                          : `🛒 SUV Space Full — Discard Goods to Buy ${card.name}?`,
                        subtitle: isHenchmanTrack
                          ? `Hiring "${card.name}" costs ${costHere}(d), and your Henchman slots are full (${viewer.usedHenchmen}/${viewer.maxHenchmen}▲). Select a Henchman to fire, or cancel the hire action.`
                          : `Buying "${card.name}" (${reqBlocks}■) costs ${costHere}(d), and your SUV has ${viewer.usedBlocks}/${viewer.maxBlocks}■ used. Select Goods on your SUV to discard so it fits, or cancel the purchase.`,
                        confirmLabelPrefix: `${isHenchmanTrack ? "Hire" : "Buy"} ${card.name} for ${costHere}(d)`,
                        cancelLabel: isHenchmanTrack ? "Cancel Hire" : "Cancel Purchase",
                        onConfirm: (discardSUVIds, fireHenchmanIds) => {
                          sendGameAction({
                            ...actionBase,
                            discardSUVIds,
                            fireHenchmanIds,
                          });
                        },
                      });
                    }
                  },
                })
              )
            )
          )
        );
      }
    }
  }

  return el(
    "div",
    { className: "market-board" },
    el(
      "div",
      { className: "panel-title fresco-banner-header fresco-merchants", style: { flexWrap: "wrap", gap: "0.5rem" } },
      el("span", { text: "🧳 Safe House Motel — Open Suitcase Market Board" }),
      renderMarketHeaderDenariiCounts(gs, viewer)
    ),
    renderMarketNpcSpeechBubble(),
    forumSpec
      ? el(
        "div",
        {
          style: {
            padding: "0.55rem 0.85rem",
            marginBottom: "0.65rem",
            background: "#ecfdf5",
            border: "1.5px solid #16a34a",
            borderRadius: "6px",
            fontSize: "0.84rem",
            color: "#14532d",
            fontWeight: "600",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            flexWrap: "wrap",
            gap: "0.5rem",
          },
        },
        el("span", {
          text: `🏛️ Your SUV occupies Forum ${forumSpec.cell} (${forumSpec.cellName}), which sells ${forumSpec.category
            } (${formatTileModifier(forumSpec.modifier)})! ${forumSpec.canTransactNow
              ? `Highlighted '${forumSpec.category}' buttons below are ready to purchase.`
              : viewer.transactedThisTurn
                ? "You have already completed your Transaction this turn."
                : "Wait for your Delivery turn to purchase."
            }`,
        }),
        appState.boardViewMode === "market"
          ? el("button", {
            className: "btn btn-sm",
            text: "🗺️ Return to Rome Board",
            onClick: () => {
              appState.highlightedMarketTrack = null;
              appState.boardViewMode = gs.phase === "market" ? "rome" : "auto";
              renderApp();
            },
          })
          : null
      )
      : null,
    el(
      "div",
      {
        className: "ostia-market-board-matrix",
        onScroll: (e) => {
          appState.marketBoardScrollLeft = e.currentTarget.scrollLeft;
          appState.marketBoardScrollTop = e.currentTarget.scrollTop;
        },
      },
      colHeadersRow,
      el("div", { className: "ostia-market-grid" }, ...gridCells)
    )
  );
}

const TIBER_UNBRIDGED_CELL_CLASSES = {};

// InstantGram SF: the five road entry/exit points into San Francisco.
const TIBER_BRIDGE_BADGES_BY_CELL = {
  B1: [{ pos: "N", label: "🌉 Golden Gate Bridge" }],
  F1: [{ pos: "E", label: "🌉 Bay Bridge" }],
  F5: [{ pos: "E", label: "🛣️ US-101" }],
  D6: [{ pos: "S", label: "🛣️ I-280" }],
  A5: [{ pos: "W", label: "🛣️ Route 1" }],
};

const ROME_HOVER_TOOLTIP_DELAY_MS = 3000;

function scheduleRomeHoverTooltip(renderTooltipFn, clientX, clientY) {
  appState._romeHoverCoords = { x: clientX, y: clientY };
  appState._romeHoverRenderFn = renderTooltipFn;
  const existingTip = document.getElementById("rome-hover-tooltip");
  if (existingTip) existingTip.remove();
  if (appState._romeHoverTimer) {
    clearTimeout(appState._romeHoverTimer);
  }
  appState._romeHoverTimer = setTimeout(() => {
    appState._romeHoverTimer = null;
    if (typeof appState._romeHoverRenderFn === "function") {
      const coords = appState._romeHoverCoords || { x: clientX, y: clientY };
      appState._romeHoverRenderFn(coords.x, coords.y);
    }
  }, ROME_HOVER_TOOLTIP_DELAY_MS);
}

function positionRomeHoverTooltip(tooltipEl, clientX, clientY) {
  if (!tooltipEl) return;
  const pad = 16;
  const w = tooltipEl.offsetWidth || 248;
  const h = tooltipEl.offsetHeight || 290;
  let left = clientX + 18;
  let top = clientY - Math.round(h * 0.35);
  if (left + w + pad > window.innerWidth) {
    left = Math.max(pad, clientX - w - 18);
  }
  if (top + h + pad > window.innerHeight) {
    top = window.innerHeight - h - pad;
  }
  if (top < pad) top = pad;
  tooltipEl.style.left = `${left}px`;
  tooltipEl.style.top = `${top}px`;
}

function showRomeHoverTooltip(coord, cell, previewTile, isScoutedPreview, crossingSummary, clientX, clientY) {
  let tooltipEl = document.getElementById("rome-hover-tooltip");
  if (!tooltipEl) {
    tooltipEl = document.createElement("div");
    tooltipEl.id = "rome-hover-tooltip";
    tooltipEl.className = "rome-hover-tooltip";
    document.body.appendChild(tooltipEl);
  }
  const sellsStr =
    (previewTile.sells || []).length > 0
      ? previewTile.sells.map((s) => `${s.category} (${formatTileModifier(s.modifier)})`).join(", ")
      : "None";
  const buysStr =
    (previewTile.buys || []).length > 0
      ? previewTile.buys.map((b) => `${b.category} (${formatTileModifier(b.modifier)})`).join(", ")
      : null;
  const centerParts = [
    previewTile.encounter ? formatEdgeLabel(previewTile.encounter) : null,
    previewTile.gamble ? "Stadium Gamble (≤20d)" : null,
    previewTile.persistent ? "Persistent (⤹)" : previewTile.refresh ? "Refresh (↻)" : null,
  ].filter(Boolean);

  tooltipEl.replaceChildren(
    el(
      "div",
      { style: { display: "flex", justifyContent: "space-between", alignItems: "center", gap: "0.4rem", marginBottom: "0.35rem", width: "100%" } },
      el("strong", { style: { color: "var(--arch-gold)", fontSize: "0.8rem" }, text: `${coord} — ${cell ? cell.name : coord}` }),
      el("span", {
        className: "badge",
        style: isScoutedPreview
          ? { borderColor: "#38bdf8", color: "#0369a1", background: "rgba(14, 42, 84, 0.92)", fontSize: "0.65rem", padding: "0.08rem 0.35rem" }
          : { fontSize: "0.65rem", padding: "0.08rem 0.35rem" },
        text: isScoutedPreview ? "👁️ Scouted" : "Exposed",
      })
    ),
    renderDynamicTileCardNode(previewTile, coord, "inspector"),
    el(
      "div",
      { style: { fontSize: "0.72rem", marginTop: "0.38rem", lineHeight: "1.35", color: "#f8f1e5", width: "100%" } },
      el("div", {}, el("strong", { style: { color: "var(--arch-gold)" }, text: "Buys: " }), sellsStr),
      buysStr ? el("div", {}, el("strong", { style: { color: "#7dd3fc" }, text: "Sells: " }), buysStr) : null,
      centerParts.length > 0 ? el("div", { style: { color: "#fde68a" }, text: centerParts.join(" • ") }) : null,
      crossingSummary
        ? el("div", {
          style: { marginTop: "0.22rem", paddingTop: "0.22rem", borderTop: "1px solid rgba(255,248,232,0.22)", fontWeight: "700", color: crossingSummary.color },
          text: crossingSummary.text,
        })
        : null
    )
  );
  positionRomeHoverTooltip(tooltipEl, clientX, clientY);
}

function showRomeSimpleHoverTooltip(headingText, detailText, clientX, clientY) {
  let tooltipEl = document.getElementById("rome-hover-tooltip");
  if (!tooltipEl) {
    tooltipEl = document.createElement("div");
    tooltipEl.id = "rome-hover-tooltip";
    tooltipEl.className = "rome-hover-tooltip";
    document.body.appendChild(tooltipEl);
  }
  tooltipEl.replaceChildren(
    el(
      "div",
      { style: { display: "flex", flexDirection: "column", gap: "0.22rem", width: "100%" } },
      el("strong", { style: { color: "var(--arch-gold)", fontSize: "0.82rem" }, text: headingText }),
      detailText
        ? el("div", { style: { fontSize: "0.74rem", lineHeight: "1.35", color: "#f8f1e5" }, text: detailText })
        : null
    )
  );
  positionRomeHoverTooltip(tooltipEl, clientX, clientY);
}

function showRomeUnrevealedCellHoverTooltip(coord, cell, unrevealedCount, crossingSummary, clientX, clientY) {
  let tooltipEl = document.getElementById("rome-hover-tooltip");
  if (!tooltipEl) {
    tooltipEl = document.createElement("div");
    tooltipEl.id = "rome-hover-tooltip";
    tooltipEl.className = "rome-hover-tooltip";
    document.body.appendChild(tooltipEl);
  }
  const cellName = cell && cell.name ? cell.name : coord;
  const featureLines = [];
  if (cell && cell.isGate) {
    featureLines.push("🛣️ Bridge / Freeway Entry Point & Exit (halves 6:00 A.M. Curfew Fine)");
  }
  if (cell && cell.isForum) {
    featureLines.push("💊 Open-Air Drug Market (purchase Goods when revealed)");
  }
  const bridgesHere = TIBER_BRIDGE_BADGES_BY_CELL[coord] || [];
  if (bridgesHere.length > 0) {
    featureLines.push(`🌉 Tiber Bridge: ${bridgesHere.map((b) => b.label).join(", ")}`);
  }

  tooltipEl.replaceChildren(
    el(
      "div",
      { style: { display: "flex", justifyContent: "space-between", alignItems: "center", gap: "0.4rem", marginBottom: "0.28rem", width: "100%" } },
      el("strong", { style: { color: "var(--arch-gold)", fontSize: "0.8rem" }, text: `${coord} — ${cellName}` }),
      el("span", {
        className: "badge",
        style: { fontSize: "0.65rem", padding: "0.08rem 0.35rem" },
        text: `${unrevealedCount} Face-Down`,
      })
    ),
    el(
      "div",
      { style: { fontSize: "0.73rem", lineHeight: "1.35", color: "#f8f1e5", width: "100%" } },
      el("div", { text: `This is neighborhood ${coord} (${cellName}). Unrevealed stack (${unrevealedCount} tiles).` }),
      ...featureLines.map((line) => el("div", { style: { color: "#fde68a", marginTop: "0.18rem" }, text: line })),
      crossingSummary
        ? el("div", {
          style: { marginTop: "0.22rem", paddingTop: "0.22rem", borderTop: "1px solid rgba(255,248,232,0.22)", fontWeight: "700", color: crossingSummary.color },
          text: crossingSummary.text,
        })
        : null,
      el("div", {
        style: { marginTop: "0.25rem", color: "#cbd5e1", fontSize: "0.68rem" },
        text: "Click to open Move, Scout, or End Turn options.",
      })
    )
  );
  positionRomeHoverTooltip(tooltipEl, clientX, clientY);
}

function getCellOffBoardDirs(coord) {
  if (!coord || coord.length < 2) return [];
  const colIdx = COLS.indexOf(coord.slice(0, 1));
  const rowIdx = ROWS.indexOf(coord.slice(1));
  if (colIdx < 0 || rowIdx < 0) return [];
  const deltas = {
    N: [0, -1],
    NE: [1, -1],
    E: [1, 0],
    SE: [1, 1],
    S: [0, 1],
    SW: [-1, 1],
    W: [-1, 0],
    NW: [-1, -1],
  };
  const offDirs = [];
  for (const [d, [dx, dy]] of Object.entries(deltas)) {
    const nx = colIdx + dx;
    const ny = rowIdx + dy;
    if (nx < 0 || nx >= COLS.length || ny < 0 || ny >= ROWS.length) {
      offDirs.push(d);
    }
  }
  return offDirs;
}

function renderRomeNightBoard(gs, viewer) {
  const missionCells = new Set();
  for (const m of viewer.missions || []) {
    if (!m.completed && !m.failed) {
      if (m.pickupCell && !m.pickedUp) missionCells.add(m.pickupCell);
      if (m.deliverCell) missionCells.add(m.deliverCell);
      if (m.cell) missionCells.add(m.cell);
    }
  }

  const scoutedTileByCoord = {};
  for (const si of viewer.scoutedInfo || []) {
    if (si && si.targetType === "tile" && si.targetKey && si.revealedData) {
      const bCell = gs.romeBoard && gs.romeBoard[si.targetKey];
      if (!bCell || !bCell.revealed) {
        scoutedTileByCoord[si.targetKey] = si.revealedData;
      }
    }
  }

  const isMyDeliveryTurn = gs.phase === "delivery" && gs.activePlayerIndex === viewer.index;
  const reachableDirsByCell = {};
  const adjacentDirInfoByCell = {};
  let passableExitDir = null;
  let anyExitDir = null;
  const playerOffBoardDirs = viewer.position ? getCellOffBoardDirs(viewer.position) : [];
  const isPlayerOnPerimeter = playerOffBoardDirs.length > 0;
  const currCellObj = viewer.position ? gs.romeBoard[viewer.position] : null;
  const currOutDirs = (currCellObj && currCellObj.revealed && currCellObj.revealed.outgoingDirections) || {};
  for (const [dir, dInfo] of Object.entries(currOutDirs)) {
    if (dInfo && dInfo.targetCell) {
      adjacentDirInfoByCell[dInfo.targetCell] = { dir, ...dInfo };
    }
  }

  if (isMyDeliveryTurn && viewer.position && viewer.movesRemaining > 0) {
    for (const [dir, dInfo] of Object.entries(currOutDirs)) {
      if (dInfo.targetCell) {
        const riverBlocked = Boolean(dInfo.blockedByRiver) || isTiberCrossingBlocked(viewer.position, dInfo.targetCell);
        if (!riverBlocked && (dInfo.passable || (viewer.turnEffects && viewer.turnEffects.shortcut))) {
          reachableDirsByCell[dInfo.targetCell] = dir;
        }
      } else if (dInfo.isExit) {
        if (!anyExitDir) anyExitDir = dir;
        if (!passableExitDir && (dInfo.passable || (viewer.turnEffects && viewer.turnEffects.shortcut))) {
          passableExitDir = dir;
        }
      }
    }
    if (!passableExitDir && viewer.turnEffects && viewer.turnEffects.shortcut && playerOffBoardDirs.length > 0) {
      passableExitDir = playerOffBoardDirs[0];
    }
    if (!anyExitDir && playerOffBoardDirs.length > 0) {
      anyExitDir = playerOffBoardDirs[0];
    }
  }

  const triggerPerimeterMapEdgeExit = (e) => {
    if (!isMyDeliveryTurn || !viewer.position || viewer.movesRemaining <= 0 || !isPlayerOnPerimeter) {
      return false;
    }
    const dirToUse = passableExitDir || anyExitDir;
    if (!dirToUse) return false;
    if (e && typeof e.stopPropagation === "function") {
      e.stopPropagation();
    }
    hideRomeHoverTooltip();
    sendGameAction({ type: "delivery_move", direction: dirToUse });
    return true;
  };

  const npcReplay = computeNpcReplayPositions(gs);
  const gridCells = [];
  for (const r of ROWS) {
    for (const c of COLS) {
      const coord = `${c}${r}`;
      const cell = gs.romeBoard[coord];
      const rev = cell ? cell.revealed : null;
      const scoutedTopTile = !rev ? scoutedTileByCoord[coord] || null : null;
      const isCurrent = viewer.position === coord;
      const isMissionTarget = missionCells.has(coord);
      const isReachableMove = Boolean(reachableDirsByCell[coord]);
      const playersHere = gs.players.filter(
        (p) => npcReplay.posByPlayer[p.index] === coord && p.index !== npcReplay.glidingPlayerIndex
      );
      const cellOffDirs = getCellOffBoardDirs(coord);
      const isCellPerimeter = cellOffDirs.length > 0;
      const unrevealedCount = cell
        ? Number(
          cell.stackCount !== undefined
            ? cell.stackCount
            : cell.unrevealedCount !== undefined
              ? cell.unrevealedCount
              : 12
        )
        : 0;

      const cellClasses = ["rome-cell"];
      if (cell && cell.isGate) {
        cellClasses.push("is-gate");
        if (gs.phase === "delivery_entry" || (gs.phase === "delivery" && Number(gs.turn) === 1)) {
          cellClasses.push("is-via-start-highlight");
        }
      }
      if (cell && cell.isForum) cellClasses.push("is-forum");
      if (rev) cellClasses.push("has-revealed-tile");
      if (isCurrent) cellClasses.push("is-current");
      if (isMissionTarget) cellClasses.push("is-mission-target");
      if (isReachableMove) cellClasses.push("is-reachable-move");
      for (const tCls of TIBER_UNBRIDGED_CELL_CLASSES[coord] || []) {
        cellClasses.push(tCls);
      }

      const cellTitleParts = [
        `This is ${coord} (${cell ? cell.name : coord})`,
        cell && cell.isGate ? "Bridge / Freeway Entry Point" : null,
        cell && cell.isForum ? "Open-Air Drug Market" : null,
        rev
          ? "Revealed Tile"
          : scoutedTopTile
            ? `Scouted Unrevealed Stack (${unrevealedCount} tiles)`
            : `Unrevealed Stack (${unrevealedCount} face-down tiles)`,
        isCurrent ? "Your SUV is here" : null,
        isReachableMove ? `Reachable Move (${reachableDirsByCell[coord]})` : null,
        isCurrent || rev ? "Click for Up-Close Tile View" : "Click for Move, Scout, or End Turn options",
      ].filter(Boolean);
      const cellHelperTitle = cellTitleParts.join(" • ");

      const handleCellClick = (e) => {
        hideRomeHoverTooltip();
        appState.inspectedCell = coord;
        renderApp();
        const moveOpts = {
          moveDir: reachableDirsByCell[coord] || null,
          adjInfo: adjacentDirInfoByCell[coord] || null,
        };
        if (isCurrent || rev) {
          openFaceUpTileUpCloseModal(gs, viewer, coord, cell, rev || scoutedTopTile, moveOpts);
          return;
        }
        openConfirmScoutNeighborhoodModal(gs, viewer, coord, cell, moveOpts);
      };

      const handleCellMouseEnter = (e) => {
        const cellEl = e.currentTarget;
        document.querySelectorAll(".compass-btn.is-hovered-dir").forEach((b) => b.classList.remove("is-hovered-dir"));
        document.querySelectorAll(".edge-hover-preview-pill").forEach((p) => p.remove());

        let crossingSummary = null;
        const adjInfo = adjacentDirInfoByCell[coord];
        if (adjInfo && viewer.position && viewer.position !== coord) {
          const compassBtn = document.querySelector(`.compass-btn[data-compass-dir="${adjInfo.dir}"]`);
          if (compassBtn) compassBtn.classList.add("is-hovered-dir");
          const riverBlocked = Boolean(adjInfo.blockedByRiver) || isTiberCrossingBlocked(viewer.position, coord);
          const bridgeName = adjInfo.bridge || getTiberBridgeName(viewer.position, coord);
          const shortcutActive = Boolean(viewer.turnEffects && viewer.turnEffects.shortcut);
          const isPassable = !riverBlocked && (adjInfo.passable || shortcutActive);
          const tollAmt = parseTollAmount(adjInfo.edge);
          const isHazard =
            !riverBlocked &&
            !shortcutActive &&
            Boolean(adjInfo.edge && !["green", "red", "None"].includes(String(adjInfo.edge)));
          let pillText = "";
          if (riverBlocked) {
            pillText = `🌊 Tiber Impassable (${adjInfo.dir})`;
            crossingSummary = { text: `🌊 Blocked by Tiber River (${viewer.position} → ${coord})`, color: "#fca5a5" };
          } else if (!isPassable) {
            pillText = `⛔ Blocked (${adjInfo.dir})`;
            crossingSummary = { text: `⛔ Red Barricade (${viewer.position} → ${coord})`, color: "#fca5a5" };
          } else if (shortcutActive && !adjInfo.passable) {
            pillText = `✨ Shortcut (${adjInfo.dir})`;
            crossingSummary = { text: `✨ Shortcut Bypasses Barricade (${adjInfo.dir})`, color: "#86efac" };
          } else if (tollAmt > 0 && !shortcutActive) {
            pillText = `${bridgeName ? "🌉 " : ""}Toll ${tollAmt}(d) (${adjInfo.dir})`;
            crossingSummary = {
              text: `${bridgeName ? `🌉 ${bridgeName} • ` : ""}Road Toll: 𐆖${tollAmt} (${adjInfo.dir})`,
              color: "#fde68a",
            };
          } else if (isHazard) {
            const hLabel = formatEdgeLabel(adjInfo.edge);
            pillText = `⚔️ ${hLabel} (${adjInfo.dir})`;
            crossingSummary = {
              text: `${bridgeName ? `🌉 ${bridgeName} • ` : ""}Edge Hazard: ${hLabel}`,
              color: "#fde68a",
            };
          } else {
            pillText = bridgeName ? `🌉 ${bridgeName} (${adjInfo.dir})` : `✓ Open Road (${adjInfo.dir})`;
            crossingSummary = {
              text: bridgeName ? `🌉 Cross ${bridgeName} — Open Street` : `✓ Open Street (${viewer.position} → ${coord})`,
              color: "#86efac",
            };
          }
          if (cellEl && pillText) {
            const pillNode = el("div", {
              className: `edge-hover-preview-pill ${!isPassable ? "is-blocked" : isHazard || tollAmt > 0 ? "is-hazard" : ""}`,
              text: pillText,
            });
            cellEl.appendChild(pillNode);
          }
        }

        const previewTile = rev || scoutedTopTile;
        if (previewTile) {
          scheduleRomeHoverTooltip(
            (cx, cy) =>
              showRomeHoverTooltip(
                coord,
                cell,
                previewTile,
                Boolean(!rev && scoutedTopTile),
                crossingSummary,
                cx,
                cy
              ),
            e.clientX,
            e.clientY
          );
        } else {
          scheduleRomeHoverTooltip(
            (cx, cy) =>
              showRomeUnrevealedCellHoverTooltip(coord, cell, unrevealedCount, crossingSummary, cx, cy),
            e.clientX,
            e.clientY
          );
        }
      };

      const handleCellMouseMove = (e) => {
        appState._romeHoverCoords = { x: e.clientX, y: e.clientY };
        const existingTip = document.getElementById("rome-hover-tooltip");
        if (existingTip) {
          positionRomeHoverTooltip(existingTip, e.clientX, e.clientY);
        }
      };

      const exitEdgeVal = passableExitDir && rev && rev.edges ? rev.edges[passableExitDir] : null;
      const shortcutBypass = Boolean(viewer.turnEffects && viewer.turnEffects.shortcut);
      const exitTollAmt = !shortcutBypass ? parseTollAmount(exitEdgeVal) : 0;
      const hasExitToll = exitTollAmt > 0;
      const hasExitHazard =
        !shortcutBypass &&
        !hasExitToll &&
        Boolean(exitEdgeVal && !["green", "red", "None"].includes(String(exitEdgeVal)));
      const exitHazardNodes = [];
      if (hasExitToll) {
        exitHazardNodes.push(
          el("span", {
            className: "exit-strip-toll-badge",
            text: `${exitTollAmt}(d)`,
          })
        );
      } else if (hasExitHazard) {
        const exitFigs = buildEncounterFigureNodes(exitEdgeVal, "exit-strip-enc-icon");
        if (exitFigs.length > 0) {
          exitHazardNodes.push(el("span", { className: "exit-strip-enc-badge" }, ...exitFigs));
        }
      }
      const exitEdgeStripNode =
        isCurrent &&
          isMyDeliveryTurn &&
          viewer.movesRemaining > 0 &&
          passableExitDir &&
          !gs.pendingEncounter &&
          !viewer.pendingNpcOffer &&
          !((viewer.pendingSUVOverflow || []).length > 0) &&
          !((viewer.pendingMarketReward || []).length > 0)
          ? el(
            "button",
            {
              type: "button",
              className: `rome-exit-edge-strip exit-dir-${passableExitDir.toLowerCase()}${hasExitHazard ? " has-exit-encounter" : hasExitToll ? " has-exit-toll" : ""
                }`,
              onClick: (e) => {
                triggerPerimeterMapEdgeExit(e);
              },
            },
            ...exitHazardNodes,
            el("span", { text: `🚪 Exit (${passableExitDir})` })
          )
          : null;

      const bridgeBadgeNodes = (TIBER_BRIDGE_BADGES_BY_CELL[coord] || []).map((bSpec) =>
        el("span", {
          className: `tiber-bridge-pill bridge-dir-${bSpec.pos}`,
          text: bSpec.label,
        })
      );

      gridCells.push(
        el(
          "div",
          {
            className: cellClasses.join(" "),
            onClick: handleCellClick,
            onMouseEnter: handleCellMouseEnter,
            onMouseMove: handleCellMouseMove,
            onMouseLeave: () => hideRomeHoverTooltip(),
          },
          rev ? renderDynamicTileCardNode(rev, coord, "board") : null,
          !rev && scoutedTopTile
            ? el("span", {
              className: "cell-scouted-badge",
              text: "👁️ Scouted",
            })
            : null,
          ...bridgeBadgeNodes,
          exitEdgeStripNode,
          el("div", {
            className: "cell-neighborhood-title",
            text: cell ? cell.name : "",
          }),
          playersHere.length > 0
            ? el(
              "div",
              {
                className: `suv-tokens-row ${playersHere.length > 1 ? "is-stacked" : ""} ${rev && rev.edges && rev.edges.S && !["green", "red", "none"].includes(rev.edges.S)
                  ? "has-south-badge"
                  : ""
                  }`.trim(),
              },
              ...playersHere.map((p, idx) => {
                const isOutsideGate = Boolean(npcReplay.waitingOutsideGateByPlayer[p.index] && cell && cell.isGate);
                const isActiveNpcHere = Boolean(
                  appState.activeNpcEvent &&
                  appState.activeNpcEvent.phase !== "market" &&
                  appState.activeNpcEvent.playerIndex === p.index
                );
                return renderSUVIconNode(
                  p.color,
                  `suv-icon-board suv-stack-item-${idx}${isOutsideGate ? " is-waiting-outside-gate" : ""}${isActiveNpcHere ? " is-active-npc-suv" : ""
                  }`,
                  ""
                );
              })
            )
            : null
        )
      );
    }
  }

  const canExitOnEdgeClick = Boolean(
    isMyDeliveryTurn && viewer.position && viewer.movesRemaining > 0 && isPlayerOnPerimeter && (passableExitDir || anyExitDir)
  );

  const showViaStartBanner =
    gs.phase === "delivery_entry" || (gs.phase === "delivery" && Number(gs.turn) === 1);

  return el(
    "div",
    { className: "rome-layout" },
    showViaStartBanner
      ? el(
        "div",
        {
          className: "via-start-reminder-bar",
        },
        el("span", { className: "via-start-reminder-icon", text: "⛩️" }),
        el(
          "span",
          {
            text:
              gs.phase === "delivery_entry"
                ? "Start at an Entry Point: Every dealer must enter San Francisco at one of the five gold-outlined entry points — B1 (Golden Gate Bridge), F1 (Bay Bridge), F5 (US-101), D6 (I-280), or A5 (Route 1)."
                : "8:00 P.M. Entry Hour: Dealers begin the night at one of San Francisco's five gold-outlined entry points (B1, F1, F5, D6, A5).",
          }
        )
      )
      : null,
    el(
      "div",
      {
        className: `rome-board-frame ${canExitOnEdgeClick && passableExitDir ? "can-exit-rome-edge" : ""}`,
        onClick: (e) => {
          if (e.target === e.currentTarget) {
            triggerPerimeterMapEdgeExit(e);
          }
        },
      },
      el(
        "div",
        { className: "rome-board-matrix" },
        el("div", {
          className: `rome-axis-corner ${canExitOnEdgeClick && passableExitDir ? "can-exit-rome-edge" : ""}`,
          onMouseEnter: (e) =>
            scheduleRomeHoverTooltip(
              (cx, cy) =>
                showRomeSimpleHoverTooltip(
                  "San Francisco Map Grid Axis",
                  "Columns A–F (West to East) × Rows 1–6 (North to South).",
                  cx,
                  cy
                ),
              e.clientX,
              e.clientY
            ),
          onMouseMove: (e) => {
            appState._romeHoverCoords = { x: e.clientX, y: e.clientY };
            const tip = document.getElementById("rome-hover-tooltip");
            if (tip) positionRomeHoverTooltip(tip, e.clientX, e.clientY);
          },
          onMouseLeave: () => hideRomeHoverTooltip(),
          onClick: (e) => triggerPerimeterMapEdgeExit(e),
        }),
        el(
          "div",
          {
            className: `rome-col-headers-bar ${canExitOnEdgeClick && passableExitDir ? "can-exit-rome-edge" : ""}`,
            onClick: (e) => triggerPerimeterMapEdgeExit(e),
          },
          ...COLS.map((c) =>
            el("div", {
              className: "rome-col-heading",
              onMouseEnter: (e) =>
                scheduleRomeHoverTooltip(
                  (cx, cy) =>
                    showRomeSimpleHoverTooltip(
                      `This is the ${c} column`,
                      `Column ${c} contains San Francisco neighborhoods ${c}1 through ${c}6.`,
                      cx,
                      cy
                    ),
                  e.clientX,
                  e.clientY
                ),
              onMouseMove: (e) => {
                appState._romeHoverCoords = { x: e.clientX, y: e.clientY };
                const tip = document.getElementById("rome-hover-tooltip");
                if (tip) positionRomeHoverTooltip(tip, e.clientX, e.clientY);
              },
              onMouseLeave: () => hideRomeHoverTooltip(),
              text: c,
            })
          )
        ),
        el(
          "div",
          {
            className: `rome-row-headers-bar ${canExitOnEdgeClick && passableExitDir ? "can-exit-rome-edge" : ""}`,
            onClick: (e) => triggerPerimeterMapEdgeExit(e),
          },
          ...ROWS.map((r) =>
            el("div", {
              className: "rome-row-heading",
              onMouseEnter: (e) =>
                scheduleRomeHoverTooltip(
                  (cx, cy) =>
                    showRomeSimpleHoverTooltip(
                      `This is Row ${r}`,
                      `Row ${r} contains San Francisco neighborhoods A${r} through F${r}.`,
                      cx,
                      cy
                    ),
                  e.clientX,
                  e.clientY
                ),
              onMouseMove: (e) => {
                appState._romeHoverCoords = { x: e.clientX, y: e.clientY };
                const tip = document.getElementById("rome-hover-tooltip");
                if (tip) positionRomeHoverTooltip(tip, e.clientX, e.clientY);
              },
              onMouseLeave: () => hideRomeHoverTooltip(),
              text: r,
            })
          )
        ),
        el("div", { className: "rome-grid" }, ...gridCells, renderRomeNpcAnimationLayer())
      )
    )
  );
}

function renderSUVNavigationWidget(gs, viewer) {
  const isSUVInRome = Boolean(viewer.position);
  const navCoord = viewer.position || "B1";
  const cell = gs.romeBoard[navCoord] || gs.romeBoard["B1"];
  const rev = isSUVInRome && cell ? cell.revealed : null;
  const isMyDeliveryTurn = gs.phase === "delivery" && gs.activePlayerIndex === viewer.index && isSUVInRome;
  const isMyGateEntryTurn = gs.phase === "delivery_entry" && gs.activePlayerIndex === viewer.index;
  const landmark = ROME_LANDMARKS[navCoord] || { icon: "🏙️", sub: "San Francisco Neighborhood" };

  const compassDirs = ["NW", "N", "NE", "W", "CENTER", "E", "SW", "S", "SE"];
  const outDirs = (rev && rev.outgoingDirections) || {};

  const compassNodes = compassDirs.map((dir) => {
    if (dir === "CENTER") {
      return el(
        "div",
        { className: "compass-center" },
        el("strong", { style: { color: "var(--gold-bright)" }, text: isSUVInRome ? `${landmark.icon} ${navCoord}` : "🧭" }),
        el("span", {
          style: { fontSize: "0.66rem", color: "var(--text-muted)" },
          text: isSUVInRome ? cell?.name || "Your SUV" : "Outside Walls",
        })
      );
    }
    const info = outDirs[dir];
    if (!info) {
      const targetAdj = isSUVInRome ? getNeighborCoordInDir(navCoord, dir) : null;
      const riverNoBridge = targetAdj ? isTiberCrossingBlocked(navCoord, targetAdj) : false;
      return el(
        "button",
        {
          type: "button",
          className: "compass-btn blocked",
          "data-compass-dir": dir,
          disabled: true,
        },
        el("strong", { text: dir }),
        el("span", { style: { fontSize: "0.66rem" }, text: riverNoBridge ? "🌊 Tiber River" : rev ? "No Road" : "—" })
      );
    }
    const riverBlocked =
      Boolean(info.tiberBlocked || info.blockedByRiver) ||
      (info.targetCell ? isTiberCrossingBlocked(navCoord, info.targetCell) : false);
    const bridgeName =
      info.bridgeName || info.bridge || (info.targetCell ? getTiberBridgeName(navCoord, info.targetCell) : null);
    const shortcutActive = Boolean(viewer.turnEffects && viewer.turnEffects.shortcut);
    const passable = !riverBlocked && (info.passable || shortcutActive);
    const canClickMove = isMyDeliveryTurn && viewer.movesRemaining > 0 && passable;
    const destLabel = info.isExit ? `🚪 ESCAPE SF${info.exitLabel ? ` (${info.exitLabel})` : ""}` : `→ ${info.targetCell}`;
    const dividedTiberActive = Boolean(bridgeName && (Number(info.bridgeTollCost) > 0 || hasActiveClimateOption(gs, "isis_3")));
    const bridgeTollWaived =
      dividedTiberActive && (shortcutActive || (Number(viewer.favor && viewer.favor.ISIS) || 0) >= 1);
    const bridgeTollNote = dividedTiberActive
      ? bridgeTollWaived
        ? " • 0d Bridge"
        : " • 4d Toll"
      : "";
    const subLabel = riverBlocked
      ? "🌊 Tiber River"
      : bridgeName
        ? `🌉 ${bridgeName} • ${formatEdgeLabel(info.edge)}${bridgeTollNote}`
        : formatEdgeLabel(info.edge);
    return el(
      "button",
      {
        type: "button",
        className: `compass-btn ${passable ? "passable" : "blocked"}`,
        "data-compass-dir": dir,
        disabled: !canClickMove,
        title: `Move ${dir} (${destLabel})${bridgeTollNote}`,
        onClick: () => sendGameAction({ type: "delivery_move", direction: dir }),
      },
      el("strong", { text: `${dir} (${destLabel})` }),
      el("span", { style: { fontSize: "0.66rem" }, text: subLabel })
    );
  });

  const locationStatusText = isSUVInRome
    ? `📍 SUV at ${viewer.position} — ${cell ? cell.name : ""}`
    : viewer.exitedRome
      ? "✓ SUV Exited Rome Safely"
      : isMyGateEntryTurn
        ? "🚪 At City Gates — Choose Entry Gate"
        : "⚓ SUV at Portus Ostiae";

  const movesStatusText = isSUVInRome
    ? gs.phase === "delivery" && gs.turn === 1 && viewer.movesRemaining === 0
      ? "Turn 1 Move Used"
      : `Moves Left: ${viewer.movesRemaining ?? 0}`
    : isMyGateEntryTurn
      ? "Turn 1 Entry"
      : gs.phase === "delivery"
        ? "Waiting"
        : "—";

  const gateCoords = Object.keys(gs.romeBoard || {}).filter(
    (coord) => gs.romeBoard[coord] && gs.romeBoard[coord].isGate
  );

  const txButtons = [];
  if (isMyDeliveryTurn && rev) {
    const smugglersFenceActive = hasActiveClimateOption(gs, "ms13_3");
    let anySellableShown = false;
    const shownBulkGrainKeys = new Set();
    for (const item of viewer.suv || []) {
      const hasPaidCost = !item.isMissionCargo && typeof item.purchasePrice === "number";
      for (const sOpt of item.availableSells || []) {
        if (!anySellableShown) {
          anySellableShown = true;
          txButtons.push(
            el("div", {
              style: { fontSize: "0.72rem", color: "var(--gold-bright)", fontWeight: "700" },
              text: viewer.transactedThisTurn ? "✓ Transaction Used This Hour" : "💰 Sell 1 Good (or Bulk Grain):",
            })
          );
        }
        const bulkKey = `${sOpt.missionId || "tile"}:${sOpt.modifier || "="}`;
        if (
          (sOpt.category === "Grain" || sOpt.category === "Weed") &&
          !sOpt.isFencedCargo &&
          Number(sOpt.bulkGrainCount) >= 2 &&
          Array.isArray(sOpt.bulkGrainCardIds) &&
          !shownBulkGrainKeys.has(bulkKey)
        ) {
          shownBulkGrainKeys.add(bulkKey);
          const bulkNet = Number(sOpt.bulkGrainTotalPrice) - Number(sOpt.bulkGrainPurchasePrice || 0);
          const bulkNetStr = bulkNet >= 0 ? `+${bulkNet}d` : `${bulkNet}d`;
          txButtons.push(
            el("button", {
              type: "button",
              className: "btn btn-sm btn-primary",
              disabled: viewer.transactedThisTurn,
              text: `🌾 Bulk Sell All ${sOpt.bulkGrainCount} Grain (${sOpt.bulkGrainTotalPrice}d @ ${sOpt.scarcitySymbol}) [Net ${bulkNetStr}]${sOpt.isMission ? " [Mission]" : ""
                }`,
              onClick: () =>
                sendGameAction({
                  type: "delivery_sell",
                  category: "Grain",
                  bulkGrain: true,
                  cardIds: sOpt.bulkGrainCardIds,
                  missionId: sOpt.missionId || undefined,
                }),
            })
          );
        }
        let profitSuffix = "";
        if (hasPaidCost && !sOpt.isFencedCargo) {
          const net = Number(sOpt.price) - Number(item.purchasePrice);
          const netStr = net >= 0 ? `+${net}d` : `${net}d`;
          profitSuffix = ` [Paid ${item.purchasePrice}d • Net ${netStr}]`;
        }
        const fenceTag = sOpt.isFencedCargo
          ? smugglersFenceActive
            ? " [Clique Fence]"
            : " [Fails Mission]"
          : "";
        txButtons.push(
          el("button", {
            type: "button",
            className: `btn btn-sm ${sOpt.isFencedCargo ? "btn-crimson" : "btn-primary"}`,
            disabled: viewer.transactedThisTurn,
            text: `${sOpt.isFencedCargo ? "🕵️ Fence" : "💰 Sell"} ${item.name} (${sOpt.price}d @ ${sOpt.scarcitySymbol})${profitSuffix}${sOpt.isMission ? " [Mission]" : fenceTag
              }`,
            onClick: () =>
              sendGameAction({
                type: "delivery_sell",
                category: sOpt.category,
                cardIds: [item.id],
                missionId: sOpt.missionId || undefined,
              }),
          })
        );
        if (Array.isArray(sOpt.amethystBoostOptions) && sOpt.amethystBoostOptions.length > 0 && !viewer.transactedThisTurn) {
          txButtons.push(
            el(
              "div",
              { className: "amethyst-boost-row" },
              ...sOpt.amethystBoostOptions.map((boost) =>
                el("button", {
                  type: "button",
                  className: "btn btn-sm amethyst-boost-btn",
                  text: `🔮 Spend ${boost.spend} Sapphire${boost.spend > 1 ? "s" : ""} → Sell ${item.name} (${boost.price}d @ ${boost.scarcitySymbol})`,
                  onClick: () =>
                    sendGameAction({
                      type: "delivery_sell",
                      category: sOpt.category,
                      cardIds: [item.id],
                      missionId: sOpt.missionId || undefined,
                      spendAmethysts: boost.spend,
                    }),
                })
              )
            )
          );
        }
      }
    }

    if (cell && cell.isForum && rev.buys && rev.buys.length > 0) {
      const bSpec = rev.buys[0];
      txButtons.push(
        el("button", {
          type: "button",
          className: "btn btn-sm btn-primary",
          text: `🏛️ Buy ${bSpec.category} at Forum`,
          onClick: () => navigateToMarketBoardForCategory(bSpec.category),
        })
      );
    }

    if (rev.gamble) {
      const alreadyGambled = Boolean(viewer.gambledThisTurn);
      txButtons.push(
        el("button", {
          type: "button",
          className: "btn btn-sm",
          disabled: alreadyGambled || viewer.transactedThisTurn || viewer.cash <= 0,
          text: alreadyGambled ? "🎲 Gambled This Turn ✓" : "🎲 Stadium Gambling (Max 20d)",
          onClick: () => openGambleModal(viewer),
        })
      );
    }
  }

  return el(
    "div",
    { className: "suv-navigation-widget" },
    el(
      "div",
      { className: "suv-nav-status-bar" },
      el("span", { style: { fontWeight: "700", color: "var(--gold-bright)" }, text: locationStatusText }),
      el("span", {
        style: {
          fontWeight: "800",
          color: isMyDeliveryTurn && viewer.movesRemaining > 0 ? "#15803d" : "var(--text-muted)",
        },
        text: movesStatusText,
      })
    ),
    isMyGateEntryTurn
      ? el(
        "div",
        {
          style: {
            marginBottom: "0.6rem",
            padding: "0.5rem 0.6rem",
            borderRadius: "7px",
            background: "rgba(216, 169, 75, 0.1)",
            border: "1px solid rgba(216, 169, 75, 0.35)",
          },
        },
        el("div", {
          style: { fontSize: "0.74rem", fontWeight: "700", color: "var(--gold-bright)", marginBottom: "0.35rem" },
          text: "🚪 Enter Rome via a City Gate:",
        }),
        el(
          "div",
          { style: { display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: "0.35rem" } },
          ...gateCoords.map((gCoord) =>
            el("button", {
              type: "button",
              className: "btn btn-sm btn-primary",
              text: `🚪 ${gCoord}`,
              title: `Move onto Gate ${gCoord}`,
              onClick: () => sendGameAction({ type: "select_gate", gate: gCoord }),
            })
          )
        )
      )
      : null,
    isSUVInRome ? el("div", { className: "compass-grid" }, ...compassNodes) : null,
    txButtons.length > 0
      ? el(
        "div",
        {
          style: {
            display: "flex",
            flexDirection: "column",
            gap: "0.42rem",
            marginTop: "0.55rem",
            paddingTop: "0.48rem",
            borderTop: "1px solid rgba(110, 82, 50, 0.28)",
          },
        },
        ...txButtons
      )
      : null
  );
}

function renderPlayerSidebar(gs, viewer) {
  const isNavTab = appState.suvPanelTab === "navigate";
  const canSteerNow =
    gs.activePlayerIndex === viewer.index &&
    ((gs.phase === "delivery" && Boolean(viewer.position) && (viewer.movesRemaining || 0) > 0) ||
      gs.phase === "delivery_entry");
  const viewerMissionsDone = Number(viewer.missionsCompleted) || 0;
  const viewerMissionsFail = Number(viewer.missionsFailed) || 0;
  const viewerNetMissions =
    typeof viewer.netMissions === "number" ? viewer.netMissions : viewerMissionsDone - viewerMissionsFail;

  return el(
    "div",
    { className: "sidebar-stack" },
    // All Players Summary
    el(
      "div",
      { className: "panel" },
      el(
        "h3",
        { className: "panel-title" },
        el("span", { text: "👥 Merchants in Rome" }),
        el("span", { style: { fontSize: "0.72rem", color: "var(--text-muted)", fontWeight: "600" }, text: "Click to inspect SUV" })
      ),
      el(
        "div",
        { className: "players-strip" },
        ...gs.players.map((p) => {
          const swatchColor = resolveDieSwatchColor(p.color, "player");
          const pDone = Number(p.missionsCompleted) || 0;
          const pFail = Number(p.missionsFailed) || 0;
          const pNet = typeof p.netMissions === "number" ? p.netMissions : pDone - pFail;
          return el(
            "div",
            {
              className: `player-mini-card clickable-merchant-card ${p.index === gs.activePlayerIndex ? "active-turn" : ""}`,
              style: { borderLeft: `3px solid ${swatchColor}` },
              title: `Click to view ${p.name}'s SUV Mat (${p.usedBlocks}/${p.maxBlocks}■ Goods, ${p.usedHenchmen}/${p.maxHenchmen}▲ Henchmen, Net Missions ${pNet >= 0 ? `+${pNet}` : pNet}, 𐆖${p.cash})`,
              onClick: () => openPlayerSUVModal(gs, p, viewer),
            },
            el(
              "div",
              { style: { display: "flex", alignItems: "center", gap: "0.35rem", fontWeight: "700" } },
              renderSUVIconNode(p.color, "", `${p.name}'s SUV`),
              el("span", { text: p.eliminated ? `☠️ ${p.name}` : p.name })
            ),
            el("div", {
              style: { color: p.eliminated ? "#b91c1c" : swatchColor, fontWeight: "800", marginTop: "0.2rem" },
              text: p.eliminated ? `☠️ ${p.cash}(d) (Eliminated)` : `💰 ${p.cash}(d)`,
            }),
            el("div", {
              style: { fontSize: "0.71rem", color: "var(--text-muted)" },
              text: `SUV: ${p.usedBlocks}/${p.maxBlocks}■ • ${p.usedHenchmen}/${p.maxHenchmen}▲ • 📜 Net ${pNet >= 0 ? `+${pNet}` : pNet}`,
            }),
            el("div", {
              style: { fontSize: "0.72rem", color: p.exitedRome ? "#15803d" : "var(--text-main)", fontWeight: p.exitedRome ? "700" : "400" },
              text: p.position ? `📍 At ${p.position}` : p.exitedRome ? "✓ Exited Safely" : "At Ostia",
            })
          );
        })
      )
    ),

    // Imperial Faction Standings (Directly under Merchants in Rome, above SUV Holdings)
    el(
      "div",
      { className: "panel" },
      el(
        "h3",
        { className: "panel-title" },
        el("span", { text: "🏛️ Faction Standings" }),
        el("span", {
          style: { fontSize: "0.72rem", color: "var(--text-muted)", fontWeight: "600" },
          text: "Click a Gem for Details",
        })
      ),
      el(
        "div",
        { className: "favor-row", style: { margin: "0" } },
        ...FACTION_META.map((fm) => {
          const val = (viewer.favor && viewer.favor[fm.key]) || 0;
          const rivals = (gs.players || []).filter((p) => p.index !== viewer.index);
          return el(
            "div",
            {
              className: "favor-box clickable-favor-box",
              style: { cursor: "pointer" },
              title: `Click to view ${fm.label || fm.key} Favor breakdown, alignments & deck counts`,
              onClick: () => openFactionFavorModal(gs, viewer, fm.key),
            },
            el("img", { className: "favor-gem-img", src: fm.gem, alt: fm.key }),
            el("div", { style: { fontWeight: "700", color: fm.color }, text: fm.label || fm.key }),
            el("div", {
              style: {
                fontWeight: "800",
                fontSize: "0.86rem",
                color: val > 0 ? "#15803d" : val < 0 ? "#b91c1c" : "var(--text-main)",
              },
              text: val > 0 ? `+${val}` : String(val),
            }),
            rivals.length > 0
              ? el(
                "div",
                { className: "faction-standings-rivals" },
                ...rivals.map((rv) => {
                  const rVal = (rv.favor && rv.favor[fm.key]) || 0;
                  const rShort = String(rv.name || "Rival").split(" ")[0];
                  return el(
                    "div",
                    {
                      className: "faction-standing-rival-line",
                      title: `${rv.name}: ${rVal > 0 ? `+${rVal}` : rVal} ${fm.label || fm.key}`,
                    },
                    el(
                      "span",
                      { className: "faction-standing-rival-name" },
                      el("span", {
                        className: "faction-standing-swatch",
                        style: { background: resolveDieSwatchColor(rv.color, "player") },
                      }),
                      el("span", { text: rShort })
                    ),
                    el("strong", {
                      style: {
                        color: rVal > 0 ? "#15803d" : rVal < 0 ? "#b91c1c" : "var(--text-muted)",
                      },
                      text: rVal > 0 ? `+${rVal}` : String(rVal),
                    })
                  );
                })
              )
              : null
          );
        })
      ),
      renderDomnaMediatorExchangeBar(gs, viewer, false)
    ),

    // Your Merchant SUV Mat & Integrated Navigation + Tile Inspector Tab
    el(
      "div",
      { className: "panel" },
      el(
        "h3",
        { className: "panel-title fresco-banner-header fresco-suv" },
        el(
          "span",
          { style: { display: "inline-flex", alignItems: "center", gap: "0.4rem" } },
          renderSUVIconNode(viewer.color, "", `${viewer.name}'s SUV`),
          el("span", { text: `${viewer.name}'s SUV` })
        ),
        el("span", { className: "fresco-header-cash", text: `${viewer.cash}(d)` })
      ),
      el(
        "div",
        { className: "suv-panel-tabs-bar", role: "tablist" },
        el(
          "button",
          {
            type: "button",
            role: "tab",
            "aria-selected": String(!isNavTab),
            className: `suv-panel-tab-btn${!isNavTab ? " is-active" : ""}`,
            title: "View physical SUV Mat (Henchmen & Cargo)",
            onClick: () => {
              appState.suvPanelTab = "suv";
              renderApp();
            },
          },
          el("span", { text: `🛒 SUV Mat (${viewer.usedBlocks}/${viewer.maxBlocks}■ • ${viewer.usedHenchmen}/${viewer.maxHenchmen}▲)` })
        ),
        el(
          "button",
          {
            type: "button",
            role: "tab",
            "aria-selected": String(isNavTab),
            className: `suv-panel-tab-btn${isNavTab ? " is-active" : ""}`,
            title: "Steer your SUV across Rome",
            onClick: () => {
              appState.suvPanelTab = "navigate";
              renderApp();
            },
          },
          canSteerNow ? el("span", { className: "suv-tab-live-dot", title: "Ready to move!" }) : null,
          el("span", {
            text:
              viewer.position && gs.phase === "delivery"
                ? `🧭 Navigate (${viewer.position} • ${viewer.movesRemaining ?? 0} mv)`
                : "🧭 Navigate",
          })
        )
      ),
      isNavTab
        ? renderSUVNavigationWidget(gs, viewer)
        : renderPhysicalSUVMatNode(gs, viewer, viewer, false)
    ),

    // Active Missions in Portrait 5:7 Format, Subtly Divided by Type (Starting → Encounter → Schizophrenic)
    (() => {
      const allMissions = viewer.missions || [];
      const startingMissions = allMissions.filter((m) => !m.source || m.source === "starting");
      const encounterMissions = allMissions.filter((m) => m.source === "encounter");
      const schizophrenicMissions = allMissions.filter((m) => m.source === "schizophrenic");
      const canActivelyCancel =
        gs.phase !== "setup_discard" && gs.phase !== "setup_climate" && gs.phase !== "finished";
      const canCancelSchizophrenic = canActivelyCancel && schizophrenicMissions.length > 5;
      const bondedCouriersActive = hasActiveClimateOption(gs, "missions_3");

      const activeGroups = [
        {
          key: "starting",
          title: `Starting (${startingMissions.length})`,
          sub: bondedCouriersActive ? "-10(d) Fine" : "No penalty",
          missions: startingMissions,
          canCancel: canActivelyCancel,
          cancelLabel: bondedCouriersActive ? "✕ Cancel (-10d Fine)" : "✕ Cancel (No Penalty)",
        },
        {
          key: "encounter",
          title: `Encounter (${encounterMissions.length})`,
          sub: bondedCouriersActive ? "👎 + -10(d) Fine" : "👎 Penalty",
          missions: encounterMissions,
          canCancel: canActivelyCancel,
          cancelLabel: bondedCouriersActive ? "✕ Cancel (👎 + -10d)" : "✕ Cancel (👎 Penalty)",
        },
        {
          key: "schizophrenic",
          title: `Schizophrenic (${schizophrenicMissions.length})`,
          sub: canCancelSchizophrenic ? "Cancel 1 Free" : bondedCouriersActive ? "🔒 2× Cash / -10d" : "🔒 Mandatory",
          missions: schizophrenicMissions,
          canCancel: canCancelSchizophrenic,
          cancelLabel: "✕ Cancel Overflow (Free)",
        },
      ].filter((g) => g.missions.length > 0);

      const rowChildren = [];
      activeGroups.forEach((g, idx) => {
        if (idx > 0) {
          rowChildren.push(
            el("div", {
              className: "mission-group-divider",
              title: `${activeGroups[idx - 1].title} | ${g.title}`,
            })
          );
        }
        rowChildren.push(
          el(
            "div",
            {
              className: `mission-row-group mission-group-${g.key}`,
            },
            el(
              "div",
              { className: `mission-section-hdr ${g.key}` },
              el("span", { className: "mission-section-title", text: g.title }),
              el("span", { className: "mission-section-sub", text: g.sub })
            ),
            el(
              "div",
              {
                className: "mission-row-group-cards",
              },
              ...g.missions.map((m) =>
                renderPhysicalMissionCardNode(m, {
                  showStatusTag: true,
                  canCancel: g.canCancel,
                  cancelLabel: g.cancelLabel,
                  schizophrenicTotalCount: schizophrenicMissions.length,
                })
              )
            )
          )
        );
      });

      return el(
        "div",
        { className: "panel" },
        el(
          "h3",
          { className: "panel-title" },
          el(
            "span",
            { text: `📜 Active Missions (${allMissions.length})${bondedCouriersActive ? " [2× Cash / -10d Fail]" : ""}` }
          ),
          schizophrenicMissions.length > 5
            ? el("span", {
              style: {
                fontSize: "0.72rem",
                background: "#b45309",
                color: "#fff",
                padding: "2px 6px",
                borderRadius: "4px",
                fontWeight: "700",
              },
              text: "⚠️ 6 Schizophrenic Missions — Cancel 1 Free!",
            })
            : el("span", {
              style: {
                fontSize: "0.72rem",
                color: viewerNetMissions > 0 ? "#15803d" : viewerNetMissions < 0 ? "#b91c1c" : "var(--text-muted)",
                fontWeight: "700",
              },
              title: "Tracks Missions Completed (✓) vs Missions Failed (✕) — including unfinished missions at Sunday Reckoning",
              text: `✓${viewerMissionsDone} • ✕${viewerMissionsFail} (Net ${viewerNetMissions >= 0 ? `+${viewerNetMissions}` : viewerNetMissions
                })`,
            })
        ),
        gs.phase === "setup_discard" && !viewer.setupDiscarded
          ? el("div", {
            className: "mission-section-empty",
            text: "Select 2 of your 5 Starting Missions to discard in the Setup panel.",
          })
          : allMissions.length === 0
            ? el("div", { className: "mission-section-empty", text: "No active missions." })
            : el(
              "div",
              {
                className: "missions-single-row",
              },
              ...rowChildren
            )
      );
    })(),

    // Influence Cards & Scouted Intelligence (Physical Card Format)
    el(
      "div",
      { className: "panel" },
      el("h3", { className: "panel-title", text: `🃏 Influence Cards (${(viewer.influence || []).length})` }),
      gs.phase === "setup_discard" && !viewer.setupDiscarded
        ? el("div", {
          style: { fontSize: "0.8rem", color: "var(--text-muted)" },
          text: "Select 2 of your 5 Starting Influence cards to discard in the Setup panel.",
        })
        : (viewer.influence || []).length === 0
          ? el("div", { style: { fontSize: "0.8rem", color: "var(--text-muted)" }, text: "No Influence cards in hand." })
          : el(
            "div",
            { className: "phys-cards-grid compact-sidebar-grid" },
            ...(viewer.influence || []).map((c) => {
              const effCode = String(c.effectCode || "");
              const effTxt = String(c.effectText || "").toLowerCase();
              const cName = String(c.name || "");
              const isTop3Card =
                effCode.startsWith("reorder_top_3") ||
                cName.toLowerCase().includes("informants") ||
                effTxt.includes("look at the top three");
              const isProcurerCard =
                effCode === "buy_any_good_common" ||
                cName.toLowerCase() === "procurer";
              const isProphecyCard = cName === "Prophecy" || effCode === "trigger_schizophrenic";
              const isSurpriseShipmentCard =
                cName === "Surprise Shipment" || effCode === "shift_category_scarcity_right";
              const isShortcutCard = cName.includes("Shortcut") || effCode === "shortcut";
              const isReactiveOnly = cName === "Twist Of Fate" || cName === "Lucky Break";
              const canPlayNow = isInfluenceCardPlayableNow(gs, viewer, c);

              let actionNode = null;
              if (canPlayNow) {
                const needsThugSwap =
                  cName.includes("Thug") && !doesItemFitWithoutSwap(viewer, { reqHenchmen: 1 });
                const needsWineForgerSwap =
                  cName.includes("Wine Forger") && !doesItemFitWithoutSwap(viewer, { reqBlocks: 1 });
                const isArmedCard = Boolean(appState.armedDieAction && appState.armedDieAction.cardId === c.id);
                actionNode = el("button", {
                  className: `btn btn-sm ${isArmedCard ? "btn-crimson" : "btn-primary"}`,
                  style: { width: "100%", fontSize: "0.72rem", padding: "0.28rem 0.5rem" },
                  text:
                    cName === "Casus Belli"
                      ? "⚔️ Play Casus Belli"
                      : isTop3Card
                        ? "👁️ Inspect & Reorder Top 3"
                        : isProcurerCard
                          ? "🛒 Choose Good @ Common (>)"
                          : isProphecyCard
                            ? "🔮 Summon Schizophrenic..."
                            : isSurpriseShipmentCard
                              ? "🚢 Shift Category Scarcity..."
                              : isShortcutCard
                                ? "🛣️ Ready Shortcut for Move"
                                : isReactiveOnly
                                  ? isArmedCard
                                    ? "👆 Click Any Die to Apply"
                                    : "🎲 Click a Die to Apply"
                                  : needsThugSwap
                                    ? "▶ Play Card (Fire Henchman)"
                                    : needsWineForgerSwap
                                      ? "▶ Play Card (Swap Good)"
                                      : "▶ Play Card",
                  onClick: (e) => {
                    e.stopPropagation();
                    if (isTop3Card) {
                      openInformantsTargetModal(gs, viewer, c);
                    } else if (isProcurerCard) {
                      openProcurerGoodModal(gs, viewer, c);
                    } else if (isProphecyCard) {
                      openProphecyTargetModal(gs, viewer, c);
                    } else if (isSurpriseShipmentCard) {
                      openSurpriseShipmentModal(gs, viewer, c);
                    } else {
                      triggerInfluenceCardPlay(gs, viewer, c);
                    }
                  },
                });
              }

              return renderPhysicalInfluenceCardNode(c, {
                actionButton: actionNode,
              });
            })
          ),
      (viewer.scoutedInfo || []).length > 0
        ? el(
          "div",
          { style: { marginTop: "0.75rem", paddingTop: "0.6rem", borderTop: "1px solid var(--border-subtle)" } },
          el("div", { style: { fontWeight: "700", fontSize: "0.82rem", color: "#38bdf8", marginBottom: "0.35rem" }, text: "👁️ Scouted Intelligence (Click to View):" }),
          ...(viewer.scoutedInfo || []).slice(-5).map((si) =>
            el(
              "div",
              {
                style: {
                  fontSize: "0.74rem",
                  marginBottom: "0.3rem",
                  color: "#ffffff",
                  padding: "0.3rem 0.45rem",
                  borderRadius: "5px",
                  background: "rgba(14, 42, 84, 0.92)",
                  border: "1px solid #00e5ff",
                  cursor: "pointer",
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  gap: "0.4rem",
                },
                onClick: () => openScoutResultModal(si),
              },
              el("span", { text: `• ${si.label}: ${si.summary}` }),
              el("span", { style: { color: "#7dd3fc", fontWeight: "700", flexShrink: "0" }, text: "🔍 View" })
            )
          )
        )
        : null
    ),

    // Chronicle Game Log
    el(
      "div",
      { id: "chronicle-of-rome-panel", className: "panel" },
      el("h3", { className: "panel-title", text: "📖 Chronicle of San Francisco" }),
      el(
        "div",
        {
          id: "chronicle-log-box",
          className: "log-box",
          onScroll: (e) => {
            const st = e.currentTarget.scrollTop;
            appState.chronicleScrollTop = st;
            appState.chronicleUserScrolled = st > 4;
          },
        },
        ...(gs.logs || [])
          .slice()
          .reverse()
          .map((lg) =>
            el("div", { className: `log-entry cat-${lg.category || "info"}`, text: `[${lg.night} T${lg.turn}] ${lg.text}` })
          )
      )
    )
  );
}

/* =========================================================================
   MODALS FOR SOURCING, SCOUTING, CARGO LOADING, TRASHING, FORUM BUY, & GAMBLING
   ========================================================================= */

function installGlobalHotkeys() {
  if (appState._hotkeysInstalled) return;
  appState._hotkeysInstalled = true;
  window.addEventListener("keydown", (e) => {
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    const activeEl = document.activeElement;
    const tag = activeEl && activeEl.tagName ? activeEl.tagName.toUpperCase() : "";
    const inEditable =
      tag === "INPUT" ||
      tag === "TEXTAREA" ||
      tag === "SELECT" ||
      Boolean(activeEl && activeEl.isContentEditable);

    if (e.key === "Escape") {
      hideRomeHoverTooltip();
      if (appState.activeDiceOverlay && !appState.isDiceRolling) {
        e.preventDefault();
        dismissDiceOverlay();
        return;
      }
      const modalRoot = document.getElementById("modal-root");
      if (modalRoot && modalRoot.hasChildNodes()) {
        e.preventDefault();
        closeModal();
        return;
      }
      if (appState.armedDieAction) {
        e.preventDefault();
        appState.armedDieAction = null;
        renderDiceOverlay();
        renderApp();
        return;
      }
      if (appState.activeNpcEvent) {
        e.preventDefault();
        stopNpcTurnPacing();
        renderApp();
      }
      return;
    }

    if (inEditable) return;

    const k = e.key.toLowerCase();
    const hk = getCustomHotkeys();
    const modalRoot = document.getElementById("modal-root");
    const hasOpenModal = Boolean(modalRoot && modalRoot.hasChildNodes());

    // Close window hotkey when a modal is open
    if (hasOpenModal && hk.closeModal && k === hk.closeModal) {
      e.preventDefault();
      closeModal();
      return;
    }

    // Modal action hotkeys for Scout Tile, Scout Deck Card, Move To, and End Turn
    if (hasOpenModal) {
      if (hk.scoutTile && k === hk.scoutTile) {
        const scoutTileBtn = document.getElementById("modal-scout-tile-btn");
        if (scoutTileBtn && !scoutTileBtn.disabled) {
          e.preventDefault();
          scoutTileBtn.click();
          return;
        }
      } else if (hk.scoutDeck && k === hk.scoutDeck) {
        const scoutDeckBtn = document.getElementById("modal-scout-deck-btn");
        if (scoutDeckBtn && !scoutDeckBtn.disabled) {
          e.preventDefault();
          scoutDeckBtn.click();
          return;
        }
      } else if (hk.moveToTile && k === hk.moveToTile) {
        const moveToBtn = document.getElementById("modal-move-to-btn");
        if (moveToBtn && !moveToBtn.disabled) {
          e.preventDefault();
          moveToBtn.click();
          return;
        }
      } else if (hk.endTurn && k === hk.endTurn) {
        const endTurnBtn = document.getElementById("modal-end-turn-btn");
        if (endTurnBtn && !endTurnBtn.disabled) {
          e.preventDefault();
          endTurnBtn.click();
          return;
        }
      }
    }

    if (e.key === " " || e.key === "Enter") {
      if (tag === "BUTTON" || tag === "A") return;
      if (appState.activeDiceOverlay && !appState.isDiceRolling) {
        const contBtn = document.querySelector("#dice-overlay-root .dice-continue-btn");
        if (contBtn) {
          e.preventDefault();
          contBtn.click();
          return;
        }
      }
      if (appState.activeNpcEvent) {
        e.preventDefault();
        stepNextNpcPacingEvent();
        return;
      }
    }

    if (appState.activeTab === "tabletop" && appState.gameState) {
      const gs = appState.gameState;
      const viewer = gs.players[gs.viewerPlayerIndex] || gs.players[0];

      // Numpad 1-9 directional Cart steering (7=NW, 8=N, 9=NE, 4=W, 6=E, 1=SW, 2=S, 3=SE)
      const numpadDir =
        NUMPAD_CODE_TO_DIR[e.code] || (e.location === 3 ? NUMPAD_DIGIT_TO_DIR[e.key] : null);
      if (numpadDir && !hasOpenModal && !appState.activeDiceOverlay && !appState.activeNpcEvent) {
        e.preventDefault();
        if (!viewer) return;
        if (gs.pendingEncounter) {
          showToast("Resolve the active Encounter before moving your Cart.", true);
          return;
        }
        if (gs.phase === "delivery_entry" && gs.activePlayerIndex === viewer.index && !viewer.position) {
          appState.cartPanelTab = "navigate";
          renderApp();
          showToast("Choose an entry point first to roll into San Francisco, then steer with Numpad 1–9.");
          return;
        }
        if (gs.phase !== "delivery" || gs.activePlayerIndex !== viewer.index || !viewer.position) {
          return;
        }
        if ((viewer.movesRemaining || 0) <= 0) {
          showToast("No Cart movement remaining this turn.", true);
          return;
        }
        const cell = gs.romeBoard && gs.romeBoard[viewer.position];
        const outInfo = cell && cell.revealed && cell.revealed.outgoingDirections
          ? cell.revealed.outgoingDirections[numpadDir]
          : null;
        if (!outInfo) {
          const adj = getNeighborCoordInDir(viewer.position, numpadDir);
          const riverMsg = adj && isTiberCrossingBlocked(viewer.position, adj)
            ? "Tiber River (no bridge here)"
            : "No road in that direction";
          showToast(`Cannot move ${numpadDir}: ${riverMsg}.`, true);
          return;
        }
        const riverBlocked =
          Boolean(outInfo.blockedByRiver) ||
          (outInfo.targetCell ? isTiberCrossingBlocked(viewer.position, outInfo.targetCell) : false);
        const passable =
          !riverBlocked && (outInfo.passable || Boolean(viewer.turnEffects && viewer.turnEffects.shortcut));
        if (!passable) {
          showToast(
            riverBlocked
              ? `Cannot move ${numpadDir}: Tiber River blocks crossing.`
              : `Cannot move ${numpadDir}: Street is barricaded.`,
            true
          );
          return;
        }
        sendGameAction({ type: "delivery_move", direction: numpadDir });
        return;
      }

      if (!hasOpenModal && !appState.activeDiceOverlay && viewer) {
        const isMyTurn =
          gs.activePlayerIndex === viewer.index &&
          (gs.phase === "delivery" || gs.phase === "delivery_entry") &&
          !gs.pendingEncounter;
        if (hk.scoutTile && k === hk.scoutTile && isMyTurn) {
          e.preventDefault();
          if (viewer.scoutedThisTurn) {
            showToast("You have already used your Scout action this turn.", true);
            return;
          }
          const targetCoord = appState.inspectedCell || viewer.position || "B1";
          const targetCell = gs.romeBoard && gs.romeBoard[targetCoord];
          if (targetCell) {
            openConfirmScoutNeighborhoodModal(gs, viewer, targetCoord, targetCell);
          } else {
            openScoutModal(gs, viewer);
          }
          return;
        }
        if (hk.scoutDeck && k === hk.scoutDeck && isMyTurn) {
          e.preventDefault();
          if (viewer.scoutedThisTurn) {
            showToast("You have already used your Scout action this turn.", true);
            return;
          }
          openScoutModal(gs, viewer);
          return;
        }
        if (hk.moveToTile && k === hk.moveToTile && isMyTurn) {
          e.preventDefault();
          const targetCoord = appState.inspectedCell || viewer.position || "B1";
          const targetCell = gs.romeBoard && gs.romeBoard[targetCoord];
          if (targetCell) {
            const currCellObj = viewer.position && gs.romeBoard ? gs.romeBoard[viewer.position] : null;
            const currOutDirs = (currCellObj && currCellObj.revealed && currCellObj.revealed.outgoingDirections) || {};
            let moveDir = null;
            let adjInfo = null;
            for (const [dir, dInfo] of Object.entries(currOutDirs)) {
              if (dInfo && dInfo.targetCell === targetCoord) {
                adjInfo = { dir, ...dInfo };
                const riverBlocked = Boolean(dInfo.blockedByRiver) || isTiberCrossingBlocked(viewer.position, targetCoord);
                if (!riverBlocked && (dInfo.passable || (viewer.turnEffects && viewer.turnEffects.shortcut))) {
                  moveDir = dir;
                }
              }
            }
            openConfirmScoutNeighborhoodModal(gs, viewer, targetCoord, targetCell, { moveDir, adjInfo });
          }
          return;
        }
        if (hk.endTurn && k === hk.endTurn && gs.phase === "delivery" && gs.activePlayerIndex === viewer.index && !gs.pendingEncounter) {
          e.preventDefault();
          sendGameAction({ type: "delivery_end_turn" });
          return;
        }
      }

      if ((e.code === "Numpad5" || (e.location === 3 && e.key === "5") || (hk.toggleCartNav && k === hk.toggleCartNav)) && !hasOpenModal) {
        e.preventDefault();
        appState.cartPanelTab = appState.cartPanelTab === "navigate" ? "cart" : "navigate";
        renderApp();
      } else if (hk.viewMarketBoard && k === hk.viewMarketBoard && !hasOpenModal) {
        e.preventDefault();
        appState.boardViewMode = appState.boardViewMode === "market" ? "auto" : "market";
        renderApp();
      } else if (hk.viewRomeBoard && k === hk.viewRomeBoard && !hasOpenModal) {
        e.preventDefault();
        appState.boardViewMode = appState.boardViewMode === "rome" ? "auto" : "rome";
        renderApp();
      } else if (hk.viewClimateBoard && k === hk.viewClimateBoard && !hasOpenModal) {
        e.preventDefault();
        appState.boardViewMode = appState.boardViewMode === "climate" ? "auto" : "climate";
        renderApp();
      } else if (hk.viewAllBoards && k === hk.viewAllBoards && !hasOpenModal) {
        e.preventDefault();
        appState.boardViewMode = appState.boardViewMode === "both" ? "auto" : "both";
        renderApp();
      }
    }
  });
}

window.addEventListener("DOMContentLoaded", () => {
  installGlobalHotkeys();
  bootstrap();
});

export { navigateToMarketBoardForCategory, FACTION_GEM_MAP, renderFactionGemNodes, getSellCategoryClass, buildEncounterFigureNodes, renderDynamicEdgeSlotNode, renderDynamicTileCardNode, renderBuriedInfluenceStackCardBackNode, renderPhysicalMissionCardNode, renderPhysicalInfluenceCardNode, renderPhysicalEncounterCardNode, apiRequest, applyUserDefaultBoardView, syncGameUiTransitions, installChronicleViewportScrollWatcher, bootstrap, startPolling, refreshPortalOverview, seedSeenScoutIds, enqueueNewMissionEvents, persistSkipMissionCompletionPopups, openMissionCompletionModal, checkPostActionModals, openGame, sendGameAction, renderApp, createTopbarSvgIcon, createTopbarLobbyWirelessIcon, createTopbarRulebookMagnifierIcon, createTopbarProfileCogIcon, createTopbarSignOutIcon, createTopbarReturnGameIcon, renderTopbar, renderPendingUndoBanner, renderTabletopView, renderClockAndTurnBanner, renderContextualPromptBanner, renderActiveClimateStrip, buildPoliticalClimateExplainerNode, buildPoliticalClimateBoardGridNode, renderPoliticalClimateBoard, renderSetupDiscardPanel, formatSignedFlat, armDieCardAction, handleDieSelectionClick, renderInlineClickableDiceRow, buildConsumableWeaponPickerNodes, openConsumableWeaponsPromptModal, initiateCombatWithConsumablePrompt, buildCombatInfluenceCardActionNode, renderOpponentPublicSUVSummaryNode, renderPendingEncounterPanel, renderPendingEncounterPanelCore, renderPendingNpcOfferPanel, renderPendingMarketRewardPanel, renderPendingSUVOverflowPanel, renderCleanupPhasePanel, openSUVGoodDetailModal, openSUVHenchmanDetailModal, renderLoadedGoodPhysicalCardNode, renderHiredHenchmanPhysicalCardNode, renderPhysicalSUVMatNode, openFactionFavorModal, openPlayerSUVModal, renderDomnaMediatorExchangeBar, getActiveForumBuySpec, computeForumBuyPriceForCard, renderMarketHeaderDenariiCounts, renderOstiaMarketBoard, TIBER_UNBRIDGED_CELL_CLASSES, TIBER_BRIDGE_BADGES_BY_CELL, positionRomeHoverTooltip, showRomeHoverTooltip, showRomeSimpleHoverTooltip, showRomeUnrevealedCellHoverTooltip, getCellOffBoardDirs, renderRomeNightBoard, renderSUVNavigationWidget, renderPlayerSidebar, installGlobalHotkeys };
