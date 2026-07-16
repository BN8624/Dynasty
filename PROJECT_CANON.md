# PROJECT_CANON.md

**Project codename:** `DYNASTY`  
**Canon version:** `0.4.1`  
**Status:** `PRODUCT_DIRECTION_AND_FIRST_PLAYABLE_LOCKED`

This file is the project-specific source of truth for durable product identity, commercial direction, gameplay contracts, protected boundaries, and first-playable validation.

---

# 1. Product Identity

## 1.1 Product

`DYNASTY` is a commercial PC single-player dynastic strategy game.

The player manages the continuity of a noble house across multiple generations. The intended commercial product is a mid-sized indie strategy game whose primary reward is growing a minor house into a lasting and influential dynasty.

A single full campaign SHOULD target approximately 15–30 hours.

## 1.2 Technology

The shipped game MUST use:

- Godot 4.
- GDScript.
- A 2D, mouse-driven interface.
- Turn-based simulation.
- Offline runtime.
- No external LLM dependency.
- No network dependency for core play.

Python MAY be used for development-only tools such as balance simulation, fixture generation, data validation, and statistical analysis.

Python MUST NOT be required to run the shipped game.

## 1.3 Core Promise

> Grow a vulnerable house into a lasting dynasty by resolving family dilemmas, pursuing long-term plans, and surviving the consequences of succession across generations.

## 1.4 Emotional Priority

The intended player experience MUST prioritize:

1. Dynasty growth and achievement.
2. Family political drama.
3. Harsh survival pressure.
4. Emergent-history observation.

The game MUST NOT become primarily a passive history viewer.

## 1.5 Player Role

The player uses a hybrid control model.

At house level, the player manages durable concerns such as:

- Education.
- Marriage.
- Heir preparation.
- Succession designation.
- House assets.
- Long-term plans.
- Family obligations.

The current house head determines or limits actions that require personal authority, including politics, finance, negotiation, offices, and title-dependent decisions.

When the house head changes, the player's dynasty-level perspective continues, but available actions and their effectiveness MAY change.

## 1.6 Product Boundary

This project is a complete game.

It is not:

- A generic history simulator.
- A dynasty-game construction kit.
- A rule editor.
- A world-generation tool.
- A general simulation framework.
- A generated-fiction product.
- A `Crusader Kings`-scale simulation of geography, warfare, religion, and culture.

The product MUST achieve scale through reusable systems and accumulated consequences rather than manual content volume alone.

---

# 2. Protected Design Invariants

## 2.1 Family Is the Strategy Space

Important characters MUST have kinship, succession rights, loyalty, ambition, relationships, and conflicting interests.

Characters MUST NOT function only as disposable stat bonuses.

## 2.2 Family Dilemmas Drive Moment-to-Moment Play

The core turn priority is:

1. Resolve or defer a family dilemma.
2. Advance long-term dynasty plans.
3. Allocate remaining scarce actions and resources.

A meaningful dilemma MUST:

- Involve identifiable characters with prior relationships.
- Create winners and losers inside the family.
- Affect at least one long-term system.
- Preserve consequences beyond the current scene.
- Avoid a universally correct option.
- Be understandable without revealing every hidden future result.

The game MUST NOT become a routine sequence of optimal resource conversions.

## 2.3 Long-Term Plans Compete With Immediate Crises

The player MUST be able to pursue multi-turn plans such as heir education, marriage networks, rank advancement, property recovery, family reconciliation, political leverage, and succession preparation.

Delayed or abandoned plans MUST remain visible enough for the player to understand their opportunity cost.

## 2.4 Succession Is the Main Resolution Point

Succession MUST resolve consequences accumulated before death, including:

- Education.
- Formal heir declaration.
- Marriage.
- Kin management.
- Relationship changes.
- Discovered secrets.
- House legitimacy.
- House cohesion.

Succession MUST NOT be implemented as a cosmetic character swap.

## 2.5 Generational Change Must Alter the Problem

Long-campaign variety MUST prioritize:

1. Internal family structure.
2. House social rank.
3. Accumulated relationships with surrounding houses.

Later generations MUST NOT merely repeat an earlier succession with renamed characters.

## 2.6 Every Material Benefit Has a Cost

No action may solve a major problem without a cost, opportunity cost, or later risk.

Required trade-off patterns include:

- A strong marriage provides protection and invites interference.
- Training a stronger but less legitimate heir intensifies rivalry.
- Restoring wealth may damage cohesion.
- Buying kin support consumes wealth or influence.
- Changing the formal heir creates opposition.

## 2.7 Success Creates Exposure

Increasing wealth, rank, titles, branches, or descendants MUST create additional obligations, rivals, or succession risk.

The game MUST NOT become permanently safe by increasing every number.

## 2.8 Important Outcomes Must Be Explainable

For succession and terminal outcomes, the game MUST expose:

- Relevant candidates.
- Base scores.
- Applied modifiers.
- Supporters.
- Opponents.
- The selected outcome.
- Immediate state changes.

Hidden randomness MUST NOT determine succession.

## 2.9 Story Emerges From Rules

Chronicle text MUST be generated from deterministic rules and templates.

External generative AI MUST NOT be used at runtime.

---

# 3. Long Campaign Direction

Sections 3 and 4 define the intended commercial product. They do not authorize implementation beyond the first-playable scope lock.

## 3.1 Campaign Scale

The intended full campaign:

- Spans multiple generations.
- Targets approximately 15–30 hours.
- Supports rise, stagnation, decline, succession crisis, and recovery.
- Creates duration through systemic variation rather than hundreds of unrelated handcrafted events.
- Remains strategically meaningful without requiring a large navigable map or tactical warfare.

## 3.2 Internal Family Structure

Generations MAY vary through:

- Number and quality of children.
- Heir competition.
- Age gaps.
- Spousal influence.
- Guardianship.
- Regency.
- Branch houses.
- Claimant factions.
- Family offices.
- Internal civil conflict.

Internal family structure is the primary source of long-campaign variation.

## 3.3 Social Rank

The house MUST be able to rise, stagnate, fall, and recover.

Possible rank progression MAY include:

- Minor landed house.
- Established regional house.
- Major noble house.
- Royal insider.
- Royal or near-royal dynasty.

Higher rank MUST add obligations and exposure rather than acting as a permanent safety upgrade.

## 3.4 External House Memory

Relations with other houses SHOULD accumulate through marriage, debt, aid, betrayal, guardianship, hostages, rival claims, shared offices, and inherited grudges.

External politics support the family game. They MUST NOT replace it as the primary focus.

## 3.5 Campaign Completion

Campaign evaluation MUST prioritize:

1. Dynasty legacy.
2. Survival across a defined generational span.
3. Highest social rank reached.

Dynasty legacy SHOULD account for categories such as:

- Final social rank.
- Assets and wealth.
- Surviving branch houses.
- Succession continuity.
- Family cohesion or fragmentation.
- Marriage network.
- Offices and titles.
- Recovery after decline.
- Historic achievements.
- Scandals, civil wars, betrayals, and destructive debt.

The final legacy evaluation MUST summarize the dynasty's history rather than reward only maximum wealth.

The exact campaign generation count and legacy weights are mutable balance values.

---

# 4. Player Experience Hierarchy

## 4.1 House Office

The house office is the primary normal-play screen.

It MUST function as the operating center of the dynasty and present the current head, family condition, active plans, obligations, resources, rank, threats, available actions, time, and recent consequences.

It MUST NOT look or behave like a generic analytics dashboard.

## 4.2 Family Council

Important family dilemmas MUST transition to a character-centered family-council scene.

The scene MUST:

- Put affected characters at the center.
- Show each participant's position or demand.
- Make emotional and political costs legible.
- Present a limited set of consequential choices.
- Return to the house office with persistent consequences.

A major family dilemma MUST NOT be reduced to a minor notification popup.

## 4.3 Genealogy

Genealogy is a supporting analysis tool, not the default play surface.

It SHOULD display bloodlines, marriages, children, deceased members, branches, claims, and current or potential heirs.

---

# 5. First Playable

## 5.1 Role

The first playable is the smallest proof of the intended commercial product.

It MUST validate:

- A house-office management surface.
- A character-centered family dilemma.
- A long-term preparation problem.
- Scarce actions.
- Known succession pressure.
- Explainable succession.
- Persistent consequences.
- A desire to replay with another family strategy.

It does not implement the multi-generation campaign, social-rank ladder, branch-house system, or dynasty-legacy ending defined in Sections 3 and 4.

## 5.2 Scenario

The first playable scenario is:

```text
THE LAST WINTER
```

## 5.3 Validation Question

The first playable exists to answer:

> Is preparing for a known death, choosing among conflicting family interests, and surviving the resulting succession crisis interesting enough to replay with a different strategy?

## 5.4 Fixed Structure

The first playable MUST have:

- Exactly 12 turns.
- Six months per turn.
- Two action points at the start of each turn.
- Edric's mandatory death on turn 6.
- Final resolution on turn 12.
- A target first-run duration of 10–20 minutes.
- A target replay duration of 5–15 minutes.

---

# 6. Canonical IDs

Stable internal IDs MUST be used. Display names MAY be localized.

## 6.1 House IDs

```text
house_arven
house_velor
house_cardin
```

## 6.2 Character IDs

```text
edric_arven
myra_arven
aldren_arven
rowen_arven
beric_arven
```

## 6.3 Action IDs

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

## 6.4 Fixed Event IDs

```text
debt_demand
brothers_conflict
edric_death
post_succession_demand
regime_test
final_judgment
```

## 6.5 Succession Outcome IDs

```text
stable_aldren
unstable_aldren
agreed_rowen
contested_rowen
succession_civil_war
```

## 6.6 Terminal Result IDs

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

# 7. Scenario Cast

## 7.1 House Arven

House Arven is a minor landed house with one estate, weak finances, low political influence, internal succession tension, and a terminally ill house head.

## 7.2 Main Characters

| ID | Role | Durable conflict |
|---|---|---|
| `edric_arven` | Current house head | Must prepare succession before mandatory death on turn 6 |
| `myra_arven` | Edric's spouse | Supports the lawful elder son |
| `aldren_arven` | Elder son and default heir | More legitimate, less capable, less healthy |
| `rowen_arven` | Younger son | More capable, less legitimate, highly ambitious |
| `beric_arven` | Edric's younger brother | Supports Rowen and seeks influence over succession |


## 7.3 External Houses

| ID | Profile | Immediate benefit | Embedded risk |
|---|---|---|---|
| `house_velor` | Wealthy and influential | Wealth and political protection | Succession and estate interference |
| `house_cardin` | Smaller and comparatively neutral | Cohesion and mediation | Limited material support |


---

# 8. State Model

## 8.1 House State

The first playable MUST track:

| Field | Type | Range | Meaning |
|---|---|---:|---|
| `wealth` | integer | unbounded | Spendable economic capacity |
| `debt` | integer | `>= 0` | Outstanding financial burden |
| `legitimacy` | integer | `0..100` | Acceptance of the current house order |
| `influence` | integer | `0..100` | Political leverage |
| `cohesion` | integer | `0..100` | Internal willingness to cooperate |
| `succession_stability` | integer | `0..100` | Current succession safety |
| `estate_count` | integer | `>= 0` | Estates controlled by the house |
| `action_points` | integer | `0..2` | Remaining actions this turn |
| `formal_heir_id` | character ID or null | — | Publicly recognized heir |
| `current_head_id` | character ID | — | Current house head |
| `turn` | integer | `1..12` | Current turn |
| `seed` | integer | — | Reproduction seed |
| `succession_outcome_id` | outcome ID or null | — | Resolved succession branch |
| `terminal_result_id` | result ID or null | — | Exactly one terminal result when play ends |

`succession_stability` is explicit state. It MUST NOT be implemented as a display-only derived value.

All bounded integer values MUST be clamped after each atomic state transition.

## 8.2 Character State

Each main character MUST track:

| Field | Type | Notes |
|---|---|---|
| `id` | stable ID | Canonical identifier |
| `display_name` | string | Localizable |
| `age_months` | integer | Internal age representation |
| `alive` | bool | Life state |
| `in_house` | bool | Whether the character remains in House Arven |
| `health` | integer | `0..100` |
| `ability` | integer | `0..100` |
| `legal_claim` | integer | `0..100` |
| `loyalty` | integer or null | `0..100`; null when not applicable |
| `ambition` | integer | `0..100` |
| `role` | stable role ID | Current position |
| `known_secrets` | set or list | Stable secret IDs |

## 8.3 Relationships

Relationships MUST use stable unordered pair keys.

The first playable MUST track:

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

## 8.4 Scenario Flags

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

# 9. Initial Fixture

## 9.1 House State

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

## 9.2 Character Values

Ages MUST be stored in months.

| ID | Age | Health | Claim | Ability | Loyalty | Ambition |
|---|---:|---:|---:|---:|---:|---:|
| `edric_arven` | 54 years | 30 | 90 | 55 | null | 35 |
| `myra_arven` | 47 years | 70 | 70 | 60 | 75 | 45 |
| `aldren_arven` | 18 years | 55 | 75 | 40 | 70 | 45 |
| `rowen_arven` | 16 years | 80 | 45 | 70 | 50 | 80 |
| `beric_arven` | 49 years | 65 | 40 | 65 | 45 | 75 |

## 9.3 Relationship Values

| Pair | Value |
|---|---:|
| Edric–Aldren | 65 |
| Edric–Rowen | 55 |
| Myra–Aldren | 80 |
| Myra–Rowen | 65 |
| Beric–Aldren | 30 |
| Beric–Rowen | 75 |
| Aldren–Rowen | 45 |

## 9.4 Initial Flags

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
succession_outcome_id = null
terminal_result_id = null
```

---

# 10. Turn State Machine

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

## 10.1 Turn Start

At `TURN_START`:

- Set `action_points = 2`.
- Clear the actions-used set for the current turn.
- Present current state.
- Present any known upcoming fixed event.

## 10.2 Player Actions

During `PLAYER_ACTIONS`:

- Each action consumes exactly one action point.
- The same action ID MUST NOT execute twice in one turn.
- The player MAY end the action phase with unused action points.
- Invalid actions MUST be disabled or rejected without changing state.
- Action effects MUST be atomic.

## 10.3 Event Choice Cost

Choices inside fixed or conditional events do not consume action points.

## 10.4 Upkeep

At `END_OF_TURN_UPKEEP`:

- Add six months to every living character's `age_months`.
- Do not apply random death.
- Do not apply unspecified random health changes.
- If `debt > 0` and the current turn is even, increase debt by `2`.
- Clamp bounded values.

Edric's turn-6 death occurs before turn-6 upkeep.

## 10.5 Terminal Checks

Immediate defeat checks run after every action, event resolution, and upkeep.

Final victory evaluation runs only during turn 12 after upkeep and after immediate defeat checks.

---

# 11. Player Actions

All listed values are canonical first-balance values.

## 11.1 `educate_aldren`

Preconditions:

```text
Edric alive
wealth >= 5
not used this turn
```

Effects:

```text
action_points -1
wealth -5
Aldren ability +8
Aldren legal_claim +3
Edric–Aldren relationship +5
```

## 11.2 `educate_rowen`

Preconditions:

```text
Edric alive
wealth >= 5
not used this turn
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

## 11.3 `appease_beric`

Preconditions:

```text
wealth >= 8
not used this turn
```

Effects:

```text
action_points -1
wealth -8
Beric loyalty +12
cohesion +6
influence -2
```

## 11.4 `negotiate_marriage`

Preconditions:

```text
marriage_completed == false
wealth >= 5
not used this turn
```

Common effects:

```text
action_points -1
wealth -5
marriage_completed = true
```

The player MUST choose one partner.

### Velor

```text
marriage_partner_house_id = house_velor
wealth +20
influence +15
legitimacy +5
velor_intervention_risk = true
```

### Cardin

```text
marriage_partner_house_id = house_cardin
influence +8
cohesion +8
succession_stability +5
```

## 11.5 `investigate_secret`

Preconditions:

```text
beric_secret_known == false
wealth >= 6
not used this turn
```

Effects:

```text
action_points -1
wealth -6
beric_secret_known = true
Beric–current head relationship -5
```

## 11.6 `reorganize_estate`

Effects:

```text
action_points -1
wealth +10
cohesion -3
```

## 11.7 `reconcile_brothers`

Preconditions:

```text
influence >= 5
Aldren alive and in house
Rowen alive and in house
not used this turn
```

Effects:

```text
action_points -1
influence -5
Aldren–Rowen relationship +10
cohesion +4
Rowen ambition -2
```

## 11.8 `declare_heir`

Preconditions:

```text
Edric alive
heir_declaration_used == false
influence >= 10
not used this turn
```

Common effects:

```text
action_points -1
influence -10
heir_declaration_used = true
```

### Declare Aldren

```text
formal_heir_id = aldren_arven
Aldren legal_claim +10
succession_stability +8
Rowen loyalty -8
Beric loyalty -5
```

### Declare Rowen

```text
formal_heir_id = rowen_arven
Rowen legal_claim +15
succession_stability -5
Aldren loyalty -12
Myra loyalty -10
Beric loyalty +10
```

---

# 12. Fixed Events

## 12.1 Turn 2 — `debt_demand`

This event MUST occur.

### Pay Now

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

### Defer Payment

```text
debt +10
influence -5
```

### Request Velor Support

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

## 12.2 Turn 4 — `brothers_conflict`

This event occurs only if the Aldren–Rowen relationship is below 50.

### Support Aldren

```text
Aldren legal_claim +5
Rowen loyalty -8
Beric loyalty -5
```

### Support Rowen

```text
Rowen ability +5
Aldren loyalty -8
Myra loyalty -5
```

### Force Reconciliation

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

If the condition is false, record the event as avoided and show no choice.

## 12.3 Turn 6 — `edric_death`

Edric MUST die during the event phase regardless of health.

Before succession scoring:

```text
Edric alive = false
Edric role = deceased_head
```

Run succession immediately.

## 12.4 Turn 8 — `post_succession_demand`

Exactly one event MUST run.

Priority:

```text
1. decisive_civil_conflict
2. velor_estate_claim
3. beric_regency_demand
4. losing_brother_demand
5. cardin_mediation
6. quiet_consolidation
```

## 12.5 Turn 10 — `regime_test`

Exactly one event MUST run.

Priority:

```text
1. claimant_departure
2. velor_pressure
3. kin_revolt
4. tax_resistance
5. estate_success
```

## 12.6 Turn 12 — `final_judgment`

After upkeep:

1. Run immediate defeat checks.
2. If no defeat applies, evaluate victory.
3. Emit exactly one terminal result.
4. Show final state and causal summary.

---

# 13. Succession Scoring

All percentage calculations use integer floor arithmetic.

## 13.1 Aldren

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

## 13.2 Rowen

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

## 13.3 Beric Modifier

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

## 13.4 Tie-Breaker

If scores are equal:

1. The formal heir wins.
2. If no valid formal heir exists, Aldren wins by primogeniture.

The tie-breaker does not prevent a civil-war outcome.

---

# 14. Succession Resolution

Evaluate civil war first.

## 14.1 `succession_civil_war`

Condition:

```text
abs(Aldren score - Rowen score) <= 5
and cohesion < 35
```

Effects:

```text
succession_outcome_id = succession_civil_war
civil_war_occurred = true
civil_war_active = true
civil_war_resolved = false
wealth -20
influence -10
```

Set the provisional house head to the score winner using the tie-breaker.

Set the other brother as `losing_claimant_id`.

The civil war MUST be resolved or lost during turn 8.

## 14.2 `stable_aldren`

Condition:

```text
Aldren score - Rowen score >= 15
and Aldren legal_claim >= 65
and cohesion >= 40
```

Effects:

```text
succession_outcome_id = stable_aldren
current_head_id = aldren_arven
losing_claimant_id = rowen_arven
legitimacy +10
succession_stability +15
Rowen loyalty -5
```

## 14.3 `unstable_aldren`

Condition:

```text
Aldren score > Rowen score
and stable_aldren conditions are false
```

Effects:

```text
succession_outcome_id = unstable_aldren
current_head_id = aldren_arven
losing_claimant_id = rowen_arven
succession_stability -5
Rowen ambition +10
Beric loyalty -10
```

## 14.4 `agreed_rowen`

Condition:

```text
Rowen score > Aldren score
and formal_heir_id == rowen_arven
and cohesion >= 50
and Aldren loyalty >= 45
```

Effects:

```text
succession_outcome_id = agreed_rowen
current_head_id = rowen_arven
losing_claimant_id = aldren_arven
legitimacy -5
```

## 14.5 `contested_rowen`

Condition:

```text
Rowen score > Aldren score
and agreed_rowen conditions are false
```

Effects:

```text
succession_outcome_id = contested_rowen
current_head_id = rowen_arven
losing_claimant_id = aldren_arven
legitimacy -15
cohesion -15
```

## 14.6 Common Succession Updates

After any non-civil-war succession:

- Set the new head's role to `house_head`.
- Set the losing brother's role to `claimant`.
- Set `formal_heir_id = null`.
- Keep both brothers in House Arven unless a later event removes one.
- Store the full score explanation for the succession screen.

---

# 15. Turn-8 Post-Succession Events

## 15.1 `decisive_civil_conflict`

Condition:

```text
civil_war_active == true
and civil_war_resolved == false
```

### Buy a Settlement

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

### Grant a Power Share

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

### Refuse Compromise

```text
cohesion -10
legitimacy -10
```

Then resolve:

```text
if current head ability + current head legal_claim
   >= losing claimant ability + losing claimant legal_claim:
    civil_war_active = false
    civil_war_resolved = true
    losing claimant loyalty -20
else:
    estate_count = 0
```

## 15.2 `velor_estate_claim`

Condition:

```text
velor_intervention_risk == true
and marriage_partner_house_id == house_velor
and succession_stability < 40
```

### Recognize Partial Rights

```text
wealth +10
influence +5
legitimacy -10
succession_stability -5
```

### Pay Compensation

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

### Reject the Claim

```text
influence -10
velor_intervention_risk = true
```

## 15.3 `beric_regency_demand`

Condition:

```text
current head age_months < 240
and Beric loyalty < 60
```

### Accept Regency

```text
regency_active = true
succession_stability +10
Beric loyalty +10
influence -5
```

### Reject Regency

```text
cohesion -10
Beric loyalty -15
legitimacy +5
```

### Use the Secret

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

## 15.4 `losing_brother_demand`

Condition:

```text
losing claimant exists
and losing claimant alive == true
and losing claimant in_house == true
and losing claimant loyalty < 45
```

### Share Estate Income

```text
wealth -10
losing claimant loyalty +15
cohesion +5
```

### Grant Court Office

```text
influence -8
losing claimant loyalty +10
losing claimant ambition +5
```

### Refuse

```text
legitimacy +3
losing claimant loyalty -15
succession_stability -8
```

## 15.5 `cardin_mediation`

Condition:

```text
marriage_partner_house_id == house_cardin
```

Effects:

```text
cohesion +8
succession_stability +8
influence -3
```

## 15.6 `quiet_consolidation`

Fallback effects:

```text
legitimacy +3
succession_stability +5
```

---

# 16. Turn-10 Regime Tests

## 16.1 `claimant_departure`

Condition:

```text
losing claimant exists
and losing claimant in_house == true
and losing claimant loyalty <= 20
```

Effects:

```text
losing claimant in_house = false
cohesion -10
succession_stability -10
```

## 16.2 `velor_pressure`

Condition:

```text
velor_intervention_risk == true
```

### Concede Revenue

```text
wealth -15
velor_intervention_risk = false
succession_stability +5
```

### Resist Politically

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

### Fail to Answer

```text
estate_count = 0
```

## 16.3 `kin_revolt`

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

## 16.4 `tax_resistance`

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

## 16.5 `estate_success`

Fallback effects:

```text
wealth +15
legitimacy +5
succession_stability +5
```

---

# 17. Victory and Defeat

## 17.1 Eligible Next Heir

An eligible next heir MUST:

- Be alive.
- Be in House Arven.
- Not be the current house head.
- Have `legal_claim >= 1`.

In the locked first playable, only the surviving non-head brother can satisfy this rule.

## 17.2 Immediate Defeat Priority

Evaluate in this order:

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
    wealth <= -10

defeat_legitimacy_collapse:
    legitimacy <= 0

defeat_no_eligible_heir:
    turn >= 6 and no eligible next heir exists

defeat_unresolved_civil_war:
    turn == 12 and civil_war_active == true
```

> **Balance revision (2026-07-16, canon 0.4 → 0.4.1):** `defeat_insolvent` threshold revised from `wealth <= -30` to `wealth <= -10` under Mutable Balance (23.2).
> Cause: every action requires wealth at least equal to its cost, so actions cannot drive wealth below 0; the only unconditional wealth-reducing events are `succession_civil_war` (−20), `share_income` (−10), `concede_revenue` (−15), `kin_revolt` (−10), and `tax_resistance` (−10), and the civil-war prerequisite `cohesion < 35` forces at least four `reorganize_estate` uses (+40 wealth). The maximum legal drain therefore cannot reach −30; a 120-run varied-strategy batch measured a minimum final wealth of −2. With the revised threshold, `defeat_insolvent` is legally reachable (regression script `S9_defeat_insolvent` in `tests/validate.gd`).

## 17.3 Basic Victory

At the end of turn 12:

```text
current head alive == true
estate_count >= 1
an eligible next heir exists
legitimacy >= 1
wealth > -20
civil_war_active == false
```

## 17.4 Victory Classification

Select exactly one result and store it in `terminal_result_id`.

Priority:

### `victory_blood_bought`

```text
civil_war_occurred == true
and civil_war_resolved == true
and basic victory is true
```

### `victory_stable_succession`

```text
legitimacy >= 65
and cohesion >= 60
and succession_stability >= 65
and wealth >= 40
and basic victory is true
```

### `victory_fragile_survival`

```text
basic victory is true
```

---

# 18. UI Contract

## 18.1 Required Screens

```text
Start Screen
House Office Screen
Family Council Screen
Succession Resolution Screen
Genealogy View
End Screen
```

## 18.2 Start Screen

Required controls:

- New Game.
- Quit.

## 18.3 House Office Screen

The house office is the default play surface.

It MUST expose:

- Current turn and half-year.
- Remaining action points.
- Current head.
- Formal heir.
- Main character status.
- House state.
- Current preparation focus and important prior choices.
- Pending obligation or threat.
- Available actions.
- Known action costs and direct effects.
- Disabled-action reasons.
- End Turn.
- Recent chronicle entries.
- Access to genealogy.

It MUST feel like the operating center of House Arven rather than a generic debug or analytics dashboard.

## 18.4 Family Council Screen

Important family dilemmas MUST use a character-centered council scene.

For the locked scenario, the turn-4 brothers' conflict and applicable turn-8 family conflict MUST use this presentation. Other important dilemmas MAY use it when doing so does not duplicate a dedicated succession or end screen.

The scene MUST expose:

- The affected characters.
- Each participant's position or demand.
- The known emotional and political stakes.
- Available choices and their known direct costs.
- A clear return to the house office after resolution.

A major family dilemma MUST NOT be presented only as a minor notification popup.

## 18.5 Succession Screen

The screen MUST expose:

- Edric's death.
- Aldren's score and modifiers.
- Rowen's score and modifiers.
- Tie-breaker if used.
- Beric modifier.
- Selected succession outcome.
- New or provisional house head.
- Losing claimant.
- Immediate state changes.

## 18.6 Genealogy View

The genealogy view is a supporting tool and MUST be reachable from the house office.

For the locked cast, it MUST show:

- Edric and Myra as parents of Aldren and Rowen.
- Beric as Edric's brother.
- Living and deceased state.
- Current head.
- Formal heir.
- Losing claimant when applicable.
- Marriage affiliation when applicable.

It MUST NOT replace the house office as the primary play surface.

## 18.7 End Screen

The screen MUST expose:

- Terminal result ID.
- Localized result title.
- Victory class or defeat cause.
- Final house state.
- Succession outcome.
- Major choices.
- Seed.
- Restart control.

---

# 19. Chronicle Contract

Chronicle entries MUST include:

- Turn and season.
- Actor or house.
- Action or event.
- Direct consequence.

The chronicle is evidence of play history, not decorative prose.

Example:

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

# 20. Determinism

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
- Succession MUST remain deterministic.
- Do not use system time as gameplay input.
- Do not call network services.
- Record the seed on the end screen.
- Core rules MUST run without rendering the UI.
- UI nodes MUST NOT be the source of truth for simulation state.

---

# 21. First-Playable Acceptance

The first playable is technically complete only when the canonical initial fixture executes the locked scenario contracts through the real game flow, including the house office, family council, succession resolution, genealogy support, and terminal result.

## 21.1 Required Reachability

Legal scripted runs beginning from the canonical initial fixture MUST prove reachability of:

- `stable_aldren`.
- `unstable_aldren`.
- `agreed_rowen` or `contested_rowen`.
- `succession_civil_war`.
- At least two victory result IDs.
- At least three defeat result IDs.

Resolver-only tests built from impossible mid-game states do not satisfy this reachability requirement.

## 21.2 Required Automated Validation

At least 100 varied legal complete runs MUST finish with:

- No crash or unresolved input state.
- No invalid state transition.
- All bounded values clamped to `0..100`.
- Exactly one `terminal_result_id` per completed run.
- Termination no later than turn 12.
- Reproducible state history for identical inputs.
- Succession evidence equal to the modifiers actually applied.

## 21.3 Human Promotion Gate

Technical completion does not authorize scope expansion. Human play review MUST evaluate:

1. Does choosing between Aldren and Rowen create a real family dilemma?
2. Does the known turn-6 death create preparation pressure?
3. Do two action points force meaningful sacrifice?
4. Does succession feel causally connected to prior choices?
5. Are marriage and kin management both useful and dangerous?
6. Is the house office understandable and does it feel like operating a dynasty rather than reading a spreadsheet?
7. Does the family council make the conflict feel centered on people rather than on a generic event popup?
8. Does failure create a desire to retry with another family strategy?

Promotion requires positive evidence for questions 1, 3, 4, 6, 7, and 8.

If the gate fails, revise the locked loop or reconsider the project. Do not add major systems to compensate.

---

# 22. Scope Lock Before Promotion

Before the human promotion gate passes, the project MUST NOT implement:

- The full multi-generation campaign.
- Generated descendants or additional named Arven characters.
- Branch-house simulation.
- The social-rank progression ladder.
- Dynasty-legacy scoring.
- A generalized long-campaign dilemma generator.
- A world map.
- Warfare.
- Armies.
- Tactical combat.
- City building.
- Trade networks.
- Religion simulation.
- Culture simulation.
- Technology trees.
- Additional named houses.
- Full character-life simulation.
- Rule editors.
- Content editors.
- Mod support.
- Multiplayer.
- Mobile targets.
- Console targets.
- Steam achievements.
- Steam cloud saves.
- Final art production.
- Voice acting.
- Runtime generative AI.
- Free-text negotiation.

Sections 3 and 4 define the future product direction only. They MUST guide first-playable architecture and presentation but MUST NOT expand the current implementation beyond the locked scenario.

Temporary UI, placeholder portraits, placeholder heraldry, basic fonts, and minimal audio are allowed only when they support first-playable validation and have safe commercial-use provenance.

---

# 23. Canon Change Boundary

## 23.1 Protected Meaning

The following contracts are protected and require an explicit canon revision to change:

- Product identity, emotional priority, player role, and runtime platform in Section 1.
- Design invariants in Section 2.
- Long-campaign direction and completion priorities in Section 3.
- House-office, family-council, and genealogy hierarchy in Section 4.
- The locked first-playable role and structure in Section 5.
- Canonical IDs and character or house roles in Sections 6 and 7.
- State semantics, fixture meaning, and turn ordering in Sections 8–10.
- The meaning and ordering of actions, events, succession, and terminal resolution in Sections 11–17.
- UI, chronicle, and determinism contracts in Sections 18–20.
- The human promotion gate and pre-promotion scope lock in Sections 21 and 22.

## 23.2 Mutable Balance

Dedicated balance work MAY change:

- Initial numeric values.
- Costs and effect magnitudes.
- Succession weights and thresholds.
- Event effect magnitudes.
- Pacing inside the locked 12-turn structure.
- Full-campaign generation count.
- Social-rank thresholds.
- Dynasty-legacy category weights.
- Dilemma selection weights and frequency.
- UI layout and presentation within the protected hierarchy.
- Chronicle wording.

Balance changes MUST preserve protected meaning and include reproducible simulation or human-play evidence.

