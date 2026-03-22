# Abomination Playtesting Guide (Final Diagnostic)

This guide provides specific procedures for advancing through the initial setup and starting the game loop to diagnose game performance and identify bugs.

## 1. Initial Setup & Character Creation

Advance through each step every three seconds.

### Step 1: Initialize
- **URL**: `http://localhost:50699/` (or current active debug port)
- **Start**: Click the **"BEGIN EXPERIMENT"** button.

### Step 2: Character Narrative & Naming
- **Origin**: Select any origin (e.g., "TERRIBLE DISEASE").
- **Critical Interaction**: For the **"NEXT"** button, click exactly on the word **"NEXT"**. 
- **Setup Screens**: Advance through Name, Age, Butler Trait, Family Focus, and Science Interest. Always click the text of the buttons.

### Step 3: Entering the Manor
- Click **"BEGIN THE WORK"** to reach the main Manor View.

## 2. Starting the Simulation

### The Game Clock
- The simulation begins **PAUSED**.
- **Action**: Click the **Play button (>)** in the top HUD menu.
- **Verification**: Ensure the clock (e.g., 08:00) is ticking up (08:01, 08:02).
- **Time Scale**: Note that **2-5 game minutes** is only a few seconds in real time.

## 3. Diagnostic Observations

### Identifying "Zero Progress"
Most tasks are assigned automatically via the NPC's schedule (Work at 08:00).
1. Click on an NPC (e.g., **Flaubert Giles**) or open the **Residents Log** (top icon).
2. Look at the **Status Panel** for their current task.
3. Observe **`minutesRemaining`**:
    - **Success**: The number decreases (e.g., 120 -> 119) within 15-30 seconds of real-time play at Normal speed.
    - **Failure**: The clock is moving, but `minutesRemaining` is stuck (e.g., stays at 120 for several game minutes).

### Targeted Testing
Assign a manual task by dragging a Character or using the Room detail view:
- Open the Room detail view of the Library Room and assign **Frankenstein** to **Restore Room**.
- Open the Room detail view of the Unused Room and assign **Giles** to **Restore Room**.
- Verify that they arrive at the rooms and the tasks begin progressing.
- Open the Room detail view of Basement C and assign **Giles** to **Restore Room**.
- Open the Room detail view of Basement B and assign **Giles** to **Restore Room**.
- Open the Field detail view of Field A and assign **Frankenstein** to **Till Field**.
- Open the Field detail view of Field A and assign **Frankenstein** to **Fertilize Field**.

### Observe State
Select each character to examine the character's Status Card. Each Character/NPC's status card should have a list of tasks that they are currently performing and the tasks they have enqueued. There should be operational buttons that allow the player to cancel or reorder upcoming assignments. 


Characters should slowly deplete Fullness and slowly deplete Energy while awake. Sleeping characters should slowly regain Energy. Completing meal consumption should cause Fullness to increase. Digestion should progress gradually over time. The Use Toilet/Washroom action should cause Digestion to reset to 0. 

## 4. Reporting
Note if any specific task type (e.g., 'Till Field', 'Rest', 'Use Toilet/Washroom') hangs while others (e.g., 'Cook', 'Restore Room') work. Check the **Browser Console (F12)** for any `Uncaught Error` or `StateError` during the tick processing.
