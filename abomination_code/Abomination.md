I want to create a new game about being a mad scientist.

The game runs on a persistent game clock that can be paused, decelerated, or accelerated, at the player’s will. 

The game starts with the player inheriting his family manor in rural Switzerland in the 1860s. The player has one person still in the family’s employ, a butler and all-round henchman who can be disposed to virtually any task, but performs most rather slowly, and only sufficiently-well. 

The manor is large, but in a state of disrepair, and needs to be cleaned. 

In the course of simple tasks (like cleaning the cellar/belfry), there is a chance that the worker assigned to the task may have something happen, or may come away from the task having gained something more than completion of the specific assignment (like finding and retrieving a rat/bat). 

The player can study, dissect, and experiment on flora and fauna (and ultimately people) that come into the player’s possession. 

The player can assign his own character to tasks, and excels at study-experiment-based assignments. The player can accelerate these assignments by solving actual science/academic based puzzles and problems (acid-base redux reactions, binomial algebra, italian grammar). 

Look:

This is intended to be a mobile-based game, so imagine navigating the following through a Fallout Shelter / This War of Mine visual format:

The player can assign restored rooms toward various functions. But fundamentally the manor starts with the following rooms:

1) an entryway, where the butler stands at attention when idle, or when he has news for the player, and where visitors queue for the player’s attention. Speaks to the moral and financial health of the manor but otherwise is mostly superficial and can be adorned with the player’s collected art/trophies. 

2) A kitchen, where the assigned cook prepares meals for all the inhabitants of the manor. 

3) A dining room, where the player’s character and invited guests eat. 

4) A study, where the player performs basic study and research.

5) Master bedroom. The player’s bedroom.

6) Second bedroom.

7) Third bedroom.

8) Attic (Unused).

9) Basement. Three large rooms, all unused.

10) Primary toilet.

11) Secondary toilet.

12) Butler’s quarters.

13) Unused room.

Outside the manor, there is additionally:

1) A chicken coop

2) A tool shed

3) A small vegetable garden

4) Two rows of wine grapes

5) Empty fields that could be farmed or used for other purposes.

6) Location for a greenhouse that can be built. 

7) Two locations for buildings that can be built that can be stand alone workshops, tenement buildings, arsenals, or other types of buildings. 


NPCs:

NPCs come to the player looking for work, either because they live nearby or have come across the manor while fleeing war/persecution/hardship elsewhere. There is intended to be a somewhat regular trickle of people who come by the property who might be willing to move in/work under the right conditions.

The player should be able to try to court/marry female NPCs and start a family. The player may also have guests come stay at the manor and leave. 

But, true to the nature of the evil scientist game, the player might also kidnap and imprison NPCs, or lobotomize them and try to turn them into zombies who will do the player’s bidding. 

Ultimately the player will be able to raise corpses from the dead, including frankenstein-type reanimated monsters, possess NPCs with demons, create cyborgs, create cybernetically enhanced beasts like bears, wolves, tigers, lions. 


Combat:

Combat, when initiated, will work mostly like South Park Phone Destroyer (SPPD) / Star Wars: Force Arena, whereby all of the player’s and opponent’s units (up to 12) that make up a force engaged in a given skirmish are represented as cards that might be drawn into the player’s hand at random. Each card has a certain number of energy points required in order to bring it into combat. The player decides when and where to place cards into combat, but then the cards act mostly independently according to preset rules. 

The cards attempt to advance on the enemy’s avatar, who is locked to a specific location on the far end of the battlefield, but defends himself automatically against attacks. 

The side that is able to kill the other player’s avatar wins combat for the purposes of deciding who wins and loses combat. Generally losing combat does not entail the deaths of any of the player’s cards/NPCs, but there may be persistent injuries and even permanent deaths under certain circumstances. 

What makes this combat model different from SPPD is that the player will have a chance to design exactly how the mechanics of his units and monsters’ abilities will work. For example, one set of technological study can unlock freezing technology. And the player can get the resources needed to make a freezing weapon, and the resources/technology needed to make one of his NPCs immune to cold, thereby creating a unit with freezing ability that can be used on the battlefield, but the player can decide whether he wants the weapon to freeze everyone in a ring around the unit, freeze and injure everyone in a tight ring, freeze everyone in a beam, freeze everyone in the combat, or some other permutation. Whatever the player chooses will have tradeoffs in terms of: affecting the energy cost of the unit (a special weapon ability will increase a unit’s energy cost by one, but a super powerful special weapon will increase the energy cost by two), affecting the supplies needed to create/repair/provide ammunition for the weapon, the amount of damage the weapon causes, the length of the weapon’s effect, the length of time it takes for the ability to recharge. 


Management:

All of the NPCs can be assigned to given tasks, which they perform at their own direction, or the player can define the NPC’s entire schedule (the NPC must permit this, or the player’s character must have the requisite dominance/control over the NPC to assert this). 

NPCs working under duress may try to escape. 

NPCs have feelings towards one another that may be positive or negative and will interact with one another accordingly. 

Each NPC has a rich personality of wants, desires, hates, interests. The player has an opportunity to create a high-functioning manor of like-minded individuals working together to share the fruits of their collective labor in the form of wealth and delicious produce prepared as interesting meals, or the player can use merciless mercenaries or mindless zombies to chain all the employees and guests to their beds every night and make them work for scraps. 



Part 2, specific implementation notes:

+to hit modifiers
+instructions




Characters, in addition to all other metrics, also belong to a default group of A, B, C, or D, in decreasing order of likelihood. These are used to set default responses in situations where the character’s stats don’t otherwise govern, and can be used to assign events and plotpoints.

Standard reload rate is 2d3-2
Reloading is like leveling:
2 pts for bow, 5 points for simple pistol, 9 for full musket 


Armrpwr
Ignore 10x armrpwr hp
And damage reduced 10% x armrpwr

Wpnpwr
Add 15%xapnpwr hp to wpn attacks
If wpnpwr > armrpwr ; armrpwr—

Future Strength:
Melee attacks: -50+(strength *10%) damage

Strength (combat ability):
Likelihood to hit: base +str*10% chance of hitting  - defense of defender *10%
Chance of failure is base - 4% *str +defense of defender * 2%

Defense(evasion):



Exhaustion
Confidence
Panic

Psychologist can study your employees and provide you with insights 


Enemies encountered in the woods:
-German troops
-special op french troops
-deserter troops
-Swiss border patrol
-armed migrants 
-bandits
-unarmed migrants
-neighbor’s employees
-rivals
-hermits
-bears
-mountain lions
-game: deer, ibex, 
-cultists
-hunters
-panners
-miners
-trappers
-traders
-priests
-children


Core combat system:
	Positioning
	Fundamental 2d spectrum of range between player and opponent.
	Each range represents 10 ft ~ 5 m stretch of lateral distance.
	Player’s parties have a default walking order
Player can instruct specific walking order
		employees might prefer a certain position
		employees being fast or slow walkers might dictate a certain position
	Default 
pitched combat encounter has Player’s party in default layout, just outside shooting range of opponent’s party (4 ranges for short-range weapons, 6~+ ranges for long), also in default position.
melee confrontation encounter  has Player’s party in default layout, 2 ranges apart from opponent’s party, also in default position.
		
	Encounter scenarios will affect:
player and opponent position order.
Range distance.
Whether player’s and/or opponent’s characters will begin the round:
Hidden
Tired
Drunk
Alert
Panicked
Terrified
Exhausted
Weapons holstered
Weapons aimed
Maximum range occupancy
Visibility
Vertical Incline
Ground obstacles
Cover
Location-specific details:
Available items for pick up (stick, rock)
Types of cover (tree cover)
Types of ground obstacles (nettles)
Available actions (climb tree, fling branch)
		Movement:
			Player’s party members will generally have lateral advance and lateral retreat available as options by default. Human employees can generally advance once range without issue, two as a run (slight risk of failure and defense penalty), and sometimes even three, such as a charge and tackle move (opponent occupying the third range). A human moving four ranges in a single turn would be exceptional (require special augmentation).
			Combatant could have advance and retreat option restricted by:
				Scenario specific
				Physical Obstacle
				Mental state: 
Terror, Panic, Tired, Drunk, Asleep, Blind, Hallucinating
				Physical State:	
					Broken limb, unconscious, exhausted
				Range width at maximum occupancy
				Opponent is blocking advance/retreat
			Movement sped/hindered by incline:
				Downhill: +1 or even +2 range total distance if coming downhill
				Slight uphill: distance limited to 2 or 1
				Serious uphill: combatant can only move one, and combatant’s avatar does not move from the range occupied to the new range until the start of the combatanat’s next turn.
				Vertical ascent: combatant loses next turn to climb (possibly more)
				Serious vertical ascent: increase risk of fall/delay.


Turn Order:
Combatant turn order is assigned based on Initiative:
Alertness, vision, movement speed, vitality, innate initiative bonuses, scenario specific.
			Generally turn order is static once set, but certain effects could cause a combatant to go earlier or later in turn order (in addition to the possibility of completely losing turns)
			
Actions: 
2 fundamental move actions (almost always available):
Advance (select  
	1 (95%)
	2 (70%) - 5% chance of fall
	3 (15%) - 15% chance of fall
Retreat 
1 (95%)
	2 (70%) - 5% chance of fall
	3 (15%) - 15% chance of fall
			3 fundamental ranged weapon actions (if ranged weapon equipped):
				Load (can take multiple turns)
				Aim (select target) (first turn is 30% increase in accuracy, 2nd, 15%, 3rd, 8%)
				Fire (select target) (without aim, low accuracy and high chance of critical failure) 

			Fundamental Context-Specific Actions:
				Equip Weapon (select weapon) 
				Holster Weapon (select weapon)
				Shield (with shield or duck and cower)
				Take Cover (if cover is available)
				
			Randomized context-specific actions:
				Punch
				Kick
				Hide
				Aim From Cover
				Sneak forward
				Sneak backward
				Pick Up (rock)
				
				
Getting shot at reduces aim
Obstacles in range between player and target reduce aim
Opponent occupying same range generally reduces aim
Opponent melee attacking completely eliminates aim

Each turn the player is told the relative present bonus of a given attack (the combatant knows it has a shot, opportunity to strike, etc.)

			Extra random actions:
				Tackle
				Insult
			
Sample combatant specific random actions:
Lunge Attack
Snipe (Await movement)
Snipe (Await aim)
Haymaker
Uppercut
High Kick	


			Fundamental Follow Up Actions:
				Throw held item
				Sneak Melee
				Sneak Ranged
				Pummel

				


			


Potential uses for fields other than agriculture:
Pig farm
Golf course
Fairgrounds
Butcher
Church
Graveyard


The player can ultimately buy neighboring land and get access to the territory(ies) in the distance behind the fields within the player’s domain. 

Intro:

Parents have died. You’ve inherited the estate. It needs to be maintained.

2) pt 1:

Your first employee is the butler/servant/groundskeeper, he lives in a tiny static single room building on the front corner of the manor lot. He feeds and shelters himself, and is eternally loyal. You have sophisticated insight into what tasks he can perform and how good he is at them.

Pt 1 entails simple tasks of ordering the butler around:
Action ; potentially gathers
collect eggs
Plant cabbage
Water cabbage
Harvest cabbage
Till cabbage field
Cook cabbage
Cook eggs
Prepare chickens
Roast meat
Clean rooms 
Clean basements 
Clean attics
Tend garden 
Repair
Forage in woods
Hunt in woods; rabbits, pheasant, 
Fish on stream
Collect wood
Chop wood
Defend chickens; foxes
Defend cabbages; rabbits, rats, voles, crows, owls, jays

Pt 2 entails activities that the player can engage in directly:
Dissect 
Purchase order
Sell
Design
Invent
Research
Write 
Autopsy
Surgery
Schedule 
Manage (hire, fire, assign lodging, assign diet, assign pay)
Talk to
Manual task (build, farm, hunt, fish, mine)

Pt 3 entails learning about the world around you

There is a war going on (Franco-Prussian) and you’re in neutral territory (Switzerland). Refugees are pouring in that are desperate for lodging and opportunity.

Player is able to accept/refuse refugees as guests/employees and decide the terms:
lodging: in manor, in independent housing, in communal housing, barn (shack allowed), barn (no shack allowed), cell
Mattress: goose down mattress, straw mattress, hemp rope cot, bare floor
Covers: goose down duvet, linen, wool blanket, cotton sheets, rags, none
Breakfast: bacon, eggs, cake, bread, none
Lunch: roast meat, stewed vegetables, bread, none
Dinner: roast meat, stewed vegetables, bread, none
Narcotics: fine wine, fine Brandy, cocaine, wine, brandy, cannabis, coffee, tobacco, cheap wine, beer
Clothing:
Equipment:
Pay: 


Conditions options for refugees;
Guest, renter, captive, trespasser
Guest, employee, slave, fired
Gift, debt, indentured servitude, slavery, depossess 
Welcome if: lots of work, good work, behave, perform X, worship X, endorse X
Banned if: insufficient volume work, insufficient quality work, if does X, if worships X, if endorses X, if from X, if member of X faction


Starting stuff:
manor
Master bedroom 
Simple bed, wool blanket, poor insulation, one dresser, poor decorations
Room for additional dresser(s), desk, aquarium, fireplace, cabinet, bookshelf 
Decorations: wallpaper, curtains, chandelier, moulding, carpet, windows, lamps
Upgradable: bed, bedding, room size, desk, dresser
Guest bedrooms 
Two starting, can add third
Renovating manor creates space for as many as six stately guest rooms in the manor
Simple beds, wool sheets, poor insulation, one dresser, poor decorations 
Library
Desk, two bookshelf’s 
Room for: five more bookshelves (12 with upgrade), desks, tables, experiments (e.g. rat maze)
Laboratory
Simple operating table and equipment stand
Lamps, tables, cabinets, chemical equipment, cold storage, animal cages
Workshop
Workbench, tool cabinet
Anvil, lathe, grinder, mill, scales, cabinets, trunks, vehicle lift, fabrication projects (icarus wings)
Dining room
8 person table, decent china, silverware, poor chandelier, poor decorations 
Used for entertaining guests and local npcs (merchants, governors, clerics)
Kitchen
Sink, basic dishes and cookware, simple range
Cold storage, fine equipment, hand mixer
Used to evaluate food stores and assign diets
Estate
Chicken coop
Assign: Collect eggs, collect chickens, sentry
Actions, collect eggs/chickens, add chickens
Starts with: 4 chickens, room for 12, 24 with upgrade. 
Room for: incubator, insulation
Barn
Fields
Start: six fields on property; one cabbage field, two-field lake, one forested, two empty pasture hills. 
Six additional fields available for purchase in escalating value. The hillside parcels available for purchase are best fields in Barony for wine grapes.
Can use two fields of equal level to create an airfield. Some huge things, e.g. manufacturing plant could be four fields, or a stadium/race-course even six.
Topography goes low in the front, up a hill to the second row of fields, and then down the hill to the third row of fields, and is bounded by the river on the northern and eastern sides. The west and northwest is buyable territory, and comprises a larger hill, also bounded by the river.
Outside world 
Front right (East by southeast by default) road to the border. 
Guarded by military
Refugees pour in
Rarely merchants, clerics, inventors, dignitaries
Events in the war and outside world determine whether/how many/what kind of refugees come in.
Occasionally the canton will become engulfed in the War, reinforcements being sent to the border/construction of a wall/ temporsry loss of territory/invasion - all potential multi-season-spanning 
Front left (west by default) road to hamlet
Visitors come from town
Way to send things to market
Majority of deliveries come from this road 
Can use this road to go into town
Immediate right (East) woods
Wood is bountiful but game is scarce because of the war 
Also people trying to avoid the border may be there
Back to the right (East by northeast) river access 
Can reach nearby town by boat.
No boat initially
Can reach city (and beyond) if improvements are made on the river between the town and city 
Can reach neighboring country if canal is dug
Back and center right (northeast) Mountain
More forest
Hike, climb, hunt, forage
Can build mines
Center back (north) trail north 
Immediately borders neighboring barony (northern face of mountain by default)
Rare visitors and deliveries from this path 
Left center back to left front (west-north) rolling hills of arable land
Available for purchase by you or others
Hamlet
Sleepy border town with room to grow to significant hamlet. 
history that put it apart from both the neighboring countries and the local national culture, rather the culture of the nation on the country’s southern border (carrouge) 
Starting stuff
Tavern
Town square
Marketplace 
Meeting hall
Church 
Residences
3 blocks, room for 12
Two blocks: three large residences
One block: six small apartments 
Room for
Taverns
Places of worship 
Residences
Town square:
Town hall
Permanent marker
Park
Fairground
Factory
Farm
Cattle
Pig 
Restaurant
Store
Butcher
Bank
NPCs characteristics 
Age
Nationality
Ethnicity
Religion
Political faction
Gender
Languages 
Education 
Alive 
Right ear
Left ear
Right eye
Left eye
Right prefrontal
Left prefrontal
Cerebellum
Nose
Mouth
Hair
Height
Weight
Build
Intellect
Strength
Endurance 
Temperament 
Willpower
Libido
Greed
Guilt
Story
Skill ability
Skill experience 
Walk speed
Binaries
Violent
Forgetful
Lazy
Late
Slow
Fast
Clumsy
Depressed
Anxious
Suicidal
Homicidal
Slow eater 


NPCs basics
1 - Terms of welcome
2 - Assignments
3 - Schedule
4 - Relationships
5 - Story
6 - Goals
Raise x money
Learn x
Go to x
Become an x
Kill x
Protect x
Eat well
Sleep well

NPC Events
Kids
Bit by dog
Lost eye 
Mushroom poisoning
Fell through ice
Found X
Became interested in X
Developed taste for X
Got in fight with X
Mother dies
Father dies
Get pet
Pet runs away
Pet returns
Pet dies
Adults
Romance with
Workplace injury
Heart attack
Midlife crisis 

WORLD
 Helvecz
Based on Switzerland 



Combat: 


Wounds: Vitality 70+ 5 wounds, 60+ 4 wounds, 40+ 3 wounds, 30+ 2 wounds, 1+ 1 wound.

To Hit Melee: weapon ability x 3 * Area ability * energy * ~intelligence * confidence x 2 * ~vitality * ~mobility * special (e.g. expertise fighting enemy of this particular type) * random
 Against: hit location * ~visibility * enemy defense x 3 
Impact: weapon modifier * strength * random
  
To Hit Ranged: weapon ability x 3 * Area ability * ~intelligence * ~confidence * special (e.g., can’t shoot if blind) * random 
Against: hit location * visibility * enemy defense x 3
Flee: confidence * temptation *



Head: 
1) temp vitality and energy loss = impact of hit (standard recovery rate of 1/turn)  {{*1.5? rounded up? Remainder goes to Vitality?}}
2) Chance of the following: {{melee}}
if impact 8+:
	.07:: knocked out
 	.13:: lost ear (wound)
	.15:: lost eye (wound)
	.2:: broken jaw (wound)
	.45:: broken skull (death)
else if Impact 6+:
.06:: knocked down
.06:: knocked out
	.08:: temp deaf
	.08:: temp blindness
	.08:: temp mute
	.10:: lost ear (wound)
	.11:: lost eye (wound)
	.13:: broken jaw (wound)
	.3:: broken skull (death)
else if Impact 4+:
	.11: nothing
	.10: knocked down
	.08: knocked out
	.08:: temp deaf
	.08:: temp blindness
	.08:: temp mute
	.10:: lost ear (wound)
	.10:: lost eye (wound)
	.12:: broken jaw (wound)
	.15:: broken skull (death)
else if Impact 2+: 
	.7: nothing
	.08:: temp deaf // busted eardrum
	.1:: temp blindness // poked in the eyes
	.12:: temp mute // lost a tooth

~~consequences of knocked down
//concussion, intracranial hemorrhage 


Chest
	1) temp energy, strength, and mobility loss equal to Impact {{*.66}}
	2) Chance of the following:
if impact 8+:
	.04:: knocked down
 	.15:: broken rib (wound)
	.16:: internal bleeding (wound)
	.2:: spine injury (wound)
	.45:: crushed sternum (death)
else if Impact 6+:
.13:: knocked down
	.08:: ~temp strength loss –
	.16:: ~temp immobile - winded
	.14:: broken rib (wound)
	.12:: internal bleeding (wound)
	.12:: spine injury (wound)
	.25:: crushed sternum (death)
else if Impact 4+:
	.17: nothing
	.06: knocked down
	.12:: ~ temp strength loss
.28::  ~ temp immobile -winded
	.11:: broken rib (wound)
	.12:: internal bleeding (wound)
	.14:: spine injury (wound)
	.1:: crushed sternum (death)
else if Impact 2+: 
	.7: nothing
	.10: knocked down
	.08:: ~ temp strength loss
.12::  ~ temp immobile -winded

Right Arm
Left Arm
	1) temp energy, strength loss equal to Impact 
	2) Chance of the following:
if impact 8+:
	.04:: sprained hand 
 	.15:: severed finger (wound)
	.21:: broken arm (wound)
	.3:: severed arm (wound)
	.3:: severed artery (death)
else if Impact 6+:
	:: disarmed
.13:: sprained hand
	.14:: severed finger (wound)
	.25:: broken arm (wound)
	.2:: severed arm (wound)
	.12:: severed artery (death)
else if Impact 4+:
	.15: nothing
	.06: disarmed
	.22:: sprained hand
.14::  severed finger (wound)
	.24:: broken arm (wound)
	.14:: severed arm (wound)
	.05:: severed artery (death)
else if Impact 2+: 
	.65: nothing
	.2: disarmed
	.15:: sprained hand

//die of shock; dismembered; spiral fracture; dislocated shoulder

Right Leg
Left Leg
	1) temp energy, mobility loss equal to Impact 
	2) Chance of the following:
if impact 8+:
	.04:: sprained leg 
 	.15:: broken toe (wound)
	.21:: broken leg (wound)
	.3:: severed leg (wound)
	.3:: severed artery (death)
else if Impact 6+:
	:: knocked down
.13:: sprained leg
	.14:: broken toe (wound)
	.25:: broken leg (wound)
	.2:: severed leg (wound)
	.12:: severed artery (death)
else if Impact 4+:
	.15: nothing
	.06: knocked down
	.22:: sprained leg
.14::  broken toe (wound)
	.24:: broken leg (wound)
	.14:: severed leg (wound)
	.05:: severed artery (death)
else if Impact 2+: 
	.7: nothing
	.2: knocked down
	.1:: sprained leg

// hamstrung; torn Achilles tendon; torn muscle; 


EVENT SYSTEM:
-deck of event cards established by weather, location, external factors


Distribution of likelihood for number of kids:
                    new RandomSelection(0, 0, .12f),
                    new RandomSelection(1, 1, .26f),
                    new RandomSelection(2, 2, .39f),
                    new RandomSelection(3, 3, .18f),
                    new RandomSelection(4, 4, .05f)



STAT GENERATION:
Start with gender
Then age
Then traits:
	If age <16: + vitality, +energy, +confidence, 60% one area ability, 35% two, 5% none; no developed skills
If age 16-30: + vitality, + energy, 60% one area ability, 35% two, 5% three, some developed skills
If age 30-60: -energy, +confidence, 50% one area ability, 40% two, 10% three; lots of developed skill
If age 60+: - energy, -vitality, +intelligence, +confidence, 50% one area ability, 40% two, 10% three; lots of developed skills

Then language
Then religion (language)
Then physical 
Then profession (gender, age, physical, ~language,  ~religion)
Then associations (~language? Religion?)
Then character
Then skills (profession)


**When generating families:**
-number of kids
-age of mother
-age of father
-age(s) of kid(s) (number)
-language of family
-religion of family
-profession of father
-profession of mother
-associations, character, skills handled individually

LANGUAGES:


RELIGIONS:
Protestantism (Lutheran…. Etc?)
Calvinist
Catholic
Sunni
Shiite
Jewish
Pagan
Atheist
Agnostic
Wicken


PHYSICAL:
[no traits – 92% one trait – 7% two traits – 1 %]
Strong
Weak
Missing arm
Missing leg
Fast
Slow
Eagle eye
Poor vision
Blind
Deaf
Mute 
Great hearing
 


PROFESSIONS:


Jeweler, blacksmith, surgeon, clockmaker, banker, horticulturalist, farmer, brewer, distiller, cook, merchant, inventor, journalist, psychologist, doctor, florist, actor, musician, etc.






Traits:
Group one – character: 

[one trait – 55% two traits – 25% three traits - 5% no traits – 15%] 

-high confidence / low confidence
- Sickly / Healthy
-high energy / low energy
-high temptation /restraint
-  spirited / depressed
-genius / idiot
-embezzler
-murderer
-pleasant/unpleasant
- loyal/mutinous
- stoic / glutinous 
- hardworking / lazy
- honest / dishonest
- violent
- efficient
- eager
misanthrope
lycanthrope
adulterer
alcoholic
serial killer
gossip
addictive personality
manic depressive
liar



Group two - associations:

Child:
[one trait – 35% none – 65%]
Adult:
[one trait – 40% two traits – 30% no traits – 30%]
Old Adult:
[one trait – 45% two traits – 50% no traits – 5%]

religious
communist
racist
Conservative
Liberal




Group four - skills:

Child:
[one trait 40% two traits 5% none 55%]
Adult
[one trait – 35% two traits – 45% three traits – 5% none 15%]
Old Adult
[one trait – 30% two traits - 50% three traits  - 15% none 5%]
track finder
forager 
~perfect pitch
greenthumb
lucky
super vision
leader
teacher
note-taker
scrivener








EVENT CARDS:


Woods:
-animal tracks:
  	-deer
	-ibex
	-chamois
	-badger
	-fox
	-wolf
	-bear
	-lynx
	-beaver
-find animal:
	-rabbit
	-marmot
	-chaffinchs, black redstarts, blackbirds, blackcaps, great and blue tits, robins, wrens, sparrows, crows, pigeons, seagulls, swans, mallards, coots, woodpeckers, starlings, swallows, nutcrackers, choughs, buzzards and kites
	-cuckoo
	-lark
	-eagle
	-bearded vulture
-lost
-disappearance
-spider bite
-bear attack
-wolf attack
-flee
-bandits
-rain
-starvation
-poisoning
-getting sick:
	-diarrea
	-pneumonia
	-echinococcus
-collect:
	firewood (nearby)
	hardwood (needs group and tools)
	honeycomb
	mushrooms {http://www.wsl.ch/dienstleistungen/inventare/pilze_flechten/swissfungi/geschuetzte-arten.pdf}
	poisonous mushrooms
	psychedelic mushrooms
	raspberries
	poisonous berries
	chestnuts
	strawberries
	walnuts
	hazelnuts   
	blackberries
	wildflowers
	redcurrants
	cherries
	sorrel
	nettles
	garlic
	myrtilles	
-discover campsite
-Health
-lower mood
-improve mood
-lower confidence
-improve confidence
-improve intelligence
-improve X skill
-improve vitality
-lower vitality
-improve energy
-


Manor:
-find bat
-find rat
-produce notes
-Temptation
-tutelage
-romance
-lower mood
-improve mood
- criticize (identify low allegiance, low confidence, low energy of other)
- praise 

Fields:

Temptation:
-feast
-inebriate
-dance
-sing
-sex
-cheat
-hit
-steal
-murder
-occult
-radicalize
-mutiny
-flee
-suicide
-lower mood
-gamble
-swim


Health:
-exercise
-cold
-diarrhea
-headache
-sprain
-injury
-amputation
-eye loss
-improve mood
-lower mood

Confidence:
-propose
-romance
~mutiny, murder, sex
-learn new skill/ability
-improve mood


Part 3: New Game:

Scene 1: image: Simplistic 19th century funeral imagery. 

Your parents have died. It was a…

a. terrible disease.
b. train crash.
c. murder-suicide.
d. Misunderstanding.

Scene 2: image: vague, bleak but humorous representation of how the player’s parents died based on the player’s answer to question 1, (which will affect the character later on; a) vulnerability to diseases but huge boost to researching them, b) later develops as a positive or negative relationship with weapons, technology, and the political forces at work in the game [the crash was an explosion!], c) lays the groundwork for the player’s character unilaterally doing sadistic and evil things if the player does not actively keep the character’s conscience and morality in check, d) later develops in different ways as a running joke that gives color to and influences the player’s character’s interactions with NPCs, and NPCs’ gossip about the player’s character). 

Leaving you, Master ___[FirstName]___ , scion of House __[LastName]__, as Junker of
___[EstateName]___ Manor.   

Scene 3. A terrible fate to befall a boy who is only…

A. 15 years old.
B. 25 years old.
C. 35 years old.
D. 45 years old.

[a is hard difficulty, B is normal difficulty, C is easy difficulty, D is a mix of easy and hard, optimized for humor].

Scene 4. Image: Showing the player’s character mourning his parents with no one but Giles.

‘In this time of great mourning, take comfort in the continued servitude of the everloyal [LastName] butler, Flaubert Giles.

Giles was always really good at…’

A. giving sage advice. 
B. making ends meet.
C. keeping his mouth shut.
D. Not shuffling his feet. 

[a. This makes Giles a very active advice giver, making him liable to try to explain game concepts whenever they are introduced. Sometimes these will include really valuable, rare insights, but it does mean encountering a lot more tutorial text. It also gives Giles a one-point intelligence boost. B. Giles finds and does free market jobs in addition to his work at the manor and is good at bringing home small bits of money and/or food to eat, particularly when things are tight. C. Giles (virtually) never says anything at all and does everything 10% faster. D. Unless d. is selected, then, if the game audio is on, the player hears Giles scrape his feet on the ground every time he walks somewhere or performs an action that involves walking around in a room standing up. 

Scene 5. Image: If the player picks a, b, or d, Giles says to the player’s character:


‘This is an opportunity for you to finally pursue your interest in…’

[if the player picked C, Giles says nothing, and the game narration continues with that text instead]

A. women.
B. money.
C. fame.
D. science. 

[These are all objectives that can be pursued, but the player’s end game score will be weighted to favor whichever of these four elements are selected, the answer will also color Giles’ interactions with the player (but for c/silent Giles).]

Scene 6. Image: delivers player to the view of the manor, centered on the front entryway. 

‘First, this house really needs to be cleaned up.’

Part 4: The Manor Layout and Vaud agriculture

At the start of the game, the date should be March 1st, 1818. The immediate estate should include the Manor, plus surrounding buildings, lots, and fields.

Manor:

Attic: Attic 1 (disrepair), Attic 2 (disrepair)
2nd story: Master bedroom, 2nd Bedroom, 3rd bedroom, upstairs bathroom, Study, Library (disrepair)
1st story: Kitchen, dining room, Entryway, downstairs bathroom, unusued room (disrepair), butler's quarters
Basement: Large empty basement room 1 (disrepair), room 2 (disrepair), and room 3 (disrepair).

The basement, first, and second stories should all take up the same amount of horizontal space (the basement rooms will be big, bathrooms small). And the attic will take up two-thirds the width of the rest of the house.

The two attic rooms and three basement rooms can all be developed for any sort of purpose. The unused room on the first story can become an additional bedroom or be used for other purposes. Additional bedrooms/house rooms are most coveted, and require expensive expansions to the house. Additional industry/mad science (laboratory, brewery, distillery, dungeon) rooms, such as can be placed in the attic or basement, can be dug into the ground, increasing in price the deeper you go (max five basement-room-sized blocks wide and five basement stories deep).

Surrounding Buildings:

chicken coop (disrepair) 
toolshed
Road into town

Lots:

Empty garden space (opportunity for greenhouse or similar)
Empty building space 1 (opportunity for factory, tenement, warehouse, etc.)
Empty building space 2  

Fields:

vegetable garden
field 2 (fallow)
field 3 (fallow)
field 4 (fallow)

Please take the following into account:

In Vaud, Switzerland, field planting generally begins in late March and continues through June, with the main spring planting season starting around April 20-26 when the danger of frost passes and the soil warms. Early crops like spinach, peas, and onions can be planted in late February to March, while warm-season crops (corn, beans) go in from late April. 
Early Spring (Mid-March - Early April): Direct sow spinach, peas, radishes, carrots, and lettuce.
Main Planting Season (Late April - May): After the last frost (roughly April 20-27), plant potatoes, onions, and prepare for warm-season crops.
Warm-Season Crops (Late April - May): Beans, corn, and squash are planted when soil temperature is warm enough, typically from late April onward.
Soil Preparation: Planting depends on the ground being thawed and workable, which usually occurs by late March. 
Key Considerations for Vaud:
Frost Date: The average last frost occurs around April 26-27.
Growing Season: The season in the Le Vaud area typically lasts from April 20 to October 27. 

In the 1800s, agriculture in the canton of Vaud, Switzerland, was transitioning from traditional subsistence farming to more specialized, market-oriented production, heavily influenced by the development of railways and the rise of commercial trade. The region was characterized by diverse, altitude-dependent produce, ranging from intensive viticulture along Lake Geneva to alpine livestock farming. 
Key produce grown in Vaud during the 19th century included:
Grapes & Wine: Viticulture was (and remains) a cornerstone of Vaudois agriculture. The Lavaux and La Côte regions specialized in Chasselas white grape varieties. The 19th century saw a shift toward commercializing this production, particularly after the 1850s.
Cereals (Grains): Wheat was widely grown in the lower-lying, fertile areas.
Fruit: Fruit cultivation was prominent, particularly at the foot of the Jura Mountains.
Sugar Beets: Cultivated around the Orbe region.
Tobacco: Produced in the La Broye Valley.
Forage & Crops for Livestock: As farmers increasingly converted to more lucrative dairy farming in the latter half of the 19th century due to competition from imported grain, crops such as turnips and clover were grown to support cattle.
Wild Daffodils: By the end of the 19th century (specifically by the 1890s), wild daffodils were heavily harvested in the region, particularly around Montreux, as a commercial "flower harvest" for sale and tourism. 
Key Agricultural Trends of the 1800s in Vaud:
Shift to Dairy: Similar to broader Swiss trends, Vaudois farmers moved from growing only crops to more dairy farming (milk, cheese) due to better profitability and transport networks.
Livestock: Pasture and livestock raising were common in the alpine areas of the canton.
Viticulture Development: The 1840s and 1850s marked a rapid rise in the commercial trade of grapes and wine. 

Part 5: character activity

What any character is doing at a given time is influenced by the following criteria:

1) Have any of the character’s breaking point needs been surpassed?
If so, the character will automatically go about satisfying those needs on their own, of will have a panic attack and then either satisfy those needs or require medical attention (a character may sleep somewhere spontaneously or eat unprepared ingredients).
2) Is there an emergency the character needs to respond to?
E.g. a catastrophic event like a fire, combat.
If so, the character responds to the emergency until the character reaches its breaking point or the emergency ends.
3) Has the character been given any responsibilities with five stars:
If so, are there any outstanding action items for those responsibilities that are above the urgency threshold?
If yes, perform that task unless/until the character’s breaking point is passed.
4) Does the character’s schedule say they should be eating at this time?
If so, the character travels to the nearest location where food is being stored, takes a dish into the dining area, and eats it. Once the dish is consumed, the character cleans the 
5) Does the character’s schedule say they should be sleeping at this time?
If so, the character travels to the character’s designated bed and sleeps until their scheduled wake up time or until they feel sufficiently rested (some characters will want more sleep than others, sick, injured, exhausted characters are most likely to sleep an rest until they feel better, ignoring any schedule).
6) Has the character been given any four star responsibilities?
If so, then, until the character reaches a breaking point or has a meal or sleep scheduled, the character performs any outstanding four star responsibilities above the urgency threshold (that they are able to perform)*.
*: if a character has four stars in Medical and there is a surgery slotted above the urgency threshold, then the character will attempt to perform that surgery, but only if the character has the minimum medical and knife skills to attempt the surgery.  
7) Is there anything the character desperately wants to do?
If so, they will perform this action before doing anything else. Characters have personal aspirations and wants and needs, and these can be particularly strong when interpersonal conflicts or courtships are going on.
E.g. a character might skip work to start a fight with or gift flowers to another character. 
8) Has the character been assigned to a specific task (either by the player dropping the character onto a room or by the character selecting a room and then assigning that specific character to perform a task)? 
If so, then, until the character reaches a breaking point or has a meal or sleep scheduled, the character will continue to perform that task until it is complete.
9) Does the character’s schedule say they should be working at this time?
If so, what is the highest priority task they can be performing? They perform this task until their scheduled work period ends or the task is complete.
10) What does the schedule say the character should be doing?
The character performs that action.
11) If the character has leisure/nothing scheduled, what is the next thing the character moderately wants to do?
Similar to ‘desperate wants’, characters will have a large number of rotating wants and desires that operate at a sub-desperate level, and characters will act on these during Leisure time until Leisure time is scheduled to end. 
Examples: take a walk, write a poem, sing a song, use substance (smoke tobacco), play a game, make art, read a book, watch birds, affection with partner, etc.

Step 6: scientific disciplines

Here is a proposed Progressive Node Tree using primarily one-word (or tight two-word) nodes.

How to Read This Tree
[Brackets]: Represents a researchable Node.

→: Represents a direct linear unlock.

+: Indicates that BOTH previous nodes are required to unlock the next one (Convergence).

1. The Flesh (Biology Branch)
Progression: Observation → Incision → Corruption

Tier 1: Foundations

[Anatomy] (The Root)

Unlocks three independent paths:

[Human] (Study of cadavers)

[Bestial] (Study of mammals/livestock)

[Insectoid] (Study of nervous systems/exoskeletons)

Tier 2: Convergence (The Surgeon's Art)

[Human] + [Bestial] → [Comparative] (Understanding muscle/bone density diffs)

[Insectoid] + [Chemistry] → [Preservation] (Fluids/Formaldehyde)

[Anatomy] + [Tools] → [Surgery] (The physical skill of cutting)

Tier 3: The Divergence (Mad Science)

[Surgery] + [Comparative] → [Vivisection] (Working on living subjects)

[Vivisection] + [Preservation] → [Grafting] (Attaching foreign limbs)

[Grafting] + [Bestial] → [Xenotransplantation] (Animal parts on humans)

Tier 4: The Apex

[Xenotransplantation] + [Galvanism] → [Chimera] (Stable hybrid monsters)

[Grafting] + [Regeneration] → [Immortality]

2. The Spark (Chemistry & Physics)
Progression: Matter → Energy → Life

Tier 1: Foundations

[Alchemy] (The Root)

Unlocks:

[Distillation] (Purifying liquids)

[Combustion] (Fire/Heat)

[Metallurgy] (Conductive materials)

Tier 2: Convergence

[Distillation] + [Nature] → [Toxins] (Poisons/Acids)

[Combustion] + [Metallurgy] → [Steam] (Basic power)

[Metallurgy] + [Storms] → [Galvanism] (Harnessing lightning)

Tier 3: The Divergence

[Toxins] + [Preservation] → [Serums] (Buff potions/mutagens)

[Galvanism] + [Surgery] → [Electrolysis] (Stimulating nerves)

[Steam] + [Toxins] → [Fumigation] (Gas warfare)

Tier 4: The Apex

[Electrolysis] + [Serums] → [Reanimation] (The "It's Alive!" moment)

[Galvanism] + [Alchemy] → [Transmutation] (Lead to Gold / Flesh to Steel)

3. The Gear (Engineering & Swiss Precision)
Progression: Mechanism → Automation → Cognition

Tier 1: Foundations

[Horology] (The Root - Watchmaking)

Unlocks:

[Gears] (Torque/Movement)

[Lenses] (Optics/Magnification)

[Springs] (Stored Energy)

Tier 2: Convergence

[Gears] + [Springs] → [Clockwork] (Complex automated movement)

[Lenses] + [Light] → [Microscopy] (Boosts Biology research)

[Clockwork] + [Steam] → [Locomotion] (Vehicles/Conveyors)

Tier 3: The Divergence

[Clockwork] + [Grafting] → [Prosthetics] (Functional mechanical limbs)

[Microscopy] + [Lenses] → [Lasers] (Archimedes Death Rays)

[Locomotion] + [Artillery] → [Ballistics]

Tier 4: The Apex

[Prosthetics] + [Galvanism] → [Cybernetics] (Powered limbs)

[Clockwork] + [Computation] → [Automata] (Robots)

4. The Mind (Psychology)
Progression: Observation → Manipulation → Domination

Tier 1: Foundations

[Psychology] (The Root)

Unlocks:

[Phrenology] (Skull shapes)

[Trauma] (Pain response)

[Dreams] (Subconscious)

Tier 2: Convergence

[Phrenology] + [Anatomy] → [Lobotomy] (Physical brain alteration)

[Trauma] + [Toxins] → [Narcotics] (Chemical compliance)

[Dreams] + [Voice] → [Mesmerism] (Hypnosis)

Tier 3: The Divergence

[Lobotomy] + [Clockwork] → [Programming] (Treating brains like machines)

[Mesmerism] + [Narcotics] → [Brainwashing] (Rewriting personality)

[Trauma] + [Galvanism] → [Shock] (Electro-shock therapy)

Tier 4: The Apex

[Brainwashing] + [Hivemind] → [Gestalt] (One mind, many bodies)

[Shock] + [Occult] → [Psionics] (Mind bullets)