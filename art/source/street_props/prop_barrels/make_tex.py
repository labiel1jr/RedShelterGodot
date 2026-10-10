"""Texturas próprias dos tambores no layout UV da malha (lateral em cima,
duas tampas embaixo), em cores chapadas da paleta (estilo toon)."""
import os
from PIL import Image, ImageDraw

S = 256
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tex")
os.makedirs(OUT, exist_ok=True)
LINE = "#16141F"

VARIANTS = {
    "rust": dict(base="#9A5A35", dark="#6E3F26", light="#C27C47", cap="#8A5236"),
    "blue": dict(base="#3F6E9E", dark="#2E5278", light="#6E97C2", cap="#3A6591"),
    "hazard": dict(base="#D9B54A", dark="#A8862F", light="#E8D79A", cap="#C9A043", stripes="#2B2E38"),
    "green": dict(base="#5E6B47", dark="#434D33", light="#7E8F5A", cap="#56623F", stencil="#E3D3B0"),
    "red": dict(base="#B5452F", dark="#7E2E22", light="#D46A4E", cap="#A63F2B", band="#ECE8DF"),
}


def v(y):  # fração da altura → pixel
    return int(y * S)


for name, c in VARIANTS.items():
    img = Image.new("RGB", (S, S), c["dark"])
    d = ImageDraw.Draw(img)
    side_bottom = v(0.627)
    # Lateral: corpo, faixas de borda e as duas nervuras.
    d.rectangle([0, 0, S, side_bottom], fill=c["base"])
    d.rectangle([0, 0, S, v(0.03)], fill=c["dark"])
    d.rectangle([0, side_bottom - v(0.03), S, side_bottom], fill=c["dark"])
    for rib in (0.185, 0.445):
        d.rectangle([0, v(rib) - 3, S, v(rib) + 3], fill=c["dark"])
        d.line([0, v(rib) + 3, S, v(rib) + 3], fill=LINE, width=1)
    # Luz chapada (toon): uma faixa clara vertical.
    d.rectangle([v(0.12), v(0.05), v(0.2), side_bottom - v(0.05)], fill=c["light"])
    if "stripes" in c:
        for x in range(-S, S, 28):
            d.polygon([(x, v(0.22)), (x + 14, v(0.22)), (x + 14 + 30, v(0.41)), (x + 30, v(0.41))], fill=c["stripes"])
    if "stencil" in c:
        d.rectangle([v(0.55), v(0.24), v(0.72), v(0.40)], outline=c["stencil"], width=3)
        d.line([v(0.58), v(0.32), v(0.69), v(0.32)], fill=c["stencil"], width=3)
    if "band" in c:
        d.rectangle([0, v(0.26), S, v(0.37)], fill=c["band"])
        d.polygon([(v(0.6), v(0.355)), (v(0.64), v(0.275)), (v(0.68), v(0.355))], fill=c["base"])
    # Detalhes cel: arranhões em linha.
    for x, y, w in ((0.35, 0.09, 0.1), (0.7, 0.55, 0.08), (0.85, 0.12, 0.06)):
        d.line([v(x), v(y), v(x + w), v(y)], fill=c["dark"], width=2)
    # Tampas.
    for cx, cy in ((0.44, 0.81), (0.81, 0.81)):
        r = v(0.185)
        d.ellipse([v(cx) - r, v(cy) - r, v(cx) + r, v(cy) + r], fill=c["cap"], outline=LINE, width=2)
        d.ellipse([v(cx) - r + 8, v(cy) - r + 8, v(cx) + r - 8, v(cy) + r - 8], outline=c["dark"], width=3)
    d.ellipse([v(0.44) - 22, v(0.81) + 10, v(0.44) - 10, v(0.81) + 22], fill=LINE)
    img.save(os.path.join(OUT, f"prop_barrels_{name}.png"))
print("ok")
