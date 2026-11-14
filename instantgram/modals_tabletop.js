import { COLS, ROWS, FACTION_META, EDGE_LABELS, parseTollAmount, formatEdgeLabel, getTiberBridgeName, isTiberCrossingBlocked, renderSUVIconNode, appState, replaceDenariiTokens, createMoveActionCircleNode, createTransactionActionCircleNode, resolveGoodTrackClass, el, formatTileModifier, renderFullGoodCardFaceNode, getInfluenceCardEffectText, formatHostileFavorPenaltyText, showToast, closeModal, showModal } from "./core_ui.js?v=120";
import { renderDynamicTileCardNode, renderPhysicalMissionCardNode, renderPhysicalInfluenceCardNode, renderPhysicalEncounterCardNode, sendGameAction, armDieCardAction } from "./app.js?v=120";

const GOOD_CATEGORY_DISPLAY_MAP = {
  Grain: "Weed",
  Weed: "Weed",
  Marble: "Party",
  Party: "Party",
  Animals: "Uppers",
  Uppers: "Uppers",
  "Meat Animals": "Pill Uppers",
  "Exotic Animals": "Powder Uppers",
  Wine: "Opiates",
  Opiates: "Opiates",
  "Cheap Wine": "Street Opiates",
  "Fine Wine": "Pharma Opiates",
  Weapons: "Weapons",
  Henchmen: "Henchmen",
};

const FACTION_GEM_ICON_MAP = {
  MAGA: "/assets/icons/ruby.png",
  ISIS: "/assets/icons/emerald.png",
  TECH: "/assets/icons/diamond.png",
  DSA: "/assets/icons/sapphire.png",
  MS13: "/assets/icons/amethyst.png",
};

function renderDynamicTileBackNode(coord, cell) {
  const colIdx = Math.max(0, COLS.indexOf(String(coord || "B1").slice(0, 1)));
  const rowIdx = Math.max(0, ROWS.indexOf(String(coord || "B1").slice(1)));
  const bgPosX = `${(colIdx / 5) * 100}%`;
  const bgPosY = `${(rowIdx / 5) * 100}%`;
  const stackCnt = cell
    ? Number(
      cell.stackCount !== undefined
        ? cell.stackCount
        : cell.unrevealedCount !== undefined
          ? cell.unrevealedCount
          : 12
    )
    : 12;

  return el(
    "div",
    {
      className: "dyn-tile-back",
      style: { backgroundPosition: `${bgPosX} ${bgPosY}` },
    },
    el("div", { className: "cell-neighborhood-title", text: cell ? cell.name : coord }),
    el(
      "div",
      {
        style: {
          background: "rgba(22, 9, 41, 0.9)",
          color: "#ff6ec7",
          padding: "3px 10px",
          borderRadius: "6px",
          fontSize: "0.74rem",
          fontWeight: "800",
          border: "1px solid #38bdf8",
          boxShadow: "0 2px 6px rgba(0,0,0,0.45)",
        },
      },
      `Face-Down Stack: ${stackCnt} Tile${stackCnt === 1 ? "" : "s"}`
    )
  );
}

function createStackWatermarkIconNode(kind) {
  const k = String(kind || "").trim();
  const kLow = k.toLowerCase();
  if (kLow === "criminals" || kLow === "nefarii") {
    return el("img", {
      className: "tile-watermark-img",
      src: "/assets/icons/criminals_icon.png?v=120",
      alt: "Criminals",
    });
  }
  if (kLow === "celebrities" || kLow === "patricii") {
    return el("img", {
      className: "tile-watermark-img",
      src: "/assets/icons/celebrities_icon.png?v=120",
      alt: "Celebrities",
    });
  }
  if (kLow === "cops" || kLow === "legiones") {
    return el("img", {
      className: "tile-watermark-img",
      src: "/assets/icons/cops_icon.png?v=120",
      alt: "Cops",
    });
  }
  if (FACTION_GEM_ICON_MAP[k]) {
    return el("img", {
      className: "tile-watermark-img is-gem-watermark",
      src: FACTION_GEM_ICON_MAP[k],
      alt: k,
    });
  }

  const svgNS = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(svgNS, "svg");
  svg.setAttribute("viewBox", "0 0 48 48");
  svg.setAttribute("class", "tile-watermark-svg");
  svg.setAttribute("aria-hidden", "true");

  const mkEl = (tag, attrs) => {
    const node = document.createElementNS(svgNS, tag);
    for (const [attrK, attrV] of Object.entries(attrs)) {
      node.setAttribute(attrK, String(attrV));
    }
    return node;
  };

  if (k === "Grain" || k === "Weed") {
    const c = "#4ade80";
    // Cannabis leaf / bud silhouette
    svg.appendChild(mkEl("path", { d: "M24 6 C26.5 14 27 21 24 31 C21 21 21.5 14 24 6 Z", fill: c }));
    svg.appendChild(mkEl("path", { d: "M10 14 C16 17 21 22 23.5 31 C16 26 12 21 10 14 Z", fill: c }));
    svg.appendChild(mkEl("path", { d: "M38 14 C32 17 27 22 24.5 31 C32 26 36 21 38 14 Z", fill: c }));
    svg.appendChild(mkEl("path", { d: "M6 27 C13 26 19 28 23.5 32.5 C16 33.5 10 31.5 6 27 Z", fill: c }));
    svg.appendChild(mkEl("path", { d: "M42 27 C35 26 29 28 24.5 32.5 C32 33.5 38 31.5 42 27 Z", fill: c }));
    svg.appendChild(mkEl("rect", { x: "22.6", y: "30", width: "2.8", height: "12", rx: "1.2", fill: c }));
  } else if (k === "Marble" || k === "Party") {
    const c = "#f472b6";
    // Martini / coupe glass + party sparkle
    svg.appendChild(mkEl("path", { d: "M10 11 H38 L24 27 Z", fill: c }));
    svg.appendChild(mkEl("rect", { x: "22.5", y: "25", width: "3", height: "13", fill: c }));
    svg.appendChild(mkEl("rect", { x: "15", y: "37", width: "18", height: "3.5", rx: "1.6", fill: c }));
    svg.appendChild(mkEl("circle", { cx: "33", cy: "7.5", r: "2.4", fill: "#38bdf8" }));
  } else if (k === "Animals" || k === "Uppers" || k === "Meat Animals" || k === "Exotic Animals") {
    const c = "#fb923c";
    // Angled capsule pill + lightning energy bolt
    svg.appendChild(
      mkEl("rect", {
        x: "11",
        y: "17",
        width: "26",
        height: "14",
        rx: "7",
        transform: "rotate(-32 24 24)",
        fill: c,
      })
    );
    svg.appendChild(
      mkEl("path", {
        d: "M26 9 L18 23 H24 L21 39 L31 23 H25 Z",
        fill: "#fde047",
      })
    );
  } else if (k === "Wine" || k === "Opiates" || k === "Cheap Wine" || k === "Fine Wine") {
    const c = "#c084fc";
    // Vial bottle / poppy capsule silhouette
    svg.appendChild(mkEl("rect", { x: "19", y: "7", width: "10", height: "4", rx: "1.5", fill: c }));
    svg.appendChild(mkEl("rect", { x: "20.5", y: "11", width: "7", height: "4", fill: c }));
    svg.appendChild(
      mkEl("path", {
        d: "M16 15 H32 L34 22 V38 C34 40.5 32 42 29.5 42 H18.5 C16 42 14 40.5 14 38 V22 Z",
        fill: c,
      })
    );
  } else if (k === "Weapons") {
    const c = "#94a3b8";
    // Compact semi-auto handgun silhouette
    svg.appendChild(
      mkEl("path", {
        d: "M8 14 H37 C39 14 40 15.2 40 17 V22 C40 23.2 39 24 37.5 24 H24 L21 38 C20.6 39.5 19.2 40.5 17.5 40.5 H12.5 C11 40.5 10.2 39.3 10.6 37.8 L13.8 24 H8 C6.8 24 6 23 6 21.8 V16 C6 14.8 6.8 14 8 14 Z",
        fill: c,
      })
    );
  } else if (k === "Henchmen") {
    const c = "#38bdf8";
    // Security / Muscle silhouette with sunglasses
    svg.appendChild(mkEl("circle", { cx: "24", cy: "15", r: "7.2", fill: c }));
    svg.appendChild(mkEl("rect", { x: "18", y: "13", width: "12", height: "3.2", rx: "1", fill: "#0f172a" }));
    svg.appendChild(
      mkEl("path", {
        d: "M10 41 C10 30 15.5 24.5 24 24.5 C32.5 24.5 38 30 38 41 Z",
        fill: c,
      })
    );
  }
  return svg;
}

function renderOverlayCountBadgeNode({ iconKind, remaining, total, label, title, compact = false }) {
  const remNum = Number(remaining ?? 0);
  const totNum = Number(total ?? remNum);
  const ratioStr = `${remNum}/${totNum}`;
  return el(
    "div",
    {
      className: `tile-watermark-badge${compact ? " is-compact" : ""}`,
      title: title || `${label}: ${remNum} remaining of ${totNum} total`,
      "data-hover-title": title || `${label}: ${remNum} remaining of ${totNum} total`,
    },
    el(
      "div",
      { className: "tile-watermark-glyph" },
      createStackWatermarkIconNode(iconKind),
      el("span", { className: "tile-watermark-count", text: ratioStr })
    ),
    el("span", { className: "tile-watermark-label", text: label })
  );
}

function renderTileStackWatermarkSection(coord, cell) {
  const stats = (cell && cell.stackStats) || null;
  if (!stats) return null;

  const topBuys = Array.isArray(stats.topBuys) ? stats.topBuys : [];
  const buyNodes = topBuys.map((entry) => {
    const rawCat = entry.category || "Grain";
    const shortLbl = GOOD_CATEGORY_DISPLAY_MAP[rawCat] || replaceDenariiTokens(rawCat);
    const rem = Number(entry.remaining ?? entry.count ?? 0);
    const tot = Number(entry.total ?? entry.count ?? rem);
    return renderOverlayCountBadgeNode({
      iconKind: rawCat,
      remaining: rem,
      total: tot,
      label: shortLbl,
      title: `${shortLbl}: ${rem} unrevealed tile(s) remaining out of ${tot} total tiles in ${coord} stack that buy ${shortLbl}`,
    });
  });

  const encStats = stats.encounters || {};
  const encSpecs = [
    { key: "criminals", label: "Criminals" },
    { key: "celebrities", label: "Celebrities" },
    { key: "cops", label: "Cops" },
  ];
  const encNodes = encSpecs.map((spec) => {
    const entry = encStats[spec.key] || {};
    const rem = typeof entry === "number" ? entry : Number(entry.remaining ?? 0);
    const tot = typeof entry === "number" ? entry : Number(entry.total ?? rem);
    return renderOverlayCountBadgeNode({
      iconKind: spec.key,
      remaining: rem,
      total: tot,
      label: spec.label,
      title: `${spec.label}: ${rem} icon(s) remaining in unrevealed stack out of ${tot} total ${spec.label} icons across all tiles in ${coord}`,
    });
  });

  return el(
    "div",
    { className: "tile-stack-watermarks-box" },
    el(
      "div",
      { className: "tile-stack-watermarks-header" },
      el("span", { text: "Top 3 Purchased Goods (Rem/Total)" }),
      el("span", { text: "Stack Encounter Icons (Rem/Total)" })
    ),
    el(
      "div",
      { className: "tile-stack-watermarks-strip" },
      el(
        "div",
        { className: "tile-stack-watermarks-group" },
        ...(buyNodes.length > 0
          ? buyNodes
          : [el("span", { style: { fontSize: "0.74rem", color: "var(--text-muted)", alignSelf: "center" }, text: "No Buyers in Stack" })])
      ),
      el("div", { className: "tile-stack-watermarks-divider", "aria-hidden": "true" }),
      el("div", { className: "tile-stack-watermarks-group" }, ...encNodes)
    )
  );
}

/**
 * Unified Tile Interaction Window:
 * Shows a full-sized version of the tile (face up if the tile is face up on the board, otherwise face down),
 * counts of the 3 most purchased goods on that tile (remaining/total over the good icon),
 * counts of total number of deck encounter icons of each type in the entire tile stack (remaining/total over the encounter icon),
 * and all tile/deck/turn interaction controls.
 */
function openFaceUpTileUpCloseModal(gs, viewer, coord, cell, tileData = null, moveOpts = null) {
  const cellName = cell ? cell.name : coord;
  const isCurrent = Boolean(viewer && viewer.position === coord && !viewer.exitedRome);
  const occupants = ((gs && gs.players) || []).filter((p) => p.position === coord && !p.exitedRome);
  const exposedTile = (cell && cell.revealed) || null;
  const scoutedTile = !exposedTile && tileData ? tileData : null;
  const unrevealedCount = cell
    ? Number(
      cell.stackCount !== undefined
        ? cell.stackCount
        : cell.unrevealedCount !== undefined
          ? cell.unrevealedCount
          : 12
    )
    : 0;

  let resolvedMoveOpts = moveOpts;
  if (!resolvedMoveOpts && gs && viewer && viewer.position && viewer.position !== coord && gs.romeBoard) {
    const currCellObj = gs.romeBoard[viewer.position];
    const currOutDirs = (currCellObj && currCellObj.revealed && currCellObj.revealed.outgoingDirections) || {};
    for (const [dir, dInfo] of Object.entries(currOutDirs)) {
      if (dInfo && dInfo.targetCell === coord) {
        const riverBlocked = Boolean(dInfo.blockedByRiver) || isTiberCrossingBlocked(viewer.position, coord);
        const passable = !riverBlocked && (dInfo.passable || (viewer.turnEffects && viewer.turnEffects.shortcut));
        resolvedMoveOpts = {
          moveDir: passable ? dir : null,
          adjInfo: { dir, ...dInfo },
        };
        break;
      }
    }
  }

  const isEntryPhase = Boolean(gs && gs.phase === "delivery_entry");
  const isDeliveryPhase = Boolean(gs && gs.phase === "delivery");
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
  const canTrashThisTile = Boolean(
    !isEntryPhase &&
    isDeliveryPhase &&
    isMyTurn &&
    !viewer.trashedThisTurn &&
    Array.isArray(viewer.influence) &&
    viewer.influence.length > 0 &&
    (exposedTile || unrevealedCount > 0)
  );
  const moveDir = resolvedMoveOpts && resolvedMoveOpts.moveDir ? String(resolvedMoveOpts.moveDir) : null;
  const adjInfo = (resolvedMoveOpts && resolvedMoveOpts.adjInfo) || null;
  const canMoveStep = Boolean(
    !isEntryPhase &&
    isDeliveryPhase &&
    isMyTurn &&
    moveDir &&
    Number(viewer.movesRemaining || 0) > 0
  );
  const canMoveHere = Boolean(canMoveStep || isGateEntrance);
  const canEndTurnHere = Boolean(!isEntryPhase && isDeliveryPhase && isMyTurn);

  const unusedMoves =
    isMyTurn && !isEntryPhase && isDeliveryPhase && viewer.position
      ? Math.max(0, Number(viewer.movesRemaining || 0))
      : 0;
  const unusedTransactions =
    isMyTurn && !isEntryPhase && isDeliveryPhase && viewer.position && !viewer.transactedThisTurn ? 1 : 0;

  let crossingNote = "";
  if (adjInfo && viewer && viewer.position && viewer.position !== coord) {
    const dir = adjInfo.dir || moveDir || "";
    const shortcutActive = Boolean(viewer.turnEffects && viewer.turnEffects.shortcut);
    const bridgeName = adjInfo.bridgeName || adjInfo.bridge || getTiberBridgeName(viewer.position, coord);
    const tollAmt = !shortcutActive ? parseTollAmount(adjInfo.edge) : 0;
    const isHazard =
      !shortcutActive &&
      tollAmt <= 0 &&
      Boolean(adjInfo.edge && !["green", "red", "None"].includes(String(adjInfo.edge)));
    if (shortcutActive && !adjInfo.passable) {
      crossingNote = `Crossing ${dir} via ✨ Shortcut.`;
    } else if (tollAmt > 0) {
      crossingNote = `Crossing ${dir}${bridgeName ? ` (${bridgeName})` : ""} — Fast Pass / Toll: ${tollAmt}(d).`;
    } else if (isHazard) {
      crossingNote = `Crossing ${dir}${bridgeName ? ` (${bridgeName})` : ""} — Edge Encounter: ${formatEdgeLabel(adjInfo.edge)}.`;
    } else if (bridgeName) {
      crossingNote = `Crossing ${dir} across ${bridgeName} (Open Route).`;
    } else if (adjInfo.passable) {
      crossingNote = `Crossing ${dir} via Open Route.`;
    }
  }

  const activeInfoTile = exposedTile || scoutedTile || null;
  const sellsStr =
    activeInfoTile && Array.isArray(activeInfoTile.sells) && activeInfoTile.sells.length > 0
      ? activeInfoTile.sells.map((s) => `${s.category} (${formatTileModifier(s.modifier)})`).join(", ")
      : "None";
  const buysStr =
    activeInfoTile && Array.isArray(activeInfoTile.buys) && activeInfoTile.buys.length > 0
      ? activeInfoTile.buys.map((b) => `${b.category} (${formatTileModifier(b.modifier)})`).join(", ")
      : null;
  const centerParts = activeInfoTile
    ? [
      activeInfoTile.encounter ? formatEdgeLabel(activeInfoTile.encounter) : "No Center Encounter",
      activeInfoTile.gamble ? "Gambling Den (≤20(d))" : null,
      activeInfoTile.persistent ? "Persistent (⤹)" : activeInfoTile.refresh ? "Refresh (↻)" : "Standard Tile",
    ].filter(Boolean)
    : [];

  const tilePreviewSlot = el(
    "div",
    { style: { width: "260px", maxWidth: "100%", margin: "0 auto" } },
    exposedTile
      ? renderDynamicTileCardNode(exposedTile, coord, "inspector")
      : renderDynamicTileBackNode(coord, cell)
  );

  let showingScoutedFace = false;
  const scoutToggleBtn =
    !exposedTile && scoutedTile
      ? el("button", {
        type: "button",
        className: "btn btn-sm",
        text: "👁️ Show Scouted Top Tile Face",
        onClick: () => {
          showingScoutedFace = !showingScoutedFace;
          scoutToggleBtn.textContent = showingScoutedFace
            ? "🔒 Show Face-Down Tile Back"
            : "👁️ Show Scouted Top Tile Face";
          tilePreviewSlot.replaceChildren(
            showingScoutedFace
              ? renderDynamicTileCardNode(scoutedTile, coord, "inspector")
              : renderDynamicTileBackNode(coord, cell)
          );
        },
      })
      : null;

  const unusedIndicatorItems = [];
  if (unusedMoves > 0) {
    unusedIndicatorItems.push(
      el(
        "span",
        {
          style: { display: "inline-flex", alignItems: "center", gap: "0.28rem", fontWeight: "800", fontSize: "0.78rem", color: "#f8fafc" },
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
          style: { display: "inline-flex", alignItems: "center", gap: "0.28rem", fontWeight: "800", fontSize: "0.78rem", color: "#f8fafc" },
          title: `${unusedTransactions} unused Transaction action remaining this turn`,
        },
        createTransactionActionCircleNode(),
        el("span", { text: `×${unusedTransactions}` })
      )
    );
  }

  const moveBtnLabel = isGateEntrance
    ? `🚪 Enter at ${cellName} (${coord})`
    : moveDir
      ? `🚙 Move to ${cellName} (${moveDir})`
      : `🚙 Move to ${cellName}`;

  const centerEncounterKey =
    exposedTile && exposedTile.encounter
      ? String(exposedTile.encounter).split("_")[0].toLowerCase()
      : null;

  showModal(
    `${isGateEntrance ? "🚪" : "🔍"} Tile ${coord} — ${cellName}`,
    el(
      "div",
      { style: { display: "flex", flexDirection: "column", alignItems: "center", gap: "0.75rem" } },
      el(
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
        el("span", {
          className: "badge",
          style: exposedTile
            ? { borderColor: "#ff6ec7", background: "rgba(34, 13, 62, 0.94)", color: "#ff6ec7", fontWeight: "800" }
            : { borderColor: "#38bdf8", background: "rgba(14, 42, 84, 0.92)", color: "#7dd3fc", fontWeight: "700" },
          text: exposedTile
            ? `Exposed Face-Up Tile (${unrevealedCount} Face-Down in Stack)`
            : `Face-Down Tile (${unrevealedCount} Unrevealed in Stack)`,
        }),
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
        ),
        scoutToggleBtn
      ),
      tilePreviewSlot,
      renderTileStackWatermarkSection(coord, cell),
      el(
        "div",
        {
          style: {
            width: "100%",
            padding: "0.6rem 0.8rem",
            borderRadius: "6px",
            background: "rgba(34, 13, 62, 0.94)",
            border: "1.5px solid #a88d6b",
            boxShadow: "var(--bevel-sunken)",
            fontSize: "0.82rem",
            display: "flex",
            flexDirection: "column",
            gap: "0.22rem",
          },
        },
        el(
          "div",
          {},
          el("strong", { style: { color: "var(--gold-bright)" }, text: "Neighborhood: " }),
          `${coord} — ${cellName}${isCurrent ? " (Your Current Tile)" : ""}`
        ),
        activeInfoTile
          ? el("div", {}, el("strong", { style: { color: "var(--gold-bright)" }, text: exposedTile ? "Buys: " : "Scouted Top Tile Buys: " }), sellsStr)
          : null,
        buysStr ? el("div", {}, el("strong", { style: { color: "#38bdf8" }, text: "Market Sells: " }), buysStr) : null,
        centerParts.length > 0
          ? el(
            "div",
            {},
            el("strong", { style: { color: "var(--gold-bright)" }, text: "Properties: " }),
            centerParts.join(" • ")
          )
          : null,
        crossingNote
          ? el("div", {
            style: {
              marginTop: "0.2rem",
              paddingTop: "0.22rem",
              borderTop: "1px solid rgba(255, 110, 199, 0.35)",
              fontWeight: "700",
              color: "#ff6ec7",
            },
            text: replaceDenariiTokens(crossingNote),
          })
          : null
      ),
      el(
        "div",
        {
          style: {
            width: "100%",
            display: "flex",
            gap: "0.75rem",
            flexWrap: "wrap",
            justifyContent: "space-between",
            alignItems: "flex-end",
            paddingTop: "0.65rem",
            borderTop: "1px solid var(--border-subtle)",
          },
        },
        el(
          "div",
          {
            style: {
              display: "flex",
              gap: "0.5rem",
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
              ? `Move your SUV to ${coord} (${cellName})`
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
                ? `Scout the top face-down tile of ${coord} before entering San Francisco`
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
              ? "Scout the top card of any of the 6 decks"
              : "Scout Deck Card is unavailable (already scouted or not your turn)",
            text: "🃏 Scout Deck Card",
            onClick: () => {
              if (!canScoutDeck) return;
              closeModal();
              openScoutModal(gs, viewer);
            },
          }),
          !isEntryPhase && isDeliveryPhase
            ? el("button", {
              id: "modal-trash-tile-btn",
              type: "button",
              className: "btn",
              disabled: !canTrashThisTile,
              title: canTrashThisTile
                ? exposedTile
                  ? `Discard 1 Influence card to trash the face-up tile on ${coord}`
                  : `Discard 1 Influence card to bury the top unrevealed tile of ${coord}`
                : "Trash Tile is unavailable (already trashed this turn, no Influence cards, or not your turn)",
              text: exposedTile ? "🗑️ Trash Face-Up Tile" : "🗑️ Bury Stack Tile",
              onClick: () => {
                if (!canTrashThisTile) return;
                closeModal();
                openTrashModal(gs, viewer, {
                  cell: coord,
                  targetMode: exposedTile ? "revealed" : "stack",
                });
              },
            })
            : null,
          el("button", {
            id: "modal-encounter-decks-btn",
            type: "button",
            className: "btn",
            title: "Open Decks Interface (Celebrities, Criminals, Cops, Goods, Jobs & Influence)",
            text: "🃏 Decks",
            onClick: () => openEncounterDecksOverviewModal(gs, centerEncounterKey),
          })
        ),
        el(
          "div",
          {
            style: {
              display: "flex",
              flexDirection: "column",
              alignItems: "flex-end",
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
                title: "Unused Move and/or Transaction actions remaining this turn",
              },
              el("span", {
                style: { fontSize: "0.68rem", fontWeight: "800", textTransform: "uppercase", letterSpacing: "0.04em", color: "#ff6ec7" },
                text: "Unused:",
              }),
              ...unusedIndicatorItems
            )
            : null,
          el(
            "div",
            { style: { display: "flex", gap: "0.45rem", alignItems: "center" } },
            el("button", {
              id: "modal-end-turn-btn",
              type: "button",
              className: "btn btn-crimson",
              disabled: !canEndTurnHere,
              title: canEndTurnHere
                ? "End your hourly turn"
                : "End Turn is unavailable when it is not your turn",
              text: "⏭️ End Turn",
              onClick: () => {
                if (!canEndTurnHere) return;
                closeModal();
                sendGameAction({ type: "delivery_end_turn" });
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
      )
    )
  );
}

function openConfirmScoutNeighborhoodModal(gs, viewer, coord, cell, moveOpts = null) {
  let scoutedTopTile = null;
  if (viewer && Array.isArray(viewer.scoutedInfo)) {
    for (const si of viewer.scoutedInfo) {
      if (si && si.targetType === "tile" && si.targetKey === coord && si.revealedData) {
        scoutedTopTile = si.revealedData;
      }
    }
  }
  return openFaceUpTileUpCloseModal(gs, viewer, coord, cell, scoutedTopTile, moveOpts);
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
  const canFence = m.source === "encounter" && Array.isArray(m.fencedSell) && m.fencedSell.length >= 5;

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
    showToast("Canceling or failing a Schizophrenic job is impossible unless you already have 5 active Schizophrenic jobs and trigger a 6th!", true);
    return;
  }

  const cargoWarning = m.pickedUp
    ? `⚠️ Because you have already picked up "${m.item || "the delivery cargo"}", canceling this job will throw the item away (it cannot be sold).`
    : null;

  let ruleExplanation = "";
  if (src === "encounter") {
    const hList = formatHostileFavorPenaltyText(m);
    ruleExplanation = `Per the rulebook, canceling or failing an Encounter Job incurs its Thumbs-Down reputational consequences (${hList}).`;
  } else if (src === "schizophrenic") {
    ruleExplanation = "Because you hold 6 active Schizophrenic jobs (after triggering a 6th), you must fail one of your Schizophrenic jobs to return to the 5-job limit.";
  } else {
    ruleExplanation = "Per the rulebook, Starting Jobs can be canceled voluntarily at any time with no Favor penalty.";
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
      sell: m.source === "encounter" ? m.fencedSell : null,
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
          discardSUVIds,
          fireHenchmanIds,
          discardCartIds: discardSUVIds,
          fireGuardIds: fireHenchmanIds,
        });
      },
    });
    return;
  }

  if ((cName.includes("Fentanyl Press") || cName.includes("Wine Forger")) && viewer && !doesItemFitWithoutSwap(viewer, { reqBlocks: 1 })) {
    openSUVReplacementModal(viewer, {
      itemType: "good",
      incomingCard: {
        name: "Pressed Fentanyl",
        category: "Opiates",
        subcategory: "Counts as any Opiate",
        track: "Opiates",
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
          discardSUVIds,
          fireHenchmanIds,
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
  const queue = (viewer && (viewer.pendingSUVOverflow || viewer.pendingCartOverflow)) || [];
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
        text: "Trigger a Schizophrenic encounter for any player (including yourself or a rival dealer).",
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
  const tracks = ["Party", "Opiates", "Uppers", "Weapons", "Weed"];
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

const ALL_PICKER_DECK_SPECS = [
  {
    key: "celebrities",
    label: "Celebrities",
    subtitle: "Tech Founders, A-Listers & VIPs",
    defaultTotal: 30,
    img: "/assets/icons/card_back_celebrities.png?v=120",
    shortDesc: "High-society patrons & influencers; rewards favor with Jobs, Cash, and Influence.",
  },
  {
    key: "criminals",
    label: "Criminals",
    subtitle: "Syndicates, Boosters & Street Crews",
    defaultTotal: 29,
    img: "/assets/icons/card_back_criminals.png?v=120",
    shortDesc: "Underworld crews & fences; risky shakedowns or black-market deals and shortcuts.",
  },
  {
    key: "cops",
    label: "Cops",
    subtitle: "SFPD, DEA, Feds & Task Forces",
    defaultTotal: 30,
    img: "/assets/icons/card_back_cops.png?v=120",
    shortDesc: "Law enforcement checkpoints; contraband sweeps, fines, and combat threats.",
  },
  {
    key: "market",
    label: "Goods",
    subtitle: "Weed, Party, Uppers, Opiates, Weapons & Henchmen",
    defaultTotal: 112,
    img: "/assets/icons/card_back_goods.png?v=120",
    shortDesc: "Next Cargo, Weapon, or Henchman card drawn into the Wholesale Market tracks.",
  },
  {
    key: "missions",
    label: "Jobs",
    subtitle: "Deliveries, Drops, Hits & Contracts",
    defaultTotal: 56,
    img: "/assets/icons/card_back_missions.png?v=120",
    shortDesc: "Next Delivery, Sale, or Contract Job card drawn.",
  },
  {
    key: "influence",
    label: "Influence",
    subtitle: "Burner Apps, Bribes, Tips & Schemes",
    defaultTotal: 43,
    img: "/assets/icons/card_back_influence.png?v=120",
    shortDesc: "Next tactical Influence card drawn or purchased at Dawn.",
  },
];

const DEFAULT_FACTION_DECK_TOTALS = {
  celebrities: { MAGA: 3, ISIS: 4, TECH: 6, DSA: 9, MS13: 4 },
  cops: { MAGA: 11, ISIS: 4, TECH: 6, DSA: 3, MS13: 4 },
  criminals: { MAGA: 3, ISIS: 6, TECH: 4, DSA: 6, MS13: 7 },
};

const DEFAULT_GOODS_TRACK_TOTALS = [
  { track: "Weed", label: "Weed", total: 16 },
  { track: "Party", label: "Party", total: 16 },
  { track: "Uppers", label: "Uppers", total: 24 },
  { track: "Opiates", label: "Opiates", total: 24 },
  { track: "Weapons", label: "Weapons", total: 16 },
  { track: "Henchmen", label: "Henchmen", total: 16 },
];

function renderDeckSubCountsStripNode(gs, deckKey) {
  const dk = String(deckKey || "").toLowerCase();
  if (dk === "celebrities" || dk === "criminals" || dk === "cops") {
    const fCounts = (gs && gs.factionDeckCounts) || {};
    const fTotalsByDeck = (gs && gs.encounterDeckFactionTotals && gs.encounterDeckFactionTotals[dk]) || DEFAULT_FACTION_DECK_TOTALS[dk] || {};
    const factionOrder = ["MAGA", "ISIS", "TECH", "DSA", "MS13"];
    const badges = factionOrder.map((fKey) => {
      const fEntry = fCounts[fKey] || {};
      const tot = Number(
        fEntry[`${dk}Total`] !== undefined
          ? fEntry[`${dk}Total`]
          : fTotalsByDeck[fKey] !== undefined
            ? fTotalsByDeck[fKey]
            : 0
      );
      const rem = Number(fEntry[dk] !== undefined ? fEntry[dk] : tot);
      return renderOverlayCountBadgeNode({
        iconKind: fKey,
        remaining: rem,
        total: tot,
        label: fKey,
        title: `${fKey} loyalty in ${dk.charAt(0).toUpperCase() + dk.slice(1)} deck: ${rem} remaining out of ${tot} total`,
        compact: true,
      });
    });
    return el("div", { className: "deck-subcounts-strip is-five-col" }, ...badges);
  }

  if (dk === "market" || dk === "goods") {
    const rawCats =
      gs && Array.isArray(gs.goodsDeckCategoryCounts) && gs.goodsDeckCategoryCounts.length > 0
        ? gs.goodsDeckCategoryCounts
        : DEFAULT_GOODS_TRACK_TOTALS.map((d) => ({
          track: d.track,
          label: d.label,
          remaining: d.total,
          total: d.total,
        }));
    const badges = rawCats.map((entry) => {
      const rem = Number(entry.remaining ?? entry.total ?? 0);
      const tot = Number(entry.total ?? rem);
      const lbl = entry.label || GOOD_CATEGORY_DISPLAY_MAP[entry.track] || entry.track;
      return renderOverlayCountBadgeNode({
        iconKind: entry.track,
        remaining: rem,
        total: tot,
        label: lbl,
        title: `${lbl} in Goods deck: ${rem} remaining out of ${tot} total`,
        compact: true,
      });
    });
    return el("div", { className: "deck-subcounts-strip is-six-col" }, ...badges);
  }

  return null;
}

function renderDeckCardBackPickerGrid(gs, deckSpecs, onSelectDeck, tapPillLabel = "👆 Tap Deck to Scout") {
  const counts = (gs && gs.deckCounts) || {};
  const totalCounts = (gs && gs.deckTotalCounts) || {};
  const specsToUse = Array.isArray(deckSpecs) && deckSpecs.length > 0 ? deckSpecs : ALL_PICKER_DECK_SPECS;
  return el(
    "div",
    { className: "scout-decks-grid" },
    ...specsToUse.map((spec) => {
      const rem = typeof counts[spec.key] === "number" ? counts[spec.key] : spec.defaultTotal ?? 0;
      const tot = typeof totalCounts[spec.key] === "number" ? totalCounts[spec.key] : spec.defaultTotal ?? rem;
      const countText = `${rem}/${tot} cards`;
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
                background: "radial-gradient(circle at 50% 35%, #4c1d4b, #1d0c24)",
                border: "3px double #d4af37",
                color: "#fef08a",
              },
            },
            el("div", { style: { fontSize: "1.6rem" }, text: spec.icon || "🃏" }),
            el("div", {
              style: { fontFamily: "Cinzel, Georgia, serif", fontWeight: "800", fontSize: "0.8rem", letterSpacing: "0.06em" },
              text: spec.label.toUpperCase(),
            })
          )
        );

      const subCountsNode = renderDeckSubCountsStripNode(gs, spec.key);

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
        subCountsNode,
        el("div", { className: "scout-deck-tap-pill", text: tapPillLabel })
      );
    })
  );
}

function openEncounterDecksOverviewModal(gs, focusDeck = null) {
  const viewer =
    gs && Array.isArray(gs.players)
      ? gs.players[gs.viewerPlayerIndex ?? gs.activePlayerIndex ?? 0]
      : null;
  const counts = (gs && gs.deckCounts) || {};
  const totalCounts = (gs && gs.deckTotalCounts) || {};
  const normalizedFocus = focusDeck ? String(focusDeck).trim().toLowerCase() : null;

  const isEntryPhase = Boolean(gs && gs.phase === "delivery_entry");
  const isDeliveryPhase = Boolean(gs && gs.phase === "delivery");
  const isMyTurn = Boolean(
    gs &&
    viewer &&
    gs.activePlayerIndex === viewer.index &&
    (isEntryPhase || isDeliveryPhase) &&
    !viewer.exitedRome &&
    !viewer.nightEnded &&
    !gs.pendingEncounter
  );
  const canScoutDeck = Boolean(isMyTurn && !viewer.scoutedThisTurn);
  const canTrashDeck = Boolean(
    !isEntryPhase &&
    isDeliveryPhase &&
    isMyTurn &&
    !viewer.trashedThisTurn &&
    Array.isArray(viewer.influence) &&
    viewer.influence.length > 0
  );
  const wiretapCard =
    viewer && Array.isArray(viewer.influence)
      ? viewer.influence.find((c) => {
        const code = String(c.effectCode || "").toLowerCase();
        const nm = String(c.name || "").toLowerCase();
        const txt = String(c.effectText || "").toLowerCase();
        return code.startsWith("reorder_top_3") || nm.includes("wiretap") || nm.includes("informant") || txt.includes("look at the top three");
      })
      : null;
  const canReorderDeck = Boolean(isDeliveryPhase && isMyTurn && wiretapCard);

  showModal(
    "🃏 InstantGram SF Decks Interface — Encounter, Goods, Jobs & Influence Decks",
    el(
      "div",
      {},
      el("p", {
        style: { fontSize: "0.84rem", color: "var(--text-main)", marginTop: "0", marginBottom: "0.75rem" },
        text: "Inspect live remaining/total card counts across all 6 decks. Each Encounter deck shows its 5 faction loyalty counts (MAGA, ISIS, TECH, DSA, MS13), and the Goods deck shows its 6 category counts (Weed, Party, Uppers, Opiates, Weapons, Henchmen). You can also Scout, Trash/Bury, or Wiretap (Inspect & Reorder Top 3) any deck directly from here.",
      }),
      el(
        "div",
        { className: "encounter-deck-profiles-grid" },
        ...ALL_PICKER_DECK_SPECS.map((spec) => {
          const dk = spec.key;
          const rem = typeof counts[dk] === "number" ? counts[dk] : spec.defaultTotal ?? 0;
          const tot = typeof totalCounts[dk] === "number" ? totalCounts[dk] : spec.defaultTotal ?? rem;
          const isFocused = normalizedFocus === dk;
          const subCountsNode = renderDeckSubCountsStripNode(gs, dk);

          return el(
            "div",
            { className: `encounter-deck-profile-card ${isFocused ? "is-active" : ""}` },
            el(
              "div",
              { className: "encounter-deck-profile-head" },
              el("img", {
                className: "encounter-deck-profile-thumb",
                src: spec.img,
                alt: `${spec.label} Deck Card Back`,
              }),
              el(
                "div",
                { style: { flex: "1 1 auto" } },
                el("div", { className: "encounter-deck-profile-title", text: spec.label }),
                el("div", {
                  className: "encounter-deck-profile-sub",
                  text: `${rem}/${tot} cards remaining`,
                }),
                spec.subtitle
                  ? el("div", {
                    style: { fontSize: "0.7rem", color: "var(--text-muted)", marginTop: "1px" },
                    text: spec.subtitle,
                  })
                  : null
              )
            ),
            spec.shortDesc
              ? el("div", {
                style: { fontSize: "0.74rem", color: "var(--text-main)", lineHeight: "1.32" },
                text: spec.shortDesc,
              })
              : null,
            subCountsNode,
            el(
              "div",
              {
                style: {
                  display: "flex",
                  gap: "0.35rem",
                  flexWrap: "wrap",
                  marginTop: "auto",
                  paddingTop: "0.35rem",
                },
              },
              el("button", {
                type: "button",
                className: canScoutDeck && rem > 0 ? "btn btn-sm btn-primary" : "btn btn-sm",
                disabled: !canScoutDeck || rem <= 0,
                title: canScoutDeck
                  ? `Scout the top card of the ${spec.label} deck`
                  : "Scout unavailable (already scouted or not your turn)",
                text: "👁️ Scout Top",
                onClick: () => {
                  if (!canScoutDeck || rem <= 0) return;
                  closeModal();
                  sendGameAction({
                    type: isEntryPhase ? "initial_scout" : "delivery_scout",
                    targetType: "deck",
                    targetKey: dk,
                  });
                },
              }),
              el("button", {
                type: "button",
                className: "btn btn-sm",
                disabled: !canTrashDeck || rem <= 0,
                title: canTrashDeck
                  ? `Discard 1 Influence card to bury the top card of the ${spec.label} deck`
                  : "Trash unavailable (already trashed, no Influence cards, or not your turn)",
                text: "🗑️ Bury Top",
                onClick: () => {
                  if (!canTrashDeck || rem <= 0) return;
                  closeModal();
                  openTrashModal(gs, viewer, { deckKey: dk });
                },
              }),
              wiretapCard
                ? el("button", {
                  type: "button",
                  className: canReorderDeck && rem > 0 ? "btn btn-sm btn-primary" : "btn btn-sm",
                  disabled: !canReorderDeck || rem <= 0,
                  title: `Play "${wiretapCard.name}" to inspect and reorder the top 3 cards of the ${spec.label} deck`,
                  text: `🕵️ ${wiretapCard.name} Top 3`,
                  onClick: () => {
                    if (!canReorderDeck || rem <= 0) return;
                    closeModal();
                    sendGameAction({
                      type: "play_influence",
                      cardId: wiretapCard.id,
                      targetType: "deck",
                      targetKey: dk,
                    });
                  },
                })
                : null
            )
          );
        })
      ),
      el(
        "div",
        { style: { display: "flex", justifyContent: "flex-end", gap: "0.5rem", marginTop: "0.65rem" } },
        el("button", {
          type: "button",
          className: "btn btn-primary",
          text: "Close",
          onClick: closeModal,
        })
      )
    ),
    { wide: true }
  );
}

function openInformantsTargetModal(gs, _viewer, card) {
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
        text: "Look at the top three cards of any of the 6 decks (tap a deck below) or the top three tiles of any neighborhood stack and put them back in any order.",
      }),
      el(
        "div",
        { style: { marginBottom: "1rem" } },
        el("div", {
          style: { fontWeight: "700", color: "var(--gold-bright)", fontSize: "0.88rem", marginBottom: "0.35rem" },
          text: "Option A: Tap Any of the 6 Card Decks to Inspect & Reorder Its Top 3 Cards",
        }),
        renderDeckCardBackPickerGrid(
          gs,
          ALL_PICKER_DECK_SPECS,
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
    ),
    { wide: true }
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
    if (dk === "missions" || dk === "missiones" || dk === "jobs") {
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
    `👁️ Reorder Top ${currentItems.length} of ${pendReorder.label}`,
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
    "📦 Source a Good onto the Market",
    el(
      "div",
      {},
      el("p", {
        style: { fontSize: "0.86rem", color: "var(--text-muted)" },
        text: "Discard 1 Influence card from your hand to search the Goods deck and push a chosen Good onto Column 1 (<<) of its Market Track.",
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
    text: "Roll the Die 🎲",
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
    "🎲 Gambling at the Den",
    el(
      "div",
      {},
      el("p", {
        style: { fontSize: "0.86rem", color: "var(--text-muted)" },
        text: "Wager between 𐆖1 and 𐆖20 (max 𐆖20 per gamble action, once per turn). Roll 1 Die (faces: 0, 0, 1, 1, 2, 3) and receive Wager × Roll!",
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
        el("label", { text: `Wager Amount (Max 𐆖${maxBet} — Cap 𐆖20 • Cash: 𐆖${viewer.cash})` }),
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

  showModal(
    isEntryPhase
      ? "👁️ Pre-Night Initial Scout (Before Selecting Entry Point)"
      : "👁️ Scout Action (Ends Turn)",
    el(
      "div",
      {},
      !isEntryPhase
        ? el("p", {
          style: { fontSize: "0.82rem", color: "var(--text-muted)", marginTop: "0", marginBottom: "0.75rem" },
          text: "Committing to your Scout action immediately advances the turn so the next dealer in sequence can begin while you examine the scouted card or tile.",
        })
        : null,
      el(
        "div",
        { style: { marginBottom: "1.1rem" } },
        el("div", {
          style: { fontWeight: "700", color: "var(--gold-bright)", fontSize: "0.9rem", marginBottom: "0.25rem" },
          text: "Option A: Tap Any of the 6 Decks to Scout Its Top Card",
        }),
        el("div", {
          style: { fontSize: "0.8rem", color: "var(--text-muted)", marginBottom: "0.5rem" },
          text: "Select from Celebrities, Criminals, Cops, Goods, Jobs, or Influence below by tapping directly on its card back:",
        }),
        renderDeckCardBackPickerGrid(
          gs,
          ALL_PICKER_DECK_SPECS,
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
    ),
    { wide: true }
  );
}

function openTrashModal(gs, viewer, prefillOpts = null) {
  const infSelect = el(
    "select",
    { className: "form-input" },
    ...(viewer.influence || []).map((c) => el("option", { value: c.id, text: c.name }))
  );

  const initialCell =
    prefillOpts && prefillOpts.cell && gs.romeBoard[prefillOpts.cell]
      ? prefillOpts.cell
      : appState.inspectedCell || viewer.position || "B1";
  const preferredMode = prefillOpts && prefillOpts.targetMode === "stack" ? "stack" : "revealed";

  const cellSelect = el(
    "select",
    { className: "form-input" },
    ...Object.keys(gs.romeBoard).map((coord) => {
      const cObj = gs.romeBoard[coord];
      const occCnt = ((gs.players) || []).filter(
        (p) => p.position === coord && !p.exitedRome && !p.eliminated
      ).length;
      const statusTag = cObj.revealed
        ? occCnt > 0
          ? "Face-Up, Occupied"
          : "Face-Up, Unoccupied"
        : "Face-Down";
      return el("option", {
        value: coord,
        selected: coord === initialCell,
        text: `${coord} — ${cObj.name} (${statusTag}, ${cObj.stackCount ?? 12} in stack)`,
      });
    })
  );

  const cellStatusBox = el("div", { className: "trash-target-status-box" });
  const trashExposedBtn = el("button", {
    id: "trash-exposed-tile-btn",
    type: "button",
    className: "btn btn-crimson",
    text: "🗑️ Trash Face-Up Tile",
    onClick: () => {
      closeModal();
      sendGameAction({
        type: "delivery_trash",
        influenceCardId: infSelect.value,
        targetType: "tile",
        targetKey: cellSelect.value,
        targetMode: "revealed",
      });
    },
  });
  const trashStackBtn = el("button", {
    id: "trash-stack-tile-btn",
    type: "button",
    className: "btn",
    text: "🗑️ Bury Next Unrevealed Stack Tile",
    onClick: () => {
      closeModal();
      sendGameAction({
        type: "delivery_trash",
        influenceCardId: infSelect.value,
        targetType: "tile",
        targetKey: cellSelect.value,
        targetMode: "stack",
      });
    },
  });

  const refreshSelectedCellUi = () => {
    const coord = cellSelect.value;
    const cObj = (gs.romeBoard && gs.romeBoard[coord]) || null;
    const occNames = ((gs.players) || [])
      .filter((p) => p.position === coord && !p.exitedRome && !p.eliminated)
      .map((p) => p.name);
    const hasExposed = Boolean(cObj && cObj.revealed);
    const stackCnt = cObj ? Number(cObj.stackCount ?? 12) : 0;
    const revSummary =
      hasExposed && cObj.revealed
        ? [
          cObj.revealed.encounter ? `Center: ${formatEdgeLabel(cObj.revealed.encounter)}` : "No Center Encounter",
          Array.isArray(cObj.revealed.sells) && cObj.revealed.sells.length > 0
            ? `Buys: ${cObj.revealed.sells.map((s) => s.category).join(", ")}`
            : "No Buyers",
        ].join(" • ")
        : "";

    trashExposedBtn.disabled = !hasExposed;
    trashStackBtn.disabled = stackCnt <= 0;
    trashExposedBtn.className =
      hasExposed && preferredMode === "revealed" ? "btn btn-crimson" : "btn";
    trashStackBtn.className =
      (!hasExposed || preferredMode === "stack") && stackCnt > 0 ? "btn btn-crimson" : "btn";

    cellStatusBox.innerHTML = "";
    if (hasExposed) {
      cellStatusBox.appendChild(
        el("div", {
          style: { fontWeight: "700", marginBottom: "0.2rem", color: "#ff6ec7" },
          text: `${coord} (${cObj.name}) — Face-Up Tile (${revSummary})`,
        })
      );
      cellStatusBox.appendChild(
        el("div", {
          text:
            occNames.length > 0
              ? `Occupied by ${occNames.join(", ")}: trashing the face-up tile sends it to the bottom of the stack and IMMEDIATELY flips the next unrevealed tile face-up (${stackCnt} available).`
              : `Unoccupied: trashing the face-up tile sends it to the bottom of the stack and leaves ${coord} face-down until a dealer enters it.`,
        })
      );
    } else {
      cellStatusBox.appendChild(
        el("div", {
          text: `${coord} (${cObj ? cObj.name : coord}) currently has no face-up tile (${stackCnt} unrevealed tiles in stack). Use "Bury Next Unrevealed Stack Tile" to send the top face-down tile to the bottom.`,
        })
      );
    }
  };

  cellSelect.addEventListener("change", refreshSelectedCellUi);
  refreshSelectedCellUi();

  showModal(
    "🗑️ Trash Action (Discard 1 Influence to Trash Face-Up Tile or Bury Deck Card)",
    el(
      "div",
      {},
      el("div", { className: "form-group" }, el("label", { text: "1. Influence Card to Discard" }), infSelect),
      el(
        "div",
        { style: { paddingTop: "0.4rem", marginBottom: "1rem" } },
        el("div", { className: "form-group" }, el("label", { text: "Option A: Target Neighborhood Tile (Trash Face-Up Tile or Bury Unrevealed Tile)" }), cellSelect),
        cellStatusBox,
        el("div", { className: "trash-target-actions-grid" }, trashExposedBtn, trashStackBtn)
      ),
      el(
        "div",
        { style: { paddingTop: "0.8rem", borderTop: "1px solid var(--border-subtle)" } },
        el("div", {
          style: { fontWeight: "700", color: "var(--gold-bright)", fontSize: "0.86rem", marginBottom: "0.35rem" },
          text: "Option B: Tap Any of the 6 Decks to Bury Its Top Card to Bottom",
        }),
        renderDeckCardBackPickerGrid(
          gs,
          ALL_PICKER_DECK_SPECS,
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
      )
    ),
    { wide: true }
  );
}

/* =========================================================================
   PLAYER PROFILE, CUSTOMIZABLE HOTKEYS, & SETTINGS VIEW
   ========================================================================= */

export { renderDynamicTileBackNode, renderTileStackWatermarkSection, openEncounterDecksOverviewModal, openFaceUpTileUpCloseModal, openConfirmScoutNeighborhoodModal, openNpcOfferModal, openMarketRewardModal, renderScoutedMarketCardPreview, openScoutResultModal, openLoadCargoPromptModal, openDeliverCargoPromptModal, openCancelMissionConfirmModal, openProcurerGoodModal, doesItemFitWithoutSwap, describeSUVItemDiscardWarning, openSUVReplacementModal, triggerMissionCargoLoadWithOverflow, triggerInfluenceCardPlay, openPendingSUVOverflowModal, openProphecyTargetModal, openSurpriseShipmentModal, renderDeckCardBackPickerGrid, openInformantsTargetModal, openTop3ReorderModal, openMarketSourceModal, openGambleModal, openScoutModal, openTrashModal };
