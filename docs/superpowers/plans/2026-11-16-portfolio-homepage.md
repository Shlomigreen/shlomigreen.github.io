# Portfolio Homepage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the LoveIt blog with a single "Moss & clay blobs" profile card, including a typed `~ whoami` title chip and content driven entirely by `config.toml`, while keeping the three old posts readable at their existing URLs.

**Architecture:** Hugo with no external theme. It uses three project layouts (`baseof`, `index`, `single`), two local shortcodes that replace LoveIt's, and one static CSS file. List, taxonomy, and RSS outputs are disabled, so the home page and post pages are the only things built.

**Tech Stack:** Hugo extended 0.115.4 (pinned in `.github/workflows/hugo.yaml`), plain CSS, a small inline JS snippet, Google Fonts, and Font Awesome Free 6.5.2 brands (cdnjs).

**Spec:** `docs/superpowers/specs/2026-11-16-portfolio-homepage-design.md`
Visual references in `.superpowers/brainstorm/39353-1794829533/content/`: use option B in `homepage-v4-styles.html` for the card (start from its `.b` CSS rules and blob/grain markup), and the pill, slot, and typing script in `whoami-v2.html` for the chip.

## Global Constraints

- Palette: surface #f2efe6, ink #1f2b22, moss #3f5a3c, fern #6f8f68, lichen #b7c2a0, bark #6b4f3a, clay #865a3c, pine #1f2b22.
- Fonts: Bricolage Grotesque (name/headings), Figtree (body), IBM Plex Mono (handle), loaded from Google Fonts.
- Card content order: avatar → name → handle → `~ whoami` chip → icons, all centered.
- No personal content may be hard-coded in templates. Name, handle, avatar, titles, and social links (`name`, `url`, `icon`) all come from `site.Params`.
- Default titles, in order: `ai-engineer`, `tech-lead`, `data-scientist`, `team-lead`, `ai-builder`, `3d-printing-artist`.
- Chip: three dots (clay, lichen, fern), a `~ whoami` prompt in lichen, the title in #e0b48f with a block cursor. Type at 90ms per character, hold 1800ms, delete at 45ms per character, wait 350ms, then type the next title. Fixed width equals the longest title length in `ch`.
- Links: https://github.com/Shlomigreen, https://www.linkedin.com/in/shlomigreen/, https://x.com/theshlomigreen.
- Avatar default: https://avatars.githubusercontent.com/u/31320788?v=4
- Icons: `<i class="fa-brands fa-{{ .icon }}" aria-hidden="true">`. Defaults are `github`, `linkedin`, and `x-twitter`.
- There is no link to the posts anywhere on the home page. Posts keep the `/posts/<bundle>/` URLs and are not marked noindex.
- Must build with Hugo 0.115.4, and the CI workflow stays unchanged.
- No horizontal scroll at 360px width, even with the 18-character `3d-printing-artist` in the chip. Hover/tilt animations, blob drift, and typing are disabled under `prefers-reduced-motion: reduce`, which shows the first title statically.

## Review Focus

1. A visitor following an old shared link to `/posts/20241005/` should get the full post, including both example boxes. This is covered by the Task 2 grep checks.
2. Phone width (360px): the blobs must not cause horizontal scroll and the card must fit with a gutter. Check this in Task 1 with `overflow:hidden` on the frame plus a manual viewport check.
3. Code blocks in posts need to stay readable without LoveIt's syntax CSS. Set `markup.highlight.noClasses = true` (inline styles) in Task 2.
4. Keyboard users need a visible focus ring on the icon links and an `aria-label` on each. Screen readers should get the titles once, as text, not the typing. Check with a grep in Task 1.
5. Editing the config must be enough. A new title or social entry appears with no template change, and a longer title widens the chip. Task 1 Step 6 builds once with a temporary extra title to prove it.

---

### Task 0: Branch and local Hugo

- [ ] **Step 1:** `git checkout -b portfolio-redesign`
- [ ] **Step 2:** Download Hugo extended 0.115.4 for macOS into the session scratchpad. Use `hugo_extended_0.115.4_darwin-universal.tar.gz` from the GitHub releases page. Do not install it system-wide.
- [ ] **Step 3:** Run `$HUGO version`. Expected: it prints `v0.115.4` and `extended`.

### Task 1: Remove LoveIt, add the base and home layouts and the CSS

**Files:**
- Delete: `themes/LoveIt` (`git submodule deinit -f themes/LoveIt && git rm -f themes/LoveIt`), `.gitmodules`, `assets/css/`, `resources/_gen/`, `.vscode/loveit.code-snippets`, `content/about/`, `.hugo_build.lock`
- Modify: `config.toml` (rewrite)
- Create: `layouts/_default/baseof.html`, `layouts/index.html`, `static/style.css`

**Interfaces:**
- Produces: `site.Params` keys `name`, `handle`, `avatar`, `titles` ([]string), and `social` ([]{name, url, icon}). Also `baseof.html` with `{{ block "main" . }}` and a `<body class="{{ block "bodyclass" . }}{{ end }}">` hook. `style.css` defines the palette as CSS custom properties `--surface --ink --moss --fern --lichen --bark --clay --pine`. Task 2 uses both.

- [ ] **Step 1: Rewrite `config.toml`.** Keep `baseURL`, `languageCode = "en"`, and `title = "Shlomi Green"`. Add `disableKinds = ["taxonomy", "term", "section", "RSS", "sitemap"]` and `[markup.goldmark.renderer] unsafe = false`. Add `[params]` with `name = "Shlomi Green"`, `handle = "@shlomigreen"`, `avatar`, `description`, `titles = [...]` (the six defaults), and a `[[params.social]]` array of `{name, url, icon}` for the three links, with a comment above each block saying what it controls. Drop everything else, including `theme`, `menu`, `outputs`, and all LoveIt params.
- [ ] **Step 2: Create `baseof.html`.** It contains the doctype, charset, viewport, `<title>{{ .Title }}` (or the site title on home), a meta description, the existing favicon links from `static/`, the Google Fonts `<link>`, the Font Awesome 6.5.2 `brands.min.css` + `fontawesome.min.css` from cdnjs, and `/style.css`.
- [ ] **Step 3: Create `layouts/index.html`.** It defines `bodyclass` as `home` and `main` as the card markup from mockup option B. Name, handle, and avatar come from params (avatar `alt` = name). Build the chip as `<p class="whoami" data-titles="{{ jsonify site.Params.titles }}">`. Inside it, put the dots, the prompt, and a `.slot` span with `style="--w: {{ $max }}ch"`, where `$max` is the longest title length (via `range` + `strings.RuneCount`). The slot is `aria-hidden` and initially contains `first title` + caret. Add a visually-hidden span that reads "Titles: ai-engineer, tech-lead, …" (built with `delimit`). The icons loop over `site.Params.social` with `<a href aria-label="{{ .name }}" rel="me noopener" target="_blank">` + the Font Awesome `<i>`. Inline the typing script from `whoami-v2.html`, reading titles from `data-titles` and returning early when `matchMedia('(prefers-reduced-motion: reduce)')` matches.
- [ ] **Step 4: Create `static/style.css`.** Port the option B rules from the mockup: the full-viewport pine frame (`min-height:100svh`, `overflow:hidden`), the blobs, the grain, the frosted card, the lichen handle pill, the bark title, and the pine icons that turn clay on hover. Add the blob drift (`@keyframes drift1/2/3` copied from `whoami-v3-drift.html`: translate up to 40px, rotate or scale, and border-radius morph, `ease-in-out infinite alternate` over 22s, 26s, and 18s), the chip rules (fixed `.slot` width, caret blink), a `max-width: 400px` media query that shrinks the chip font and card padding so an 18-character title fits at 360px, `.visually-hidden`, `a:focus-visible{outline:3px solid var(--clay);outline-offset:3px}` and a `@media (prefers-reduced-motion: reduce)` block that removes transitions and transforms.
- [ ] **Step 5: Build.** Run `$HUGO --gc --minify -d /tmp-scratch/public`, writing into the scratchpad. Expected: exit 0 with no `WARN`/`ERROR` lines about missing layouts.
- [ ] **Step 6: Verify the output.** Run these greps against the built `index.html`:
  - `grep -c 'aria-label' index.html` returns 3.
  - `Shlomi Green`, `@shlomigreen`, and `AI / ML Engineer` are each present.
  - `grep -c '/posts/' index.html` returns 0.
  - `data-titles` contains all six titles, and the slot's `--w` is `18ch`.
  - `grep -c 'fa-brands fa-' index.html` returns 3.
  - Temporarily add the title `a-much-longer-title-here` and a fourth social entry to config, then rebuild. `--w` should become `24ch` and there should be 4 icons. Revert the config afterwards.
  - `ls` shows no `tags/`, `categories/`, or `index.xml`.
- [ ] **Step 7: Check it visually.** Run `$HUGO server` and open it at desktop width and at 360px using browser devtools or the chrome-devtools MCP. There should be no horizontal scroll while `3d-printing-artist` is typed, the chip should not change width, and the card should match mockup B. With reduced motion emulated, it shows a static `ai-engineer`.
- [ ] **Step 8: Commit.** Message: `feat: replace LoveIt with single profile card`.

### Task 2: Post page and replacement shortcodes

**Files:**
- Create: `layouts/_default/single.html`, `layouts/shortcodes/admonition.html`, `layouts/shortcodes/person.html`
- Modify: `config.toml` (add `[markup.highlight] noClasses = true`), `static/style.css` (add `.post` rules)

**Interfaces:**
- Consumes: `baseof.html` blocks and the palette variables from Task 1.

- [ ] **Step 1: Create `single.html`.** It defines `bodyclass` as `post` and `main` as a readable article. The article has a max-width of 68ch on a surface background, `.Title` and `.Params.subtitle` in Bricolage, and the date as `{{ .Date.Format "Jan 2, 2006" }}` in Plex Mono. Below that comes `.Content`, then a small "← Shlomi Green" link to `/`. There are no blobs on this page.
- [ ] **Step 2: Create `admonition.html`.** Render `<details class="admonition" {{ if .Get "open" }}open{{ end }}><summary>{{ .Get "title" }}</summary>{{ .Inner | .Page.RenderString }}</details>`. Positional/named params: `type` is ignored, while `title` and `open` are used.
- [ ] **Step 3: Create `person.html`.** Render `<a href="{{ .Get "url" }}">{{ .Get "name" }} ({{ .Get "nick" }})</a>`.
- [ ] **Step 4: Style posts.** Add `.post` rules to `style.css`: body text in ink on surface, links in moss, `pre` with a lichen border and horizontal scroll, and `.admonition` with a fern left border and a bold summary.
- [ ] **Step 5: Build.** Same command as Task 1, Step 5. Expected: exit 0 with no errors about unknown shortcodes.
- [ ] **Step 6: Verify the old URLs.** All of these must hold in the built output:
  - `posts/20240928/index.html`, `posts/20241005/index.html`, and `posts/identifying-bottlenecks/index.html` all exist.
  - `grep -c '<details' posts/20241005/index.html` returns 2.
  - `grep -c 'x.com/theshlomigreen' posts/20241005/index.html` returns at least 1.
  - `posts/index.html` does not exist.
  - The draft `first_post` is not built.
- [ ] **Step 7: Check visually.** Open `/posts/20241005/` at 360px. The code blocks should scroll horizontally inside their box and the page should not scroll sideways.
- [ ] **Step 8: Commit.** Message: `feat: plain post page and local shortcodes for archived posts`.

### Task 3: Finish

- [ ] **Step 1:** Commit the spec and plan docs (`docs/superpowers/`).
- [ ] **Step 2:** Use the superpowers:finishing-a-development-branch skill. Pushing to `main` deploys the site through the existing workflow. Confirm with Shlomi before pushing or merging.
