# P2 (Grounding Ring) - Session Handoff Checkpoint

## 0. Meta

Date: 2026-07-03.
Reason: OnCloud course-correction - P2 is executed by a NEW session, not the P1-Conductor session that scoped it.
This document is the durable checkpoint so the new P2 session can start from the gated plan, not from scratch.

Authority note (for the record): a prior session's flip grant does NOT transfer.
The new P2 session starts with NO flip; it gets its own grant from OnCloud directly (or per-PR words).
Reviewer PASS discipline applies to it exactly as from wave one.

Reviewer / coordinator peer: `ipwyagrv` (does not implement; independently git-verifies and gates each PR; holds the full P2 gate state on their board and will re-brief the new session).
Implementing peer that scoped P2: the P1-Conductor session (retains Track 1, the in-VPC smoke, NOT P2).

Base state: `development` tip `d990dd5c` (P1 complete, 8 PRs merged, zero rework).
Flag `AGENT_PIPELINE_DAG_ENABLED` default OFF; legacy `createTripV4Refs` authoritative.
The whole new DAG pipeline is behind that OFF flag, so every P2 change is inert in production until a deliberate flip.

## 1. What P2 is

Spec: `docs/ai-agent-pipeline-redesign.md`.
Read Part 4 P2 (line 581), Part 2 section B "Grounding" (line 159), section 2.2 cross-cutting (line 298), Part 6 data contracts (line 754).

P2 = the grounding ring (時效 / 簽證 / 預算 / clarify).
Four steps: `clarify_or_assume`, `resolve_entry_requirements`, `gather_temporal_evidence`, `allocate_budget_envelope`.

HEADLINE INSIGHT that shapes the whole phase: P2 is ACTIVATE-pre-designed-contract-surface + wire, NOT schema invention.
Every P2 contract type already exists in `modules/CreateTrip/pipeline/contracts.ts` (EntryRequirement, AdmissibilityGate, BudgetEnvelope, SpendByCategory, AssumptionLedger, FieldDisposition, ClarificationQuestion, ProceedGate, ResolvedRequirements, TemporalEvidence).
So `contracts.ts` is NOT a contention surface this phase (unlike P1).
The only shared-file contention is `orchestrator.ts` (`buildPipelineSteps` + `PipelineDeps`, edited by every wave, handled by sequential merges as in P1) and exactly ONE new error code in P2-2.

Exit bars (spec line 584), behavioral not structural:
- An inadmissible passport is blocked BEFORE any money is spent.
- A missing nationality triggers a question rather than a silent assumption.
- Temporal evidence returns TYPED weather / holiday / sunlight / events (fail-soft).
- The budget envelope VISIBLY changes the searched cabin class and hotel star cap.

## 2. Gated 4-wave plan (order APPROVED by the reviewer)

Model: 4 waves, one PR each, base=`development`, each adversarially verified by an independent skeptic + reviewer line-by-line gate.

Order rationale (accepted as a real dependency, not a preference): `clarify_or_assume` resolves nationality / party / budget-tier that `resolve_entry_requirements` and `allocate_budget_envelope` consume, so clarify is foundational and goes first.
`gather_temporal_evidence` is the LARGE step with external-integration schedule risk AND its consumers are P3/P4 (it gates nothing in P2's own exit bars), so it goes last to de-risk the phase.

| Wave | Step | Reuse (live) | Build (gap) | Hard exit bar | Risk |
|---|---|---|---|---|---|
| P2-1 | `clarify_or_assume` (replaces the P1 stub) | all contracts + AskAdapter/resolveProceedGate | per-field confidence thresholds -> ask/assume/present dispositions + AssumptionLedger + ProceedGate wiring to SSE | missing nationality -> ask, not assume | MED |
| P2-2 | `resolve_entry_requirements` (new + confirm_flights wiring) | LIVE passportVisa reader, EntryRequirement + AdmissibilityGate contracts | ISO-2<->ISO-3 map, admissibility hard-block, transit warnings (today []), ONE new EC | inadmissible passport blocked before spend | MED-HIGH |
| P2-3 | `allocate_budget_envelope` (new + search rewire) | budgetNormalizer, BudgetEnvelope/SpendByCategory/Money, majorToMinorAmount, cabin->Duffel | tier->amount pure fn, DIDA star-cap filter wiring | envelope visibly changes searched cabin + star | MED |
| P2-4 | `gather_temporal_evidence` (LARGE, last) | modules/weather, modules/solar, TemporalEvidence contract | holidays + events sourcing (net-new), fail-soft aggregation | typed weather/holiday/sunlight/events, fail-soft | LARGE build / LOW blast radius |

## 3. Reviewer rulings (authoritative - do not relitigate)

Order: APPROVED (clarify -> entry -> budget -> temporal). Contention analysis accepted (orchestrator.ts sequential like P1; one EC code).

DESIGN CALL - ABSORB (ruled): `resolve_entry_requirements` absorbs the `transit_visa_check` seam. One visa authority (the passportVisa read) emits both admissibility + transit warnings; a seam step that merely forwards another step's output is a near-empty fork, and refactor-don't-fork kills it.
THREE conditions on the absorb (all required):
1. Grep-prove nothing references the `transit_visa_check` step id beyond the DAG registration + the C1 fixture; both updated in the SAME PR; the PR body records "seam ABSORBED not forked" with the rationale (the only consumer rewires to the real step).
2. Keep the two outputs SEPARABLE on the entry step's result: `transitVisaWarnings` as its own field, not derivable-from-admissibility; `confirm_flights` consumes exactly the warnings, never parses admissibility internals.
3. This is the ONE seam deletion; `clarify_or_assume` (P2-1) still REPLACES its stub behind the unchanged id (swap-in-place). The absorb is justified only because the seam's only consumer rewires to the real step; that reasoning goes in the PR body.

Per-wave review bars (bring these built-in):
- P2-1: the contract's hard line at contracts.ts:148 is the bar - real-money/eligibility fields MUST be `asked` or `present`, NEVER `assumed`. "Ask only spend-blocking fields" is the correct anti-over-block posture. Exit test: nationality-missing -> ask. AssumptionLedger stays an array. ProceedGate -> AskAdapter -> the SSE channel replacing the hardcoded nulls (service:849, 944); reviewer verifies the wiring end-to-end.
- P2-2: money-gate discipline (independent skeptic verify + reviewer line-by-line). Fail-closed BEFORE any confirm_*. `entry_not_admissible`: catalog + 6 locales + generate:errors, shown at review per the errors rule. The ISO-2<->ISO-3 static map cites the source standard in a comment; no LLM-derived country codes.
- P2-3: the rewires (flightCabin + hotelStarCap from envelope) are input-source swaps on MERGED money steps - keep them minimal and clearly-hunked; reviewer diffs those files expecting near-zero logic delta. Money minor-unit throughout.
- P2-4: fail-soft per sub-source (temporal is evidence, not a correctness gate).

## 4. OnCloud scope ruling

Temporal depth (P2-4): CORE NOW, events-venue deferred to P3.
P2-4 ships weather + solar (reuse) + holidays via Nager.date (free, no-key, fail-soft) + advisories via the existing Serper client + free-text `lockedEvents` WITHOUT `venueSiteId`.
The event -> venueSiteId binding lands in P3 with `build_candidate_pool` + the site-DB fuzzy match.
This settles all three temporal scope questions (events depth, holiday source, venueSiteId timing); non-blocking for waves 1-3.

## 5. Capability reuse map (Sweep 2A) - per step

### A. resolve_entry_requirements
| Sub-capability | Asset | Status | Verdict |
|---|---|---|---|
| passport/visa reader | modules/database/mongo/functions/app/passportVisa/read.ts (readByPassportAndDestination / readManyByPassport / readManyByDestination) | LIVE | REUSE |
| PassportVisa type | modules/database/mongo/types/PassportVisa.ts (Passport ISO-3, Destination ISO-3, Requirement enum) | LIVE | REUSE |
| EntryRequirement contract | contracts.ts:223-237 | LIVE | REUSE |
| AdmissibilityGate contract | contracts.ts:239-242 ({ok:true} | {ok:"conditional"; notes[]} | {ok:false; blockedTravelers[]}) | LIVE | REUSE |
| ISO-2<->ISO-3 map | @rapideditor/country-coder (used in modules/geolocation/resolveLocation.ts) does coord->ISO-2 only | PARTIAL | BUILD a static ISO-2<->ISO-3 table (PassportVisa DB keys are alpha-3; pipeline is alpha-2) |
| transit/connection visa | modules/CreateTrip/pipeline/steps/transit-visa-check.ts | DORMANT stub | ABSORB into resolve_entry_requirements (per ruling) |

### B. gather_temporal_evidence (LARGE)
| Sub-capability | Asset | Status | Verdict |
|---|---|---|---|
| weather | modules/weather/index.ts (OpenWeather One Call 3.0: oneCall, daily[], alerts) | LIVE | REUSE |
| sunrise/sunset | modules/solar/index.ts (getSolarTimes(date,lat,lng) -> {sunrise,sunset,dawn,dusk,solarNoon}; isDaylight/isAfterSunset; fail-null on polar) matches TemporalEvidence.daylight shape | LIVE | REUSE |
| TemporalEvidence contract | contracts.ts:279-301 (lockedEvents[], holidays[], weather[], daylight[], safetyAdvisories[], disruptions[]) | LIVE | REUSE |
| public-holiday calendar | none | ABSENT | BUILD via Nager.date (OnCloud ruling), fail-soft |
| events/venue | modules/maps/functions/newPlaces (nearby only; no event verb, no showtimes) | PARTIAL | free-text lockedEvents via Serper NOW; venueSiteId binding deferred to P3 |

### C. allocate_budget_envelope
| Sub-capability | Asset | Status | Verdict |
|---|---|---|---|
| tier normalizer | modules/CreateTrip/helpers/budgetNormalizer.ts:3-23 (normalizeBudgetTier) | LIVE | REUSE |
| BudgetEnvelope contract | contracts.ts:314-320 (total:Money, perCategory:SpendByCategory, hotelStarCap:number, flightCabin:string, perNightLodging:Money) | LIVE | REUSE |
| SpendByCategory | contracts.ts:304-311 ({flights,lodging,activities,food,transfers,buffer} all Money) | LIVE | REUSE |
| Money minor-unit | contracts.ts:57-60 ({amountMinor,currency}) | LIVE | REUSE |
| currency conversion | src/app/shopping/shared/currency.util.ts:36-46 (majorToMinorAmount, zero-decimal + whole-major sets) | LIVE | REUSE |
| cabin class | modules/provider/duffel/shopping/shoppingOffers.ts (cabinClass already flows to Duffel payload) | LIVE | REUSE |
| hotel star cap | contracts.ts:317 hotelStarCap named; DIDA search has NO star pre-filter input | DORMANT | BUILD tier->starCap + wire filter into DIDA hotel search |
| tier->amount table | none | ABSENT | BUILD pure module fn (tier x nights x party x dest -> total + SpendByCategory + perNightLodging) |

### D. clarify_or_assume
All contracts LIVE and ready: AssumptionLedger (contracts.ts:152-156), FieldDisposition (136-139), ClarificationQuestion (141-144), ProceedGate (158-160), ResolvedRequirements (147-150), Confidence (68), TripRequirements input (112-134 with fieldConfidence + missingRequiredFields).
Confidence-threshold precedent: modules/CreateTrip/helpers/serper.ts:88-92.
Stub to REPLACE: modules/CreateTrip/pipeline/steps/clarify-or-assume.ts.
BUILD: per-field threshold logic + ask/assume/present decision loop + populate dispositions + derive ProceedGate. No new types.

Cross-cutting gap noted by 2A: modules/maps/types/Money.ts uses a deprecated {units,nanos} shape - not P2's job but avoid it; use the minor-unit Money + majorToMinorAmount everywhere.

## 6. Stub-seam contracts + step conventions (Sweep 2B)

### The two P1 stub seams
`clarify_or_assume` (modules/CreateTrip/pipeline/steps/clarify-or-assume.ts):
- id const `CLARIFY_OR_ASSUME_STEP_ID = "clarify_or_assume"`; dependsOn ["parse_intent"]; output `Step<AssumptionLedger>`.
- Stub: if `requirements.adults < 1`, pushes ONE ledger entry {field:"party", assumedValue:{adults:2,...}, rationale:"..."}; else returns []. Emits stub:true, stub_seam:"fixed_party_clarify".
- Consumer: `compose_narrative` ONLY, soft (not a declared dependsOn). Reads via `readResult(results, CLARIFY_STEP_ID, isAssumptionLedger)` at compose-narrative.ts:148; degrades to null if shape is off. So the output MUST stay array-derivable OR compose_narrative must be updated (it will be).

`transit_visa_check` (modules/CreateTrip/pipeline/steps/transit-visa-check.ts):
- id const `TRANSIT_VISA_CHECK_STEP_ID = "transit_visa_check"`; dependsOn ["resolve_places"]; output `TransitVisaDeferral = {deferred:true; reason; destinationCountries:CountryAlpha2[]}`.
- Stub: always defers; never gates. Emits stub:true, stub_seam:"transit_visa_deferred".
- LATENT consumer: `confirm_flights` HARDCODES `transitVisaWarnings: []` (confirm-flights.ts:184, 274) and does NOT read the step today. P2-2 must add the dep and populate warnings. Under ABSORB, confirm_flights depends on resolve_entry_requirements instead, reading its `transitVisaWarnings` field.

### Relevant contract types (verbatim shapes)
- FieldDisposition = {kind:"asked"; question:ClarificationQuestion} | {kind:"assumed"; value:unknown; rationale:string} | {kind:"present"} (contracts.ts:136-139).
- ClarificationQuestion = {field:string; prompt:string} (141-144).
- ResolvedRequirements = TripRequirements & {dispositions: Record<string,FieldDisposition>} (147-150). Comment: real-money/eligibility fields here MUST be asked or present, never assumed.
- AssumptionLedger = Array<{field:string; assumedValue:unknown; rationale:string}> (152-156).
- ProceedGate = {ok:true} | {ok:false; blockedOn:ClarificationQuestion[]} (158-160).
- EntryRequirement = {travelerIndex; destination:CountryAlpha3; status:"visa_free"|"e_visa"|"eta"|"visa_on_arrival"|"visa_required"|"no_admission"; visaType:string|null; passportValidityOk:boolean; onwardTicketRequired:boolean; vaccinations:string[]} (223-237).
- ConfirmedFlightRef has `transitVisaWarnings: string[]` already (filled by P2, hardcoded [] today).
- Branded ids: IsoDate, IsoDateTime, IanaTimeZone, CountryAlpha2, CountryAlpha3, CurrencyCode, IataCode, SiteId, OfferId - LLM must never invent; code/provider only.

### Step-authoring conventions
- Step<Output> = {id:StepId; dependsOn:StepId[]; run:(args:StepRunArgs)=>Promise<Output>} (step.ts:21-25). StepRunArgs = {ctx:PipelineRunContext; results:ReadonlyMap<StepId,unknown>}.
- dependsOn uses LOCAL string-literal id constants declared per step file; steps NEVER import sibling step files.
- Factory pattern: `make<Unit>Step(deps): Step<Output>`; deps injected via closure.
- validateDag runs first inside runPipeline; rejects duplicate ids (pipeline_dag_duplicate_step), dangling edges (pipeline_dag_missing_dependency), cycles (pipeline_dag_cycle).
- Execution: level-synchronous BFS; each wave runs all ready steps concurrently via Promise.all; ctx.signal.throwIfAborted() between waves. Step errors PROPAGATE unchanged (a throw halts the run).
- Registration: buildPipelineSteps(deps) returns the Step[] array (currently 21 steps); per-step deps come from the PipelineDeps struct; the 5 P1 stub seams read only `deps.stubs = {logger?}`.
- To graduate a stub: keep the id, swap the factory body, add a real per-step deps sub-struct to PipelineDeps, replace the call site in buildPipelineSteps. If dependsOn shape is unchanged, validateDag + BFS work unchanged.

## 7. Sharpening findings (P1-Conductor probes - save the new session the digging)

- AskAdapter EXISTS: step.ts:35 `AskAdapter = {ask:(q:ClarificationQuestion[])=>Promise<AskAnswers>}`; step.ts:59 `resolveProceedGate(gate, adapter)` routes blockedOn through adapter.ask (returns null when nothing asked). The pure layer never imports a transport; the entrypoint injects the adapter.
- PipelineResult already has a `clarificationQuestion` field (hardcoded null) and a `status:"needs_clarification"` degraded result: `buildDegradedResult(tripId, message)` at service:940 (mirrors v4Refs; HTTP renders apology, voice emits pipeline:error for non-ready).
- HALT PATH: `runDagPipeline` generator (service:286) runs `runPipeline(buildPipelineSteps(deps), ctx)` at service:346; on ANY thrown error the catch at service:358 yields `buildDegradedResult` (needs_clarification) - never a thrown generator. So a step that throws halts the whole DAG fail-closed BEFORE downstream spend steps run. This is the lever P2-1 uses to stop-before-spend on a blocked gate.
- No existing visa/admissibility EC codes -> P2-2 introduces `entry_not_admissible` (the only new code in P2).
- Serper: `createSerperClient` exists (serper.ts:334) but NO holiday/event/advisory helper functions yet - those are net-new in P2-4.

## 8. P2-1 head-start design (worked out, NOT yet coded)

This is a proposed design the new session can adopt or revise with the reviewer; it is not gated code.

Output type: change `clarify_or_assume` from `Step<AssumptionLedger>` to `Step<ResolvedRequirements>` (the designed contract; ledger + gate are derivable from `dispositions`).

Criticality table (deterministic, per gating field):
- CRITICAL, never assume (ask-or-present): `adults` and `nationality` (travelers[].nationality). Rationale for the reviewer: nationality has NO safe default (wrong nationality = visa/eligibility error + DIDA reprice/rejection); party size affects money so it is ask-or-present per contracts.ts:148. If stated -> present; if missing/low-confidence -> asked (into ProceedGate.blockedOn).
- SOFT, assume + ledger: `budgetTier` (default "mid-range" when "unknown"). If missing -> assumed with a ledger entry.
- Dates and destination are NOT clarify's job; they are grounded downstream where the steps refuse to guess (see resolve-dates.ts:244 comment).

Gate wiring (stop-before-spend, keep P2-1 EC-free if possible):
- Build ProceedGate from `asked` dispositions; call `resolveProceedGate(gate, askAdapter)`.
- The service (buildDagDeps) injects an AskAdapter. For the current single-turn HTTP/voice entrypoints there is no mid-run bidirectional round-trip, so a blocked gate must HALT fail-closed and surface `needs_clarification` + populate `clarificationQuestion` (the primary blocking question), replacing the service:849/944 nulls.
- Preferred mechanism: reuse the existing generator catch -> buildDegradedResult path (extend buildDegradedResult to carry the clarification question) rather than adding a new EC code. Confirm the exact mechanism with the reviewer (their per-wave bar explicitly verifies ProceedGate -> AskAdapter -> the SSE channel end-to-end).
- When the client re-invokes with the answer, parse_intent yields the field as present, the gate opens, the pipeline proceeds.

Consumer update (required): compose_narrative reads clarify at compose-narrative.ts:148 via `isAssumptionLedger`. Change it to read `ResolvedRequirements` and DERIVE the ledger from `dispositions` (the `assumed` entries), keeping `formatAssumptions` input an array. This is the one consumer edit the output-type change forces.

Deps: `PipelineDeps.clarifyOrAssume` gains `askAdapter` (was `deps.stubs`); buildPipelineSteps passes it; buildDagDeps in the service provides the AskAdapter impl.

Throwaway fixture (dev script, no unit tests): nationality-missing -> gate blocked -> needs_clarification + clarificationQuestion; adults+nationality present -> gate ok -> proceeds; budgetTier "unknown" -> assumed + ledger entry; ledger derived from dispositions is an array (narrative-compatible).

Behavior change to flag in the PR: with the real gate, a slice/smoke intake that omits adults or nationality will now (correctly) ASK instead of silently assuming. Flag is OFF so there is no production impact, but the Track 1 in-VPC smoke intake must include adults + nationality (or it will block on the gate).

## 9. Key file:line index

- Pipeline core: modules/CreateTrip/pipeline/{runner.ts, step.ts, contracts.ts, orchestrator.ts}.
- Stubs to graduate: modules/CreateTrip/pipeline/steps/{clarify-or-assume.ts, transit-visa-check.ts}.
- Consumers: modules/CreateTrip/pipeline/steps/{compose-narrative.ts:148, confirm-flights.ts:184,274}.
- Orchestrator service (entrypoint, flag-gated): src/app/itinerary-pipeline/services/pipeline-dag-orchestrator.service.ts (runDagPipeline:286, runPipeline call:346, catch:358, buildResult:837, buildDegradedResult:940).
- Reuse assets: modules/database/mongo/functions/app/passportVisa/read.ts; modules/weather/index.ts; modules/solar/index.ts; modules/CreateTrip/helpers/budgetNormalizer.ts; src/app/shopping/shared/currency.util.ts; modules/provider/duffel/shopping/shoppingOffers.ts; modules/CreateTrip/helpers/serper.ts:334.
- Flag: modules/environmentVariable/getEnv.ts (AGENT_PIPELINE_DAG_ENABLED, default OFF).

## 10. Guardrails (hard rules - unchanged from P1)

- Edit in place; NEVER create fooV2 / safeFoo / fooNew. Refactor, don't fork.
- All throws use CustomError with EC.* codes; a new code touches modules/errors/catalog + all 6 locales (en-US, zh-TW, zh-CN, ja-JP, ko-KR, id-ID) + `bun run generate:errors`. New codes are a contention surface.
- NO unit tests. Fixtures are throwaway dev scripts (removed or clearly marked throwaway).
- Money is ALWAYS minor-unit {amountMinor, currency}; never float, never major-unit bare numbers; convert via majorToMinorAmount at the adapter seam.
- NEVER touch attachment-processor.service.ts (PIC-207 owner).
- NEVER EDIT T-SAFE files: set_trip.ts, version.service.ts, temp-itinerary*.ts. You MAY call their public API (e.g. commitUpdate), never edit them.
- i18n: backend sends KEYS not translated strings.
- Isolation: edit ONLY inside the worktree; after edits, verify the main checkout is clean (a P1 breach wrote a file to main by mistake). Use `trash`, never `rm`.
- Toolchain: bun is the package manager, Node is the runtime; Biome is the sole linter; `bun run build` is the compile smoke; `bun run check` is the pre-push gate.
- Worktree base: feature PRs target `development`, NOT `main`. `worktree.baseRef` is unset, so the EnterWorktree default (`fresh`) would branch from origin/main which is WRONG. Create the worktree manually from development: `git worktree add .claude/worktrees/<name> -b oncloud/<branch> development`, then enter by path. A fresh worktree has no node_modules - run `bun install --cwd <worktree>` before build/generate:errors.
- Sync before branching: local `development` can be stale; `git fetch` + fast-forward to origin/development first (verify the tip) so you build on the true base.

## 11. Handoff status

P2-1 scaffolding was parked: a worktree was created and bun-installed but ZERO code was written; it is being removed cleanly (no authored changes lost).
Track 1 (the in-VPC full-money smoke: hotelId precondition PR + re-runnable harness + the run) stays with the P1-Conductor session and is NOT part of this handoff.
The reviewer `ipwyagrv` holds the full gate state and will re-brief the new P2 session on arrival.
