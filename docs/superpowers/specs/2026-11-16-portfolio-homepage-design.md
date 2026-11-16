# Portfolio homepage redesign

## Intent

Shlomi no longer blogs. shlomigreen.github.io stays published, but as a calm, single-screen
"who I am + where to find me" page instead of a blog. Old posts are archived: they stay readable
at their existing URLs (links shared on LinkedIn/X keep working) but nothing on the site lists them.
The site should stay cheap to grow later (e.g. a Projects or Talks page) without a redesign.

## Goals / non-goals

- Goal: one homepage — photo, name, handle, title, social icons — in the agreed "Moss & clay blobs" style.
- Goal: existing post URLs keep resolving.
- Non-goal: search, tags, categories, share buttons, RSS, archive list page, about page, comments.
- Anti-goal: anything that makes the page feel busy or generic (default theme look, bright colors).

## Approaches considered

1. **Plain `index.html`, drop Hugo.** Simplest, but old post links 404 and future pages mean hand-written HTML.
2. **Keep Hugo + LoveIt, restyle via overrides.** Keeps everything, but fights a heavy blog theme for a one-card page.
3. **Keep Hugo, replace LoveIt with a tiny own layout.** ← picked by Shlomi. Old URLs keep working, new pages
   are just markdown, and the theme weight goes away.

## Design (decided together)

- **Layout:** centered card. Top to bottom: avatar → name → handle (mono) → terminal chip → centered row of
  icons (GitHub, LinkedIn, X). No link to old posts.
- **Terminal chip (rotating title):** a small pine "window" inside the card: three dots (clay, lichen, fern),
  a `~ whoami` prompt in lichen, then the current title in warm clay with a blinking block cursor. Each title
  is typed out letter by letter, held for about 1.8s, then deleted, and the next one is typed. The chip has a
  **fixed width** sized to the longest title, so only the title text changes and the prompt and frame never
  move. Titles, in order: `ai-engineer`, `tech-lead`, `data-scientist`, `team-lead`, `ai-builder`,
  `3d-printing-artist`.
  Without JS, it shows a static `~ whoami ai-engineer`. Screen readers get one sentence
  listing every title and don't hear the typing.
- **Everything is configurable in `config.toml` `[params]`** (no edits to templates needed): display name,
  handle, avatar URL, titles list, and social links. Each social link has a name, URL, and icon.
- **Style "B · Moss & clay blobs":** pine `#1f2b22` background with large organic blobs in moss, clay,
  and lichen, a light film grain, and a slightly translucent (92%) surface-colored card. There is no backdrop
  blur: at 92% it barely showed and it cost a full-screen blur on every frame. The avatar has a
  surface border plus a fern ring, the handle sits in a lichen pill, the title is in bark, and the icons are
  pine circles that turn clay and tilt on hover.
  The blobs drift slowly, each moving about 40px with a little rotation or scale and gently changing shape
  over an 18 to 26 second back-and-forth loop. It's pure CSS.
  All animations deliberately ignore the OS reduced-motion setting (Shlomi's call after launch).
- **Palette:** surface #f2efe6, moss #3f5a3c, fern #6f8f68, lichen #b7c2a0, bark #6b4f3a,
  clay #865a3c, pine #1f2b22 (also the text color; it replaced the identical "ink").
  Added in the build: clay-light #e0b48f for the typed title, because clay on pine is only about 2.9:1, and
  paper-2 #e8e4d8 for inline code and admonition backgrounds on post pages.
- **Fonts (Google Fonts):** Bricolage Grotesque for the name and headings, Figtree for body text, IBM Plex Mono
  for the handle and the terminal chip.
- Reference mockups (not committed): `.superpowers/brainstorm/*/content/homepage-v4-styles.html` option B for
  the card, and `whoami-v2.html` for the chip.

## Implementation shape (Claude's calls — check these)

- Remove the LoveIt submodule (`themes/LoveIt`, `.gitmodules`, `theme =` in config), `assets/css/` overrides,
  `resources/_gen/`, `.vscode/loveit.code-snippets`, and the unused About page.
- New `layouts/`: `index.html` (the card), `_default/baseof.html`, and `_default/single.html` (a plain,
  readable post page in the same palette with no blobs, so archived posts still look intentional).
  One `static/style.css`.
- Posts use two LoveIt shortcodes (`admonition`, `person`). Add minimal local versions in
  `layouts/shortcodes/` so the posts still build: `admonition` becomes a `<details>` box, and `person`
  becomes a plain link.
- `disableKinds = ["taxonomy", "term", "section", "RSS"]`, so there are no list pages, tag pages, or feed.
  Post pages still render at `/posts/<slug>/`, and `sitemap.xml` is still built so they stay findable.
- Every page gets Open Graph and Twitter card tags from Hugo's built-in templates, so links shared in chat
  apps show a preview. The image is `params.images` (the avatar).
- Archived posts stay indexable by search engines, with no `noindex`, so people searching can still find
  them. Flip this if "unlist" should also mean hidden from Google.
- Defaults in config: avatar is the GitHub avatar URL. Social URLs are github.com/Shlomigreen,
  linkedin.com/in/shlomigreen, and x.com/theshlomigreen.
- **Icons come from Font Awesome Free 6 (brands)**, loaded from cdnjs. A social entry's `icon` is the
  Font Awesome brand name (`github`, `linkedin`, `x-twitter`, ...), rendered as `fa-brands fa-<icon>`. I didn't
  use Simple Icons because it no longer ships a LinkedIn icon.
- The chip width is computed in the template from the longest title, as `Nch` in the mono font. The longest
  title, `3d-printing-artist`, is 18 characters, which is tight on a 360px phone, so the chip's font size and
  the card padding shrink under a `max-width: 400px` media query. The three dots stay visible there. The rotation is about 15 lines of inline JS with no
  library.
- The GitHub Actions workflow is trimmed: the submodule checkout, npm step, and `HUGO_ENV*` variables are
  gone, since there is no theme or `package.json` anymore.
- Accessibility: icon links get `aria-label`s, and there's a visible focus ring. Animations run regardless
  of `prefers-reduced-motion` (see above).


## Left to the builder

Exact blob sizes and positions at different screen widths, grain intensity, and favicon reuse
(the existing files in `static/` stay).
