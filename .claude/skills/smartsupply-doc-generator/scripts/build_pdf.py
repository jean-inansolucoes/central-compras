#!/usr/bin/env python3
"""Gera o PDF da documentacao do SmartSupply a partir do HTML vivo e prepara
previews PNG pagina-a-pagina para conferencia visual do agente.

Este script NAO decide se o layout esta correto -- ele so gera os artefatos
(PDF + PNGs) e aponta paginas suspeitas por heuristica de densidade de texto.
A conferencia visual real (overflow, elemento invisivel, tabela quebrada,
numeracao do sumario dessincronizada) deve ser feita pelo agente lendo os
PNGs com a ferramenta Read, pagina por pagina.

Uso:
  python3 build_pdf.py --html documentos/smartsupply-painel-de-compras.html

Gera (por padrao, ao lado do HTML):
  documentos/smartsupply-painel-de-compras.pdf
  <preview-dir>/page_01.png, page_02.png, ...  (preview-dir default: pasta
  temporaria do sistema, informada na saida)
"""
import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

CHROME_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "google-chrome",
    "google-chrome-stable",
    "chromium",
    "chromium-browser",
]

MIN_CHARS_MIOLO = 120  # abaixo disso, pagina de miolo e suspeita de estar quase vazia


def find_chrome() -> str:
    for cand in CHROME_CANDIDATES:
        if cand.startswith("/"):
            if Path(cand).exists():
                return cand
        else:
            found = shutil.which(cand)
            if found:
                return found
    print("ERRO: nenhum Chrome/Chromium encontrado. Instale um ou informe o "
          "caminho via --chrome.", file=sys.stderr)
    sys.exit(1)


def ensure_pymupdf():
    try:
        import fitz  # noqa: F401
        return
    except ImportError:
        subprocess.run([sys.executable, "-m", "pip", "install", "--quiet", "pymupdf"], check=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--html", required=True, help="Caminho do HTML fonte da documentacao")
    ap.add_argument("--out", help="Caminho do PDF de saida (default: mesmo nome do HTML, extensao .pdf)")
    ap.add_argument("--preview-dir", help="Pasta para salvar os PNGs de cada pagina (default: pasta temporaria)")
    ap.add_argument("--chrome", help="Caminho do executavel do Chrome/Chromium (auto-detectado por padrao)")
    ap.add_argument("--zoom", type=float, default=1.3, help="Fator de escala do PNG de preview (default 1.3)")
    args = ap.parse_args()

    html_path = Path(args.html).resolve()
    if not html_path.exists():
        print(f"ERRO: HTML nao encontrado: {html_path}", file=sys.stderr)
        sys.exit(1)

    pdf_path = Path(args.out).resolve() if args.out else html_path.with_suffix(".pdf")
    chrome = args.chrome or find_chrome()

    cmd = [
        chrome, "--headless", "--disable-gpu", "--no-pdf-header-footer",
        f"--print-to-pdf={pdf_path}", "--print-to-pdf-no-header",
        f"file://{html_path}",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    if not pdf_path.exists():
        print("ERRO ao gerar PDF. Saida do Chrome:", file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        sys.exit(1)

    ensure_pymupdf()
    import fitz  # type: ignore

    doc = fitz.open(str(pdf_path))
    n_pages = len(doc)

    preview_dir = Path(args.preview_dir).resolve() if args.preview_dir else Path(tempfile.mkdtemp(prefix="smartsupply_doc_preview_"))
    preview_dir.mkdir(parents=True, exist_ok=True)
    for f in preview_dir.glob("page_*.png"):
        f.unlink()

    suspeitas = []
    for i in range(n_pages):
        page = doc[i]
        pix = page.get_pixmap(matrix=fitz.Matrix(args.zoom, args.zoom))
        img_path = preview_dir / f"page_{i+1:02d}.png"
        pix.save(str(img_path))
        texto = page.get_text().strip()
        is_borda = i == 0 or i == n_pages - 1  # capa / encerramento: pouco texto e esperado
        if not is_borda and len(texto) < MIN_CHARS_MIOLO:
            suspeitas.append((i + 1, len(texto)))

    print(f"PDF gerado: {pdf_path}")
    print(f"Paginas: {n_pages}")
    print(f"Previews PNG em: {preview_dir}")
    if suspeitas:
        print("\nATENCAO -- paginas de miolo com pouco texto (possivel overflow/pagina quase vazia, confira visualmente):")
        for num, chars in suspeitas:
            print(f"  - page_{num:02d}.png ({chars} caracteres)")
    else:
        print("\nNenhuma pagina de miolo suspeita pela heuristica de densidade de texto.")
    print("\nLembrete: a heuristica acima NAO substitui a leitura visual dos PNGs. "
          "Releia com a ferramenta Read pelo menos as paginas editadas e as paginas "
          "imediatamente antes/depois delas antes de considerar a atualizacao concluida.")


if __name__ == "__main__":
    main()
