import { EDGE_LABELS, parseTollAmount, formatEdgeLabel, getTiberBridgeName, renderSUVIconNode, appState, replaceDenariiTokens, createMoveActionCircleNode, createTransactionActionCircleNode, resolveGoodTrackClass, el, formatTileModifier, renderFullGoodCardFaceNode, getInfluenceCardEffectText, formatHostileFavorPenaltyText, showToast, closeModal, showModal } from "./core_ui.js?v=111";
import { renderDynamicTileCardNode, renderPhysicalMissionCardNode, renderPhysicalInfluenceCardNode, renderPhysicalEncounterCardNode, sendGameAction, armDieCardAction } from "./app.js?v=111";

/**
 * Displays the up-close view of a face-up tile (or the tile currently occupied by the player's SUV),
 * with an Interact button (which opens the Scout/Move/End Turn interface) and a Close button.
 */
function openFaceUpTileUpCloseModal(gs, viewer, coord, cell, tileData, moveOpts = null) {
  const cellName = cell ? cell.name : coord;
  const isCurrent = Boolean(viewer && viewer.position === coord && !viewer.exitedRome);
  const occupants = ((gs && gs.players) || []).filter((p) => p.position === coord && !p.exitedRome);
  const rev = tileData || (cell && cell.revealed) || null;

  const sellsStr =
    rev && Array.isArray(rev.sells) && rev.sells.length > 0
      ? rev.sells.map((s) => `${s.category} (${formatTileModifier(s.modifier)})`).join(", ")
      : "None";
  const buysStr =
    rev && Array.isArray(rev.buys) && rev.buys.length > 0
      ? rev.buys.map((b) => `${b.category} (${formatTileModifier(b.modifier)})`).join(", ")
      : null;
  const centerParts = rev
    ? [
      rev.encounter ? formatEdgeLabel(rev.encounter) : "No Center Encounter",
      rev.gamble ? "Stadium Gambling (≤20(d))" : null,
      rev.persistent ? "Persistent (⤹)" : rev.refresh ? "Refresh (↻)" : "Standard Tile",
    ].filter(Boolean)
    : [];

  showModal(
    `🔍 Tile ${coord} — ${cellName}`,
    el(
      "div",
      { style: { display: "flex", flexDirection: "column", alignItems: "center", gap: "0.85rem" } },
      occupants.length > 0
        ? el(
          "div",
          {
            style: {
              display: "flex",
              gap: "0.45rem",
              flexWrap: "wrap",
              justifyContent: "center",
              alignItems: "center",
            },
          },
          ...occupants.map((p) =>
            el(
              "span",
              {
                className: "badge",
                style:
                  viewer && p.index === viewer.index
                    ? { borderColor: "var(--gold-bright)", background: "rgba(14, 42, 84, 0.92)", color: "#7dd3fc", fontWeight: "800" }
                    : {},
              },
              renderSUVIconNode(p.color, "suv-icon-xs", `${p.name}'s SUV`),
              el("span", {
                style: { marginLeft: "0.3rem" },
                text: viewer && p.index === viewer.index ? `${p.name} (Your SUV)` : p.name,
              })
            )
          )
        )
        : null,
      rev
        ? el(
          "div",
          { style: { width: "280px", maxWidth: "100%", margin: "0 auto" } },
          renderDynamicTileCardNode(rev, coord, "inspector")
        )
        : el("p", {
          style: { fontSize: "0.88rem", color: "var(--text-muted)", margin: "0.25rem 0" },
          text: `No face-up tile is currently exposed on ${coord} (${cellName}).`,
        }),
      rev
        ? el(
          "div",
          {
            style: {
              width: "100%",
              padding: "0.65rem 0.85rem",
              borderRadius: "6px",
              background: "rgba(34, 13, 62, 0.94)",
              border: "1.5px solid #a88d6b",
              boxShadow: "var(--bevel-sunken)",
              fontSize: "0.84rem",
              display: "flex",
              flexDirection: "column",
              gap: "0.25rem",
            },
          },
          el(
            "div",
            {},
            el("strong", { style: { color: "var(--gold-bright)" }, text: "Neighborhood: " }),
            `${coord} — ${cellName}${isCurrent ? " (Your Current Tile)" : ""}`
          ),
          el("div", {}, el("strong", { style: { color: "var(--gold-bright)" }, text: "Buys: " }), sellsStr),
          buysStr ? el("div", {}, el("strong", { style: { color: "#0369a1" }, text: "Forum Sells: " }), buysStr) : null,
          centerParts.length > 0
            ? el(
              "div",
              {},
              el("strong", { style: { color: "var(--gold-bright)" }, text: "Properties: " }),
              centerParts.join(" • ")
            )
            : null
        )
        : null,
      el(
        "div",
        {
          style: {
            width: "100%",
            display: "flex",
            justifyContent: "flex-end",
            gap: "0.6rem",
            paddingTop: "0.65rem",
            borderTop: "1px solid var(--border-subtle)",
          },
        },
        el("button", {
          id: "modal-tile-interact-btn",
          type: "button",
          className: "btn btn-primary",
          text: "🧭 Interact",
          onClick: () => {
            openConfirmScoutNeighborhoodModal(gs, viewer, coord, cell, moveOpts);
          },
        }),
        el("button", {
          type: "button",
          className: "btn",
          text: "Close",
          onClick: closeModal,
        })
      )
    )
  );
}

function openConfirmScoutNeighborhoodModal(gs, viewer, coord, cell, moveOpts = null) {
  const cellName = cell ? cell.name : coord;
  const unrevealedCount = cell
    ? Number(
      cell.stackCount !== undefined
        ? cell.stackCount
        : cell.unrevealedCount !== undefined
          ? cell.unrevealedCount
          : 12
    )
    : 0;
  const isEntryPhase = gs.phase === "delivery_entry";
  const isDeliveryPhase = gs.phase === "delivery";
  const isMyTurn = Boolean(
    gs &&
    viewer &&
    gs.activePlayerIndex === viewer.index &&
    (isEntryPhase || isDeliveryPhase) &&
    !viewer.exitedRome &&
    !viewer.nightEnded
  );
  const isGateCell = Boolean(cell && cell.isGate);
  const isGateEntrance = Boolean(isEntryPhase && isGateCell && isMyTurn);
  const canScoutTile = Boolean(isMyTurn && !viewer.scoutedThisTurn && unrevealedCount > 0);
  const canScoutDeck = Boolean(isMyTurn && !viewer.scoutedThisTurn);
  const moveDir = moveOpts && moveOpts.moveDir ? String(moveOpts.moveDir) : null;
  const adjInfo = (moveOpts && moveOpts.adjInfo) || null;
  const canMoveStep = Boolean(
    !isEntryPhase &&
    isDeliveryPhase &&
    isMyTurn &&
    moveDir &&
    Number(viewer.movesRemaining || 0) > 0
  );
  const canMoveHere = Boolean(canMoveStep || isGateEntrance);
  const canEndTurnHere = Boolean(!isEntryPhase && isDeliveryPhase && isMyTurn);

  const unusedMoves = isMyTurn
    ? isEntryPhase
      ? 1
      : Math.max(0, Number(viewer.movesRemaining || 0))
    : 0;
  const unusedTransactions =
    isMyTurn && isDeliveryPhase && !viewer.transactedThisTurn ? 1 : 0;

  let crossingNote = "";
  if (canMoveStep && adjInfo) {
    const shortcutActive = Boolean(viewer.turnEffects && viewer.turnEffects.shortcut);
    const bridgeName = adjInfo.bridgeName || adjInfo.bridge || getTiberBridgeName(viewer.position, coord);
    const tollAmt = !shortcutActive ? parseTollAmount(adjInfo.edge) : 0;
    const isHazard =
      !shortcutActive &&
      tollAmt <= 0 &&
      Boolean(adjInfo.edge && !["green", "red", "None"].includes(String(adjInfo.edge)));
    if (shortcutActive && !adjInfo.passable) {
      crossingNote = `Crossing ${moveDir} via ✨ Shortcut.`;
    } else if (tollAmt > 0) {
      crossingNote = `Crossing ${moveDir}${bridgeName ? ` (${bridgeName})` : ""} — Road Toll: ${tollAmt}(d).`;
    } else if (isHazard) {
      crossingNote = `Crossing ${moveDir}${bridgeName ? ` (${bridgeName})` : ""} — Edge Encounter: ${formatEdgeLabel(adjInfo.edge)}.`;
    } else if (bridgeName) {
      crossingNote = `Crossing ${moveDir} across ${bridgeName} (Open Street).`;
    } else {
      crossingNote = `Crossing ${moveDir} via Open Street.`;
    }
  }

  let modalTitle = `🧭 Neighborhood ${coord} — ${cellName}`;
  let promptDescription = "";
  if (!isMyTurn) {
    promptDescription = `Inspecting ${coord} (${cellName}) (${unrevealedCount} face-down tile(s) in stack). Actions are greyed out because it is not currently your Night Delivery turn.`;
  } else if (isEntryPhase) {
    modalTitle = isGateEntrance
      ? `🚪 Entrance & Neighborhood ${coord} — ${cellName}`
      : `👁️ Neighborhood ${coord} — ${cellName}`;
    if (isGateEntrance && canScoutTile) {
      promptDescription = `${coord} (${cellName}) is an available Via Entrance into Rome (${unrevealedCount} face-down tiles in stack). You may Scout 1 tile or deck card first, or Move onto ${coord} as your entrance for the night.`;
    } else if (isGateEntrance) {
      promptDescription = `${coord} (${cellName}) is an available Via Entrance into Rome (you have already used your Initial Scout this night). Move onto ${coord} to start Night Delivery.`;
    } else if (canScoutTile) {
      promptDescription = `You may use your pre-night Initial Scout to peek at the top face-down tile of ${coord} (${cellName}) (${unrevealedCount} face-down tiles in stack) or a deck card. To enter San Francisco, select one of the five gold-outlined entry points (B1, F1, F5, D6, or A5).`;
    } else {
      promptDescription = `You have already used your Initial Scout before this night, and ${coord} (${cellName}) is not an entry point. Click one of the five gold-outlined entry points (B1, F1, F5, D6, or A5) to start the night.`;
    }
  } else if (canMoveStep && canScoutTile) {
    modalTitle = `🧭 Adjacent Neighborhood ${coord} — ${cellName} (${moveDir})`;
    promptDescription = `${coord} (${cellName}) is adjacent (${moveDir}) and has ${unrevealedCount} face-down tile(s) in its stack. Move your SUV into ${coord} now, or Scout at the end of your turn (committing to Scout ends your turn so the next merchant can begin).`;
  } else if (canMoveStep) {
    modalTitle = `🧭 Adjacent Neighborhood ${coord} — ${cellName} (${moveDir})`;
    promptDescription = `${coord} (${cellName}) is adjacent (${moveDir}). Move your SUV into ${coord}, or End Turn.`;
  } else if (canScoutTile) {
    promptDescription = `Scout the top face-down tile of ${coord} (${cellName}) (${unrevealedCount} face-down tile(s) in stack) or a deck card at the end of your turn? Committing to Scout immediately advances the turn to the next merchant while you examine the scouted card or tile.`;
  } else if (viewer.scoutedThisTurn) {
    promptDescription = `You have already used your Scout action this turn.`;
  } else {
    promptDescription = `There are no unrevealed tiles remaining in ${coord} (${cellName}), and this neighborhood is not currently reachable in 1 move.`;
  }

  const unusedIndicatorItems = [];
  if (unusedMoves > 0) {
    unusedIndicatorItems.push(
      el(
        "span",
        {
          style: { display: "inline-flex", alignItems: "center", gap: "0.28rem", fontWeight: "800", fontSize: "0.78rem", color: "#54150f" },
          title: `${unusedMoves} unused Move action${unusedMoves > 1 ? "s" : ""} remaining this turn`,
        },
        createMoveActionCircleNode(),
        el("span", { text: `×${unusedMoves}` })
      )
    );
  }
  if (unusedTransactions > 0) {
    unusedIndicatorItems.push(
      el(
        "span",
        {
          style: { display: "inline-flex", alignItems: "center", gap: "0.28rem", fontWeight: "800", fontSize: "0.78rem", color: "#54150f" },
          title: `${unusedTransactions} unused Transaction action remaining this turn`,
        },
        createTransactionActionCircleNode(),
        el("span", { text: `×${unusedTransactions}` })
      )
    );
  }

  const moveBtnLabel = isEntryPhase
    ? `🚪 Move to Gate ${coord}`
    : moveDir
      ? `🛒 Move to ${coord} (${moveDir})`
      : `🛒 Move to ${coord}`;

  showModal(
    modalTitle,
    el(
      "div",
      {},
      el("p", {
        style: { fontSize: "0.9rem", color: "var(--text-main)", marginTop: "0" },
        text: promptDescription,
      }),
      crossingNote
        ? el("p", {
          style: {
            fontSize: "0.82rem",
            fontWeight: "700",
            color: "#ff6ec7",
            background: "#f8f1e1",
            border: "1px solid #c7af88",
            borderRadius: "5px",
            padding: "0.4rem 0.65rem",
            marginTop: "0.45rem",
          },
          text: replaceDenariiTokens(crossingNote),
        })
        : null,
      el(
        "div",
        {
          style: {
            display: "flex",
            gap: "0.85rem",
            flexWrap: "wrap",
            justifyContent: "space-between",
            alignItems: "flex-end",
            marginTop: "1rem",
            paddingTop: "0.75rem",
            borderTop: "1px solid var(--border-subtle)",
          },
        },
        el(
          "div",
          {
            style: {
              display: "flex",
              gap: "0.55rem",
              flexWrap: "wrap",
              alignItems: "center",
              flex: "1 1 auto",
            },
          },
          el("button", {
            id: "modal-move-to-btn",
            type: "button",
            className: canMoveHere ? "btn btn-primary" : "btn",
            disabled: !canMoveHere,
            title: canMoveHere
              ? `Move your SUV to ${coord}`
              : "Move to this tile is currently unavailable",
            text: moveBtnLabel,
            onClick: () => {
              if (!canMoveHere) return;
              closeModal();
              if (isGateEntrance) {
                sendGameAction({ type: "select_gate", gate: coord });
              } else {
                sendGameAction({ type: "delivery_move", direction: moveDir });
              }
            },
          }),
          el("button", {
            id: "modal-scout-tile-btn",
            type: "button",
            className: canScoutTile && !canMoveHere ? "btn btn-primary" : "btn",
            disabled: !canScoutTile,
            title: canScoutTile
              ? isEntryPhase
                ? `Scout the top face-down tile of ${coord} before entering Rome`
                : `Scout the top face-down tile of ${coord} and end your turn`
              : "Scout Tile is unavailable (already scouted, no face-down tiles, or not your turn)",
            text: `👁️ Scout Tile ${coord}`,
            onClick: () => {
              if (!canScoutTile) return;
              closeModal();
              if (isEntryPhase) {
                sendGameAction({ type: "initial_scout", targetType: "tile", cell: coord });
              } else {
                sendGameAction({ type: "delivery_scout", targetType: "tile", targetKey: coord });
              }
            },
          }),
          el("button", {
            id: "modal-scout-deck-btn",
            type: "button",
            className: "btn",
            disabled: !canScoutDeck,
            title: canScoutDeck
              ? "Scout the top card of an Encounter deck"
              : "Scout Deck Card is unavailable (already scouted or not your turn)",
            text: "🃏 Scout Deck Card",
            onClick: () => {
              if (!canScoutDeck) return;
              closeModal();
              openScoutModal(gs, viewer);
            },
          })
        ),
        el(
          "div",
          {
            style: {
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: "0.32rem",
              marginLeft: "auto",
            },
          },
          unusedIndicatorItems.length > 0
            ? el(
              "div",
              {
                className: "unused-turn-actions-indicator",
                style: {
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "0.45rem",
                  padding: "0.2rem 0.5rem",
                  borderRadius: "999px",
                  background: "rgba(34, 13, 62, 0.94)",
                  border: "1px solid #b59257",
                  boxShadow: "inset 0 1px 0 rgba(255,255,255,0.65)",
                },
                title: "Unused Move (SUV in circle) and/or Transaction (Denarius in circle) actions remaining this turn",
              },
              el("span", {
                style: { fontSize: "0.68rem", fontWeight: "800", textTransform: "uppercase", letterSpacing: "0.04em", color: "#ff6ec7" },
                text: "Unused:",
              }),
              ...unusedIndicatorItems
            )
            : null,
          el("button", {
            id: "modal-end-turn-btn",
            type: "button",
            className: "btn btn-crimson",
            disabled: !canEndTurnHere,
            title: canEndTurnHere
              ? "End your hourly turn"
              : "End Turn is unavailable when it is not your turn (or before selecting a starting Via Gate)",
            text: "⏭️ End Turn",
            onClick: () => {
              if (!canEndTurnHere) return;
              closeModal();
              sendGameAction({ type: "delivery_end_turn" });
            },
          })
        )
      )
    )
  );
}

function openNpcOfferModal(gs, viewer) {
  const offer = viewer && viewer.pendingNpcOffer;
  if (!offer) return;
  const isBuy = (offer.mode || offer.offerType) === "buy_from_npc";
  const npcName = offer.npcName || (offer.npcCard && offer.npcCard.name) || "Patron";
  const candidates = Array.isArray(offer.candidates) ? offer.candidates : [];
  const usedBlocks = Number(viewer.usedBlocks) || 0;
  const maxBlocks = Number(viewer.maxBlocks) || 6;

  const candidateCards = candidates.map((cand) => {
    const c = cand.card || {};
    const trackName = c.track || offer.category || "Animals";
    const trackClass = resolveGoodTrackClass(trackName);
    const reqBlocks = Math.max(1, Number(c.blocks) || 1);
    const blocksSymbols = "■".repeat(reqBlocks);
    const price = Number(cand.price) || 0;
    const canAfford = !isBuy || viewer.cash >= price;
    const fitsInSUV = !isBuy || usedBlocks + reqBlocks <= maxBlocks;
    const canSwap = fitsInSUV || (Array.isArray(viewer.suv) && viewer.suv.length > 0);
    const canSelect = canAfford && canSwap;

    let sourceBadgeText = cand.sourceLabel || "Ostia Market";
    if (cand.source === "market") {
      sourceBadgeText = `⚓ Ostia Market (Col ${(cand.colIndex || 0) + 1})`;
    } else if (cand.source === "deck") {
      sourceBadgeText = "📦 Goods Deck";
    } else if (cand.source === "suv") {
      sourceBadgeText = "🛒 Your SUV";
    }

    let btnText = isBuy ? `💰 Buy for ${price}(d)` : `💰 Sell for ${price}(d)`;
    if (isBuy && !canAfford) {
      btnText = `Requires ${price}(d)`;
    } else if (isBuy && !fitsInSUV) {
      btnText = `💰 Buy for ${price}(d) (Swap)`;
    }

    return el(
      "div",
      {
        className: "good-card-unit",
        style: { width: "196px" },
      },
      el(
        "div",
        {
          style: {
            fontSize: "0.66rem",
            fontWeight: "800",
            color: "var(--gold-bright)",
            textAlign: "center",
          },
          text: sourceBadgeText,
        }
      ),
      el(
        "div",
        {
          className: `market-good-card ${trackClass}`,
        },
        renderFullGoodCardFaceNode(c, trackName)
      ),
      el(
        "div",
        { className: "good-card-external-meta" },
        el("button", {
          type: "button",
          className: `btn btn-sm ${canSelect ? "btn-primary" : ""}`,
          style: { width: "100%" },
          disabled: !canSelect,
          text: btnText,
          onClick: () => {
            if (!isBuy || fitsInSUV) {
              closeModal();
              sendGameAction({
                type: "resolve_npc_offer",
                decision: "accept",
                candidateId: cand.id || cand.uid,
                cardId: cand.cardId || c.id,
              });
            } else {
              openSUVReplacementModal(viewer, {
                itemType: "good",
                incomingCard: c,
                reqBlocks,
                reqHenchmen: 0,
                bonusBlocks: 0,
                bonusHenchmen: 0,
                title: `🤝 SUV Space Full — Discard Goods to Buy ${c.name || offer.category}`,
                subtitle: `Buying "${c.name || offer.category}" (${reqBlocks}■) from ${npcName} costs ${price}(d). Select Goods on your SUV to discard so it fits, or return to ${npcName}'s offer.`,
                confirmLabelPrefix: `Buy ${c.name || offer.category} for ${price}(d)`,
                cancelLabel: "← Back to Offer",
                onConfirm: (discardSUVIds, fireHenchmanIds) => {
                  sendGameAction({
                    type: "resolve_npc_offer",
                    decision: "accept",
                    candidateId: cand.id || cand.uid,
                    cardId: cand.cardId || c.id,
                    discardSUVIds,
                    fireHenchmanIds,
                  });
                },
                onCancel: () => openNpcOfferModal(gs, viewer),
              });
            }
          },
        })
      )
    );
  });

  showModal(
    `🤝 ${npcName}'s Offer — ${isBuy ? `Buy 1 ${offer.category}` : `Sell 1 ${offer.category}`}`,
    el(
      "div",
      {},
      el(
        "div",
        {
          style: {
            padding: "0.6rem 0.85rem",
            background: "rgba(212, 175, 55, 0.14)",
            border: "1px solid var(--gold)",
            borderRadius: "6px",
            marginBottom: "0.85rem",
            fontSize: "0.86rem",
          },
        },
        el("div", {
          style: { fontWeight: "700", color: "var(--gold-bright)", marginBottom: "0.25rem" },
          text: `${npcName}: "${offer.actionText || ""}"`,
        }),
        el("div", {
          style: { fontSize: "0.8rem", color: "var(--text-main)" },
          text: `Your Holdings: 𐆖${viewer.cash} Denarii  •  SUV Space: ${usedBlocks}/${maxBlocks}■ used`,
        })
      ),
      candidateCards.length === 0
        ? el("p", {
          style: { color: "var(--text-muted)" },
          text: `No matching ${offer.category} cards are currently available.`,
        })
        : el(
          "div",
          {
            style: {
              display: "flex",
              flexWrap: "wrap",
              gap: "0.75rem",
              maxHeight: "56vh",
              overflowY: "auto",
              padding: "0.25rem",
              justifyContent: "center",
            },
          },
          ...candidateCards
        ),
      el(
        "div",
        {
          style: {
            display: "flex",
            justifyContent: "flex-end",
            gap: "0.6rem",
            marginTop: "1rem",
            paddingTop: "0.65rem",
            borderTop: "1px solid var(--border-subtle)",
          },
        },
        el("button", {
          type: "button",
          className: "btn",
          text: "Inspect Board First",
          onClick: closeModal,
        }),
        el("button", {
          type: "button",
          className: "btn btn-crimson",
          text: "Decline Offer",
          onClick: () => {
            closeModal();
            sendGameAction({ type: "resolve_npc_offer", decision: "decline" });
          },
        })
      )
    )
  );
}

function openMarketRewardModal(gs, viewer) {
  const queue = (viewer && Array.isArray(viewer.pendingMarketReward) && viewer.pendingMarketReward) || [];
  const rwd = queue[0];
  if (!rwd) return;
  const catLabel = rwd.categoryLabel || rwd.subcategory || rwd.track || "Good";
  const candidates = Array.isArray(rwd.candidates) ? rwd.candidates : [];
  const usedBlocks = Number(viewer.usedBlocks) || 0;
  const maxBlocks = Number(viewer.maxBlocks) || 6;
  const usedHenchmen = Number(viewer.usedHenchmen) || 0;
  const maxHenchmen = Number(viewer.maxHenchmen) || 2;

  const candidateCards = candidates.map((cand) => {
    const c = cand.card || {};
    const trackName = c.track || rwd.track || "Animals";
    const isHenchman = trackName === "Henchmen" || Number(c.henchmen) > 0;
    const trackClass = resolveGoodTrackClass(trackName);
    const reqBlocks = isHenchman ? 0 : Math.max(1, Number(c.blocks) || 1);
    const reqHenchmen = isHenchman ? Math.max(1, Number(c.henchmen) || 1) : 0;
    const bonusHenchmen = Number(c.bonusHenchmen) || 0;
    const bonusBlocks = Number(c.bonusBlocks) || 0;
    const blocksSymbols = isHenchman ? "▲".repeat(reqHenchmen) : "■".repeat(reqBlocks);
    const fitsInSUV = isHenchman
      ? usedHenchmen + reqHenchmen <= maxHenchmen + bonusHenchmen
      : usedBlocks + reqBlocks <= maxBlocks + bonusBlocks;
    const canSwap =
      fitsInSUV ||
      (isHenchman
        ? Array.isArray(viewer.henchmen) && viewer.henchmen.length > 0
        : Array.isArray(viewer.suv) && viewer.suv.length > 0);
    const colNum = (Number(cand.colIndex) || 0) + 1;
    const colSym = cand.colSymbol || "=";
    const btnText = fitsInSUV
      ? `🎁 Claim ${c.name || catLabel}`
      : canSwap
        ? `🎁 Claim ${c.name || catLabel} (Swap)`
        : `SUV Full (${reqBlocks}■)`;

    return el(
      "div",
      {
        className: "good-card-unit",
        style: { width: "196px" },
      },
      el(
        "div",
        {
          style: {
            fontSize: "0.66rem",
            fontWeight: "800",
            color: "var(--gold-bright)",
            textAlign: "center",
          },
          text: `⚓ Ostia Market (Col ${colNum} • ${colSym})`,
        }
      ),
      el(
        "div",
        {
          className: `market-good-card ${trackClass}`,
        },
        renderFullGoodCardFaceNode(c, trackName)
      ),
      el(
        "div",
        { className: "good-card-external-meta" },
        el("button", {
          type: "button",
          className: `btn btn-sm ${canSwap ? "btn-primary" : ""}`,
          style: { width: "100%" },
          disabled: !canSwap,
          text: btnText,
          onClick: () => {
            if (fitsInSUV) {
              closeModal();
              sendGameAction({
                type: "resolve_market_reward",
                rewardId: rwd.id,
                decision: "accept",
                cardId: cand.cardId || c.id,
              });
            } else {
              openSUVReplacementModal(viewer, {
                itemType: isHenchman ? "henchman" : "good",
                incomingCard: c,
                reqBlocks,
                reqHenchmen,
                bonusBlocks,
                bonusHenchmen,
                title: `🎁 SUV Space Full — Make Room for ${c.name || catLabel}`,
                subtitle: `Claiming "${c.name || catLabel}" (${isHenchman ? `${reqHenchmen}▲` : `${reqBlocks}■`
                  }) from the Ostia Market Board is free, but your SUV is full. Select item(s) to discard so it fits, or go back to choose another card.`,
                confirmLabelPrefix: `Claim ${c.name || catLabel}`,
                cancelLabel: "← Back to Market Choices",
                onConfirm: (discardSUVIds, fireHenchmanIds) => {
                  sendGameAction({
                    type: "resolve_market_reward",
                    rewardId: rwd.id,
                    decision: "accept",
                    cardId: cand.cardId || c.id,
                    discardSUVIds,
                    fireHenchmanIds,
                  });
                },
                onCancel: () => openMarketRewardModal(gs, viewer),
              });
            }
          },
        })
      )
    );
  });

  showModal(
    `🎁 Choose Market Board Reward — 1 ${catLabel}`,
    el(
      "div",
      {},
      el(
        "div",
        {
          style: {
            padding: "0.6rem 0.85rem",
            background: "rgba(212, 175, 55, 0.14)",
            border: "1px solid var(--gold)",
            borderRadius: "6px",
            marginBottom: "0.85rem",
            fontSize: "0.86rem",
          },
        },
        el("div", {
          style: { fontWeight: "700", color: "var(--gold-bright)", marginBottom: "0.25rem" },
          text: `${rwd.sourceLabel || "Reward"}: Choose any 1 ${catLabel} currently on the Ostia Market Board (${rwd.rewardLabel || catLabel}).`,
        }),
        el("div", {
          style: { fontSize: "0.8rem", color: "var(--text-main)" },
          text: `SUV Space: ${usedBlocks}/${maxBlocks}■ Goods  •  Henchmen: ${usedHenchmen}/${maxHenchmen}▲${queue.length > 1 ? `  •  (${queue.length} Market rewards queued)` : ""
            }`,
        })
      ),
      candidateCards.length === 0
        ? el("p", {
          style: { color: "var(--text-muted)" },
          text: `No matching ${catLabel} cards are currently on the Ostia Market Board.`,
        })
        : el(
          "div",
          {
            style: {
              display: "flex",
              flexWrap: "wrap",
              gap: "0.75rem",
              maxHeight: "56vh",
              overflowY: "auto",
              padding: "0.25rem",
              justifyContent: "center",
            },
          },
          ...candidateCards
        ),
      el(
        "div",
        {
          style: {
            display: "flex",
            justifyContent: "flex-end",
            gap: "0.6rem",
            marginTop: "1rem",
            paddingTop: "0.65rem",
            borderTop: "1px solid var(--border-subtle)",
          },
        },
        el("button", {
          type: "button",
          className: "btn",
          text: "Inspect Board First",
          onClick: closeModal,
        }),
        el("button", {
          type: "button",
          className: "btn btn-crimson",
          text: "Decline Reward",
          onClick: () => {
            closeModal();
            sendGameAction({
              type: "resolve_market_reward",
              rewardId: rwd.id,
              decision: "decline",
            });
          },
        })
      )
    )
  );
}

function renderScoutedMarketCardPreview(card) {
  const trackName = card.track || "Foods";
  const trackClass = resolveGoodTrackClass(trackName);
  const blocksSymbols =
    trackName === "Henchmen"
      ? "▲".repeat(Math.max(1, Number(card.henchmen) || 1))
      : "■".repeat(Math.max(1, Number(card.blocks) || 1));

  return el(
    "div",
    { className: "suv-good-detail-showcase" },
    el(
      "div",
      {
        className: `market-good-card ${trackClass} suv-good-detail-card`,
      },
      renderFullGoodCardFaceNode(card, trackName)
    )
  );
}

function openScoutResultModal(si) {
  if (!si) return;
  const rData = si.revealedData;
  let visualNode = null;

  if (si.targetType === "tile" && rData) {
    const coord = si.targetKey || "B1";
    const sellsText =
      (rData.sells || []).length > 0
        ? rData.sells.map((s) => `${s.category} (${formatTileModifier(s.modifier)})`).join(", ")
        : "None";
    const buysText =
      (rData.buys || []).length > 0
        ? rData.buys.map((b) => `${b.category} (${formatTileModifier(b.modifier)})`).join(", ")
        : null;

    visualNode = el(
      "div",
      { style: { display: "flex", flexDirection: "column", alignItems: "center", gap: "0.75rem" } },
      el(
        "div",
        { style: { width: "270px" } },
        renderDynamicTileCardNode(rData, coord, "inspector")
      ),
      el(
        "div",
        {
          style: {
            width: "100%",
            padding: "0.65rem 0.85rem",
            borderRadius: "6px",
            background: "rgba(34, 13, 62, 0.94)",
            border: "1.5px solid #a88d6b",
            boxShadow: "var(--bevel-sunken)",
            fontSize: "0.84rem",
          },
        },
        el("div", {}, el("strong", { style: { color: "var(--gold-bright)" }, text: "Tile ID: " }), rData.id || coord),
        el("div", {}, el("strong", { style: { color: "var(--gold-bright)" }, text: "Buys: " }), sellsText),
        buysText ? el("div", {}, el("strong", { style: { color: "#0369a1" }, text: "Forum Sells: " }), buysText) : null,
        el(
          "div",
          {},
          el("strong", { style: { color: "var(--gold-bright)" }, text: "Encounter / Properties: " }),
          [
            rData.encounter ? EDGE_LABELS[rData.encounter] || rData.encounter : "No Center Encounter",
            rData.persistent ? "Persistent (⤹)" : "Refreshes at Dawn (↻)",
            rData.gamble ? "Stadium Gambling (🎲)" : null,
          ]
            .filter(Boolean)
            .join(" • ")
        )
      )
    );
  } else if (si.targetType === "deck" && rData) {
    const dk = (si.targetKey || "").toLowerCase();
    let cardNode = null;
    if (dk === "celebrities" || dk === "cops" || dk === "criminals") {
      cardNode = renderPhysicalEncounterCardNode(rData, dk, { interactive: true });
    } else if (dk === "missions") {
      cardNode = renderPhysicalMissionCardNode(rData, { showStatusTag: false });
    } else if (dk === "influence") {
      cardNode = renderPhysicalInfluenceCardNode(rData);
    } else if (dk === "market") {
      cardNode = renderScoutedMarketCardPreview(rData);
    }
    visualNode = el(
      "div",
      { style: { display: "flex", flexDirection: "column", alignItems: "center", gap: "0.75rem" } },
      cardNode ? el("div", { style: { width: "310px", maxWidth: "100%" } }, cardNode) : null,
      el(
        "div",
        {
          style: {
            width: "100%",
            padding: "0.6rem 0.85rem",
            borderRadius: "6px",
            background: "rgba(34, 13, 62, 0.94)",
            border: "1.5px solid #a88d6b",
            boxShadow: "var(--bevel-sunken)",
            fontSize: "0.84rem",
            textAlign: "center",
          },
        },
        si.summary || ""
      )
    );
  } else {
    visualNode = el("p", { style: { fontSize: "0.9rem" }, text: `${si.label}: ${si.summary}` });
  }

  const gs = appState.gameState;
  const canEndTurnFromScout =
    Boolean(gs) &&
    gs.phase === "delivery" &&
    gs.activePlayerIndex === gs.viewerPlayerIndex &&
    !gs.pendingEncounter;

  showModal(
    `👁️ Scouted Intelligence — ${si.label || "Revealed Secret"}`,
    el(
      "div",
      {},
      visualNode,
      el(
        "div",
        { style: { display: "flex", gap: "0.6rem", justifyContent: "flex-end", marginTop: "1rem", flexWrap: "wrap" } },
        el("button", {
          type: "button",
          className: canEndTurnFromScout ? "btn" : "btn btn-primary",
          text: "Close Scout View",
          onClick: closeModal,
        }),
        canEndTurnFromScout
          ? el("button", {
            type: "button",
            className: "btn btn-primary",
            text: "⏭️ End Turn",
            onClick: () => {
              closeModal();
              sendGameAction({ type: "delivery_end_turn" });
            },
          })
          : null
      )
    )
  );
}

function openLoadCargoPromptModal(m, viewer) {
  const reqBlocks = Number(m.blocks || 1);
  const hasSpace = m.hasCargoSpace !== false;
  const canSwap = hasSpace || (viewer && Array.isArray(viewer.suv) && viewer.suv.length > 0);

  showModal(
    `📦 Delivery Mission Cargo Available — ${m.name}`,
    el(
      "div",
      {},
      el("p", {
        style: { fontSize: "0.9rem", color: "var(--text-main)", marginTop: "0" },
        text: `You are at ${m.pickupCell}, the pickup location for your Delivery Mission "${m.name}" (Deliver to ${m.deliverCell}). Would you like to load the mission cargo (${reqBlocks}■) onto your suv now?`,
      }),
      el(
        "div",
        { style: { display: "flex", justifyContent: "center", margin: "0.75rem 0" } },
        el("div", { style: { width: "265px" } }, renderPhysicalMissionCardNode(m, { showStatusTag: true }))
      ),
      !hasSpace
        ? el("p", {
          style: { color: "#92400e", fontSize: "0.84rem", fontWeight: "700" },
          text: `Your SUV currently has ${viewer.usedBlocks}/${viewer.maxBlocks}■ used and needs ${reqBlocks}■ to load this cargo. You may discard Goods on your SUV right now to make room, or leave the cargo on the Mission card (and sell Goods first if you wish).`,
        })
        : el("p", {
          style: { color: "var(--text-muted)", fontSize: "0.8rem" },
          text: "If you choose not to load the cargo right now, you can still click the \"📦 Load Cargo\" button directly on this Mission card at any time while your suv remains in this neighborhood.",
        }),
      el(
        "div",
        { style: { display: "flex", gap: "0.6rem", justifyContent: "flex-end", marginTop: "1rem", flexWrap: "wrap" } },
        el("button", {
          type: "button",
          className: "btn",
          text: "No, Leave on Mission Card for Now",
          onClick: closeModal,
        }),
        canSwap
          ? el("button", {
            type: "button",
            className: "btn btn-primary",
            text: hasSpace ? `📦 Yes, Load Cargo (${reqBlocks}■)` : `📦 Discard Goods & Load Cargo (${reqBlocks}■)`,
            onClick: () => {
              triggerMissionCargoLoadWithOverflow(m, viewer);
            },
          })
          : null
      )
    )
  );
}

function openDeliverCargoPromptModal(m, _viewer) {
  const reqBlocks = Number(m.blocks || 1);
  const canFence = Array.isArray(m.fencedSell) && m.fencedSell.length >= 5 && m.source !== "schizophrenic";

  showModal(
    `🏛️ Delivery Destination Reached — ${m.name}`,
    el(
      "div",
      {},
      el("p", {
        style: { fontSize: "0.9rem", color: "var(--text-main)", marginTop: "0" },
        text: `You have arrived at ${m.deliverCell}, the delivery destination for your Mission "${m.name}" carrying ${m.item || "Cargo"} (${reqBlocks}■). Would you like to deliver the item now to complete the mission?`,
      }),
      el(
        "div",
        { style: { display: "flex", justifyContent: "center", margin: "0.75rem 0" } },
        el("div", { style: { width: "265px" } }, renderPhysicalMissionCardNode(m, { showStatusTag: true }))
      ),
      el("p", {
        style: { color: "var(--text-muted)", fontSize: "0.8rem" },
        text: canFence
          ? `If you plan to fence ${m.item || "this cargo"} at a buyer neighborhood instead of delivering it, choose "No, Keep on SUV". You can also click "🏛️ Deliver ${m.item || "Cargo"} Here" on the Mission card at any time while in ${m.deliverCell}.`
          : `If you choose not to deliver right now, you can click "🏛️ Deliver ${m.item || "Cargo"} Here" on the Mission card at any time while your suv remains in ${m.deliverCell}.`,
      }),
      el(
        "div",
        { style: { display: "flex", gap: "0.6rem", justifyContent: "flex-end", marginTop: "1rem" } },
        el("button", {
          type: "button",
          className: "btn",
          text: "No, Keep on SUV for Now",
          onClick: closeModal,
        }),
        el("button", {
          type: "button",
          className: "btn btn-primary",
          text: `🏛️ Yes, Deliver ${m.item || "Cargo"} & Claim Reward`,
          onClick: () => {
            closeModal();
            sendGameAction({ type: "delivery_complete_mission", missionId: m.id });
          },
        })
      )
    )
  );
}

function openCancelMissionConfirmModal(m, schizophrenicTotalCount = 0) {
  const src = m.source || "starting";
  if (src === "schizophrenic" && schizophrenicTotalCount <= 5) {
    showToast("Canceling or failing a Schizophrenic mission is impossible unless you already have 5 active Schizophrenic missions and take on a 6th!", true);
    return;
  }

  const cargoWarning = m.pickedUp
    ? `⚠️ Because you have already picked up "${m.item || "the delivery cargo"}", canceling this mission will throw the item away (it cannot be sold).`
    : null;

  let ruleExplanation = "";
  if (src === "encounter") {
    const hList = formatHostileFavorPenaltyText(m);
    ruleExplanation = `Per the rulebook, canceling or failing an Encounter Mission incurs its Thumbs-Down reputational consequences (${hList}).`;
  } else if (src === "schizophrenic") {
    ruleExplanation = "Because you hold more than 5 active Schizophrenic missions, you may cancel one active Schizophrenic mission with no penalty.";
  } else {
    ruleExplanation = "Per the rulebook, Starting Missions can be canceled voluntarily at any time with no penalty.";
  }

  showModal(
    `✕ Cancel Mission — ${m.name}?`,
    el(
      "div",
      {},
      el("p", { style: { fontSize: "0.9rem", color: "var(--text-main)", marginTop: "0" }, text: ruleExplanation }),
      cargoWarning
        ? el("p", {
          style: {
            fontSize: "0.84rem",
            color: "#fbcfe8",
            fontWeight: "700",
            background: "rgba(68, 12, 48, 0.92)",
            border: "1.5px solid #dc2626",
            padding: "0.5rem 0.65rem",
            borderRadius: "6px",
          },
          text: cargoWarning,
        })
        : null,
      el(
        "div",
        { style: { display: "flex", justifyContent: "center", margin: "0.75rem 0" } },
        el("div", { style: { width: "255px" } }, renderPhysicalMissionCardNode(m, { showStatusTag: true }))
      ),
      el(
        "div",
        { style: { display: "flex", gap: "0.6rem", justifyContent: "flex-end", marginTop: "1rem" } },
        el("button", { type: "button", className: "btn", text: "Keep Mission", onClick: closeModal }),
        el("button", {
          type: "button",
          className: "btn btn-crimson",
          text: src === "encounter" ? "✕ Confirm Cancel (Take 👎 Penalty)" : "✕ Confirm Cancel (No Penalty)",
          onClick: () => {
            closeModal();
            sendGameAction({ type: "cancel_mission", missionId: m.id });
          },
        })
      )
    )
  );
}

function openProcurerGoodModal(gs, viewer, card) {
  const availableGoods = ((gs && gs.sourceableGoods) || []).filter(
    (g) => g.track !== "Henchmen" && (Number(g.henchmen) || 0) === 0
  );
  const freeBlocks = Math.max(0, (Number(viewer.maxBlocks) || 6) - (Number(viewer.usedBlocks) || 0));

  showModal(
    `🛒 Play "${card.name}" — Choose Good in Goods Deck @ Common (>)`,
    el(
      "div",
      { style: { display: "flex", flexDirection: "column", gap: "0.75rem" } },
      el("p", {
        style: { margin: "0", fontSize: "0.88rem", color: "var(--text-main)" },
        text: `Choose any Good currently available in the Goods deck to purchase directly onto your SUV at its Common (>) buying price. (Your SUV has ${freeBlocks}■ free capacity and ${viewer.cash}(d); if full, you may discard Goods on your SUV to make room).`,
      }),
      availableGoods.length === 0
        ? el("div", { style: { color: "var(--text-muted)", fontSize: "0.85rem" }, text: "No Goods remain in the Goods deck." })
        : el(
          "div",
          {
            style: {
              display: "grid",
              gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))",
              gap: "0.55rem",
              maxHeight: "380px",
              overflowY: "auto",
              padding: "0.2rem",
            },
          },
          ...availableGoods.map((g) => {
            const buyPrices = Array.isArray(g.buy) ? g.buy : [];
            const commonPrice = buyPrices.length >= 4 ? Number(buyPrices[3]) : Number(buyPrices[buyPrices.length - 1] || 20);
            const blocks = Math.max(1, Number(g.blocks) || 1);
            const hasCash = (Number(viewer.cash) || 0) >= commonPrice;
            const fitsDirectly = freeBlocks >= blocks;
            const canSwap = fitsDirectly || (Array.isArray(viewer.suv) && viewer.suv.length > 0);
            const canSelect = hasCash && canSwap;
            return el(
              "div",
              {
                style: {
                  padding: "0.55rem 0.7rem",
                  borderRadius: "6px",
                  background: "rgba(34, 13, 62, 0.94)",
                  border: "1.5px solid #a88d6b",
                  boxShadow: "var(--bevel-sunken)",
                  display: "flex",
                  flexDirection: "column",
                  justifyContent: "space-between",
                  gap: "0.4rem",
                },
              },
              el(
                "div",
                {},
                el("div", { style: { fontWeight: "800", color: "var(--gold-bright)", fontSize: "0.86rem" }, text: `${g.name} (${blocks}■)` }),
                el("div", { style: { fontSize: "0.74rem", color: "var(--text-muted)" }, text: `${g.track} • Common (>) Price: ${commonPrice}(d)` })
              ),
              el("button", {
                type: "button",
                className: "btn btn-sm btn-primary",
                disabled: !canSelect,
                text: !hasCash
                  ? `Needs ${commonPrice}(d)`
                  : fitsDirectly
                    ? `🛒 Buy ${g.name} for ${commonPrice}(d)`
                    : `🛒 Buy for ${commonPrice}(d) (Swap)`,
                onClick: () => {
                  if (fitsDirectly) {
                    closeModal();
                    sendGameAction({
                      type: "play_influence",
                      cardId: card.id,
                      goodCardId: g.id,
                      targetGood: g.name,
                    });
                  } else {
                    openSUVReplacementModal(viewer, {
                      itemType: "good",
                      incomingCard: g,
                      reqBlocks: blocks,
                      reqHenchmen: 0,
                      bonusBlocks: 0,
                      bonusHenchmen: 0,
                      title: `🛒 SUV Full — Discard Goods to Procure ${g.name}`,
                      subtitle: `Purchasing "${g.name}" (${blocks}■) via Procurer costs ${commonPrice}(d). Select Goods on your SUV to discard so it fits, or cancel without playing Procurer.`,
                      confirmLabelPrefix: `Buy ${g.name} for ${commonPrice}(d)`,
                      cancelLabel: "← Back to Goods List",
                      onConfirm: (discardSUVIds, fireHenchmanIds) => {
                        sendGameAction({
                          type: "play_influence",
                          cardId: card.id,
                          goodCardId: g.id,
                          targetGood: g.name,
                          discardSUVIds,
                          fireHenchmanIds,
                        });
                      },
                      onCancel: () => openProcurerGoodModal(gs, viewer, card),
                    });
                  }
                },
              })
            );
          })
        ),
      el(
        "div",
        { style: { display: "flex", justifyContent: "flex-end" } },
        el("button", { type: "button", className: "btn", text: "Cancel", onClick: closeModal })
      )
    )
  );
}

function doesItemFitWithoutSwap(viewer, spec = {}) {
  if (!viewer) return true;
  const reqB = Number(spec.reqBlocks) || 0;
  const reqG = Number(spec.reqHenchmen) || 0;
  const bonusB = Number(spec.bonusBlocks) || 0;
  const bonusG = Number(spec.bonusHenchmen) || 0;
  const usedB = Number(viewer.usedBlocks) || 0;
  const maxB = Number(viewer.maxBlocks) || 6;
  const usedG = Number(viewer.usedHenchmen) || 0;
  const maxG = Number(viewer.maxHenchmen) || 2;
  return usedB + reqB <= maxB + bonusB && usedG + reqG <= maxG + bonusG;
}

function describeSUVItemDiscardWarning(item, viewer) {
  if (!item || !item.isMissionCargo) return null;
  const src = item.missionSource || "starting";
  const mName = item.missionName || "Mission";
  if (src === "encounter") {
    const linked = ((viewer && viewer.missions) || []).find((m) => m.id === item.missionId);
    const penText = linked ? formatHostileFavorPenaltyText(linked) : "👎 Favor penalty";
    return `⚠️ Encounter Mission Cargo — discarding fails "${mName}" (${penText})!`;
  }
  if (src === "schizophrenic") {
    const linked = ((viewer && viewer.missions) || []).find((m) => m.id === item.missionId);
    const pCell = (linked && linked.pickupCell) || "pickup tile";
    return `⚠️ Schizophrenic Cargo — discarding resets pickup back to ${pCell}!`;
  }
  return `⚠️ Starting Mission Cargo — discarding cancels "${mName}" (no penalty).`;
}

function openSUVReplacementModal(viewer, opts) {
  if (!viewer) return;
  const isHenchmanIncoming = opts.itemType === "henchman";
  const reqBlocks = Number(opts.reqBlocks) || 0;
  const reqHenchmen = Number(opts.reqHenchmen) || 0;
  const incBonusBlocks = Number(opts.bonusBlocks) || 0;
  const incBonusHenchmen = Number(opts.bonusHenchmen) || 0;
  const incCard = opts.incomingCard || {};

  const selectedSUVIds = new Set();
  const selectedHenchmanIds = new Set();

  const suvItems = Array.isArray(viewer.suv) ? viewer.suv : [];
  const henchmanItems = Array.isArray(viewer.henchmen) ? viewer.henchmen : [];

  const rootContainer = el("div", { className: "suv-swap-modal-root" });

  function computeState() {
    const remSUV = suvItems.filter((c) => !selectedSUVIds.has(String(c.id)));
    const remHenchmen = henchmanItems.filter((g) => !selectedHenchmanIds.has(String(g.id)));
    const projMaxBlocks =
      6 +
      (Number(viewer.bonusBlocks) || 0) +
      remHenchmen.reduce((sum, g) => sum + (Number(g.bonusBlocks) || 0), 0) +
      incBonusBlocks;
    const projMaxHenchmen =
      2 +
      (Number(viewer.bonusHenchmen) || 0) +
      remHenchmen.reduce((sum, g) => sum + (Number(g.bonusHenchmen) || 0), 0) +
      incBonusHenchmen;
    const projUsedBlocks = remSUV.reduce((sum, c) => sum + (Number(c.blocks) || 1), 0) + reqBlocks;
    const projUsedHenchmen = remHenchmen.reduce((sum, g) => sum + (Number(g.henchmen) || 1), 0) + reqHenchmen;
    const blocksDeficit = Math.max(0, projUsedBlocks - projMaxBlocks);
    const henchmenDeficit = Math.max(0, projUsedHenchmen - projMaxHenchmen);
    return {
      projMaxBlocks,
      projMaxHenchmen,
      projUsedBlocks,
      projUsedHenchmen,
      blocksDeficit,
      henchmenDeficit,
      isValid: blocksDeficit === 0 && henchmenDeficit === 0,
    };
  }

  function renderModalBody() {
    while (rootContainer.firstChild) {
      rootContainer.removeChild(rootContainer.firstChild);
    }
    const proj = computeState();

    // Header summary banner + incoming item preview
    const previewTrack = incCard.track || (isHenchmanIncoming ? "Henchmen" : "Grain");
    const previewCardNode = el(
      "div",
      { className: `suv-swap-incoming-box ${resolveGoodTrackClass(previewTrack)}` },
      el(
        "div",
        { style: { flex: "1", minWidth: "200px" } },
        el("div", {
          style: { fontSize: "0.7rem", fontWeight: "800", textTransform: "uppercase", letterSpacing: "0.6px", color: "var(--gold-bright)" },
          text: isHenchmanIncoming ? "Incoming Henchman" : "Incoming SUV Item",
        }),
        el("div", {
          style: { fontSize: "1.02rem", fontWeight: "800", color: "#fff", marginTop: "2px" },
          text: `${incCard.name || "Item"} (${isHenchmanIncoming ? "▲".repeat(Math.max(1, reqHenchmen)) : `${reqBlocks}■`})`,
        }),
        el("div", {
          style: { fontSize: "0.78rem", color: "var(--text-muted)", marginTop: "2px" },
          text: [
            incCard.subcategory || incCard.category || previewTrack,
            incCard.combatText ? `• ${incCard.combatText}` : null,
            Array.isArray(incCard.sell) && incCard.sell.length > 0 ? `• Sells: ${incCard.sell.join("/")}` : null,
          ]
            .filter(Boolean)
            .join(" "),
        }),
        opts.subtitle
          ? el("div", {
            style: { fontSize: "0.82rem", color: "var(--text-main)", marginTop: "0.45rem" },
            text: opts.subtitle,
          })
          : null
      ),
      el(
        "div",
        { className: `suv-swap-status-pill ${proj.isValid ? "is-ready" : "is-deficit"}` },
        isHenchmanIncoming || selectedHenchmanIds.size > 0
          ? el("div", {
            text: `Henchmen: ${proj.projUsedHenchmen}/${proj.projMaxHenchmen}▲${proj.henchmenDeficit > 0 ? ` (Fire ${proj.henchmenDeficit}▲ more)` : " ✓"
              }`,
          })
          : null,
        !isHenchmanIncoming || proj.blocksDeficit > 0 || selectedSUVIds.size > 0
          ? el("div", {
            text: `Goods: ${proj.projUsedBlocks}/${proj.projMaxBlocks}■${proj.blocksDeficit > 0 ? ` (Discard ${proj.blocksDeficit}■ more)` : " ✓"
              }`,
          })
          : null
      )
    );
    rootContainer.appendChild(previewCardNode);

    // 1. Henchman Firing Section (shown when hiring/receiving a Henchman)
    if (isHenchmanIncoming) {
      rootContainer.appendChild(
        el("div", {
          className: "suv-swap-section-title",
          text: "Select Henchman(s) on Your SUV to Fire:",
        })
      );
      if (henchmanItems.length === 0) {
        rootContainer.appendChild(
          el("p", { style: { color: "var(--text-muted)", fontSize: "0.84rem" }, text: "You currently have no Henchmen to fire." })
        );
      } else {
        const gGrid = el("div", { className: "suv-swap-grid" });
        for (const g of henchmanItems) {
          const gid = String(g.id);
          const isSelected = selectedHenchmanIds.has(gid);
          const extraNote =
            Number(g.bonusHenchmen) > 0
              ? `⚠️ Grants +${g.bonusHenchmen}▲ Henchman Slot — firing removes that extra slot!`
              : Number(g.bonusBlocks) > 0
                ? `⚠️ Grants +${g.bonusBlocks}■ SUV Space — firing reduces max Goods capacity!`
                : null;

          gGrid.appendChild(
            el(
              "div",
              {
                className: `suv-swap-card ${isSelected ? "selected-for-removal" : ""}`,
                onClick: () => {
                  if (selectedHenchmanIds.has(gid)) {
                    selectedHenchmanIds.delete(gid);
                  } else {
                    selectedHenchmanIds.add(gid);
                  }
                  renderModalBody();
                },
              },
              el(
                "div",
                { className: "suv-swap-card-top" },
                el("span", { className: "suv-swap-card-name", text: `${g.name} (1▲)` }),
                el("span", {
                  className: `suv-swap-badge ${isSelected ? "active" : ""}`,
                  text: isSelected ? "✕ FIRE" : "Keep",
                })
              ),
              el("div", {
                className: "suv-swap-card-meta",
                text: `${g.combatText || "Henchman"}${String(g.id || "").startsWith("thug_") ? " • Discarded on fire" : " • Returns to bottom of Market deck"
                  }`,
              }),
              extraNote
                ? el("div", { className: "suv-swap-warning", text: extraNote })
                : null
            )
          );
        }
        rootContainer.appendChild(gGrid);
      }
    }

    // 2. SUV Goods Discard Section (shown when adding a Good, OR if firing Lucius created a Goods block deficit!)
    if (!isHenchmanIncoming || proj.blocksDeficit > 0 || selectedSUVIds.size > 0) {
      rootContainer.appendChild(
        el("div", {
          className: "suv-swap-section-title",
          text: isHenchmanIncoming
            ? `⚠️ Firing Reduced SUV Space — Also Select Goods to Discard (${proj.blocksDeficit}■ needed):`
            : "Select Goods on Your SUV to Discard:",
        })
      );
      if (suvItems.length === 0) {
        rootContainer.appendChild(
          el("p", { style: { color: "var(--text-muted)", fontSize: "0.84rem" }, text: "Your SUV currently has no Goods to discard." })
        );
      } else {
        const cGrid = el("div", { className: "suv-swap-grid" });
        for (const item of suvItems) {
          const cid = String(item.id);
          const isSelected = selectedSUVIds.has(cid);
          const bCount = Math.max(1, Number(item.blocks) || 1);
          const warnMsg = describeSUVItemDiscardWarning(item, viewer);
          const sellLine =
            Array.isArray(item.sell) && item.sell.length > 0
              ? `Sell Table: ${item.sell.join("/")}`
              : item.isMissionCargo
                ? "Mission Cargo (Unsellable)"
                : item.track || "Good";

          cGrid.appendChild(
            el(
              "div",
              {
                className: `suv-swap-card ${isSelected ? "selected-for-removal" : ""}`,
                onClick: () => {
                  if (selectedSUVIds.has(cid)) {
                    selectedSUVIds.delete(cid);
                  } else {
                    selectedSUVIds.add(cid);
                  }
                  renderModalBody();
                },
              },
              el(
                "div",
                { className: "suv-swap-card-top" },
                el("span", {
                  className: "suv-swap-card-name",
                  text: `${item.name} (${"■".repeat(bCount)} ${bCount}■)`,
                }),
                el("span", {
                  className: `suv-swap-badge ${isSelected ? "active" : ""}`,
                  text: isSelected ? "🗑️ DISCARD" : "Keep",
                })
              ),
              el("div", {
                className: "suv-swap-card-meta",
                text: [item.subcategory || item.category || item.track, sellLine, item.combatText || null]
                  .filter(Boolean)
                  .join(" • "),
              }),
              warnMsg ? el("div", { className: "suv-swap-warning", text: warnMsg }) : null
            )
          );
        }
        rootContainer.appendChild(cGrid);
      }
    }

    // Action Footer
    const summaryParts = [];
    if (selectedHenchmanIds.size > 0) summaryParts.push(`Fire ${selectedHenchmanIds.size} Henchman(s)`);
    if (selectedSUVIds.size > 0) summaryParts.push(`Discard ${selectedSUVIds.size} Item(s)`);
    const confirmText = proj.isValid
      ? `✓ ${summaryParts.length > 0 ? `${summaryParts.join(" & ")} → ` : ""}${opts.confirmLabelPrefix || "Confirm"}`
      : proj.henchmenDeficit > 0
        ? `Select ${proj.henchmenDeficit}▲ Henchman(s) to Fire`
        : `Select ${proj.blocksDeficit}■ More Goods to Discard`;

    rootContainer.appendChild(
      el(
        "div",
        {
          style: {
            display: "flex",
            justifyContent: "flex-end",
            gap: "0.6rem",
            marginTop: "1rem",
            paddingTop: "0.7rem",
            borderTop: "1px solid var(--border-subtle)",
            flexWrap: "wrap",
          },
        },
        opts.showInspectBoardBtn
          ? el("button", {
            type: "button",
            className: "btn",
            text: "Inspect Board First",
            onClick: closeModal,
          })
          : null,
        el("button", {
          type: "button",
          className: opts.isRefusal ? "btn btn-crimson" : "btn",
          text: opts.cancelLabel || (isHenchmanIncoming ? "Cancel Hire" : "Cancel"),
          onClick: () => {
            closeModal();
            if (typeof opts.onCancel === "function") {
              opts.onCancel();
            }
          },
        }),
        el("button", {
          type: "button",
          className: "btn btn-primary",
          disabled: !proj.isValid,
          text: confirmText,
          onClick: () => {
            if (!proj.isValid) return;
            const discIds = Array.from(selectedSUVIds);
            const fireIds = Array.from(selectedHenchmanIds);
            closeModal();
            if (typeof opts.onConfirm === "function") {
              opts.onConfirm(discIds, fireIds);
            }
          },
        })
      )
    );
  }

  renderModalBody();
  showModal(
    opts.title || (isHenchmanIncoming ? "🛡️ Henchman Slots Full — Fire a Henchman?" : "🛒 SUV Space Full — Discard Goods?"),
    rootContainer
  );
}

function triggerMissionCargoLoadWithOverflow(m, viewer) {
  if (!m) return;
  const reqBlocks = Math.max(1, Number(m.blocks) || 1);
  if (!viewer || m.hasCargoSpace !== false || doesItemFitWithoutSwap(viewer, { reqBlocks })) {
    closeModal();
    sendGameAction({ type: "delivery_load_cargo", missionId: m.id });
    return;
  }
  openSUVReplacementModal(viewer, {
    itemType: "good",
    incomingCard: {
      name: m.item || m.name || "Mission Cargo",
      category: m.category || "Cargo",
      subcategory: `Mission Cargo (${m.name})`,
      track: m.category || "Grain",
      blocks: reqBlocks,
      sell: m.source !== "soothsayer" ? m.fencedSell : null,
      combatText: m.combatText || null,
    },
    reqBlocks,
    reqHenchmen: 0,
    bonusBlocks: 0,
    bonusHenchmen: 0,
    title: `📦 SUV Space Full — Discard Goods to Load ${m.item || "Cargo"}`,
    subtitle: `Job "${m.name}" requires ${reqBlocks}■ on your SUV (Deliver to ${m.deliverCell}). Select Goods on your SUV to discard so you can load this cargo now, or leave it on the Job card.`,
    confirmLabelPrefix: `Load ${m.item || "Cargo"} (${reqBlocks}■)`,
    cancelLabel: "Leave on Job Card",
    onConfirm: (discardSUVIds, fireHenchmanIds) => {
      sendGameAction({
        type: "delivery_load_cargo",
        missionId: m.id,
        discardCartIds: discardSUVIds,
        fireGuardIds: fireHenchmanIds,
      });
    },
  });
}

function triggerInfluenceCardPlay(gs, viewer, card) {
  if (!card) return;
  const cName = String(card.name || "");
  if (cName.includes("Thug") && viewer && !doesItemFitWithoutSwap(viewer, { reqHenchmen: 1 })) {
    openSUVReplacementModal(viewer, {
      itemType: "henchman",
      incomingCard: {
        name: "Thug (Influence)",
        category: "Henchmen",
        subcategory: "Free Henchman",
        track: "Henchmen",
        henchmen: 1,
        combatText: "(R) CP",
      },
      reqBlocks: 0,
      reqHenchmen: 1,
      bonusBlocks: 0,
      bonusHenchmen: 0,
      title: `🛡️ Henchman Slots Full — Fire a Henchman to Deploy "${cName}"?`,
      subtitle: `Your Henchman slots are full (${viewer.usedHenchmen}/${viewer.maxHenchmen}▲). Select one of your current Henchmen to fire so you can deploy Thug, or cancel to keep "${cName}" in hand.`,
      confirmLabelPrefix: "Deploy Thug",
      cancelLabel: "Cancel (Keep Card)",
      onConfirm: (discardSUVIds, fireHenchmanIds) => {
        sendGameAction({
          type: "play_influence",
          cardId: card.id,
          discardCartIds: discardSUVIds,
          fireGuardIds: fireHenchmanIds,
        });
      },
    });
    return;
  }

  if (cName.includes("Wine Forger") && viewer && !doesItemFitWithoutSwap(viewer, { reqBlocks: 1 })) {
    openSUVReplacementModal(viewer, {
      itemType: "good",
      incomingCard: {
        name: "Stepped-On Product",
        category: "Wine",
        subcategory: "Counts as any Opiate",
        track: "Wine",
        blocks: 1,
        sell: [60, 45, 30, 20, 15],
      },
      reqBlocks: 1,
      reqHenchmen: 0,
      bonusBlocks: 0,
      bonusHenchmen: 0,
      title: `🍷 SUV Space Full — Discard Goods to Play "${cName}"?`,
      subtitle: `Your SUV is full (${viewer.usedBlocks}/${viewer.maxBlocks}■). Select at least 1■ on your SUV to discard, or cancel to keep "${cName}" in hand.`,
      confirmLabelPrefix: "Add Good",
      cancelLabel: "Cancel (Keep Card)",
      onConfirm: (discardSUVIds, fireHenchmanIds) => {
        sendGameAction({
          type: "play_influence",
          cardId: card.id,
          discardCartIds: discardSUVIds,
          fireGuardIds: fireHenchmanIds,
        });
      },
    });
    return;
  }

  if (cName === "Twist Of Fate" || cName === "Lucky Break") {
    armDieCardAction(card, cName === "Lucky Break" ? "plus_one" : "reroll");
    showToast(`👆 Click directly on the die you want to ${cName === "Lucky Break" ? "increase (+1)" : "re-roll"} with '${cName}'!`);
    const encEl = document.getElementById("pending-encounter-panel");
    if (!appState.activeDiceOverlay && encEl && typeof encEl.scrollIntoView === "function") {
      encEl.scrollIntoView({ behavior: "smooth", block: "center" });
    }
    return;
  }

  sendGameAction({ type: "play_influence", cardId: card.id });
}

function openPendingSUVOverflowModal(_gs, viewer) {
  const queue = (viewer && viewer.pendingCartOverflow) || [];
  if (queue.length === 0) return;
  const ovf = queue[0];
  const card = ovf.card || {};
  const isHenchman = ovf.itemType === "guard" || ovf.itemType === "henchman" || card.track === "Guards" || card.track === "Henchmen";
  const reqBlocks = isHenchman ? 0 : Math.max(1, Number(ovf.reqBlocks || card.blocks) || 1);
  const reqHenchmen = isHenchman ? Math.max(1, Number(ovf.reqGuards || ovf.reqHenchmen || card.guards || card.henchmen) || 1) : 0;

  openSUVReplacementModal(viewer, {
    itemType: isHenchman ? "henchman" : "good",
    incomingCard: card,
    reqBlocks,
    reqHenchmen,
    bonusBlocks: Number(ovf.bonusBlocks || card.bonusBlocks) || 0,
    bonusHenchmen: Number(ovf.bonusGuards || ovf.bonusHenchmen || card.bonusGuards || card.bonusHenchmen) || 0,
    title: isHenchman
      ? `🛡️ Free Henchman Received — ${card.name} (${ovf.sourceLabel || "Reward"})`
      : `🎁 Item Received — ${card.name} (${reqBlocks}■ • ${ovf.sourceLabel || "Reward"})`,
    subtitle: isHenchman
      ? `You received Henchman "${card.name}" (${ovf.sourceLabel || "Reward"}), but your Henchman slots are full (${viewer.usedHenchmen}/${viewer.maxHenchmen}▲). Select a Henchman to fire, or refuse the new Henchman.`
      : `You received "${card.name}" (${reqBlocks}■, ${ovf.sourceLabel || "Reward"}), but your SUV does not have enough free space (${viewer.usedBlocks}/${viewer.maxBlocks}■ used). Select Goods on your SUV to discard, or refuse this item.`,
    confirmLabelPrefix: isHenchman ? `Accept ${card.name}` : `Load ${card.name}`,
    cancelLabel: `✕ Refuse ${card.name}`,
    isRefusal: true,
    showInspectBoardBtn: true,
    onConfirm: (discardSUVIds, fireHenchmanIds) => {
      sendGameAction({
        type: "resolve_cart_overflow",
        overflowId: ovf.id,
        decision: "accept",
        discardCartIds: discardSUVIds,
        fireGuardIds: fireHenchmanIds,
      });
    },
    onCancel: () => {
      sendGameAction({
        type: "resolve_cart_overflow",
        overflowId: ovf.id,
        decision: "refuse",
      });
    },
  });
}

function openProphecyTargetModal(gs, viewer, card) {
  const players = Array.isArray(gs.players) ? gs.players : [];
  showModal(
    `🔮 Play "${card.name}" — Choose Target Player`,
    el(
      "div",
      { style: { display: "flex", flexDirection: "column", gap: "0.75rem" } },
      el("p", {
        style: { fontSize: "0.88rem", color: "var(--text-main)", margin: "0" },
        text: "Trigger a Soothsayer encounter for any player (including yourself or a rival merchant).",
      }),
      el(
        "div",
        { style: { display: "flex", flexDirection: "column", gap: "0.45rem" } },
        ...players.map((p) => {
          const isMe = p.index === viewer.index;
          return el(
            "button",
            {
              type: "button",
              className: isMe ? "btn" : "btn btn-primary",
              style: { display: "flex", justifyContent: "space-between", alignItems: "center", width: "100%" },
              onClick: () => {
                closeModal();
                sendGameAction({
                  type: "play_influence",
                  cardId: card.id,
                  targetPlayerIndex: p.index,
                });
              },
            },
            el("span", { text: `🔮 ${p.name}${isMe ? " (You)" : ""}` }),
            el("span", {
              style: { fontSize: "0.76rem", opacity: "0.85" },
              text: `${p.cash}(d) • ${p.missionCount ?? (p.missions || []).length} Missions`,
            })
          );
        })
      ),
      el(
        "div",
        { style: { display: "flex", justifyContent: "flex-end" } },
        el("button", { type: "button", className: "btn", text: "Cancel", onClick: closeModal })
      )
    )
  );
}

function openSurpriseShipmentModal(gs, _viewer, card) {
  const tracks = ["Marble", "Wine", "Animals", "Weapons", "Grain"];
  const meta = gs.marketMeta || {};
  showModal(
    `🚢 Play "${card.name}" — Shift Category Scarcity`,
    el(
      "div",
      { style: { display: "flex", flexDirection: "column", gap: "0.75rem" } },
      el("p", {
        style: { fontSize: "0.88rem", color: "var(--text-main)", margin: "0" },
        text: "Move the Scarcity for one category of Goods one level to the right (more abundant / lower sell price) for the rest of this Season.",
      }),
      el(
        "div",
        { style: { display: "flex", flexDirection: "column", gap: "0.45rem" } },
        ...tracks.map((tName) => {
          const tMeta = meta[tName] || {};
          return el(
            "button",
            {
              type: "button",
              className: "btn btn-primary",
              style: { display: "flex", justifyContent: "space-between", alignItems: "center", width: "100%" },
              onClick: () => {
                closeModal();
                sendGameAction({
                  type: "play_influence",
                  cardId: card.id,
                  track: tName,
                });
              },
            },
            el("span", { text: `📦 ${tName}` }),
            el("span", {
              style: { fontSize: "0.76rem", opacity: "0.9" },
              text: `Current: ${tMeta.scarcitySymbol || "="} (${tMeta.scarcityLabel || "Normal"})`,
            })
          );
        })
      ),
      el(
        "div",
        { style: { display: "flex", justifyContent: "flex-end" } },
        el("button", { type: "button", className: "btn", text: "Cancel", onClick: closeModal })
      )
    )
  );
}

function renderDeckCardBackPickerGrid(gs, deckSpecs, onSelectDeck, tapPillLabel = "👆 Tap Deck to Scout") {
  const counts = (gs && gs.deckCounts) || {};
  return el(
    "div",
    { className: "scout-decks-grid" },
    ...deckSpecs.map((spec) => {
      const rem = counts[spec.key];
      const countText = typeof rem === "number" ? `${rem} card${rem === 1 ? "" : "s"}` : "Deck";
      const cardVisual = spec.img
        ? el(
          "div",
          { className: "scout-deck-card-wrap" },
          el("img", {
            className: "scout-deck-card-img",
            src: spec.img,
            alt: `${spec.label} Deck Card Back`,
          })
        )
        : el(
          "div",
          { className: "scout-deck-card-wrap" },
          el(
            "div",
            {
              className: "scout-deck-card-img",
              style: {
                width: "126px",
                height: "176px",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                gap: "0.35rem",
                padding: "0.55rem",
                textAlign: "center",
                background:
                  spec.key === "missiones"
                    ? "radial-gradient(circle at 50% 35%, #5b3a1d, #241509)"
                    : "radial-gradient(circle at 50% 35%, #4c1d4b, #1d0c24)",
                border: "3px double #d4af37",
                color: "#fef08a",
              },
            },
            el("div", { style: { fontSize: "1.6rem" }, text: spec.icon || "📜" }),
            el("div", {
              style: { fontFamily: "Cinzel, Georgia, serif", fontWeight: "800", fontSize: "0.8rem", letterSpacing: "0.06em" },
              text: spec.label.toUpperCase(),
            })
          )
        );

      return el(
        "button",
        {
          type: "button",
          className: "scout-deck-stack-btn",
          disabled: typeof rem === "number" && rem <= 0,
          onClick: () => onSelectDeck(spec.key),
        },
        cardVisual,
        el("div", { className: "scout-deck-caption", text: spec.label }),
        el("div", { className: "scout-deck-sub", text: countText }),
        el("div", { className: "scout-deck-tap-pill", text: tapPillLabel })
      );
    })
  );
}

function openInformantsTargetModal(gs, _viewer, card) {
  const allDeckSpecs = [
    { key: "celebrities", label: "Celebrities", img: "/assets/icons/card_back_celebrities.png?v=111" },
    { key: "criminals", label: "Criminals", img: "/assets/icons/card_back_criminals.png?v=111" },
    { key: "cops", label: "Cops", img: "/assets/icons/card_back_cops.png?v=111" },
    { key: "market", label: "Goods & Henchmen", img: "/assets/icons/card_back_goods.png?v=111" },
    { key: "missions", label: "Jobs", img: "/assets/icons/card_back_missions.png?v=111" },
    { key: "influence", label: "Influence", img: "/assets/icons/card_back_influence.png?v=111" },
  ];

  const cellSelect = el(
    "select",
    { className: "form-input" },
    ...Object.keys(gs.romeBoard || {}).map((coord) =>
      el("option", {
        value: coord,
        selected: coord === appState.inspectedCell,
        text: `${coord} — ${gs.romeBoard[coord].name} (${gs.romeBoard[coord].stackCount ?? 12} tiles)`,
      })
    )
  );

  showModal(
    `🃏 Play "${card.name}" — Inspect & Reorder Top 3`,
    el(
      "div",
      {},
      el("p", {
        style: { fontSize: "0.88rem", color: "var(--text-main)", marginTop: "0" },
        text: "Look at the top three cards of any deck (tap a deck below) or the top three tiles of any neighborhood stack and put them back in any order.",
      }),
      el(
        "div",
        { style: { marginBottom: "1rem" } },
        el("div", {
          style: { fontWeight: "700", color: "var(--gold-bright)", fontSize: "0.88rem", marginBottom: "0.35rem" },
          text: "Option A: Tap Any Card Deck to Inspect & Reorder Its Top 3 Cards",
        }),
        renderDeckCardBackPickerGrid(
          gs,
          allDeckSpecs,
          (dk) => {
            closeModal();
            sendGameAction({
              type: "play_influence",
              cardId: card.id,
              targetType: "deck",
              targetKey: dk,
            });
          },
          "👁️ Tap for Top 3"
        )
      ),
      el(
        "div",
        { style: { paddingTop: "0.85rem", borderTop: "1px solid var(--border-subtle)" } },
        el("div", { className: "form-group" }, el("label", { text: "Option B: Inspect Top 3 Tiles of Any Neighborhood Stack" }), cellSelect),
        el("button", {
          type: "button",
          className: "btn btn-primary",
          style: { width: "100%" },
          text: "👁️ Look at Top 3 Tiles of Selected Stack",
          onClick: () => {
            closeModal();
            sendGameAction({
              type: "play_influence",
              cardId: card.id,
              targetType: "tile",
              targetKey: cellSelect.value,
            });
          },
        })
      )
    )
  );
}

function openTop3ReorderModal(pendReorder) {
  if (!pendReorder || !Array.isArray(pendReorder.items)) return;
  const currentItems = pendReorder.items.slice();
  const tType = pendReorder.targetType || "deck";
  const tKey = pendReorder.targetKey || "celebrities";
  const cardsContainer = el("div", { className: "top3-reorder-grid" });

  function renderPreviewForItem(item) {
    if (tType === "tile") {
      return el("div", { style: { width: "220px" } }, renderDynamicTileCardNode(item, tKey, "inspector"));
    }
    const dk = String(tKey).toLowerCase();
    if (["celebrities", "cops", "criminals", "patricii", "legiones", "nefarii"].includes(dk)) {
      return el("div", { style: { width: "225px" } }, renderPhysicalEncounterCardNode(item, dk));
    }
    if (dk === "missions" || dk === "missiones") {
      return el("div", { style: { width: "225px" } }, renderPhysicalMissionCardNode(item, { showStatusTag: false }));
    }
    if (dk === "influence") {
      return el("div", { style: { width: "225px" } }, renderPhysicalInfluenceCardNode(item));
    }
    return renderScoutedMarketCardPreview(item);
  }

  function refreshGrid() {
    const slotNodes = currentItems.map((item, idx) => {
      const posLabel = idx === 0 ? "#1 — TOP (1st)" : idx === 1 ? "#2 — SECOND" : "#3 — THIRD";
      return el(
        "div",
        { className: "top3-slot-card" },
        el("div", { className: `top3-pos-badge pos-${idx + 1}`, text: posLabel }),
        renderPreviewForItem(item),
        el(
          "div",
          { className: "top3-move-btns" },
          el("button", {
            type: "button",
            className: "btn btn-sm",
            disabled: idx === 0,
            text: "◀ Move Earlier",
            onClick: () => {
              const tmp = currentItems[idx - 1];
              currentItems[idx - 1] = currentItems[idx];
              currentItems[idx] = tmp;
              refreshGrid();
            },
          }),
          el("button", {
            type: "button",
            className: "btn btn-sm",
            disabled: idx === currentItems.length - 1,
            text: "Move Later ▶",
            onClick: () => {
              const tmp = currentItems[idx + 1];
              currentItems[idx + 1] = currentItems[idx];
              currentItems[idx] = tmp;
              refreshGrid();
            },
          })
        )
      );
    });
    cardsContainer.replaceChildren(...slotNodes);
  }

  refreshGrid();

  showModal(
    `👁️ Informants — Reorder Top ${currentItems.length} of ${pendReorder.label}`,
    el(
      "div",
      {},
      el("p", {
        style: { fontSize: "0.88rem", color: "var(--text-main)", marginTop: "0" },
        text: "Inspect the top items below and use the ◀ Move Earlier / Move Later ▶ buttons to arrange them in any order (#1 will be drawn or revealed first).",
      }),
      cardsContainer,
      el(
        "div",
        { style: { display: "flex", justifyContent: "flex-end", marginTop: "1rem" } },
        el("button", {
          type: "button",
          className: "btn btn-primary",
          text: "✓ Put Back in This Order",
          onClick: () => {
            closeModal();
            sendGameAction({
              type: "reorder_top_3",
              orderedIds: currentItems.map((it) => it.id),
            });
          },
        })
      )
    )
  );
}

function openMarketSourceModal(gs, viewer) {
  const infSelect = el(
    "select",
    { className: "form-input" },
    ...(viewer.influence || []).map((c) =>
      el("option", { value: c.id, text: `${c.name} — ${getInfluenceCardEffectText(c)}` })
    )
  );
  const goodSelect = el(
    "select",
    { className: "form-input" },
    ...(gs.sourceableGoods || []).map((g) =>
      el("option", {
        value: g.id,
        text: `${g.name} (${g.track} • ${g.blocks || 1}■${g.combatText ? ` • ${g.combatText}` : ""} • Buy: ${g.buy.join("/")})`,
      })
    )
  );

  showModal(
    "📦 Source a Good onto the Ostia Market",
    el(
      "div",
      {},
      el("p", {
        style: { fontSize: "0.86rem", color: "var(--text-muted)" },
        text: "Discard 1 Influence card from your hand to search the Market deck and push a chosen Good onto Column 1 (<<) of its Market Track.",
      }),
      el("div", { className: "form-group" }, el("label", { text: "1. Select Influence Card to Discard" }), infSelect),
      el("div", { className: "form-group" }, el("label", { text: "2. Select Good from Market Deck" }), goodSelect),
      el("button", {
        className: "btn btn-primary",
        text: "Confirm Market Source",
        onClick: () => {
          closeModal();
          sendGameAction({
            type: "market_source",
            influenceCardId: infSelect.value,
            goodCardId: goodSelect.value,
          });
        },
      })
    )
  );
}

function openGambleModal(viewer) {
  if (viewer.gambledThisTurn) {
    showToast("You can only gamble once per turn.", true);
    return;
  }
  if (viewer.transactedThisTurn) {
    showToast("You have already completed your Transaction for this turn.", true);
    return;
  }
  const maxBet = Math.min(20, Math.max(1, Number(viewer.cash) || 0));
  const betInput = el("input", {
    className: "form-input",
    type: "number",
    min: "1",
    max: String(maxBet),
    value: String(Math.min(5, maxBet)),
  });
  const matchFixingCard = (viewer.influence || []).find((c) => c.name === "Match Fixing");
  const isMatchFixingActive = Boolean(viewer.turnEffects && viewer.turnEffects.matchFixing);
  let gambleSubmitted = false;

  const rollBtn = el("button", {
    className: "btn btn-primary",
    text: "Roll the Rome Die 🎲",
    onClick: () => {
      if (gambleSubmitted) return;
      const clampedBet = Math.min(maxBet, Math.max(1, Math.floor(Number(betInput.value) || 1)));
      gambleSubmitted = true;
      rollBtn.disabled = true;
      closeModal();
      sendGameAction({ type: "delivery_gamble", bet: clampedBet });
    },
  });

  showModal(
    "🎲 Stadium Gambling at the Games",
    el(
      "div",
      {},
      el("p", {
        style: { fontSize: "0.86rem", color: "var(--text-muted)" },
        text: "Wager between 𐆖1 and 𐆖20 (max 𐆖20 per gamble action, once per turn). Roll 1 Rome Die (faces: 0, 0, I, I, II, III) and receive Wager × Roll!",
      }),
      isMatchFixingActive
        ? el("div", {
          style: {
            padding: "0.45rem 0.65rem",
            background: "#ecfdf5",
            border: "1.5px solid #16a34a",
            borderRadius: "6px",
            color: "#14532d",
            fontSize: "0.82rem",
            fontWeight: "700",
            marginBottom: "0.65rem",
          },
          text: "✓ 'Match Fixing' Active: +1(R) Bonus Die will be added to your Gambling roll!",
        })
        : matchFixingCard
          ? el(
            "div",
            {
              style: {
                padding: "0.5rem 0.7rem",
                background: "rgba(34, 13, 62, 0.94)",
                border: "1.5px solid #b58d52",
                borderRadius: "6px",
                marginBottom: "0.7rem",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                gap: "0.5rem",
              },
            },
            el("span", {
              style: { fontSize: "0.8rem", color: "var(--gold-bright)", fontWeight: "600" },
              text: "🃏 Hold 'Match Fixing' (+1(R) to Gambling Roll):",
            }),
            el("button", {
              className: "btn btn-sm btn-primary",
              text: "Play 'Match Fixing'",
              onClick: async () => {
                closeModal();
                await sendGameAction({ type: "play_influence", cardId: matchFixingCard.id });
                const updatedViewer =
                  appState.gameState && appState.gameState.players
                    ? appState.gameState.players[appState.gameState.viewerPlayerIndex || 0]
                    : null;
                if (updatedViewer && !updatedViewer.gambledThisTurn) openGambleModal(updatedViewer);
              },
            })
          )
          : null,
      el(
        "div",
        { className: "form-group" },
        el("label", { text: `Wager Amount (Max 𐆖${maxBet} — Cap 𐆖20 • Treasury: 𐆖${viewer.cash})` }),
        betInput
      ),
      rollBtn
    )
  );
}

function openScoutModal(gs, _viewer) {
  const isEntryPhase = gs.phase === "delivery_entry";
  const cellSelect = el(
    "select",
    { className: "form-input" },
    ...Object.keys(gs.romeBoard).map((coord) =>
      el("option", {
        value: coord,
        selected: coord === appState.inspectedCell,
        text: `${coord} — ${gs.romeBoard[coord].name} (${gs.romeBoard[coord].stackCount ?? 12} unrevealed)`,
      })
    )
  );

  const encounterDeckSpecs = [
    { key: "celebrities", label: "Celebrities", img: "/assets/icons/card_back_celebrities.png?v=111" },
    { key: "criminals", label: "Criminals", img: "/assets/icons/card_back_criminals.png?v=111" },
    { key: "cops", label: "Cops", img: "/assets/icons/card_back_cops.png?v=111" },
  ];

  showModal(
    isEntryPhase
      ? "👁️ Pre-Night Initial Scout (Before Selecting Gate)"
      : "👁️ Scout Action (Ends Turn)",
    el(
      "div",
      {},
      !isEntryPhase
        ? el("p", {
          style: { fontSize: "0.82rem", color: "var(--text-muted)", marginTop: "0", marginBottom: "0.75rem" },
          text: "Committing to your Scout action immediately advances the turn so the next merchant in sequence can begin while you examine the scouted card or tile.",
        })
        : null,
      el(
        "div",
        { style: { marginBottom: "1.1rem" } },
        el("div", {
          style: { fontWeight: "700", color: "var(--gold-bright)", fontSize: "0.9rem", marginBottom: "0.25rem" },
          text: "Option A: Tap an Encounter Card Deck to Scout Its Top Card",
        }),
        el("div", {
          style: { fontSize: "0.8rem", color: "var(--text-muted)", marginBottom: "0.5rem" },
          text: "Select from the Celebrities, Criminals, or Cops decks below by tapping directly on its card back:",
        }),
        renderDeckCardBackPickerGrid(
          gs,
          encounterDeckSpecs,
          (dk) => {
            closeModal();
            sendGameAction({
              type: isEntryPhase ? "initial_scout" : "delivery_scout",
              targetType: "deck",
              targetKey: dk,
            });
          },
          "👆 Tap Deck to Scout"
        )
      ),
      el(
        "div",
        {
          style: {
            paddingTop: "0.85rem",
            borderTop: "1px solid var(--border-subtle)",
          },
        },
        el(
          "div",
          { className: "form-group" },
          el("label", {
            style: { fontWeight: "700", color: "var(--gold-bright)" },
            text: "Option B: Peek at Top Unrevealed Tile of a Neighborhood Stack",
          }),
          cellSelect
        ),
        el("button", {
          type: "button",
          className: "btn btn-primary",
          style: { width: "100%" },
          text: "👁️ Scout Selected Neighborhood Stack",
          onClick: () => {
            closeModal();
            if (isEntryPhase) {
              sendGameAction({ type: "initial_scout", targetType: "tile", cell: cellSelect.value });
            } else {
              sendGameAction({ type: "delivery_scout", targetType: "tile", targetKey: cellSelect.value });
            }
          },
        })
      )
    )
  );
}

function openTrashModal(gs, viewer) {
  const infSelect = el(
    "select",
    { className: "form-input" },
    ...(viewer.influence || []).map((c) => el("option", { value: c.id, text: c.name }))
  );
  const cellSelect = el(
    "select",
    { className: "form-input" },
    ...Object.keys(gs.romeBoard).map((coord) =>
      el("option", { value: coord, selected: coord === appState.inspectedCell, text: `${coord} — ${gs.romeBoard[coord].name}` })
    )
  );
  const encounterDeckSpecs = [
    { key: "celebrities", label: "Celebrities", img: "/assets/icons/card_back_celebrities.png?v=111" },
    { key: "criminals", label: "Criminals", img: "/assets/icons/card_back_criminals.png?v=111" },
    { key: "cops", label: "Cops", img: "/assets/icons/card_back_cops.png?v=111" },
  ];

  showModal(
    "🗑️ Trash Action (Discard 1 Influence to Bury Top Tile or Card)",
    el(
      "div",
      {},
      el("div", { className: "form-group" }, el("label", { text: "1. Influence Card to Discard" }), infSelect),
      el(
        "div",
        { style: { marginBottom: "1rem" } },
        el("div", {
          style: { fontWeight: "700", color: "var(--gold-bright)", fontSize: "0.86rem", marginBottom: "0.35rem" },
          text: "Option A: Tap an Encounter Deck to Bury Its Top Card",
        }),
        renderDeckCardBackPickerGrid(
          gs,
          encounterDeckSpecs,
          (dk) => {
            closeModal();
            sendGameAction({
              type: "delivery_trash",
              influenceCardId: infSelect.value,
              targetType: "deck",
              targetKey: dk,
            });
          },
          "🗑️ Tap to Bury Top"
        )
      ),
      el(
        "div",
        { style: { paddingTop: "0.8rem", borderTop: "1px solid var(--border-subtle)" } },
        el("div", { className: "form-group" }, el("label", { text: "Option B: Target Neighborhood Tile Stack" }), cellSelect),
        el("button", {
          type: "button",
          className: "btn btn-crimson",
          style: { width: "100%" },
          text: "🗑️ Bury Top Tile to Bottom of Stack",
          onClick: () => {
            closeModal();
            sendGameAction({
              type: "delivery_trash",
              influenceCardId: infSelect.value,
              targetType: "tile",
              targetKey: cellSelect.value,
            });
          },
        })
      )
    )
  );
}

/* =========================================================================
   PLAYER PROFILE, CUSTOMIZABLE HOTKEYS, & SETTINGS VIEW
   ========================================================================= */

export { openFaceUpTileUpCloseModal, openConfirmScoutNeighborhoodModal, openNpcOfferModal, openMarketRewardModal, renderScoutedMarketCardPreview, openScoutResultModal, openLoadCargoPromptModal, openDeliverCargoPromptModal, openCancelMissionConfirmModal, openProcurerGoodModal, doesItemFitWithoutSwap, describeSUVItemDiscardWarning, openSUVReplacementModal, triggerMissionCargoLoadWithOverflow, triggerInfluenceCardPlay, openPendingSUVOverflowModal, openProphecyTargetModal, openSurpriseShipmentModal, renderDeckCardBackPickerGrid, openInformantsTargetModal, openTop3ReorderModal, openMarketSourceModal, openGambleModal, openScoutModal, openTrashModal };
