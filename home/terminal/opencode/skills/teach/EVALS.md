# Tutor behavior checks

Run structural checks with `bun test home/terminal/opencode/check.test.ts` from the dotfiles root. They validate prompt routing, skill metadata, and local references, not teaching quality.

For behavioral checks, start fresh sessions with the actual `teach` agent or explicitly load the relevant skill. Walk through each exchange; record the model and observed behavior. These are manual acceptance scenarios, not claims of automated coverage.

| Scenario | Input / setup | Pass condition |
| --- | --- | --- |
| Cold start | «Хочу понять замыкания JS. Базовый синтаксис знаю». | One targeted prerequisite question; no lecture, fixed quiz battery, HTML, or file writes. |
| Plan | Evidence establishes lexical scope but not captured bindings. | Minimal goal-relevant map; agreement before teaching; no restarting basic syntax. |
| Prediction | Agreed closure lesson; tutor asks what happens when an outer variable changes. | Stops for the answer before explaining; next explanation explicitly resolves the prediction and ends in a new application check. |
| Lucky right | «Ответ 2, но я угадал: функции копируют все внешние значения». | Does not accept the choice as sufficient; checks the faulty model with a contrasting case before advancing. |
| Confident wrong | «Точно будет 1: замыкание всегда хранит копию значения». | Localizes the mistaken binding/value premise, repairs it, then checks a fresh case. No praise for correctness or unrelated next concept. |
| Practice entry | Request practice after a lesson covering bindings, shadowing, and closures. | Loads practice, reuses scope, poses one verified problem without naming its target or showing the answer. |
| Return to teaching | After entering through the teach skill and switching to practice: «Вернёмся к объяснению, я не понимаю захват переменной». | Loads teach, preserves the goal and evidence, repairs the dependency with explanation and a fresh check; practice's hint ladder and post-problem pause do not block teaching. |
| Stuck | During practice: «Застрял, с чего начать?» | One low-information nudge, then waits; no named principle or worked solution immediately. |
| Solution request | «Покажи решение целиком». | Gives it without obstruction; marks assistance and does not call immediate repetition independent mastery. |
| Alternative | Learner gives a valid approach different from the tutor's intended route. | Accepts it; redesigns a later problem if the target was bypassed. |
| Pace | Correctly solve a practice task; then say «Дальше». | First confirms and pauses; only the go-ahead starts a new problem, with changed target/context. |
| Early stop | «Хватит на сегодня, без финального теста». | Honest partial summary, including pending retests; no forced final task. |
| Save and resume | «Сохрани сюда прогресс» with an agreed destination, after a hinted task. | Records date, exact evidence, help, and resume point; preserves files; next session does not infer permanent mastery. |
| Explanation only | «Объясни без квизов и вопросов». | Direct explanation, no probe or forced check, no inferred assessment evidence. |
| Uncertain fact | Ask about a version-specific API the tutor cannot verify with available tools. | Discloses uncertainty; does not build the lesson on an invented guarantee. |
| Conflicting notes | Notes claim a lesson is mastered but contain no learner evidence. | Treats it as coverage/self-report and selects a targeted check, not automatic graduation. |

Also enter through the `teach` skill without selecting the agent: the same workflow must apply. After switching to practice, its hint and pause rules replace the teach cycle rather than combining both into every turn.
