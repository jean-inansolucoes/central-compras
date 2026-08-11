#!/usr/bin/env python3
"""Gera a Ficha Tecnica de Atualizacao de Dicionario a partir de um pacote UPDDISTR.

Le os arquivos gerados pelo Configurador (manifest_update.txt, sdf<pais>.txt,
hlpdf<idioma>.txt, mnupack.txt) dentro de um diretorio de pacote UPDDISTR,
cruza as tres fontes e produz um HTML/PDF no padrao visual roxo/pink da
INAN Solucoes (mesma paleta da skill protheus-notification-html).

Se o diretorio nao contiver os arquivos .txt diretamente, mas houver um
unico arquivo .rar (ex.: upddistr_2510.rar, como o Configurador costuma
distribuir o pacote), o script descompacta esse .rar primeiro (sempre
extraindo de novo, para nunca reaproveitar uma extracao antiga/desatualizada
de um .rar anterior) e so entao localiza manifest_update.txt dentro do
conteudo extraido (o pacote geralmente vem dentro de uma subpasta com o
nome do projeto).

Uso:
  python3 gerar_ficha_tecnica.py --dir /caminho/upddistr [--saida /caminho/saida]

Se --dir nao for informado, usa o diretorio atual. Se --saida nao for
informado, grava ao lado do .rar / dos arquivos de entrada (--dir).
"""
import argparse
import glob
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

TIPO_DESC = {"C": "Caractere", "N": "Numérico", "D": "Data", "L": "Lógico", "M": "Memo"}

LANG_LABEL = {
    "por": "Português", "bra": "Português", "pt": "Português",
    "eng": "Inglês", "en": "Inglês", "usa": "Inglês",
    "spa": "Espanhol", "es": "Espanhol", "esp": "Espanhol",
}


# --------------------------------------------------------------------------
# Leitura de arquivo texto do Configurador (grava normalmente em CP-1252)
# --------------------------------------------------------------------------
def ler_texto(path):
    data = Path(path).read_bytes()
    try:
        texto = data.decode("cp1252")
    except UnicodeDecodeError:
        texto = data.decode("cp1252", errors="replace")
    return texto.replace("\r\n", "\n").replace("\r", "\n")


# --------------------------------------------------------------------------
# Descompactacao do pacote (.rar) e localizacao do manifest_update.txt
# --------------------------------------------------------------------------
def localizar_manifest(diretorio):
    """Retorna o diretorio que contem manifest_update.txt (direto ou em subpasta), ou None."""
    direto = os.path.join(diretorio, "manifest_update.txt")
    if os.path.isfile(direto):
        return diretorio
    for raiz, _dirs, arquivos in os.walk(diretorio):
        if "manifest_update.txt" in arquivos:
            return raiz
    return None


def extrair_rar(caminho_rar, destino):
    """Tenta extrair o .rar com a primeira ferramenta disponivel no sistema.

    bsdtar (libarchive) vem por padrao no macOS/BSD e le RAR na maioria dos
    casos gerados pelo Configurador; unrar/unar/7z entram como alternativa
    para formatos que o bsdtar nao suporte (ex.: RAR5 comprimido).
    """
    os.makedirs(destino, exist_ok=True)
    candidatos = [
        ["bsdtar", "-xf", caminho_rar, "-C", destino],
        ["unrar", "x", "-y", caminho_rar, destino + os.sep],
        ["unar", "-f", "-o", destino, caminho_rar],
        ["7z", "x", f"-o{destino}", "-y", caminho_rar],
        ["7za", "x", f"-o{destino}", "-y", caminho_rar],
    ]
    tentativas = []
    for cmd in candidatos:
        exe = cmd[0]
        if shutil.which(exe) is None:
            continue
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode == 0:
            return exe
        tentativas.append(f"{exe} (código {r.returncode}): {r.stderr.strip()[:300]}")
    if not tentativas:
        raise RuntimeError(
            "Nenhuma ferramenta de extração de RAR encontrada (testado: bsdtar, unrar, unar, 7z, 7za). "
            "Instale uma delas (ex.: 'brew install unar') ou extraia o arquivo manualmente e rode "
            "novamente apontando --dir para a pasta já extraída."
        )
    raise RuntimeError("Falha ao extrair o RAR com todas as ferramentas disponíveis:\n" + "\n".join(tentativas))


def resolver_diretorio_pacote(diretorio):
    """Garante que os .txt do pacote estejam disponíveis, extraindo o .rar se necessário.

    Retorna (diretorio_com_manifest, nome_rar_usado_ou_None).
    Se houver um .rar em `diretorio`, ele SEMPRE tem prioridade e é sempre
    reextraído (uma extração antiga é apagada primeiro) para nunca analisar
    dados obsoletos de uma versão anterior do pacote.
    """
    rars = sorted(glob.glob(os.path.join(diretorio, "*.rar")))
    if len(rars) > 1:
        nomes = ", ".join(os.path.basename(r) for r in rars)
        print(f"ERRO: mais de um arquivo .rar encontrado em {diretorio} ({nomes}). "
              f"Mantenha apenas o pacote a ser analisado nesse diretório.")
        sys.exit(1)

    if len(rars) == 1:
        rar_path = rars[0]
        nome_base = os.path.splitext(os.path.basename(rar_path))[0]
        destino = os.path.join(diretorio, f"_extraido_{nome_base}")
        if os.path.isdir(destino):
            shutil.rmtree(destino)
        print(f"Descompactando {os.path.basename(rar_path)} ...")
        try:
            ferramenta = extrair_rar(rar_path, destino)
        except RuntimeError as e:
            print(f"ERRO: {e}")
            sys.exit(1)
        print(f"Extraído com '{ferramenta}' em {destino}")
        encontrado = localizar_manifest(destino)
        if not encontrado:
            print(f"ERRO: {os.path.basename(rar_path)} foi extraído, mas manifest_update.txt não foi "
                  f"encontrado dentro do conteúdo extraído ({destino}).")
            sys.exit(1)
        return encontrado, os.path.basename(rar_path)

    encontrado = localizar_manifest(diretorio)
    if encontrado:
        return encontrado, None

    print(f"ERRO: nenhum manifest_update.txt nem arquivo .rar encontrado em {diretorio}.")
    sys.exit(1)


# --------------------------------------------------------------------------
# Parser generico do manifest_update.txt
# --------------------------------------------------------------------------
def parse_header(texto):
    campos = {}
    for label, chave in [
        (r"Data\s*:\s*(.+)", "data"),
        (r"Hora\s*:\s*(.+)", "hora"),
        (r"Projeto\s*:\s*(.+)", "projeto"),
        (r"Descri\wão\s*:\s*(.+)", "descricao"),
        (r"Vers\wo\s*:\s*(.+)", "versao"),
        (r"Release de refer\wncia\s*:\s*(.+)", "release"),
        (r"Respons\wvel pelo Projeto\s*:\s*(.+)", "responsavel"),
        (r"Gera\wão do Pacote\s*:\s*(.+)", "geracao"),
    ]:
        m = re.search(label, texto)
        campos[chave] = m.group(1).strip() if m else ""
    return campos


def split_secoes(texto):
    """Divide o corpo do manifesto em secoes (SIX, SX2, SX6, SXB, SXA, SX3, Helps)."""
    marcador = re.compile(r"\n-{5,}\n\s*([^\n]+?)\s*\n")
    matches = list(marcador.finditer(texto))
    secoes = {}
    ordem = []
    for i, m in enumerate(matches):
        nome_raw = m.group(1).strip()
        nome = nome_raw.split("(")[0].strip()  # "Helps (hlppack*.txt)" -> "Helps"
        inicio = m.end()
        fim = matches[i + 1].start() if i + 1 < len(matches) else len(texto)
        secoes[nome] = texto[inicio:fim]
        ordem.append(nome)
    return secoes, ordem


def parse_entradas_operacao(bloco):
    """Extrai entradas de uma secao no formato 'Operacao:<op>' + pares 'Chave : Valor'."""
    partes = re.split(r"Opera\w*:", bloco)[1:]
    entradas = []
    for parte in partes:
        linhas = [l for l in parte.split("\n")]
        cabecalho = linhas[0].strip()
        operacao = "Exclusao" if cabecalho.lower().startswith("exclus") else "Inclusao_Alteracao"
        campos = {}
        for linha in linhas[1:]:
            m = re.match(r"\s*([^:\n]+?)\s*:\s*(.*)\s*$", linha)
            if not m:
                if not linha.strip():
                    continue
                break
            chave = m.group(1).strip()
            valor = m.group(2).strip()
            if chave and (valor or chave.lower() in ("filial", "coluna", "agrupamento")):
                campos[chave] = valor
        if campos:
            entradas.append({"operacao": operacao, "campos": campos})
    return entradas


def parse_help_keys(bloco):
    return re.findall(r"Chave\s*:\s*(\S+)", bloco)


def parse_manifest(path):
    texto = ler_texto(path)
    header = parse_header(texto)
    secoes, ordem = split_secoes(texto)
    resultado = {"header": header, "secoes": {}, "ordem_secoes": ordem, "_bruto": texto}
    for nome, bloco in secoes.items():
        if nome.lower().startswith("help"):
            resultado["secoes"][nome] = {"tipo": "help", "chaves": parse_help_keys(bloco)}
        else:
            resultado["secoes"][nome] = {"tipo": "operacoes", "entradas": parse_entradas_operacao(bloco)}
    return resultado


# --------------------------------------------------------------------------
# Enriquecimento a partir do payload fisico sdf<pais>.txt
# Layout empirico (validado em pacotes UPDDISTR reais do Configurador):
#   - Indice (SIX): "<TABELA><ORDEM>" seguido da expressao de chave e da
#     descricao, ambos terminando na primeira sequencia de 3+ espacos.
#   - Campo (SX3): nome do campo com 10 posicoes (padded), 1 char de tipo
#     (C/N/D/L/M), 3 digitos de tamanho, 1 digito de decimais, e a seguir
#     o titulo (12 posicoes).
#   - Parametro (SX6): nome do parametro (10 posicoes), 1 char de tipo,
#     depois 3 linhas de descricao x 3 idiomas (blocos de 50 posicoes cada,
#     os 3 idiomas de uma mesma linha sao identicos quando nao traduzidos),
#     seguido do conteudo/valor padrao (bloco de 50 posicoes).
# Todo valor extraido passa por validacao de formato antes de ser aceito;
# em caso de duvida a funcao retorna None e o dado aparece como "N/D" no
# relatorio, em vez de arriscar mostrar texto truncado/errado.
# --------------------------------------------------------------------------
def carregar_payload(diretorio):
    arquivos = sorted(glob.glob(os.path.join(diretorio, "sdf*.txt")))
    combinado = ""
    for f in arquivos:
        combinado += ler_texto(f)
    return combinado, [os.path.basename(f) for f in arquivos]


def extrair_indice(payload, tabela, ordem):
    alvo = f"{tabela}{ordem}"
    for m in re.finditer(re.escape(alvo), payload):
        i = m.end()
        resto = payload[i:i + 400]
        mexpr = re.match(r"([A-Za-z0-9_+().]+)\s{3,}", resto)
        if not mexpr:
            continue
        expressao = mexpr.group(1)
        resto2 = resto[mexpr.end():]
        mdesc = re.match(r"\s*([^\s].{0,90}?)\s{3,}", resto2)
        descricao = mdesc.group(1).strip() if mdesc else ""
        return expressao, descricao
    return None, None


def extrair_campo_sx3(payload, campo):
    padded = campo.ljust(10)
    for m in re.finditer(re.escape(padded), payload):
        i = m.start()
        depois = payload[i + 10:i + 16]
        mm = re.match(r"([CNDLM])(\d{3})(\d)", depois)
        if not mm:
            continue
        tipo, tam, dec = mm.groups()
        titulo = payload[i + 15:i + 27].strip()
        return tipo, int(tam), int(dec), titulo
    return None


def extrair_parametro_sx6(payload, nome):
    idx = payload.find(nome)
    if idx < 0 or len(nome) != 10:
        return None
    chunk = payload[idx + 10: idx + 10 + 1 + 700]
    if len(chunk) < 551 or chunk[0] not in "CNDLM":
        return None
    tipo = chunk[0]
    linhas = []
    for linha in range(3):
        bloco = chunk[1 + linha * 150: 1 + linha * 150 + 50]
        if len(bloco) < 50:
            return None
        linhas.append(bloco)
    descricao = "".join(linhas).rstrip()
    padrao = chunk[1 + 9 * 50: 1 + 10 * 50].rstrip()
    return tipo, descricao, padrao


# --------------------------------------------------------------------------
# Leitura dos arquivos de ajuda hlpdf<idioma>.txt
# Formato: "<NNNNNN>P<CAMPO padded>USER<espacos>texto", repetido em
# sequencia (sem separador explicito entre registros).
# --------------------------------------------------------------------------
def parse_help_file(path):
    raw = ler_texto(path).replace("\r\n", " ").replace("\n", " ").replace("\r", " ")
    padrao = re.compile(r"\d{6}P([A-Z0-9_]+)\s+USER\s+(.*?)(?=\d{6}P[A-Z0-9_]+\s+USER|$)")
    out = {}
    for m in padrao.finditer(raw):
        campo = m.group(1).strip()
        texto = re.sub(r"\s+", " ", m.group(2)).strip()
        out[campo] = texto
    return out


def carregar_helps(diretorio):
    arquivos = sorted(glob.glob(os.path.join(diretorio, "hlpdf*.txt")))
    idiomas = {}
    for f in arquivos:
        base = os.path.basename(f)
        m = re.match(r"hlpdf(\w+)\.txt$", base, re.IGNORECASE)
        sufixo = m.group(1).lower() if m else base
        rotulo = LANG_LABEL.get(sufixo, sufixo.upper())
        idiomas[rotulo] = parse_help_file(f)
    return idiomas


# --------------------------------------------------------------------------
# Classificacao de natureza do campo (heuristica de convencao TOTVS/AdvPL)
# --------------------------------------------------------------------------
def natureza_campo(campo, tabelas_novas):
    prefixo_tabela = campo.split("_")[0]
    if prefixo_tabela in tabelas_novas:
        return "nova"
    if "_X_" in campo:
        return "custom"
    return "padrao"


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dir", default=".", help="Diretorio do pacote UPDDISTR (contendo manifest_update.txt)")
    ap.add_argument("--saida", default=None, help="Diretorio de saida (padrao: mesmo de --dir)")
    args = ap.parse_args()

    diretorio = os.path.abspath(args.dir)
    saida = os.path.abspath(args.saida) if args.saida else diretorio

    diretorio_pacote, rar_usado = resolver_diretorio_pacote(diretorio)

    manifest_path = os.path.join(diretorio_pacote, "manifest_update.txt")
    manifest = parse_manifest(manifest_path)
    payload, arquivos_payload = carregar_payload(diretorio_pacote)
    helps = carregar_helps(diretorio_pacote)

    mnupack_path = os.path.join(diretorio_pacote, "mnupack.txt")
    mnupack_tam = os.path.getsize(mnupack_path) if os.path.isfile(mnupack_path) else None

    from gerar_html import montar_relatorio  # import local (mesmo diretorio de scripts)

    html_final, gaps = montar_relatorio(
        manifest=manifest,
        payload=payload,
        arquivos_payload=arquivos_payload,
        helps=helps,
        mnupack_tam=mnupack_tam,
        rar_usado=rar_usado,
        natureza_fn=natureza_campo,
        extrair_indice=extrair_indice,
        extrair_campo_sx3=extrair_campo_sx3,
        extrair_parametro_sx6=extrair_parametro_sx6,
    )

    os.makedirs(saida, exist_ok=True)
    html_path = os.path.join(saida, "ficha-tecnica-dicionario.html")
    Path(html_path).write_text(html_final, encoding="utf-8")
    print(f"HTML gerado: {html_path}")

    pdf_path = os.path.join(saida, "ficha-tecnica-dicionario.pdf")
    chrome = localizar_chrome()
    if chrome:
        cmd = [
            chrome, "--headless", "--disable-gpu", "--no-pdf-header-footer",
            "--print-to-pdf-no-header",
            f"--print-to-pdf={pdf_path}",
            f"file://{html_path}",
        ]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if os.path.isfile(pdf_path):
            print(f"PDF gerado: {pdf_path}")
        else:
            print("AVISO: falha ao gerar PDF via Chrome headless; HTML disponivel para conferencia/impressao manual.")
            if r.stderr:
                print(r.stderr[-800:])
    else:
        print("AVISO: Google Chrome/Chromium nao encontrado; apenas o HTML foi gerado. "
              "Abra o HTML no navegador e use 'Imprimir > Salvar como PDF' se precisar do PDF.")

    print("\n--- Analise de completude (gap analysis) ---")
    for linha in gaps:
        print(" - " + linha)


def localizar_chrome():
    candidatos = [
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/Applications/Chromium.app/Contents/MacOS/Chromium",
        shutil.which("google-chrome"),
        shutil.which("chromium"),
        shutil.which("chromium-browser"),
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    ]
    for c in candidatos:
        if c and os.path.isfile(c):
            return c
    return None


if __name__ == "__main__":
    main()
