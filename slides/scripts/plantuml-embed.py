# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
#
# Replaces the ```plantuml code blocks of the given markdown files with an image that a
# PlantUML server renders, because Marp itself does not know PlantUML. The diagram is
# deflated into the image url, so the server needs no access to the sources.
# Usage: plantuml-embed.py <server-url> <file.md>...
# A block may carry these options, all optional:
#   renderer_hint="![bg right:30% 90%]"   the image tag to put the url in, taken as it is,
#                                 so every image syntax of the renderer works
#   alt="Overview"                the alt text, when the block brings no renderer hint
#   width="700px" height="..."    the size, as image keywords and as a scale directive for
#                                 the server, so the svg already arrives in that size
# e.g. ```plantuml renderer_hint="![bg right:30% 90%]" width="700px"
# Blocks inside a longer fence stay as they are, so documentation can show the syntax.
import re
import sys
import zlib

ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
FENCE = re.compile(r"^(`{3,})[ \t]*(\S*)[ \t]*([^\n]*?)[ \t]*$")


def encode(diagram):
    """Deflate and encode the diagram the way the PlantUML servers expect it in the url."""
    deflate = zlib.compressobj(9, zlib.DEFLATED, -15)
    data = deflate.compress(diagram.encode()) + deflate.flush()
    url = ""
    for start in range(0, len(data), 3):
        chunk = data[start:start + 3] + b"\0\0"   # the last chunk is padded with zeros
        url += (ALPHABET[chunk[0] >> 2]
                + ALPHABET[(chunk[0] & 0x03) << 4 | chunk[1] >> 4]
                + ALPHABET[(chunk[1] & 0x0F) << 2 | chunk[2] >> 6]
                + ALPHABET[chunk[2] & 0x3F])
    return url


def scale(attributes):
    """Turn width/height into the PlantUML scale directive that sizes the rendered svg."""
    sizes = {name: attributes.get(name, "").removesuffix("px") for name in ("width", "height")}
    sizes = {name: value for name, value in sizes.items() if value.isdigit()}
    if len(sizes) == 2:
        return "scale %s*%s" % (sizes["width"], sizes["height"])   # fit into the box
    for name, value in sizes.items():
        return "scale %s %s" % (value, name)
    return ""   # no size, or one in units the server does not take, e.g. a percentage


def image(server, options, diagram):
    """Build the Marp image tag that points to the diagram on the PlantUML server."""
    attributes = dict(re.findall(r'([a-z_]+)="([^"]*)"', options))
    if not diagram.lstrip().startswith("@start"):
        diagram = "@startuml\n%s\n@enduml" % diagram
    directive = scale(attributes)
    if directive:   # right behind @startuml, where the server expects its directives
        diagram = re.sub(r"@start\w+[^\n]*\n", lambda start: start[0] + directive + "\n",
                         diagram, count=1)
    if "renderer_hint" in attributes:   # the deck says how to embed, brackets optional
        tag = attributes["renderer_hint"].strip().removeprefix("![").removesuffix("]")
    else:
        keywords = ["%s:%s" % (short, attributes[name])
                    for name, short in (("width", "w"), ("height", "h")) if name in attributes]
        tag = " ".join(keywords + [attributes.get("alt", "PlantUML diagram")])
    return "![%s](%s/svg/%s)" % (tag, server, encode(diagram))


def embed(server, text):
    """Replace the plantuml blocks of the markdown, those of an enclosing block excluded."""
    markdown, fence, block = [], "", None
    for line in text.split("\n"):
        marker = FENCE.match(line)
        if not fence:                                    # outside of any code block
            if marker:
                fence = marker[1]
                if marker[2] == "plantuml":
                    block = [line, marker[3]]            # the opening line and its options
                    continue
            markdown.append(line)
        elif marker and len(marker[1]) >= len(fence) and not marker[2] and not marker[3]:
            if block:                                    # the plantuml block is complete
                markdown.append(image(server, block[1], "\n".join(block[2:])))
                block = None
            else:
                markdown.append(line)
            fence = ""
        elif block:
            block.append(line)
        else:
            markdown.append(line)
    if block:                                            # no closing fence, keep the block
        markdown += [block[0]] + block[2:]
    return "\n".join(markdown)


def main(server, paths):
    for path in paths:
        with open(path, encoding="utf-8") as markdown:
            text = markdown.read()
        embedded = embed(server, text)
        if embedded != text:
            with open(path, "w", encoding="utf-8") as markdown:
                markdown.write(embedded)
            print("plantuml-embed: %s diagram(s) in %s"
                  % (embedded.count("/svg/") - text.count("/svg/"), path))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit("usage: plantuml-embed.py <server-url> <file.md>...")
    main(sys.argv[1].rstrip("/"), sys.argv[2:])
