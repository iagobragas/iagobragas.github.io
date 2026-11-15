# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project overview

Personal blog of Iago Bragas at https://iagobragas.com.br. Hugo static site using the
[Hextra](https://github.com/imfing/hextra) theme (v0.13.0, Hugo module vendored in `_vendor/`)
with a custom editorial layout on top (`layouts/`). Bilingual: Brazilian Portuguese (canonical) + English.

Layouts and scripts derive from [akitaonrails.github.io](https://github.com/akitaonrails/akitaonrails.github.io)
(synced up to upstream commit `490109a`, 2026-11-06), with all Akita-specific content and branding removed.

## Commands

Requires Hugo Extended 0.170.0+, Ruby 3+ (macOS system Ruby 2.6 is too old: use Homebrew's
`/opt/homebrew/opt/ruby/bin`), Node 26 LTS (tests only, pinned in `.node-version`), `uv` (OG image only).
Go is only needed to update the theme: `hugo mod get github.com/imfing/hextra@vX.Y.Z && hugo mod vendor`,
then run the tests and compare screenshots (layouts in `layouts/` override parts of the theme).

```bash
./scripts/generate_index.rb               # regenerate homepage + archives listings
./scripts/tag_catalog.rb --check          # validate every post tag against data/tag_taxonomy.yml
./scripts/tag_catalog.rb --search "termo" # find a canonical tag before creating one
./scripts/tag_catalog.rb --write TAGGING.md
hugo server -p 1313                       # http://localhost:1313
hugo --gc --minify                        # production build into public/

# Tests (each builds the site into a temp dir)
for t in scripts/test_*.rb; do ruby "$t"; done
node --test scripts/test_*.cjs

# Default share image (static/og-default.png)
uv run --no-project --with pillow python scripts/generate_og_image.py
```

`./scripts/generate_index.rb --future` / `--drafts` are local preview flags only: re-run without them before committing.

## Content

Posts live at `content/YYYY/MM/DD/slug/index.md` (PT) with an optional `index.en.md` sibling (EN).

```yaml
---
title: "Título do post"
date: '2026-11-15T10:00:00-03:00'  # ISO 8601, Brazil timezone
description: "Resumo de uma linha (aparece nos cards e no SEO)"
tags: [programacao]                 # must exist in data/tag_taxonomy.yml (pt slug in PT, en slug in EN)
draft: false
# optional: slug, images
---
```

**Generated files, never edit by hand:** `content/_index.md`, `content/_index.en.md`,
`content/archives/_index.md`, `content/archives/_index.en.md`, `TAGGING.md`.
Run `generate_index.rb` after adding, removing or retitling a post.

**Featured carousel:** edit `FEATURED_POSTS` / `FEATURED_POSTS_EN` at the top of
`scripts/generate_index.rb` (`[date, title, url]`), then regenerate. Empty lists hide the carousel.

## Multilingual

- `hugo.yaml`: `pt-br` is `defaultContentLanguage`, `en` is secondary.
- PT posts at `/YYYY/MM/DD/slug/`, EN at `/en/YYYY/MM/DD/slug/`.
- PT | EN toggle: `layouts/partials/custom/lang-toggle.html`. Locale redirect and the
  `lang_pref` cookie live in `layouts/partials/custom/head-end.html`.

**Editing an existing post** that has a sibling: apply the same change to both languages in the same turn.

**Writing a new post:** write only in the requested language, stop for review, translate only after
approval, and commit only when the author asks.

## Layout map

| File | Purpose |
|------|---------|
| `layouts/baseof.html`, `_partials/navbar.html`, `_partials/footer.html` | Page shell, header, footer |
| `layouts/home.html`, `section.html`, `taxonomy.html`, `term.html` | Home, archives, tag index, tag pages |
| `layouts/single.html` | Post template (TL;DR link, next post, optional Disqus) |
| `layouts/partials/custom/editorial-styles.html` | Design system (light/dark, responsive, featured carousel) |
| `layouts/partials/custom/head-end.html` | Fonts, CSS, language redirect, DuckDuckGo site search |
| `static/fonts/` | Self-hosted Inter, JetBrains Mono, Newsreader (latin + latin-ext woff2, SIL OFL in `LICENSES/`). No Google Fonts requests |
| `layouts/partials/custom/tldr-link.html` | "TL;DR com IA" link (Claude / ChatGPT / Grok) |
| `layouts/partials/components/chronological-next.html` | "Próximo post" card |
| `layouts/_partials/opengraph.html`, `partials/schema.html`, `sitemap.xml` | SEO: OG, JSON-LD, hreflang sitemap |
| `layouts/_default/list.rss.xml` | RSS (home, per tag, per section) |

Disqus is off. To enable, add `services.disqus.shortname` to `hugo.yaml`.

## License

Whole repo (code and posts) is CC BY-NC-SA 4.0 (`LICENSE`), required by ShareAlike because layouts/scripts are
adapted from akitaonrails.github.io (CC BY-NC-SA 4.0); keep the attribution in README "Créditos".
Third-party exceptions (Hextra MIT, fonts OFL) are in `THIRD_PARTY_NOTICES.md`; update it when the theme version changes.
NonCommercial: no ads/sponsored monetization of the site without revisiting this.

## Deployment

GitHub Pages via `.github/workflows/pages.yaml` on push to `main` (validates tags, then builds).
Custom domain: `static/CNAME` (`iagobragas.com.br`), also set in the repo's Pages settings.
