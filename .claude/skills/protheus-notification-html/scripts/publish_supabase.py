#!/usr/bin/env python3
"""Publica um fragmento cBody ja gerado/validado como um novo registro na tabela
NOTIFICATION do Supabase (mesma tabela que a Central de Notificacoes do SmartSupply
le em tempo real - ver src/main/JSNOTIFY.prw / U_JSNOTIFY).

Mapeamento de campos (confirmado em src/main/JSNOTIFY.prw, funcao doSave):
  ID        -> gerado automaticamente pelo Supabase (nao enviado)
  TITLE     -> --titulo (texto acentuado normal, sem restricao de ASCII)
  BODY      -> conteudo bruto do arquivo <nome>-cbody.html (fragmento ja validado)
  COMPANYID -> --company (int) ou null por padrao (nome real da coluna; NAO e "COMPANY")
  VERSION   -> --versao (ex.: "23.0012")
  USERID    -> --userid (string) ou null por padrao
  CREATED   -> gerado automaticamente pelo Supabase (nao enviado)
  DELETED   -> sempre "N"
  DATAATL   -> timestamp atual (timestamptz), sempre no timezone America/Sao_Paulo
               (independente do timezone configurado na maquina que roda o script)

Credenciais: este script NUNCA guarda a URL/API key em texto no fonte. Ordem de
resolucao: 1) parametros --url/--key; 2) variaveis de ambiente SUPABASE_URL /
SUPABASE_KEY; 3) automaticamente via generated_notify/supabase_credentials.py, que le
os mesmos valores hoje hardcoded em src/main/JSPAIGEN.prw nas funcoes
User Function JSGETDB() / User Function JSGETKEY() - mesmo projeto/chave "anon" ja
usada em producao pelo proprio Protheus para ler e gravar nesta mesma tabela. Na
pratica, na maioria dos casos nao e preciso configurar nada.

Uso:
  python3 publish_supabase.py <nome>-cbody.html --titulo "SmartSupply - Notas de Versao" \
      --versao 23.0012 [--company 123] [--userid jean.saggin] [--dry-run]
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

TABELA = "NOTIFICATION"
TZ_SAO_PAULO = ZoneInfo("America/Sao_Paulo")
_GENERATED_NOTIFY = Path(__file__).resolve().parents[4] / "generated_notify"


def _credenciais_do_fonte():
    """Fallback: le SUPABASE_URL/SUPABASE_KEY de generated_notify/supabase_credentials.py
    (que por sua vez le de src/main/JSPAIGEN.prw). Retorna (url, key) ou (None, None)
    se nao conseguir resolver, sem nunca imprimir o valor da key."""
    if str(_GENERATED_NOTIFY) not in sys.path:
        sys.path.insert(0, str(_GENERATED_NOTIFY))
    try:
        from supabase_credentials import get_url, get_key
        return get_url(), get_key()
    except Exception as e:
        print("Aviso: nao foi possivel auto-resolver credenciais via supabase_credentials.py: " + str(e))
        return None, None


def montar_payload(titulo: str, body: str, versao: str, company, userid) -> dict:
    return {
        "TITLE": titulo,
        "BODY": body,
        "COMPANYID": company,
        "VERSION": versao,
        "USERID": userid,
        "DELETED": "N",
        "DATAATL": datetime.now(TZ_SAO_PAULO).isoformat(timespec="seconds"),
    }


def publicar(url_base: str, api_key: str, payload: dict) -> int:
    endpoint = url_base.rstrip("/") + "/rest/v1/" + TABELA
    corpo = json.dumps([payload]).encode("utf-8")

    req = urllib.request.Request(endpoint, data=corpo, method="POST")
    req.add_header("apikey", api_key)
    req.add_header("Authorization", "Bearer " + api_key)
    req.add_header("Content-Type", "application/json")
    req.add_header("Prefer", "return=representation")

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            resposta = resp.read().decode("utf-8")
            registros = json.loads(resposta)
            print("NOTIFICACAO PUBLICADA COM SUCESSO no Supabase (tabela NOTIFICATION).")
            if registros:
                print(" - ID gerado.: " + str(registros[0].get("ID")))
                print(" - CREATED...: " + str(registros[0].get("CREATED")))
            return 0
    except urllib.error.HTTPError as e:
        detalhe = e.read().decode("utf-8", errors="replace")
        print("FALHA AO PUBLICAR (HTTP " + str(e.code) + "):")
        print(detalhe)
        return 1
    except urllib.error.URLError as e:
        print("FALHA DE COMUNICACAO com o Supabase: " + str(e.reason))
        return 1


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("fragmento", type=Path, help="Caminho do <nome>-cbody.html ja gerado por build_outputs.py")
    p.add_argument("--titulo", required=True, help="Titulo da notificacao (campo TITLE, pode ter acentos)")
    p.add_argument("--versao", required=True, help='Versao a partir da qual a novidade esta disponivel (ex.: "23.0012")')
    p.add_argument("--company", type=int, default=None, help="ID da empresa (COMPANYID). Omitir = null = todas as empresas")
    p.add_argument("--userid", default=None, help="Codigo do usuario (USERID). Omitir = null = todos os usuarios")
    p.add_argument("--url", default=os.environ.get("SUPABASE_URL"), help="URL do projeto Supabase (default: env SUPABASE_URL)")
    p.add_argument("--key", default=os.environ.get("SUPABASE_KEY"), help="API key do Supabase (default: env SUPABASE_KEY)")
    p.add_argument("--dry-run", action="store_true", help="Apenas mostra o payload JSON que seria enviado, sem gravar no banco")
    args = p.parse_args()

    if not args.fragmento.is_file():
        print("Arquivo de fragmento nao encontrado: " + str(args.fragmento))
        sys.exit(1)

    body = args.fragmento.read_text(encoding="utf-8")
    payload = montar_payload(args.titulo, body, args.versao, args.company, args.userid)

    if args.dry_run:
        preview = dict(payload)
        preview["BODY"] = "<%d caracteres omitidos no preview>" % len(payload["BODY"])
        print("DRY-RUN - payload que seria enviado para " + TABELA + ":")
        print(json.dumps(preview, ensure_ascii=False, indent=2))
        sys.exit(0)

    url, key = args.url, args.key
    if not url or not key:
        url_auto, key_auto = _credenciais_do_fonte()
        url = url or url_auto
        key = key or key_auto
        if url_auto or key_auto:
            print("Credenciais resolvidas automaticamente a partir de src/main/JSPAIGEN.prw.")

    if not url or not key:
        print("Nao foi possivel resolver SUPABASE_URL / SUPABASE_KEY (nem via --url/--key, env,")
        print("nem via generated_notify/supabase_credentials.py). Confira se src/main/JSPAIGEN.prw")
        print("ainda define User Function JSGETDB() / User Function JSGETKEY() nesse formato.")
        sys.exit(1)

    sys.exit(publicar(url, key, payload))


if __name__ == "__main__":
    main()
