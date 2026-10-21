# Marp slide sources

Markdown sources for workshop slides, rendered with [Marp](https://marp.app/).

## How to create slides
Use `../scripts/build.sh`, not `marp` directly:
```bash
../scripts/build.sh                   # html into ../dist, the default
../scripts/build.sh . html pdf pptx   # html, pdf and pptx (slower)
```
The decks go to `../dist`, and the script copies `assets/` there as well. The built html
references the pictures relative to itself, so a bare `marp` run leaves the slides without
them. It uses `marp` from `$PATH`, or `npx @marp-team/marp-cli@4` when there is none; set
`MARP` to pick another command.

The script builds from a copy of these sources in a temporary directory, so the diagram
step below never writes into the sources. The copy is removed afterwards, unless the build
is asked to keep it:
```bash
DEBUG=1 ../scripts/build.sh            # keeps the copy and prints the rm to clean it up
```
That copy holds the markdown as Marp got it, which is the place to look up the diagram urls
the build created.

## PlantUML diagrams
Marp knows no PlantUML, so `../scripts/plantuml-embed.py` replaces every ```` ```plantuml ````
block in the copy with an image that a PlantUML server renders:
````markdown
```plantuml renderer_hint="![bg right:30% 90%]" width="700px"
!include <edgy/edgy>
...
```
````
The diagram travels deflated inside the image url, so the server renders it without any
access to this repository. All options of the block are optional:

| Option | Effect |
| --- | --- |
| `renderer_hint="![bg right:30% 90%]"` | the image tag the url goes into, taken as it is, so every image syntax of the renderer works; the brackets may be left out |
| `alt="Overview"` | the alt text, for blocks without a `renderer_hint` |
| `width="700px"`, `height="400px"` | the size, as Marp keyword and, in pixels, as a `scale` directive for the server, so the diagram already arrives in that size |

A block inside a longer fence, like the example above, stays as it is.

* The default server is https://www.plantuml.com/plantuml; set `PLANTUML_SERVER` to use
  another one, e.g. `PLANTUML_SERVER=http://localhost:8080` for a self-hosted server.
* The step needs `python3`. Without it the build prints a warning and the blocks stay
  code blocks.
* The server has to be reachable: the html loads the diagram when a slide is shown, pdf
  and pptx already while they are built.

Mermaid diagrams work differently: they are rendered in the browser by the script in the
deck front matter and therefore only show up in the html.

## Publishing
Every push to `main` that changes `slides/src/**` runs `.github/workflows/slides.yml`.
It builds html, pdf and pptx and uploads `slides/dist` as the GitHub Pages artifact, so the
files are served as they are, without a Jekyll build:
https://infraguide-org.github.io/setup-sandbox/ (`index.json` lists the decks).
All pictures must be local files under `assets/`, no references to infraguide.org. The
PlantUML and mermaid diagrams are the exception, as they come from their render server
resp. CDN; put a picture under `assets/` if a deck has to work offline.
