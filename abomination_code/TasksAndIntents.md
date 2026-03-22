This document is going to act as the central guide for the task system. 

Every type of action an NPC might take falls into five different categories: 

1) Emergency Tasks
2) High Priority Tasks
3) Normal Priority Tasks
4) Low Priority Tasks
5) Idle State Behavior

All NPCs are also assigned to a daily schedule, set in the Chronicle of Time. Activity types include (but are not limited to):

A) Sleep
B) Eat
C) Work
D) Leisure

Every minute in game time, determine what each NPC should be doing by performing the following test:

I) What activity type is the NPC assigned to in the Chronicle of Time?

A) Sleep

0) Is the NPC in the process of consuming a meal? If so, the NPC should continue consuming the meal until it is finished.

1) If the NPC is not in the process of consuming a meal, is the NPC responding to an Emergency? If so, check to see if the Emergency is resolved. If not, the NPC should perform the next minute of activity related to the Emergency response.

2) If the NPC is not responding to an emergency, check to see if the NPC has any Emergency Tasks. If so, the NPC begins responding to the top Emergency Task in the Emergency queue, performing the first minute of activity related to that emergency. 

3) If the NPC is not responding to an Emergency, and there are no Emergency Tasks, check to see if the NPC is already performing a high priority action. If so, check to see if the high priority action is resolved or no longer available. If not, the NPC should perform the next minute of activity related to the high priority action.

4) If the NPC is not responding to an emergency, there are no Emergency Tasks, and the NPC is not performing a high priority action, check to see if the NPC has any high priority actions enqueued. If so, the NPC should proceed with performing the first minute of the top action in the high priority queue, if possible.

5) If the NPC is not responding to an emergency, there are no Emergency Tasks, the NPC is not performing a high priority action, and there are no high priority tasks, check to see if the NPC is presently sleeping (Resting). If so, the NPC should continue sleeping until the NPC's scheduled wake up time. 

6) If the NPC is not responding to an emergency, there are no Emergency Tasks, the NPC is not performing a high priority action, there are no high priority tasks, and the NPC is not presently sleeping, check to see if the NPC is presently traveling to sleep. If so, the NPC should continue traveling to sleep until the NPC reaches their assigned bed. 

B) Eat

0) Is the NPC in the process of consuming a meal? If so, the NPC should continue consuming the meal until it is finished.

1) If the NPC is not in the process of consuming a meal, is the NPC responding to an Emergency? If so, check to see if the Emergency is resolved. If not, the NPC should perform the next minute of activity related to the Emergency response.

2) If the NPC is not responding to an emergency, check to see if the NPC has any Emergency Tasks. If so, the NPC begins responding to the top Emergency Task in the Emergency queue, performing the first minute of activity related to that emergency. 

3) If the NPC is not responding to an Emergency, and there are no Emergency Tasks, check to see if the NPC is already performing a high priority action. If so, check to see if the high priority action is resolved or no longer available. If not, the NPC should perform the next minute of activity related to the high priority action.

4) If the NPC is not responding to an emergency, there are no Emergency Tasks, and the NPC is not performing a high priority action, check to see if the NPC has any high priority actions enqueued. If so, the NPC should proceed with performing the first minute of the top action in the high priority queue, if possible.

5) If the NPC is not responding to an emergency, there are no Emergency Tasks, the NPC is not performing a high priority action, and there are no high priority tasks, check to see if the NPC is presently performing an "Activity Related to Eating". If so, the NPC should perform the next minute of "Activity Related to Eating" until the meal is finished. 

6) If the NPC is not responding to an emergency, there are no Emergency Tasks, the NPC is not performing a high priority action, there are no high priority tasks, and the NPC is not presently performing an "Activity Related to Eating", check to see if the NPC is presently traveling to perform an Activity Related to Eating. If so, the NPC should continue traveling until the NPC reaches their destination. 


C) Work

0) Is the NPC in the process of consuming a meal? If so, the NPC should continue consuming the meal until it is finished.

1) If the NPC is not in the process of consuming a meal, is the NPC responding to an Emergency? If so, check to see if the Emergency is resolved. If not, the NPC should perform the next minute of activity related to the Emergency response.

2) If the NPC is not responding to an emergency, check to see if the NPC has any Emergency Tasks. If so, the NPC begins responding to the top Emergency Task in the Emergency queue, performing the first minute of activity related to that emergency. 

3) If the NPC is not responding to an Emergency, and there are no Emergency Tasks, check to see if the NPC is already performing a high priority action. If so, check to see if the high priority action is resolved or no longer available. If not, the NPC should perform the next minute of activity related to the high priority action.

4) If the NPC is not responding to an emergency, there are no Emergency Tasks, and the NPC is not performing a high priority action, check to see if the NPC has any high priority actions enqueued. If so, the NPC should proceed with performing the first minute of the top action in the high priority queue, if possible.

5) If the NPC is not responding to an emergency, there are no Emergency Tasks, the NPC is not performing a high priority action, and there are no high priority tasks, check to see if the NPC is presently performing a Normal Priority Assignment. If so, the NPC should perform the next minute of activity related to the Normal Priority Assignment until the work is finished. 

6) If the NPC is not responding to an emergency, there are no Emergency Tasks, the NPC is not performing a high priority action, there are no high priority tasks, and the NPC is not presently performing a Normal Priority Assignment, check to see if the NPC is presently traveling to perform a Normal Priority Assignment. If so, the NPC should continue traveling until the NPC reaches their destination. 

7) If the NPC is not responding to an emergency, there are no Emergency Tasks, the NPC is not performing a high priority action, there are no high priority tasks, and there are no normal priority tasks, check to see if the NPC has any normal priority tasks enqueued. If so, the NPC should proceed with performing the first minute of the top action in the normal priority queue, if possible.

8) If the NPC is not responding to an emergency, there are no Emergency Tasks, the NPC is not performing a high priority action, there are no high priority tasks, and there are no normal priority tasks, check to see if the NPC's schedule says the NPC should be working. If so, check to see if the NPC is already traveling to or performing a Low Priority work task. If so, check to see if the low priority task is resolved or no longer available. If not, the NPC should perform the next minute of activity related to the low priority work task. Else, the NPC should perform the top Low Priority work task in the Low Priority work queue.

9) If the NPC is not responding to an emergency, there are no Emergency Tasks, the NPC is not performing a high priority action, there are no high priority tasks, the NPC is not performing a normal priority action, there are no normal priority tasks, the NPC is not performing a low priority action, and there are no low priority tasks, the NPC should perform an Idle State Behavior. 
  a) the main character's idle state behavior is to wander the manor, read in the library, or idle about in the garden.
  b) Flaubert Giles' idle state behavior is to stand at attention in the Entry or to idle about in the chicken coop. 


D) Leisure

0) Is the NPC in the process of consuming a meal? If so, the NPC should continue consuming the meal until it is finished.

1) If the NPC is not in the process of consuming a meal, is the NPC responding to an Emergency? If so, check to see if the Emergency is resolved. If not, the NPC should perform the next minute of activity related to the Emergency response.

2) If the NPC is not responding to an emergency, check to see if the NPC has any Emergency Tasks. If so, the NPC begins responding to the top Emergency Task in the Emergency queue, performing the first minute of activity related to that emergency. 

3) If the NPC is not responding to an Emergency, and there are no Emergency Tasks, check to see if the NPC is already performing a high priority action. If so, check to see if the high priority action is resolved or no longer available. If not, the NPC should perform the next minute of activity related to the high priority action.

4) If the NPC is not responding to an emergency, there are no Emergency Tasks, and the NPC is not performing a high priority action, check to see if the NPC has any high priority actions enqueued. If so, the NPC should proceed with performing the first minute of the top action in the high priority queue, if possible.

5) If the NPC is not responding to an emergency, there are no Emergency Tasks, the NPC is not performing a high priority action, there are no high priority tasks, check to see if the NPC is presently performing a Low Priority Leisure action. If so, check to see if the action is resolved or no longer available. If not, the NPC should perform the next minute of activity related to the Low Priority Leisure action.

6) If the NPC is not responding to an emergency, there are no Emergency Tasks, the NPC is not performing a high priority action, there are no high priority tasks, and the NPC is not performing a low priority leisure action, check to see if the NPC has any low priority leisure actions enqueued. If so, the NPC should proceed with performing the first minute of the top action in the low priority queue, if possible.

7) If the NPC is not responding to an emergency, there are no Emergency Tasks, the NPC is not performing a high priority action, there are no high priority tasks, the NPC is not performing a low priority leisure action, and there are no low priority leisure actions enqueued, the NPC should perform an Idle State Behavior. 
  a) the main character's idle state behavior is to wander the manor, read in the library, or idle about in the garden.
  b) Flaubert Giles' idle state behavior is to stand at attention in the Entry or to idle about in the chicken coop. 