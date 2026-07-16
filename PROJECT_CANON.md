# PROJECT_CANON.md

**Project codename:** `DYNASTY`  
**Canon version:** `0.1`  
**Canon status:** `FIRST_PLAYABLE_LOCKED`

This file defines durable project semantics, contracts, invariants, protected boundaries, and high-risk validation requirements.

An active GitHub Issue may select part of this canon for implementation. It MUST NOT silently redefine this canon. Numeric values explicitly marked as balance values may change only in a dedicated balance task with reproducible evidence.

---

## CANON-01 — Product Identity

### Product

`DYNASTY` is a commercial PC single-player dynastic survival strategy game.

The player controls the continuity of a house, not one permanent character. When the current house head dies, play continues through succession if the house remains viable.

### Runtime technology

The shipped game MUST use:

- Godot 4.
- GDScript.
- A 2D, mouse-driven interface.
- Turn-based simulation.
- Offline execution with no external LLM or network dependency.

Python MAY be used for development-only tools such as balance simulation, fixture generation, and data validation. Python MUST NOT be required to run the shipped game.

### Core promise

> Preserve a house through imperfect choices where the most capable heir and the most legitimate heir may be different people.

### Core loop

```text
Inspect the house
→ spend limited actions
→ apply costs and reactions
→ advance time
→ resolve death and succession
→ continue with the changed house
```

### Product boundary

This project is a finished game. It is not:

- A generic history simulator.
- A dynasty-game construction kit.
- A rule editor.
- A world-generation tool.
- A general simulation framework.
- A generated-fiction product.

---

## CANON-02 — Design Invariants

### Family is the strategy space

Important characters MUST have:

- Kinship.
- Succession rights.
- Loyalty.
- Ambition.
- Relationships.
- Conflicting interests.

Characters MUST NOT be reduced to disposable stat bonuses.

### Succession is the central resolution system

Succession MUST resolve consequences accumulated before death, including:

- Education.
- Formal heir declaration.
- Marriage.
- Kin management.
- Relationship changes.
- Discovered secrets.
- House legitimacy and cohesion.

Succession MUST NOT be a cosmetic character swap.

### Every material benefit has a cost

No action may solve a major problem without cost, opportunity cost, or later risk.

Required trade-off patterns:

- A strong marriage provides protection and invites interference.
- Training the younger son improves capability and intensifies rivalry.
- Restoring wealth reduces cohesion.
- Buying kin support consumes wealth or influence.
- Changing the formal heir creates opposition.

### Success creates exposure

Increasing wealth, power, titles, or descendants MUST create additional obligations, rivals, or succession risk.

The game MUST NOT become permanently safe by increasing every number.

### Important outcomes are explainable

For succession and terminal outcomes, the UI MUST expose:

- Relevant candidates.
- Base scores.
- Applied modifiers.
- Supporters and opponents.
- The selected outcome.
- Immediate state changes.

Hidden randomness MUST NOT determine succession.

### Story emerges from rules

Chronicle text MUST be generated from deterministic rules and templates.

External generative AI MUST NOT be used at runtime.

### Build the game, not an engine

Until the first playable passes `CANON-17`, implementation MUST prioritize the locked scenario and MUST NOT create generalized systems for hypothetical future content.

---

## CANON-03 — First Playable Contract

### Scenario

```text
THE LAST WINTER
```

### Validation question

> Is preparing for a known death and surviving the resulting succession crisis interesting enough to replay with a different strategy?

### Fixed structure

The first playable MUST have:

- Exactly 12 turns.
- Six months per turn.
- Two action points at the start of each turn.
- Edric's mandatory death on turn 6.
- Final resolution on turn 12.
- Target first-run duration of 10–20 minutes.
- Target replay duration of 5–15 minutes.

### Scope lock

Before the first playable passes the promotion gate, the project MUST NOT add:

- A world map.
- Warfare or armies.
- Tactical combat.
- City building.
- Trade networks.
- Religion simulation.
- Culture simulation.
- Technology trees.
- Dozens of houses.
- Hundreds of simulated characters.
- Full character-life simulation.
- Rule editors.
- Content editors.
- Mod support.
- Multiplayer.
- Mobile or console targets.
- Steam achievements or cloud saves.
- Final art production.
- Voice acting.
- Runtime generative AI.
- Free-text negotiation.

Temporary UI, placeholder icons, basic fonts, and minimal audio are allowed only when they support first-playable validation.

---

## CANON-04 — Stable Internal IDs

Display names MAY be localized. Internal IDs MUST remain stable.

### Houses

```text
house_arven
house_velor
house_cardin
```

### Characters

```text
edric_arven
myra_arven
aldren_arven
rowen_arven
beric_arven
```

### Actions

```text
educate_aldren
educate_rowen
appease_beric
negotiate_marriage
investigate_secret
reorganize_estate
reconcile_brothers
declare_heir
```

### Fixed events

```text
debt_demand
brothers_conflict
edric_death
post_succession_demand
regime_test
final_judgment
```

### Succession outcomes

```text
stable_aldren
unstable_aldren
agreed_rowen
contested_rowen
succession_civil_war
```

### Terminal results

```text
victory_stable_succession
victory_fragile_survival
victory_blood_bought
defeat_no_eligible_heir
defeat_estate_lost
defeat_insolvent
defeat_legitimacy_collapse
defeat_unresolved_civil_war
```

---

## CANON-05 — Scenario Cast

### House Arven

House Arven is a minor landed house with:

- One estate.
- Weak finances.
- Low political influence.
- Internal succession tension.
- A terminally ill house head.

### Main characters

| ID | Role | Durable conflict |
|---|---|---|
| `edric_arven` | Current house head | Must prepare succession before mandatory death on turn 6 |
| `myra_arven` | Edric's spouse | Supports the lawful elder son |
| `aldren_arven` | Elder son and default heir | More legitimate, less capable, less healthy |
| `rowen_arven` | Younger son | More capable, less legitimate, highly ambitious |
| `beric_arven` | Edric's younger brother | Supports Rowen and seeks influence over succession |

No additional named Arven character may be added before first-playable promotion.

### External houses

| ID | Profile | Immediate benefit | Embedded risk |
|---|---|---|---|
| `house_velor` | Wealthy and influential | Wealth and political protection | Succession and estate interference |
| `house_cardin` | Smaller and comparatively neutral | Cohesion and mediation | Limited material support |

No additional external house may be added before first-playable promotion.

---

## CANON-06 — State Model

### House state

The first playable MUST track:

| Field | Type | Range | Meaning |
|---|---|---:|---|
| `wealth` | integer | unbounded | Spendable economic capacity |
| `debt` | integer | `>= 0` | Outstanding financial burden |
| `legitimacy` | integer | `0..100` | Acceptance of the current house order |
| `influence` | integer | `0..100` | Political leverage |
| `cohesion` | integer | `0..100` | Internal willingness to cooperate |
| `succession_stability` | integer | `0..100` | Explicit tracked succession stability |
| `estate_count` | integer | `>= 0` | Estates controlled by House Arven |
| `action_points` | integer | `0..2` | Remaining actions this turn |
| `formal_heir_id` | character ID or null | — | Publicly recognized heir |
| `current_head_id` | character ID | — | Current house head |
| `turn` | integer | `1..12` | Current turn |
| `seed` | integer | — | Reproduction seed |

`succession_stability` is explicit simulation state. It MUST NOT be implemented as a display-only derived value.

All bounded integer values MUST be clamped after each atomic state transition.

### Character state

Each main character MUST track:

| Field | Type | Notes |
|---|---|---|
| `id` | stable ID | Canonical identifier |
| `display_name` | string | Localizable |
| `age_months` | integer | Internal age representation |
| `alive` | bool | Life state |
| `in_house` | bool | Membership in House Arven |
| `health` | integer | `0..100` |
| `ability` | integer | `0..100` |
| `legal_claim` | integer | `0..100` |
| `loyalty` | integer or null | `0..100`; null where not applicable |
| `ambition` | integer | `0..100` |
| `role` | stable role ID | Current position |
| `known_secrets` | collection | Stable secret IDs |

`is_formal_heir` MUST be derived from `formal_heir_id`, not stored as an independent source of truth.

### Relationships

Relationships MUST use stable unordered character-pair keys.

The first playable MUST track at least:

```text
edric_arven <-> aldren_arven
edric_arven <-> rowen_arven
myra_arven <-> aldren_arven
myra_arven <-> rowen_arven
beric_arven <-> aldren_arven
beric_arven <-> rowen_arven
aldren_arven <-> rowen_arven
```

Relationship values are integers clamped to `0..100`.

### Scenario flags

The first playable MUST support:

```text
marriage_partner_house_id
marriage_completed
velor_intervention_risk
beric_secret_known
heir_declaration_used
civil_war_occurred
civil_war_active
civil_war_resolved
losing_claimant_id
regency_active
```

---

## CANON-07 — Initial Fixture

### House values

| Field | Value |
|---|---:|
| `wealth` | 60 |
| `debt` | 20 |
| `legitimacy` | 55 |
| `influence` | 35 |
| `cohesion` | 45 |
| `succession_stability` | 35 |
| `estate_count` | 1 |
| `formal_heir_id` | `aldren_arven` |
| `current_head_id` | `edric_arven` |
| `turn` | 1 |
| `action_points` | 2 |

### Character values

Ages MUST be stored in months.

| ID | Age | Health | Claim | Ability | Loyalty | Ambition |
|---|---:|---:|---:|---:|---:|---:|
| `edric_arven` | 54 years | 30 | 90 | 55 | null | 35 |
| `myra_arven` | 47 years | 70 | 70 | 60 | 75 | 45 |
| `aldren_arven` | 18 years | 55 | 75 | 40 | 70 | 45 |
| `rowen_arven` | 16 years | 80 | 45 | 70 | 50 | 80 |
| `beric_arven` | 49 years | 65 | 40 | 65 | 45 | 75 |

### Relationship values

| Pair | Value |
|---|---:|
| Edric–Aldren | 65 |
| Edric–Rowen | 55 |
| Myra–Aldren | 80 |
| Myra–Rowen | 65 |
| Beric–Aldren | 30 |
| Beric–Rowen | 75 |
| Aldren–Rowen | 45 |

### Initial flags

```text
marriage_partner_house_id = null
marriage_completed = false
velor_intervention_risk = false
beric_secret_known = false
heir_declaration_used = false
civil_war_occurred = false
civil_war_active = false
civil_war_resolved = false
losing_claimant_id = null
regency_active = false
```

---

## CANON-08 — Turn State Machine

Each turn MUST execute in this order:

```text
1. TURN_START
2. PLAYER_ACTIONS
3. FIXED_OR_CONDITIONAL_EVENT
4. EVENT_CHOICE_RESOLUTION
5. END_OF_TURN_UPKEEP
6. TERMINAL_CHECK
7. ADVANCE_TURN
```

### Turn start

At `TURN_START`:

- Set `action_points = 2`.
- Clear the set of actions used during the current turn.
- Present current state and any known fixed event.

### Player actions

During `PLAYER_ACTIONS`:

- Each action consumes exactly one action point.
- The same action ID MUST NOT execute twice in one turn.
- The player MAY end the action phase with unused action points.
- Invalid actions MUST be disabled or rejected without changing state.
- Action effects MUST be atomic.

### Event choices

Choices inside fixed or conditional events do not consume action points.

### End-of-turn upkeep

At `END_OF_TURN_UPKEEP`:

- Add six months to every living character's `age_months`.
- Do not apply random death in the first playable.
- Do not apply unspecified random health changes.
- If `debt > 0` and the turn is even, increase `debt` by `2`.
- Clamp bounded values.

Edric's turn-6 death occurs before turn-6 upkeep.

### Terminal checks

Immediate defeat checks run after every action, event resolution, and upkeep.

Final victory evaluation runs only during turn 12 after upkeep and after immediate defeat checks.

---

## CANON-09 — Player Actions

All values in this section are canonical first-balance values.

### `educate_aldren`

Preconditions:

```text
Edric alive
wealth >= 5
action not used this turn
```

Effects:

```text
action_points -1
wealth -5
Aldren ability +8
Aldren legal_claim +3
Edric–Aldren relationship +5
```

### `educate_rowen`

Preconditions:

```text
Edric alive
wealth >= 5
action not used this turn
```

Effects:

```text
action_points -1
wealth -5
Rowen ability +6
Rowen loyalty +4
Rowen ambition +3
Aldren–Rowen relationship -3
```

### `appease_beric`

Preconditions:

```text
wealth >= 8
action not used this turn
```

Effects:

```text
action_points -1
wealth -8
Beric loyalty +12
cohesion +6
influence -2
```

### `negotiate_marriage`

Preconditions:

```text
marriage_completed == false
wealth >= 5
action not used this turn
```

Common effects:

```text
action_points -1
wealth -5
marriage_completed = true
```

The player MUST choose exactly one partner.

#### Velor marriage

```text
marriage_partner_house_id = house_velor
wealth +20
influence +15
legitimacy +5
velor_intervention_risk = true
```

#### Cardin marriage

```text
marriage_partner_house_id = house_cardin
influence +8
cohesion +8
succession_stability +5
```

### `investigate_secret`

Preconditions:

```text
beric_secret_known == false
wealth >= 6
action not used this turn
```

Effects:

```text
action_points -1
wealth -6
beric_secret_known = true
Beric–current head relationship -5
```

### `reorganize_estate`

Precondition:

```text
action not used this turn
```

Effects:

```text
action_points -1
wealth +10
cohesion -3
```

### `reconcile_brothers`

Preconditions:

```text
influence >= 5
Aldren alive and in House Arven
Rowen alive and in House Arven
action not used this turn
```

Effects:

```text
action_points -1
influence -5
Aldren–Rowen relationship +10
cohesion +4
Rowen ambition -2
```

### `declare_heir`

Preconditions:

```text
Edric alive
heir_declaration_used == false
influence >= 10
action not used this turn
```

Common effects:

```text
action_points -1
influence -10
heir_declaration_used = true
```

#### Declare Aldren

```text
formal_heir_id = aldren_arven
Aldren legal_claim +10
succession_stability +8
Rowen loyalty -8
Beric loyalty -5
```

#### Declare Rowen

```text
formal_heir_id = rowen_arven
Rowen legal_claim +15
succession_stability -5
Aldren loyalty -12
Myra loyalty -10
Beric loyalty +10
```

---

## CANON-10 — Fixed Events

### Turn 2 — `debt_demand`

This event MUST occur on turn 2.

#### Pay now

Precondition:

```text
wealth >= 15
```

Effects:

```text
wealth -15
debt = max(0, debt -15)
legitimacy +3
```

#### Defer payment

```text
debt +10
influence -5
```

#### Request Velor support

Precondition:

```text
marriage_partner_house_id == house_velor
```

Effects:

```text
debt = max(0, debt -10)
velor_intervention_risk = true
succession_stability -3
```

### Turn 4 — `brothers_conflict`

The event occurs only if the Aldren–Rowen relationship is below 50 when the event phase begins.

#### Support Aldren

```text
Aldren legal_claim +5
Rowen loyalty -8
Beric loyalty -5
```

#### Support Rowen

```text
Rowen ability +5
Aldren loyalty -8
Myra loyalty -5
```

#### Force reconciliation

Precondition:

```text
influence >= 8
```

Effects:

```text
influence -8
Aldren–Rowen relationship +8
cohesion +3
```

If the event condition is false, record the event as avoided and show no choice.

### Turn 6 — `edric_death`

Edric MUST die during the turn-6 event phase regardless of health.

Before succession scoring:

```text
Edric alive = false
Edric role = deceased_head
```

Run succession immediately.

### Turn 8 — `post_succession_demand`

Exactly one post-succession event MUST run.

Use this priority order:

```text
1. decisive_civil_conflict
2. velor_estate_claim
3. beric_regency_demand
4. losing_brother_demand
5. cardin_mediation
6. quiet_consolidation
```

Select the first event whose condition is true.

### Turn 10 — `regime_test`

Exactly one regime test MUST run.

Use this priority order:

```text
1. claimant_departure
2. velor_pressure
3. kin_revolt
4. tax_resistance
5. estate_success
```

### Turn 12 — `final_judgment`

After turn-12 upkeep:

1. Run immediate defeat checks.
2. If no defeat applies, evaluate victory.
3. Emit exactly one terminal result ID.
4. Show the final state and causal summary.

---

## CANON-11 — Succession Scoring

All percentage terms use integer floor arithmetic.

### Aldren score

```text
score = 40
score += floor(Aldren legal_claim * 0.30)
score += floor(Aldren ability * 0.10)

if Myra loyalty >= 60:
    score += 10

if formal_heir_id == aldren_arven:
    score += 15

if Aldren–Rowen relationship >= 50:
    score += 5
```

### Rowen score

```text
score = 20
score += floor(Rowen legal_claim * 0.30)
score += floor(Rowen ability * 0.20)

if Beric loyalty >= 60:
    score += 15

if formal_heir_id == rowen_arven:
    score += 20

if Rowen ambition >= 75:
    score += 5
```

### Beric modifier

Apply exactly one branch:

```text
if Beric loyalty >= 70:
    succession_stability += 5

else if Beric loyalty < 50 and beric_secret_known == false:
    Rowen score += 10
    succession_stability -= 10

else if Beric loyalty < 50 and beric_secret_known == true:
    Rowen score += 5
    succession_stability -= 5

else:
    no modifier
```

### Tie-breaker

When scores are equal:

1. The formal heir wins.
2. If no valid formal heir exists, Aldren wins by primogeniture.

The tie-breaker does not prevent a civil-war outcome.

---

## CANON-12 — Succession Resolution

Evaluate `succession_civil_war` before all other outcomes.

### Civil war

Condition:

```text
abs(Aldren score - Rowen score) <= 5
and cohesion < 35
```

Effects:

```text
outcome_id = succession_civil_war
civil_war_occurred = true
civil_war_active = true
civil_war_resolved = false
wealth -20
influence -10
```

Set the provisional house head to the score winner using the tie-breaker in `CANON-11`.

Set the other brother as `losing_claimant_id`.

The civil war MUST be resolved or lost during the turn-8 decisive conflict.

### Stable Aldren succession

Condition:

```text
Aldren score - Rowen score >= 15
and Aldren legal_claim >= 65
and cohesion >= 40
```

Effects:

```text
outcome_id = stable_aldren
current_head_id = aldren_arven
losing_claimant_id = rowen_arven
legitimacy +10
succession_stability +15
Rowen loyalty -5
```

### Unstable Aldren succession

Condition:

```text
Aldren score > Rowen score
and stable_aldren conditions are false
```

Effects:

```text
outcome_id = unstable_aldren
current_head_id = aldren_arven
losing_claimant_id = rowen_arven
succession_stability -5
Rowen ambition +10
Beric loyalty -10
```

### Agreed Rowen succession

Condition:

```text
Rowen score > Aldren score
and formal_heir_id == rowen_arven
and cohesion >= 50
and Aldren loyalty >= 45
```

Effects:

```text
outcome_id = agreed_rowen
current_head_id = rowen_arven
losing_claimant_id = aldren_arven
legitimacy -5
```

### Contested Rowen succession

Condition:

```text
Rowen score > Aldren score
and agreed_rowen conditions are false
```

Effects:

```text
outcome_id = contested_rowen
current_head_id = rowen_arven
losing_claimant_id = aldren_arven
legitimacy -15
cohesion -15
```

### Common succession updates

After any non-civil-war succession:

- Set the new head's role to `house_head`.
- Set the losing brother's role to `claimant`.
- Set `formal_heir_id = null`.
- Keep both brothers in House Arven unless a later event removes one.
- Store a complete succession explanation record.

---

## CANON-13 — Turn-8 Post-Succession Events

### `decisive_civil_conflict`

Condition:

```text
civil_war_active == true
and civil_war_resolved == false
```

#### Buy a settlement

Precondition:

```text
wealth >= 20
```

Effects:

```text
wealth -20
cohesion +15
legitimacy +5
civil_war_active = false
civil_war_resolved = true
losing claimant loyalty +10
```

#### Grant a power share

Precondition:

```text
influence >= 10
```

Effects:

```text
influence -10
cohesion +10
succession_stability +8
losing claimant ambition +8
civil_war_active = false
civil_war_resolved = true
```

#### Refuse compromise

Immediate effects:

```text
cohesion -10
legitimacy -10
```

Deterministic resolution:

```text
if current head ability + current head legal_claim
   >= losing claimant ability + losing claimant legal_claim:
    civil_war_active = false
    civil_war_resolved = true
    losing claimant loyalty -20
else:
    estate_count = 0
```

### `velor_estate_claim`

Condition:

```text
velor_intervention_risk == true
and marriage_partner_house_id == house_velor
and succession_stability < 40
```

#### Recognize partial rights

```text
wealth +10
influence +5
legitimacy -10
succession_stability -5
```

#### Pay compensation

Precondition:

```text
wealth >= 20
```

Effects:

```text
wealth -20
legitimacy +5
velor_intervention_risk = false
```

#### Reject the claim

```text
influence -10
velor_intervention_risk = true
```

### `beric_regency_demand`

Condition:

```text
current head age_months < 240
and Beric loyalty < 60
```

#### Accept regency

```text
regency_active = true
succession_stability +10
Beric loyalty +10
influence -5
```

#### Reject regency

```text
cohesion -10
Beric loyalty -15
legitimacy +5
```

#### Use the secret

Precondition:

```text
beric_secret_known == true
```

Effects:

```text
regency_active = false
Beric loyalty -10
influence -5
cohesion -5
```

### `losing_brother_demand`

Condition:

```text
losing claimant exists
and losing claimant alive
and losing claimant in_house
and losing claimant loyalty < 45
```

#### Share estate income

```text
wealth -10
losing claimant loyalty +15
cohesion +5
```

#### Grant court office

```text
influence -8
losing claimant loyalty +10
losing claimant ambition +5
```

#### Refuse

```text
legitimacy +3
losing claimant loyalty -15
succession_stability -8
```

### `cardin_mediation`

Condition:

```text
marriage_partner_house_id == house_cardin
```

Automatic effects:

```text
cohesion +8
succession_stability +8
influence -3
```

### `quiet_consolidation`

Fallback automatic effects:

```text
legitimacy +3
succession_stability +5
```

---

## CANON-14 — Turn-10 Regime Tests

Select exactly one branch in priority order.

### `claimant_departure`

Condition:

```text
losing claimant exists
and losing claimant in_house
and losing claimant loyalty <= 20
```

Effects:

```text
losing claimant in_house = false
cohesion -10
succession_stability -10
```

Run immediate defeat checks after removal.

### `velor_pressure`

Condition:

```text
velor_intervention_risk == true
```

#### Concede revenue

```text
wealth -15
velor_intervention_risk = false
succession_stability +5
```

#### Resist politically

Precondition:

```text
influence >= 10
```

Effects:

```text
influence -10
legitimacy +5
velor_intervention_risk = false
```

#### Fail to answer

```text
estate_count = 0
```

### `kin_revolt`

Condition:

```text
cohesion < 30
```

Effects:

```text
wealth -10
legitimacy -10
succession_stability -10
```

### `tax_resistance`

Condition:

```text
current head ability < 55
or debt >= 40
```

Effects:

```text
wealth -10
debt +5
legitimacy -5
```

### `estate_success`

Fallback effects:

```text
wealth +15
legitimacy +5
succession_stability +5
```

---

## CANON-15 — Victory and Defeat

### Eligible next heir

An eligible next heir MUST:

- Be alive.
- Be in House Arven.
- Not be the current house head.
- Have `legal_claim >= 1`.
- Be a canon-approved close Arven relative.

In the locked first playable, only the surviving non-head brother can qualify.

### Immediate defeat priority

Evaluate in this order and select the first matching result:

```text
1. defeat_estate_lost
2. defeat_insolvent
3. defeat_legitimacy_collapse
4. defeat_no_eligible_heir
5. defeat_unresolved_civil_war
```

Conditions:

```text
defeat_estate_lost:
    estate_count <= 0

defeat_insolvent:
    wealth <= -30

defeat_legitimacy_collapse:
    legitimacy <= 0

defeat_no_eligible_heir:
    turn >= 6 and no eligible next heir exists

defeat_unresolved_civil_war:
    turn == 12 and civil_war_active == true
```

### Basic victory

At the end of turn 12, victory requires:

```text
current head alive
estate_count >= 1
eligible next heir exists
legitimacy >= 1
wealth > -20
civil_war_active == false
```

### Victory classification

Select exactly one result using this priority.

#### `victory_blood_bought`

```text
civil_war_occurred == true
civil_war_resolved == true
basic victory == true
```

#### `victory_stable_succession`

```text
legitimacy >= 65
cohesion >= 60
succession_stability >= 65
wealth >= 40
basic victory == true
```

#### `victory_fragile_survival`

```text
basic victory == true
```

Exactly one terminal result MUST be emitted.

---

## CANON-16 — UI and Chronicle Contract

### Required screens

The first playable MUST contain:

```text
Start Screen
Play Screen
Succession Resolution Screen
End Screen
```

### Start Screen

Required controls:

- New Game.
- Quit.

### Play Screen

The screen MUST expose:

- Current turn and half-year.
- Remaining action points.
- Current head.
- Formal heir.
- Main character list.
- House state.
- Current event and choices.
- Available actions.
- End Turn.
- Recent chronicle entries.

### Succession Resolution Screen

The screen MUST expose:

- Edric's death.
- Aldren's score and modifiers.
- Rowen's score and modifiers.
- Tie-breaker if used.
- Beric modifier.
- Selected succession outcome.
- Immediate state changes.

### End Screen

The screen MUST expose:

- Terminal result ID and localized title.
- Victory class or defeat cause.
- Final house state.
- Succession outcome.
- Major choices.
- Seed.
- Restart control.

### Chronicle

Each chronicle entry MUST include:

- Turn and season.
- Actor or house.
- Action or event.
- Direct consequence.

The chronicle is play-history evidence, not decorative prose.

Example output:

```text
Year 1, Spring
Edric invested house wealth in Aldren's education.

Year 2, Spring
House Arven accepted Velor marriage support.

Year 3, Autumn
Edric Arven died after a long illness.

Year 3, Autumn
Aldren inherited the house, but Rowen and Beric rejected a stable settlement.
```

---

## CANON-17 — Determinism and Promotion Gate

### Determinism

The implementation MUST satisfy:

```text
same canon version
+ same initial fixture
+ same seed
+ same ordered actions
+ same event choices
= same state history and terminal result
```

Requirements:

- Use one controlled RNG stream if randomness is introduced.
- Succession itself MUST remain deterministic.
- Do not use system time as gameplay input.
- Do not call network services.
- Record the seed on the End Screen.
- Core rules MUST be callable without rendering the UI.
- UI nodes MUST NOT be the source of truth for simulation state.

### Required reachable outcomes

Automated or scripted legal play paths MUST prove that the following are reachable from the default fixture:

- `stable_aldren`.
- `unstable_aldren`.
- `agreed_rowen` or `contested_rowen`.
- `succession_civil_war`.
- At least two victory result IDs.
- At least three defeat result IDs.

### Automated validation

The first playable MUST support at least 100 automated complete runs with:

- No crash.
- No invalid state transition.
- No bounded value outside `0..100` after clamping.
- Exactly one terminal result per run.
- Reproducible repeated identical runs.
- Succession explanation matching applied score calculations.

### Human promotion gate

Technical completion does not authorize scope expansion.

A human play review MUST answer with observed evidence:

1. Does choosing between Aldren and Rowen create a real dilemma?
2. Does the known turn-6 death create preparation pressure?
3. Do two action points force meaningful sacrifice?
4. Does the succession result feel causally connected to prior choices?
5. Are marriage and kin management both useful and dangerous?
6. Does the player feel responsible for a house rather than a spreadsheet?
7. Does failure create a desire to retry with another strategy?

Promotion requires positive evidence for questions 1, 3, 4, and 7.

If the gate fails, revise the existing loop or reconsider the project. Do not add major systems to compensate.

---

## CANON-18 — Mutable Balance vs. Protected Meaning

### Protected meaning

Changing any item below requires an explicit canon-change task:

- Commercial single-player dynastic survival identity.
- Godot 4 and GDScript runtime.
- Offline runtime with no external LLM.
- House continuity as the player role.
- Succession as the central resolution system.
- The 12-turn first playable.
- Two actions per turn.
- Mandatory Edric death on turn 6.
- Aldren as the lawful but weaker candidate.
- Rowen as the stronger but less legitimate candidate.
- Beric as the pro-Rowen internal actor.
- Velor as high-benefit interference risk.
- Cardin as lower-benefit stabilizer.
- Explainable deterministic succession.
- Scope lock in `CANON-03`.
- Promotion gate in `CANON-17`.

### Mutable balance values

A dedicated balance task MAY change:

- Initial numeric values.
- Action costs.
- Action effect magnitudes.
- Succession weights.
- Thresholds.
- Event effect magnitudes.
- Target pacing within the locked turn count.
- UI layout and presentation.
- Chronicle wording.

A balance change MUST preserve protected meaning and MUST include reproducible simulation or human-play evidence.

---

## CANON-19 — Post-Promotion Expansion Order

After the first playable passes the human promotion gate, expand one player value at a time.

Preferred candidate order:

1. A second succession generation.
2. Actual marriage partners and descendants.
3. Persistent inter-house relationships and inherited grudges.
4. Loss of status followed by recovery.
5. Limited regional politics.
6. Multiple starting houses.
7. Long-run victory objectives.

Do not increase world scale before the single-house choice loop remains understandable and replayable across multiple generations.

---

## CANON-20 — Final Boundary

Every feature MUST strengthen this product definition:

> A complete dynastic survival strategy game in which the player directly shapes succession, marriage, family relationships, decline, and recovery, and sees those consequences persist across generations.

A feature that does not strengthen this definition is out of scope.
