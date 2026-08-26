#!/usr/bin/env python3
"""Extrai as credenciais do Supabase (URL e API key) diretamente de
src/main/JSPAIGEN.prw (User Function JSGETDB / User Function JSGETKEY),
a mesma fonte que o proprio Protheus usa em producao para este fim.

Evita duplicar a credencial em um segundo arquivo do repositorio: este
modulo apenas LE o valor, em tempo de execucao, do fonte AdvPL existente -
nunca grava nem copia o segredo em nenhum outro lugar. Se a chave for
rotacionada, so precisa atualizar JSPAIGEN.prw; nada mais no repositorio
precisa mudar.

Uso como modulo (recomendado - ex.: em publish_supabase.py):
    from supabase_credentials import get_url, get_key
    url = get_url()
    key = get_key()

Uso via linha de comando (para conferencia manual, sem imprimir o valor
inteiro da key sem querer em um terminal compartilhado):
    python3 supabase_credentials.py --url
    python3 supabase_credentials.py --key
    python3 supabase_credentials.py --export   # imprime export SUPABASE_URL=... / export SUPABASE_KEY=...
"""
import argparse
import re
from pathlib import Path

_JSPAIGEN = Path(__file__).resolve().parent.parent / "src" / "main" / "JSPAIGEN.prw"


def _extrair(funcao: str) -> str:
    if not _JSPAIGEN.is_file():
        raise FileNotFoundError(
            "Nao encontrei " + str(_JSPAIGEN) + " - este modulo espera rodar "
            "dentro do repositorio central-compras, a partir de generated_notify/."
        )
    texto = _JSPAIGEN.read_bytes().decode("cp1252")
    padrao = r"User [Ff]unction " + re.escape(funcao) + r"\(\)\s*\r?\n\s*[Rr]eturn\s+\"([^\"]+)\""
    m = re.search(padrao, texto)
    if not m:
        raise ValueError(
            "Nao encontrei " + funcao + "() em " + str(_JSPAIGEN) +
            " - o fonte pode ter mudado de formato; confira manualmente."
        )
    return m.group(1)


def get_url() -> str:
    """URL do projeto Supabase (mesmo valor de User Function JSGETDB())."""
    return _extrair("JSGETDB")


def get_key() -> str:
    """API key anonima do Supabase (mesmo valor de User Function JSGETKEY())."""
    return _extrair("JSGETKEY")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    g = p.add_mutually_exclusive_group()
    g.add_argument("--url", action="store_true", help="Imprime apenas a URL")
    g.add_argument("--key", action="store_true", help="Imprime apenas a API key")
    g.add_argument("--export", action="store_true", help='Imprime "export SUPABASE_URL=..." e "export SUPABASE_KEY=..."')
    args = p.parse_args()

    if args.url:
        print(get_url())
    elif args.key:
        print(get_key())
    else:
        print('export SUPABASE_URL="' + get_url() + '"')
        print('export SUPABASE_KEY="' + get_key() + '"')


if __name__ == "__main__":
    main()
