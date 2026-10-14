# setup-sandbox
Prerequisites and scripts to prepare a sandbox for infraguide labs

## Slides
The slides are published on GitHub Pages: [infraguide-org.github.io/setup-sandbox](https://infraguide-org.github.io/setup-sandbox/)

| Deck | Content | Files |
|---|---|---|
| Setup | Setup a sandbox for infraguide labs | `slides-setup` |

Every deck is available as HTML, PDF and PPTX, for example
`https://infraguide-org.github.io/setup-sandbox/slides-setup.pdf`.
[`index.json`](https://infraguide-org.github.io/setup-sandbox/index.json) lists the decks in their order and all files in a machine-readable form.

## How to create slides
The sources are Markdown files in `slides/src`, rendered with [Marp](https://marp.app/):

```bash
cd slides/src
marp          # html
marp --pdf    # pdf
marp --pptx   # pptx
```

The output goes to `slides/dist`. Every push to `main` that changes `slides/src` or `slides/scripts`
builds the slides and the index page and publishes them with the workflow `.github/workflows/slides.yml`.
The order of the decks is set by the `order` field in the front matter of each deck.
