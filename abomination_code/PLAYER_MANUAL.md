# Abomination - Player Manual (Empirical Edition)

Welcome, Doctor. This manual defines the rigorous quantitative systems governing the manor. To master your legacy, you must understand the underlying calculations that drive every action.

---

## 1. The Science of Knowledge

Knowledge is quantified in **Knowledge Points (KP)**. All progression, unlocking, and discovery depend on the accumulation of KP in specific disciplines.

### The KP Formula
The total Knowledge Points contributed by any item stored in a room is determined by:
**`KP = Quantity * Quality * Type Multiplier`**

#### **Type Multipliers**
*   **Research Notes**: 1.0x
*   **Research Study**: 5.0x
*   **Research Book**: 10.0x
*   **Encyclopedia**: 50.0x

### Disciplines & Discovery
There are six core disciplines (Anatomy, Zoology, Medicine, Chemistry, Psychology, Alchemy). Unlocks occur when the manor's total KP in a discipline meets a threshold.

**Initial Discovery Requirements:**
*   **Basic Reanimation**: 1.0 KP Anatomy AND 1.0 KP Alchemy.
*   **Cryogenic Suspension**: 3.0 KP Alchemy.
*   **Artificial Muscle**: 2.0 KP Anatomy AND 2.0 KP Zoology.

---

## 2. Worker Attributes & Task Efficiency

Every worker has attributes (0-100 scale). These are converted to a **Base Efficiency (BE)** multiplier (0.0 to 1.0) for tasks.

### Task Calculations
*   **Research (Study)**: `BE = (Intelligence + Judgment + Perception) / 300`
    *   *Result*: Produces research notes with quality based on `BE`.
*   **Dissection**: `BE = (Intelligence / 100) * 0.5`
    *   *Result*: `BE` acts as a bonus to the base Anatomical Study quality.
*   **Cooking (Kitchen)**: `BE = (Hygiene + Perception + Dexterity + Intelligence) / 400`
    *   *Result*: Meal quality scaled to `BE * 2.0` (Range: 0.0 - 2.0).
*   **Cleaning/Restoration**: `BE = (Endurance + Hygiene + Temperament) / 300`
    *   *Result*: Final room cleanliness rated `BE * 2.0`. Higher BE increases specimen find rates.
*   **Farming (Fields)**: `BE = (Strength + Endurance + Temperament) / 300`
    *   *Result*: Yield and speed influenced by `BE`.

---

## 3. Combat Mechanics

Combat is a real-time tactical simulation governed by raw stats and Action Points (AP).

### Combat Values Defined
*   **Attack**: Raw offensive power before reduction.
*   **Defense**: A flat reduction applied to incoming damage.
*   **Damage Formula**: `Damage = max(1.0, Attacker Attack - Target Defense)`
    *   *Swarm Rule*: Damage against swarms is capped at `maxHealth / swarmSize` per hit.
*   **Accuracy**: The percentage chance (0.0 to 1.0) for an attack to land.
*   **Speed**: The interval between attacks. **Combat Tick Interval = `Stat Speed * 4.0` seconds.**
*   **Movement**: Physical speed across the grid.
    *   *Approach*: Units move at `Stat Movement * 0.25` m/s when closing distance.
    *   *General*: Units move at `Stat Movement * 0.5` m/s otherwise.
*   **Distance**: The maximum range (in meters) for an attack. Melee is typically < 1.0m.

### Action Points (AP)
AP is the universal resource for spawning units.
*   **Starting Buffer**: 6.0 AP.
*   **Maximum Capacity**: 10.0 AP.
*   **Generation Rate**: 0.15 AP per real-time second.

### Special Charges
Abilities of type `Special` charge over time:
**`Charge Increase = Elapsed Seconds / Stat ChargeTime`** (Typically 7-10 seconds)

---

## 4. Materials & Specimens

Specimens (Rats, Bats, Humans) are found through labor.
*   **Clean Room**: 4% - 8% base find rate.
*   **Restore Room**: 15% - 20% base find rate.
*   **Quality**: Heavier and older specimens provide a higher quality base for dissection, directly increasing KP output.
