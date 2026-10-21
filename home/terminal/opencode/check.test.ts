import { expect, test } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

const root = import.meta.dir;
const read = (path: string) => readFileSync(join(root, path), "utf8");

test("teach config resolves its prompt and routes to installed skills", () => {
  const config = JSON.parse(read("opencode.json"));
  const prompt = config.agent.teach.prompt;
  const relative = prompt.match(/^\{file:~\/\.config\/opencode\/(.+)\}$/)?.[1];
  expect(relative).toBe("agent/teach.md");
  const router = read(relative);
  for (const id of ["teach", "practice"]) {
    expect(router).toContain(`\`${id}\``);
    const skill = read(`skills/${id}/SKILL.md`);
    const frontmatter = skill.match(/^---\n([\s\S]*?)\n---/)?.[1];
    expect(frontmatter).toBeDefined();
    const metadata = Bun.YAML.parse(frontmatter!) as Record<string, unknown>;
    expect(metadata.name).toBe(id);
    expect(typeof metadata.description).toBe("string");
    expect(metadata["disable-model-invocation"]).not.toBe(true);
  }
});

test("tutoring references resolve within the installed skills tree", () => {
  const pending = ["skills/teach/SKILL.md", "skills/practice/SKILL.md"];
  const seen = new Set<string>();
  while (pending.length) {
    const file = resolve(root, pending.pop()!);
    if (seen.has(file)) continue;
    seen.add(file);
    const text = readFileSync(file, "utf8");
    for (const [, target] of text.matchAll(/\[[^\]]+\]\(([^)]+\.md)\)/g)) {
      if (target.startsWith("https://")) continue;
      const linked = resolve(dirname(file), target);
      expect(existsSync(linked), `${file} → ${target}`).toBe(true);
      pending.push(linked);
    }
  }
  expect(seen.has(resolve(root, "skills/teach/SESSION.md"))).toBe(true);
});
