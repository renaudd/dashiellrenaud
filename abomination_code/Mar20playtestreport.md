Playtest Bug Report
1. Fainted Residents Don't Stop Working (Critical)

Observation: Flaubert was marked as FAINTED (red avatar background and status indicator) but his physical body was simultaneously executing CLEAN ROOM (ENTRY).
Cause: When the NPC's energy hits 0, the logic flags the status to Fainted, but we are never forcibly clearing/canceling the activeTaskId to make them drop the broom before they hit the floor.
2. Simulation Auto-Pause at Midnight (Moderate)

Observation: The simulation completely auto-paused precisely at the rollover to March 2, 00:00 without user intervention.
Cause: There appears to be hardcoded breakpoint logic or midnight-event processing that improperly halts the engine without putting up a UI notification modal.
3. "Ghost Fire" Extinguish Logic (Major)

Observation: Alphonse was seen with a speech bubble declaring priorities for "FIGHT A BLAZE" despite no fire existing anywhere on the manor grid and no fires being reported in notifications.
Cause: Either the emergency intent queueing is being falsely tripped, or an old fire isn't properly cleaning up its task hooks after being extinguished.
4. Speech Bubbles Leaking Code Enumerations (Minor/UI)

Observation: Speech bubble strings over residents frequently include internal code like (ScheduleActivity.eat) or stringified enum values instead of human-readable thoughts.
Cause: The notification/thought generator is interpolating raw ScheduleActivity/TaskType enums without running them through a display string formatter.
5. Physical Location vs. System State Desync (Major)

Observation: Alphonse was physically located/rendered in the "Junior Bedroom" on the floor plan grid, but the backend Manor Log simultaneously insisted his active state was "REST (MASTER BEDROOM)".
Cause: The assignment system allows NPCs to physically path to any available bed, but the log or the task engine didn't properly update the target room string dynamically.