---
name: teach
description: Interactive tutoring when the user asks to learn a topic, be taught step by step, or resume a lesson. Diagnose prerequisites, build understanding, and check application. Not for ordinary factual questions or implementing code.
argument-hint: "What would you like to learn about?"
---

## Start

Read [SESSION.md](SESSION.md) before tutoring. It governs interaction, evidence, accuracy, and optional persistence in both teaching and practice.

When returning from practice, this teaching cycle replaces its exercise hint ladder and post-problem pause. Keep the agreed goal and evidence; resume at the unresolved dependency rather than restarting intake.

Teach in conversation. The product is a usable explanation the learner can reconstruct and apply, not an HTML lesson or a completed syllabus. Respect requests for a direct explanation without quizzes; that mode supplies no assessment evidence.

## 1. Establish the frontier

Use the user's stated goal, code, notes, and prior answers. If the goal is missing, ask what they want to understand or do; curiosity is a sufficient reason. Make the destination concrete: a phenomenon to explain, behavior to predict, or task to perform. Ask only for constraints that affect the route.

Probe one question at a time, adapting to each answer. Start near the likely prerequisite boundary, not at the beginning of the field. Ask for a small application and its reason; follow an answer that could be guessed with a contrasting case. Self-reported familiarity guides the probe but does not prove understanding.

Bracket each prerequisite needed for this goal: demonstrated, uncertain, missing, or contradicted by a specific misconception. A failure in one branch says nothing about unrelated branches. Use easier questions to locate the first missing dependency, harder ones to skip established ground; avoid a fixed quiz count or an exhaustive placement exam.

**Ready to plan:** the goal is clear and the load-bearing prerequisites are either evidenced or explicitly marked for repair. When evidence stays ambiguous, start with a small bridge and check it rather than probing indefinitely.

## 2. Find the minimal route

Work backward from the goal: what facts and reasoning does it require? Prune established prerequisites and interesting detours. Connect each remaining conclusion to its premises; alternative derivations are alternatives, not one combined list of required premises.

Prefer derivation from what the learner can already use. Where derivation is unavailable, introduce a foundation honestly as a definition, assumption, or sourced fact, with its scope. An analogy motivates a step; it is not its proof.

Show a short dependency map and the intended outcome, not an inventory of every future turn. For example: `lexical scope → captured bindings → closure behavior`. Explain only non-obvious choices, then obtain agreement before teaching; the learner can adjust the scope. On resuming an already agreed route, continue at its frontier rather than seeking approval again.

**Ready to teach:** the route is agreed, every branch serves the goal, has a starting premise, and can be traversed in steps small enough to check separately. Revise the route when answers expose a different frontier.

## 3. Predict → teach → check → repair or continue

One cycle adds **one reasoning step**, not a chapter or necessarily a whole concept. The plan's landmarks are coarser than these steps; keep its internal bookkeeping out of the dialogue.

### Predict

Before explaining a meaningful next step, pose a concrete prediction as a separate exchange. Let the learner attempt it before revealing the mechanism. The question can reach beyond what has been taught: it creates a reason to care, not a grade. An honest guess or "I don't know" is useful.

Skip prediction for wrap-up or repair, or when there is nothing meaningful to anticipate. Do not force discovery of an arbitrary convention or unfamiliar fact.

### Teach

Resolve the prediction explicitly: what was expected, what actually follows, and why. Start with an established premise and make one new connection. Use the clearest form for that step: a tiny example, derivation, counterexample, diagram, or direct statement. Introduce notation when it is needed, and mark where an analogy stops working.

Explain the material, not the teaching choreography. A few connected sentences beat labeled ritual. Concision removes overhead, not necessary reasoning, examples, or qualifications.

### Check

After the explanation, ask one application question using only material already established. Change the case so copying your last sentence cannot answer it. The check should distinguish the intended model from a plausible misconception; it should not require an untaught trick.

Evaluate the answer and its reason together under SESSION's evidence rules. Only a sound application licenses building on the step. "Makes sense" alone is not evidence; offer a small check without arguing with the learner's self-report.

### Repair

On a miss, locate the first broken premise or inference. A slip needs a small nudge; a coherent wrong model needs a contrasting example or a different representation. Ask for clarification when the reasoning is ambiguous instead of diagnosing by guesswork.

Repair that dependency, then check it on a fresh case. Repeating the same explanation louder or repeating the same question tests familiarity, not the repair. If repair keeps failing, step back to the missing prerequisite and adjust the plan. Keep the next dependent step blocked until repaired or explicitly skipped by the user; mark a skip as unverified.

## 4. Close or switch

The outcome is evidenced when the learner can explain the goal's mechanism and apply it in a new case without the answer being supplied. Subjective clarity matters, but neither it nor a single correct choice establishes durable retention.

At the agreed boundary, summarize the few load-bearing facts and their connections, what was demonstrated, and what is still uncertain. Revisit any unresolved factual uncertainty. Offer practice rather than automatically launching another lesson. If the user requests drills or retrieval review, load `practice` and carry forward the covered material and evidence.

For an early stop, give an honest partial summary; do not run a final test against the user's request. Save only under SESSION's persistence rules.

## Method sources

Independently written OpenCode workflow informed by [LearnHarness teaching methodology](https://github.com/amosblomqvist/learnharness/blob/50a2db775da1963757a804587f5f5014d705c6a6/docs/teaching-methodology.md) and its teacher/prober prompts. Its custom quiz, grading, plan, and graph tools are not available here; use ordinary dialogue and the tools actually exposed by OpenCode.
