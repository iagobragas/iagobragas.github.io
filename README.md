# iagobragas.com.br

Personal blog of Iago Braga: technology, software development, and whatever else interests me.
Posts are written in Brazilian Portuguese, with optional English translations.

Built with [Hugo](https://gohugo.io/) and the [Hextra](https://github.com/imfing/hextra) theme.
Published on GitHub Pages at https://iagobragas.com.br.

## Running locally

Requirements: [Hugo Extended](https://gohugo.io/installation/) 0.170.0+ and Ruby 3+ (`brew install hugo ruby`).

```bash
./scripts/generate_index.rb   # build the homepage listing
hugo server                   # http://localhost:1313
```

Or with Docker:

```bash
./scripts/dev.sh start
```

## New post

```bash
./scripts/new_post.rb "Post title" --tags programacao,ferramentas
```

Creates `content/YYYY/MM/DD/slug/index.md` as a **draft** (`draft: true`); the slug comes from the title without accents.
Tags must exist in `data/tag_taxonomy.yml` (see `TAGGING.md`). For an English version, add `index.en.md` in the same folder.

1. Write the post and fill in `description` and `tags`
2. Preview locally with `hugo server -D` (`-D` shows drafts)
3. To publish: remove `draft: true`, run `./scripts/generate_index.rb`, commit and push

To feature posts in the homepage carousel, edit `FEATURED_POSTS` in `scripts/generate_index.rb`.

## Credits

This site's layouts and scripts are adapted from [akitaonrails.github.io](https://github.com/akitaonrails/akitaonrails.github.io)
by Fabio Akita, licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).
**Changes:** removed all of the original author's content and branding, new index generator,
self-hosted fonts, own favicon and configuration, among others.

The [Hextra](https://github.com/imfing/hextra) theme (MIT) and the fonts (SIL OFL) keep their own licenses;
see [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## License

[![CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

© Iago Braga. This repository, including the blog posts, is licensed under
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/)
(full text in [`LICENSE`](LICENSE)), except for the third-party components listed in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
