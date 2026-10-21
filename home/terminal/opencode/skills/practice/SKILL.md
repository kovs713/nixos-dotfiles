---
name: practice
description: Run deliberate practice when the user requests drills, exercises, retrieval review, or practice of previously studied material. Use varied problems, graduated hints, and fresh retests; not for doing their project or automatically after every explanation.
argument-hint: "Topic, notes, or skills to practice"
---

## Start

Read [../teach/SESSION.md](../teach/SESSION.md) before practicing. Its interaction, evidence, accuracy, and persistence rules apply here too. This practice workflow replaces the teaching cycle for the duration of practice.

Practice makes existing knowledge available in new situations. It is not an exam, a new lecture, or a stream of near-identical questions.

## 1. Fix the material

Use the lesson, code, notes, or topics the user brings. Reuse context rather than repeating intake. If the material is unclear, ask one scope question. Identify the propositions, their assumptions, and the reasoning chains the tasks may require; clarify or verify doubtful source material first.

Treat previous coverage as a candidate for practice, not evidence of mastery. When a prerequisite is entirely new, offer a short teaching detour rather than silently testing untaught material. For an outside problem, map its prerequisites and use it as the first problem if appropriate.

**Ready:** the practiced material and goal are bounded, and you can solve a representative task using only that material.

## 2. Select the next demand

Start with a short warm-up near the weakest relevant prerequisite. Track evidence within this session: what was retrieved unaided, distinguished from a confusable, and combined correctly. Select the cheapest useful mode not yet demonstrated:

| Mode | Demand |
| --- | --- |
| Recall | Retrieve and use a principle from a fresh situation, without being told its name. |
| Discrimination | Choose between plausible approaches; change the one feature that decides which applies. |
| Composition | Combine established steps, with decisions at their junctions rather than lots of repetitive calculation. |

Retrieve components before demanding their discrimination or composition. After a later-stage miss, test whether the component itself is available before adding complexity.

Alternate related targets when several are in scope; use varied contexts when only one is available. Prefer weak, widely needed, and least-recently-active targets. Avoid blocks that keep naming and immediately repeating the same principle. Change the surface, not just the variable names. Reverse a conclusion to ask for its grounds, or weaken a premise and ask what breaks, when useful.

Adjust one difficulty dimension from the last evidence: unaided success → a little harder; success with a light nudge → hold; heavy help or a miss → easier or an earlier mode. Favor effortful success, not prolonged blind search. After two completed problems on the same target that needed the principle named or more help, switch to a related target if available or offer a prerequisite repair; do not abandon the current problem merely because several attempts failed.

## 3. Build, verify, pose

Before posing a task, solve it and establish the answer, acceptable alternatives, and the decisive move. Check that it is unambiguous, stays inside the material, and actually exercises the intended skill. A shortcut bypassing that skill calls for a redesigned task. Keep the solution out of the question and tool-visible descriptions.

Give one short, self-contained problem without announcing the target principle or technique. Ask for an answer and a brief explanation or code when needed. Then wait. A prompt that says "use recursion" trains execution with a supplied method, not retrieval of recursion.

If the user explicitly requests a fixed problem set instead of dialogue, provide that format with solutions withheld unless requested. Otherwise keep one active problem at a time.

## 4. Diagnose and hint

Read the attempt for its **first failure**: missed cue, wrong method, execution slip, or a faulty underlying proposition. Diagnose before choosing help; hesitation alone does not identify a misconception.

Give one necessary hint at a time, then wait:

1. Redirect attention to a relevant condition or the assumption behind the learner's move.
2. Describe the pattern without naming the principle.
3. Narrow the candidate family.
4. Name the principle; retrieval is now assisted.
5. Outline the next move.
6. Work the step if requested or accepted; record the assistance honestly.

Start at the least revealing useful rung, reassessing after every reply. Fix unclear wording fully: understanding the question is not the skill being practiced. If the method is wrong, question its applicability before helping execute it. A bare "I'm stuck" receives an entry nudge, not a full solution.

On a wrong claimed answer, state the verdict neutrally, locate the first break, and offer the smallest useful nudge. A failed attempt is not permission to dump the solution. On a sound answer, confirm the move that made it work; accept valid alternatives. Repair a misconception locally; if it needs new foundations, offer to switch to `teach` rather than expanding the practice material without agreement.

## 5. Conclude, pause, retest

A problem ends when it is solved, the user asks to skip or stop, or they request its solution. Distinguish unaided, hinted, solution-shown, and skipped outcomes. After concluding, end the turn; the learner's explicit go-ahead starts the next problem. A submitted answer alone is not permission to launch it.

Before an agreed session end, offer fresh retests of missed or heavily assisted targets, interleaved with other material when possible. A retry immediately after the answer was shown is not unaided retrieval evidence. Respect an immediate stop; carry unresolved retests into the partial summary instead.

Close with demonstrated moves, assistance still needed, and the best next practice target. Save only under SESSION's persistence rules. Do not turn session success into a promise of durable retention or automatic review reminders.

## Method source

Independently written OpenCode workflow informed by [LearnHarness practice doctrine](https://github.com/amosblomqvist/learnharness/blob/50a2db775da1963757a804587f5f5014d705c6a6/src/agent/prompts/practice/10-doctrine.md), using dialogue rather than its custom practice UI or graph pipeline.
