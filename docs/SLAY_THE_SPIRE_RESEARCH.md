# Slay the Spire Research: What Makes It Great

## Overview

This document compiles research on Slay the Spire's design philosophy, mechanics, balancing strategies, and key development decisions. This research informs the development of Deck Masters Roguelike, which draws inspiration from Slay the Spire's roguelike deck-building mechanics.

---

## 1. What Makes Slay the Spire So Good

### Core Strengths

#### Perfect Balance of Randomness and Skill
Slay the Spire achieves an exceptional balance between randomness and player agency. While card draws, enemy encounters, and rewards involve chance, players have significant control through:
- **Strategic deck-building choices**: Selecting which cards to add/remove shapes the run
- **Pathing decisions**: Choosing routes through the spire balances risk vs reward
- **Turn-by-turn decision making**: How to play cards, when to block, when to attack
- **Resource management**: Energy management and card draw optimization

The game ensures that while luck plays a role, skill and strategy are the primary determinants of success. Players can mitigate bad luck through good decision-making.

#### Transparent Information Systems
The "Intents" system is a cornerstone of Slay the Spire's design. Enemies clearly telegraph their next move, showing:
- What attack they're planning (with exact damage numbers)
- What debuffs they'll apply
- Whether they're blocking or buffing themselves

This transparency enables strategic planning rather than guesswork. Players can:
- Calculate exactly how much block they need
- Decide when to take damage vs block
- Plan multi-turn strategies
- Make informed risk/reward decisions

#### Data-Driven Balancing
With over 250 cards, 150+ relics, and numerous enemy encounters, balancing Slay the Spire required a systematic approach. The developers:
- Collected extensive gameplay data from players
- Analyzed metrics like card selection rates, win rates, damage taken
- Identified overpowered and underpowered cards through statistics
- Made iterative adjustments based on data, not just intuition

As Anthony Giovannetti (co-founder of Mega Crit) stated: *"We have so many cards and so many interactions that even though we have a pretty strong card game background, there's no way we can intuitively do it all correctly."*

#### Incremental Complexity
The game introduces complexity gradually:
- Starter cards are simple and straightforward
- Basic enemies teach core mechanics
- Complexity increases as players progress
- New mechanics are introduced gradually
- Players learn organically through play

This approach makes the game accessible to newcomers while maintaining depth for experienced players.

#### Meaningful Decisions
Every choice in Slay the Spire matters:
- **Card selection**: Each card added shapes the deck's capabilities
- **Pathing**: Choosing routes determines encounters and rewards
- **Card removal**: Removing starter cards refines the deck
- **Relic selection**: Permanent bonuses shape strategy
- **Shop purchases**: Limited gold forces prioritization
- **Event choices**: Risk/reward trade-offs in random events

No decision is trivial - they all have consequences that affect the run's outcome.

---

## 2. Core Mechanics and Balancing

### Key Mechanics

#### Deck Building System
- Players start with a basic deck (character-specific starter cards)
- New cards are acquired throughout the run (rewards, shops, events)
- Cards can be removed at shops and events (deck thinning)
- Deck size management is a strategic consideration
- Synergies emerge from card combinations

#### Pathing System
Players choose routes through the spire:
- **Normal fights**: Standard enemies, moderate rewards
- **Elite fights**: Harder enemies, better rewards (relics, gold, cards)
- **Question marks**: Random events with varied outcomes
- **Shops**: Spend gold on cards, relics, potions, or card removal
- **Rest sites**: Heal HP or upgrade a card

Pathing decisions balance:
- Risk (taking elite fights) vs Safety (avoiding elites)
- Immediate needs (rest sites for healing) vs Long-term gains (more fights for rewards)
- Current deck state vs potential upgrades

#### Three-Act Structure
Each act has distinct characteristics:
- **Act 1**: Focus on building a functional deck, establishing core strategy
- **Act 2**: Tests deck's capabilities, introduces new enemy types
- **Act 3**: Final challenge, tests deck's completeness and power level
- Each act ends with a boss that tests different aspects of the deck

This structure creates a natural progression arc and allows for escalating difficulty.

#### Relic System
Relics provide permanent passive bonuses:
- Modify card costs or effects
- Grant resources (energy, gold, card draw)
- Provide defensive capabilities (block, damage reduction)
- Enable new strategies or synergies
- Rare relics can completely change how a deck functions

Relics are powerful but rare, making each one feel impactful.

#### Card Removal
Players can remove cards from their deck:
- Costs gold at shops
- Available at certain events
- Critical for removing weak starter cards
- Enables deck refinement and consistency
- Creates tension: remove cards vs buy new ones?

#### Energy System
- Players have limited energy per turn (usually 3, can be increased)
- Cards cost energy to play
- Energy management creates strategic depth:
  - Low-cost cards = more actions per turn
  - High-cost cards = more powerful effects
  - Balancing the energy curve is crucial

### Balancing Philosophy

#### Metrics-Driven Approach
The developers collected and analyzed extensive data:
- **Card selection rates**: Which cards are picked most/least often?
- **Win rates**: Which cards/relics correlate with wins?
- **Damage statistics**: How much damage do players take from specific enemies?
- **Usage patterns**: How are cards actually used in successful runs?
- **Synergy analysis**: Which card combinations are overpowered?

This data-driven approach allowed them to:
- Identify cards that were too strong or too weak
- Understand how players actually play vs how designers expected
- Make informed balance adjustments
- Ensure no single strategy dominates

#### Iterative Design
Slay the Spire went through continuous balance updates:
- Regular patches based on player data
- Community feedback integration
- A/B testing of balance changes
- Willingness to revert changes that didn't work

The game was balanced over time, not perfected at launch.

#### No Dominant Strategies
The developers ensured that:
- Multiple viable strategies exist for each character
- No single card/relic combo wins every run
- Different strategies work against different bosses
- Players must adapt to what they're given
- Variety and experimentation are rewarded

#### Context-Dependent Balance
Cards are balanced not in isolation, but in relation to:
- **Encounters**: Some cards are strong against specific enemies
- **Synergies**: Cards that are weak alone can be powerful with the right combos
- **Act relevance**: Some cards are better in early acts, others in late acts
- **Character identity**: Each character has cards that fit their playstyle

A card that's weak in one context can be strong in another - this creates depth.

#### Viability Principle
The goal was to ensure:
- Every card has situations where it's useful
- No cards are "always skip" or "always pick"
- Context determines card value
- Players can find value in unexpected cards
- Deck-building remains interesting and varied

---

## 3. Tough Design Decisions

### Decision 1: The Intent System

**The Challenge**
Initially, Slay the Spire did not show what enemies planned to do next. Players had to guess or memorize enemy attack patterns.

**The Problem**
- Players felt overwhelmed by unpredictability
- Gameplay felt like guesswork rather than strategy
- New players were confused and frustrated
- Strategic planning was impossible
- Success felt more dependent on luck than skill

**The Solution**
The developers implemented the "Intents" system, where enemies clearly display:
- Icons showing their next action type (attack, debuff, block, buff)
- Exact damage numbers for attacks
- Visual indicators for status effects they'll apply

**The Tough Choice**
The developers initially hesitated to implement this system because:
- They worried it would make the game too easy
- They feared it would remove challenge
- They thought hidden information added tension
- They weren't sure players would appreciate transparency

**The Result**
The Intent system actually enhanced strategic depth:
- Players could plan multiple turns ahead
- Decision-making became more skill-based
- The game felt more fair and strategic
- Challenge remained through complex enemy patterns, not hidden information
- Players reported feeling more in control and satisfied with their decisions

This was a counterintuitive decision - more information made the game more strategic, not easier.

### Decision 2: Transparency of Numbers

**The Challenge**
Should the game show exact damage numbers, or just use icons/indicators?

**The Decision**
Show precise numbers for:
- Enemy attack damage
- Player card damage
- Block amounts
- Status effect values
- All numerical game state

**The Reasoning**
Playtesting revealed that:
- Precise information enhanced strategic planning
- Players could calculate optimal plays
- Uncertainty about exact values was frustrating, not engaging
- Numerical transparency enabled deeper strategy
- Players preferred knowing exactly what would happen

**The Result**
Showing exact numbers:
- Allowed players to make mathematically optimal decisions
- Enabled complex multi-turn planning
- Made the game feel more skill-based
- Improved player satisfaction and sense of control
- Created deeper strategic gameplay

### Decision 3: Balancing Randomness

**The Challenge**
How much randomness is acceptable in a skill-based game? Too little randomness = predictable and boring. Too much randomness = frustrating and unfair.

**The Approach**
Slay the Spire uses multiple layers of variability, but all influenceable by player choices:

**Random Elements:**
- Card draw order (shuffled deck)
- Enemy encounters (random from pools)
- Reward selection (random cards/relics offered)
- Event outcomes (random events with varied results)
- Map generation (procedurally generated paths)

**Player Influence:**
- Deck-building choices determine what cards can be drawn
- Pathing decisions determine which encounter pools are available
- Card selection shapes reward quality
- Strategic play mitigates bad draw sequences
- Multiple viable strategies reduce impact of bad luck

**The Philosophy**
- Randomness adds variety and replayability
- Skill should be the primary determinant of success
- Players should be able to mitigate bad luck through good decisions
- Randomness creates interesting problems to solve, not unfair losses
- The game should feel fair even when luck is involved

**The Implementation**
- Players can build consistent decks that reduce draw variance
- Multiple win conditions reduce reliance on specific cards
- Resource management allows recovery from bad draws
- Strategic flexibility enables adaptation to randomness
- Long-term planning reduces impact of short-term variance

### Decision 4: Complexity Management

**The Challenge**
Slay the Spire has:
- 250+ cards per character
- 150+ relics
- Dozens of enemy types
- Multiple character classes
- Countless card/relic/enemy interactions

How do you balance such a complex system?

**The Solution: Data-Driven Balancing**
The developers recognized that intuition alone wasn't sufficient. They implemented:

**Metrics Collection:**
- Card selection rates (pick rates)
- Card win rates (correlation with victories)
- Damage statistics (damage taken from enemies)
- Usage patterns (how cards are actually used)
- Synergy analysis (which combinations are powerful)

**Analysis Process:**
- Identify outliers (cards picked too much/too little)
- Correlate cards/relics with win rates
- Understand actual player behavior vs designer intent
- Test balance hypotheses with data
- Make informed adjustments, not guesses

**Anthony Giovannetti's Insight:**
*"We have so many cards and so many interactions that even though we have a pretty strong card game background, there's no way we can intuitively do it all correctly."*

This humility and reliance on data was crucial to the game's success.

**The Approach:**
1. Design cards with intent and vision
2. Release and collect data
3. Analyze actual player behavior
4. Identify imbalances through metrics
5. Make targeted adjustments
6. Repeat iteratively

### Decision 5: Procedural Generation vs Curated Experience

**The Challenge**
Balance between:
- **Procedural generation**: Creates replayability, each run feels different
- **Curated experience**: Ensures balance, meaningful encounters, proper difficulty curve

**The Approach**
Slay the Spire uses a hybrid system:

**Procedural Elements:**
- Map layout (paths through the spire)
- Encounter order (which enemies appear when)
- Reward selection (which cards/relics are offered)
- Event outcomes (random events with varied results)

**Curated Elements:**
- Carefully balanced encounter pools (enemies appropriate for each act)
- Hand-crafted boss encounters (each boss tests different deck aspects)
- Designed difficulty curve (each act increases in difficulty)
- Balanced card pools (cards appropriate for each act)
- Structured progression (acts provide natural milestones)

**The Result**
- Each run feels unique and different
- Balance and difficulty remain consistent
- Strategic depth is maintained
- Replayability is high
- The game feels fair and well-designed

This balance between procedural generation and curation is a key to the game's success.

---

## 4. Design Principles Applied

Based on the research, Slay the Spire follows several key design principles:

### 1. Player Agency Over Randomness
While randomness exists throughout the game, player decisions are the primary determinant of success. Randomness creates variety and interesting problems to solve, but skill and strategy determine outcomes.

### 2. Transparency Enables Strategy
Showing enemy intents and exact numbers doesn't make the game easier - it makes it more strategic. Players can plan, calculate, and optimize rather than guess.

### 3. Data-Driven Iteration
Use metrics and data to inform balance decisions. Intuition is valuable, but data reveals how the game actually plays, not just how designers intended it to play.

### 4. Context-Dependent Balance
Cards and mechanics are balanced in relation to encounters, synergies, and situations. A card that's weak in one context can be strong in another, creating depth and variety.

### 5. Meaningful Choices
Every decision point should matter and have consequences. No choice should feel trivial - players should feel the weight of their decisions.

### 6. Progressive Complexity
Introduce complexity gradually. Let players learn organically through play. Start simple, build complexity over time.

### 7. No Dominant Strategies
Ensure multiple viable strategies exist. Prevent any single approach from being optimal in all situations. Reward variety and adaptation.

### 8. Iterative Refinement
Balance is a process, not a destination. Be willing to make adjustments based on data and feedback. Perfection is achieved through iteration.

---

## 5. Key Takeaways for Deck Masters Roguelike

Based on this research, here are insights relevant to Deck Masters Roguelike:

### Transparency and Information Systems
- **Consider showing boss intents**: Your game already has turn-based boss actions - consider clearly telegraphing what bosses will do next turn
- **Show exact numbers**: Display damage, healing, and status effect values clearly
- **Enable strategic planning**: Give players enough information to plan ahead

### Balancing Approach
- **Track metrics if possible**: Consider tracking card usage rates, win rates, team composition success rates
- **Use data, not just intuition**: If you have access to playtest data, use it to inform balance
- **Iterate on balance**: Be willing to adjust cards, heroes, and bosses based on how the game actually plays

### Player Agency
- **Balance randomness with strategy**: Ensure randomness exists (card draws, etc.) but players can influence outcomes through good decisions
- **Meaningful choices**: Every card play, hero selection, and turn decision should matter
- **Multiple viable strategies**: Ensure different team compositions and strategies are viable

### Game Structure
- **Progressive difficulty**: Your five-boss structure is good - ensure the difficulty curve is smooth
- **Each boss tests different aspects**: Like Slay the Spire's bosses, each of your bosses should test different strategies
- **Clear progression**: Players should feel they're making progress and building power

### Deck Building Considerations
- **Card removal/thinning**: Consider adding ways to remove starter cards or refine decks (if you add deck-building between fights)
- **Synergy opportunities**: Ensure cards have interesting synergies within and across heroes
- **Context-dependent value**: Cards should be good in some situations, weak in others

### Design Philosophy
- **Transparency enables strategy**: Don't be afraid to show information - it enables deeper strategy
- **No dominant strategies**: Ensure no single team composition or strategy always wins
- **Iterative refinement**: Balance through playtesting and iteration, not just theory

---

## 6. Research Sources and References

### Primary Sources
- **GameDeveloper.com**: "How Slay the Spire's Devs Use Data to Balance Their Roguelike Deck-Builder" - Article on metrics-driven balancing approach
- **Anthony Giovannetti's Presentations**: GDC and other game design talks on metrics-driven design and balancing
- **Wikipedia**: Slay the Spire article with overview of mechanics and design

### Secondary Sources
- **The Thoughtful Gamer**: "Slay the Spire and Randomness Tolerance" - Analysis of randomness vs skill balance
- **Gunslinger's Revenge**: Articles on balancing randomness and skill in deck-builders
- **Various game design articles**: On balancing, procedural generation, and roguelike design

### Recommended Further Reading
- Watch Anthony Giovannetti's GDC/design presentations on metrics-driven design
- Read the GameDeveloper.com article on data-driven balancing
- Study how the Intent system evolved and its impact on gameplay
- Research how procedural generation and curation are balanced in roguelikes

---

## Conclusion

Slay the Spire's success stems from its exceptional balance of:
- **Transparency** (showing information enables strategy)
- **Player agency** (skill matters more than luck)
- **Data-driven balance** (metrics inform decisions)
- **Meaningful choices** (every decision matters)
- **Iterative refinement** (continuous improvement)

The game demonstrates that showing information, relying on data, and prioritizing player agency can create deeply strategic and engaging gameplay. These principles can guide the development of Deck Masters Roguelike as it evolves and grows.

---

*Research compiled: 2025-01-30*
*For: Deck Masters Roguelike Development*





