#!/usr/bin/env python3
"""Valida um fragmento cBody de notificacao do Protheus e gera os entregaveis.

Gera 3 arquivos no diretorio de saida:
  <nome>-cbody.html      -> o fragmento validado (conteudo do cBody)
  <nome>-preview.html    -> simulacao fiel do wrapper AdvPL para conferir no navegador
  <nome>-cbody.advpl.txt -> linhas cBody += '...'+ EOL prontas para colar no fonte

Uso:
  python3 build_outputs.py fragmento.html --titulo "SmartSupply - Nova release" \
      --saida /mnt/user-data/outputs --nome smartsupply-release
"""
import argparse
import re
import sys
from pathlib import Path

WRAPPER_TOPO = '''<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{font-family:"Segoe UI",Arial,sans-serif;margin:0;padding:16px;background:#eef1f4;color:#22303c;box-sizing:border-box;min-height:100vh;display:flex;align-items:center;justify-content:center;}
.wrap{max-width:1400px;width:95%;margin:0 auto;}
.badge{display:inline-block;font-size:12px;color:#5a6b7b;margin-bottom:8px;}
.card{background:#fff;border-radius:10px;padding:24px;box-shadow:0 2px 8px rgba(0,0,0,.10);}
h1{font-size:20px;color:#0a5ab4;margin:0 0 16px;border-bottom:1px solid #e3e8ee;padding-bottom:10px;}
img{max-width:100%;height:auto;}
</style></head><body><div class="wrap">
<div class="badge">Notificacao 1/1</div>
<div class="card"><h1>__TITULO__</h1>
'''
WRAPPER_FIM = '''</div>
</div></body></html>'''


def validar(frag: str) -> list:
    erros = []
    if "'" in frag:
        linhas = [i + 1 for i, ln in enumerate(frag.split("\n")) if "'" in ln]
        erros.append(f"Aspas simples encontradas (quebram a string AdvPL) nas linhas: {linhas}")
    nao_ascii = sorted({c for c in frag if ord(c) > 127})
    if nao_ascii:
        erros.append(
            "Caracteres nao-ASCII encontrados (usar entidades HTML como &eacute;): "
            + repr("".join(nao_ascii))
        )
    baixo = frag.lower()
    for tag in ["<!doctype", "<html", "<head", "<body", "<h1", "<script"]:
        if tag in baixo:
            erros.append(f"Tag proibida no fragmento: {tag}")
    if "position:fixed" in baixo.replace(" ", ""):
        erros.append("position:fixed nao e permitido no fragmento")
    if re.search(r"\d(vw|vh|vmin|vmax)\b", baixo):
        erros.append("Unidades de viewport (vw/vh/vmin/vmax) nao sao permitidas")
    if re.search(r"https?://", baixo) or "url(" in baixo:
        erros.append("Recursos externos (http/url()) nao sao permitidos - o Protheus nao tem internet")
    classes_ruins = sorted({
        c for c in re.findall(r'class="([^"]+)"', frag)
        for c in c.split()
        if not c.startswith("ss-")
    })
    if classes_ruins:
        erros.append(f"Classes sem prefixo ss- (conflitam com o wrapper): {classes_ruins}")
    return erros


def gerar(frag_path: Path, titulo: str, saida: Path, nome: str) -> int:
    frag = frag_path.read_text(encoding="utf-8")
    erros = validar(frag)
    if erros:
        print("FRAGMENTO REPROVADO:\n")
        for e in erros:
            print(" - " + e)
        return 1

    saida.mkdir(parents=True, exist_ok=True)

    # 1) fragmento (cBody)
    destino_frag = saida / f"{nome}-cbody.html"
    destino_frag.write_text(frag, encoding="utf-8")

    # 2) preview com o wrapper simulado
    preview = WRAPPER_TOPO.replace("__TITULO__", titulo) + frag + WRAPPER_FIM
    destino_prev = saida / f"{nome}-preview.html"
    destino_prev.write_text(preview, encoding="utf-8")

    # 3) concatenacao AdvPL
    linhas = ["// Conteudo da notificacao (cBody) - gerado pela skill protheus-notification-html",
              'cBody := ""']
    for ln in frag.split("\n"):
        ln = ln.rstrip()
        if not ln:
            continue
        linhas.append("cBody += '" + ln + "'+ EOL")
    destino_advpl = saida / f"{nome}-cbody.advpl.txt"
    destino_advpl.write_text("\n".join(linhas) + "\n", encoding="utf-8")

    print("FRAGMENTO APROVADO. Arquivos gerados:")
    print(" - " + str(destino_frag))
    print(" - " + str(destino_prev))
    print(" - " + str(destino_advpl))
    return 0


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("fragmento", type=Path, help="Caminho do fragmento HTML (cBody)")
    p.add_argument("--titulo", default="SmartSupply - Notificacao",
                   help="Titulo (cTitle) usado no preview do wrapper")
    p.add_argument("--saida", type=Path, default=Path("/mnt/user-data/outputs"),
                   help="Diretorio de saida dos entregaveis")
    p.add_argument("--nome", default=None,
                   help="Nome-base dos arquivos gerados (padrao: nome do fragmento sem -cbody)")
    args = p.parse_args()

    nome = args.nome or args.fragmento.stem.replace("-cbody", "")
    sys.exit(gerar(args.fragmento, args.titulo, args.saida, nome))


if __name__ == "__main__":
    main()
