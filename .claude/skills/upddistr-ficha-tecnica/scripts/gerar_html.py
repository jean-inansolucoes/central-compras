#!/usr/bin/env python3
"""Construcao do HTML da Ficha Tecnica de Atualizacao de Dicionario (UPDDISTR).

Modulo auxiliar de gerar_ficha_tecnica.py: recebe as estruturas ja
parseadas do manifesto + payload + helps e devolve (html, gap_analysis).
Nao possui logica de parsing (fica em gerar_ficha_tecnica.py) - aqui e so
classificacao/agrupamento e montagem visual.
"""
import html
import re
import unicodedata

TIPO_DESC = {"C": "Caractere", "N": "Numérico", "D": "Data", "L": "Lógico", "M": "Memo"}

PALETA_CSS = """
  :root{
    --branco:#ffffff;
    --roxo-escuro:#2e105d;
    --roxo:#441c7d;
    --roxo-medio:#6b31b0;
    --roxo-claro:#a57dd0;
    --roxo-claro2:#8256b9;
    --pink:#f41dab;
    --pink-esc:#cd1f92;
    --lilas-muted:#b6acc7;
    --texto:#241a33;
    --fundo-tabela-par:#faf8fd;
    --borda:#e4dcf0;
  }
  *{box-sizing:border-box;}
  body{
    margin:0; padding:0;
    font-family:"Segoe UI",Arial,sans-serif;
    color:var(--texto);
    background:var(--branco);
    font-size:13px;
    line-height:1.5;
  }
  .capa{
    background:linear-gradient(135deg,var(--roxo-escuro) 0%,var(--roxo) 55%,var(--roxo-medio) 100%);
    color:var(--branco);
    padding:56px 48px 40px 48px;
    position:relative;
    overflow:hidden;
  }
  .capa:before{
    content:"";
    position:absolute; top:0; left:0; right:0; height:5px;
    background:linear-gradient(90deg,var(--roxo-medio),var(--pink),var(--pink-esc));
  }
  .capa .selo{
    display:inline-block;
    background:linear-gradient(90deg,var(--pink),var(--pink-esc));
    color:var(--branco);
    font-size:10.5px;
    font-weight:700;
    letter-spacing:1.5px;
    text-transform:uppercase;
    padding:5px 14px;
    border-radius:999px;
    margin-bottom:18px;
  }
  .capa h1{ font-size:27px; margin:0 0 8px 0; font-weight:700; letter-spacing:.2px; }
  .capa .subtitulo{ font-size:15px; color:#e7defc; margin:0 0 28px 0; font-weight:400; }
  .capa .meta-grid{
    display:grid; grid-template-columns:repeat(3,1fr); gap:14px 28px;
    background:rgba(255,255,255,0.07); border:1px solid rgba(255,255,255,0.18);
    border-radius:10px; padding:18px 22px;
  }
  .capa .meta-grid div .k{ font-size:9.5px; text-transform:uppercase; letter-spacing:1px; color:var(--lilas-muted); margin-bottom:3px; }
  .capa .meta-grid div .v{ font-size:13px; font-weight:600; color:var(--branco); }
  .conteudo{ padding:36px 48px 60px 48px; }
  h2.secao{
    color:var(--roxo); font-size:18px; margin:38px 0 6px 0; padding-bottom:8px;
    border-bottom:2.5px solid var(--pink-esc); display:flex; align-items:baseline; gap:10px;
  }
  h2.secao .num{ color:var(--pink-esc); font-weight:800; }
  h3.subsecao{ color:var(--roxo-medio); font-size:14.5px; margin:22px 0 8px 0; }
  p{ margin:8px 0; }
  .lead{ color:#4a3d63; font-size:13.5px; }
  .muted{ color:#6b6178; }
  .small{ font-size:11.5px; }
  .mono{ font-family:"SF Mono",Consolas,monospace; font-size:11.5px; color:var(--roxo); font-weight:600;}
  strong{ color:var(--roxo); }
  .stat-row{ display:grid; grid-template-columns:repeat(4,1fr); gap:12px; margin:18px 0 6px 0; }
  .stat-card{
    background:linear-gradient(160deg,var(--roxo) 0%, var(--roxo-medio) 100%); color:var(--branco);
    border-radius:10px; padding:14px 16px; position:relative; overflow:hidden;
  }
  .stat-card:after{
    content:""; position:absolute; right:-18px; top:-18px; width:60px; height:60px;
    background:radial-gradient(circle, var(--pink) 0%, transparent 70%); opacity:.55;
  }
  .stat-card .num{ font-size:24px; font-weight:800; line-height:1; }
  .stat-card .lbl{ font-size:10px; text-transform:uppercase; letter-spacing:.6px; color:#e7defc; margin-top:5px;}
  table.data-table{ width:100%; border-collapse:collapse; margin:10px 0 18px 0; font-size:11.5px; }
  table.data-table thead th{
    background:var(--roxo); color:var(--branco); text-align:left; padding:8px 9px;
    font-size:10.5px; text-transform:uppercase; letter-spacing:.4px; font-weight:700;
  }
  table.data-table tbody td{ padding:6.5px 9px; border-bottom:1px solid var(--borda); vertical-align:top; }
  table.data-table tbody tr:nth-child(even){ background:var(--fundo-tabela-par); }
  table.data-table td.center{ text-align:center; }
  table.data-table td.mono{ font-family:"SF Mono",Consolas,monospace; font-size:11px; color:var(--roxo); font-weight:600; white-space:nowrap;}
  .badge{ display:inline-block; padding:2.5px 9px; border-radius:999px; font-size:9.5px; font-weight:700; letter-spacing:.3px; white-space:nowrap; }
  .badge-incl{ background:#efe7fa; color:var(--roxo-medio); border:1px solid var(--roxo-claro); }
  .badge-excl{ background:#fde5f3; color:var(--pink-esc); border:1px solid var(--pink); }
  .tag{ display:inline-block; padding:2px 8px; border-radius:6px; font-size:9px; font-weight:700; white-space:nowrap; }
  .tag-padrao{ background:#eef1f4; color:#54607a; }
  .tag-custom{ background:#fdf1e0; color:#a06a00; }
  .tag-nova{ background:#e6f4ea; color:#22823a; }
  .tag-existente{ background:#e5eefc; color:#25599c; }
  .count-pill{
    display:inline-block; background:var(--roxo-claro); color:var(--branco); font-size:9.5px;
    font-weight:700; padding:2px 9px; border-radius:999px; margin-left:8px; vertical-align:middle;
  }
  .subtable-head{ margin-top:20px; }
  .subtable-head h4{ margin:0 0 3px 0; font-size:13px; color:var(--roxo-escuro); }
  .callout{ border-left:4px solid var(--pink-esc); background:#fdf6fb; border-radius:0 8px 8px 0; padding:12px 16px; margin:14px 0; }
  .callout.roxo{ border-left-color:var(--roxo-medio); background:#f6f2fb; }
  .callout h4{ margin:0 0 6px 0; color:var(--pink-esc); font-size:12.5px; }
  .callout.roxo h4{ color:var(--roxo-medio); }
  .callout ol, .callout ul{ margin:4px 0 0 0; padding-left:18px; }
  .callout li{ margin-bottom:6px; }
  .consolidado td, .consolidado th{ text-align:center; }
  .consolidado td:first-child, .consolidado th:first-child{ text-align:left; }
  .consolidado td:nth-child(2), .consolidado th:nth-child(2){ text-align:left; }
  .footer-note{ margin-top:46px; padding-top:16px; border-top:1px solid var(--borda); font-size:10.5px; color:var(--lilas-muted); display:flex; justify-content:space-between; }
  .quebra{ page-break-before:always; }
  @media print{
    body{ font-size:12px; }
    .capa{ padding:40px 40px 30px 40px; }
    table.data-table{ font-size:10.5px; }
    h2.secao{ margin-top:26px; }
    tr, .stat-card, .callout, .subtable-head{ break-inside:avoid; }
  }
"""


def esc(s):
    return html.escape(str(s), quote=True)


def normaliza(s):
    s = unicodedata.normalize("NFKD", str(s))
    s = "".join(c for c in s if not unicodedata.combining(c))
    return s.lower().strip()


def get_campo(campos, *nomes):
    alvo = {normaliza(n) for n in nomes}
    for k, v in campos.items():
        if normaliza(k) in alvo:
            return v
    return ""


def badge_op(op):
    if op == "Exclusao":
        return '<span class="badge badge-excl">Exclusão</span>'
    return '<span class="badge badge-incl">Inclusão/Alteração</span>'


def tabela_do_campo(campo):
    prefixo = campo.split("_")[0]
    if prefixo.startswith("Z"):
        return prefixo
    return "S" + prefixo


def parse_preferencias(manifest_texto_bruto):
    m = re.search(r"tipo template\s*:\s*\n+(.*?)\n\n\n", manifest_texto_bruto, re.S)
    if not m:
        return []
    return [l.strip("- ").strip() for l in m.group(1).split("\n") if l.strip().startswith("-")]


def extrair_consulta_titulo(payload, consulta):
    """Melhor esforco: tenta achar o titulo (coluna DB) da consulta padrao tipo1/seq01."""
    alvo = f"{consulta.strip()}101"
    idx = payload.find(alvo)
    if idx < 0:
        return None
    resto = payload[idx + len(alvo) + 2: idx + len(alvo) + 2 + 120]
    m = re.match(r"([^\s].{0,60}?)\s{3,}", resto)
    return m.group(1).strip() if m else None


def montar_relatorio(manifest, payload, arquivos_payload, helps, mnupack_tam,
                      natureza_fn, extrair_indice, extrair_campo_sx3, extrair_parametro_sx6,
                      rar_usado=None):
    header = manifest["header"]
    secoes = manifest["secoes"]
    gaps = []
    if rar_usado:
        gaps.append(f"Arquivos extraídos automaticamente de {rar_usado} antes da análise.")

    def sec_entradas(nome):
        s = secoes.get(nome)
        return s["entradas"] if s and s.get("tipo") == "operacoes" else []

    sx2 = sec_entradas("SX2")
    six = sec_entradas("SIX")
    sx3 = sec_entradas("SX3")
    sx6 = sec_entradas("SX6")
    sxa = sec_entradas("SXA")
    sxb = sec_entradas("SXB")
    help_sec = next((secoes[n] for n in secoes if n.lower().startswith("help")), None)
    help_chaves = help_sec["chaves"] if help_sec else []

    tabelas_novas = {get_campo(e["campos"], "Tabela") for e in sx2}
    tabelas_novas.discard("")

    def conta(lst):
        total = len(lst)
        excl = sum(1 for e in lst if e["operacao"] == "Exclusao")
        return total, total - excl, excl

    # ---------------- Cross-referencia SX6 -> tabela (para dica de negocio) ----------------
    sx6_enriquecido = []
    param_por_tabela = {}
    for e in sx6:
        nome_param = get_campo(e["campos"], "Parâmetro", "Parametro")
        filial = get_campo(e["campos"], "Filial")
        info = extrair_parametro_sx6(payload, nome_param) if nome_param else None
        tipo, desc, padrao = info if info else (None, None, None)
        sx6_enriquecido.append({
            "nome": nome_param, "filial": filial, "operacao": e["operacao"],
            "tipo": tipo, "descricao": desc, "padrao": padrao,
        })
        if padrao and padrao in tabelas_novas:
            param_por_tabela.setdefault(padrao, []).append(nome_param)

    # ---------------- SX3: agrupamento por tabela ----------------
    grupos = {}
    ordem_tabelas = []
    for e in sx3:
        campo = get_campo(e["campos"], "Campo")
        if not campo:
            continue
        tabela = tabela_do_campo(campo)
        if tabela not in grupos:
            grupos[tabela] = []
            ordem_tabelas.append(tabela)
        grupos[tabela].append((campo, e["operacao"]))

    ref_lang = None
    if helps:
        ref_lang = max(helps, key=lambda k: sum(1 for v in helps[k].values() if v))
    help_ref = helps.get(ref_lang, {}) if ref_lang else {}

    campos_nao_localizados = []
    natureza_counts = {"nova": 0, "custom_tabela_existente": 0, "custom_campo": 0, "padrao": 0}
    padrao_tocados = []

    def natureza_tag(campo):
        nat = natureza_fn_wrap(campo)
        natureza_counts[nat] = natureza_counts.get(nat, 0) + 1
        if nat == "padrao":
            padrao_tocados.append(campo)
        return {
            "nova": '<span class="tag tag-nova">Tabela custom. (neste pacote)</span>',
            "custom_tabela_existente": '<span class="tag tag-existente">Tabela custom. (pré-existente)</span>',
            "custom_campo": '<span class="tag tag-custom">Campo custom.</span>',
            "padrao": '<span class="tag tag-padrao">Padrão TOTVS</span>',
        }[nat]

    def natureza_fn_wrap(campo):
        prefixo = campo.split("_")[0]
        if prefixo in tabelas_novas:
            return "nova"
        if prefixo.startswith("Z"):
            return "custom_tabela_existente"
        if "_X_" in campo:
            return "custom_campo"
        return "padrao"

    sx3_sections_html = ""
    for t in ordem_tabelas:
        campos_t = grupos[t]
        rows = ""
        for campo, op in campos_t:
            info = extrair_campo_sx3(payload, campo)
            if info:
                tipo, tam, dec, titulo = info
                tipo_desc = TIPO_DESC.get(tipo, tipo)
                tam_str = f"{tam}" + (f",{dec}" if dec else "")
            else:
                tipo_desc, tam_str, titulo = "N/D", "N/D", ""
                campos_nao_localizados.append(campo)
            desc_txt = help_ref.get(campo, "")
            rows += f"""
    <tr>
      <td class="mono">{esc(campo)}</td>
      <td class="center">{badge_op(op)}</td>
      <td class="center">{natureza_tag(campo)}</td>
      <td class="center">{esc(tipo_desc)}</td>
      <td class="center">{esc(tam_str)}</td>
      <td>{esc(titulo)}</td>
      <td class="small">{esc(desc_txt)}</td>
    </tr>"""
        dica = ""
        if t in param_por_tabela:
            dica = f"Referenciada pelo(s) parâmetro(s) {', '.join(sorted(set(param_por_tabela[t])))}."
        elif t in tabelas_novas:
            primeiro_titulo = ""
            for campo, _ in campos_t:
                if campo.endswith("_FILIAL"):
                    continue
                info = extrair_campo_sx3(payload, campo)
                if info and info[3]:
                    primeiro_titulo = info[3]
                    break
            dica = f"Tabela incluída neste pacote (SX2)." + (f" Ex.: campo &ldquo;{esc(primeiro_titulo)}&rdquo;." if primeiro_titulo else "")
        sx3_sections_html += f"""
  <div class="subtable-head">
    <h4><span class="mono">{esc(t)}</span> <span class="count-pill">{len(campos_t)} campo(s)</span></h4>
    <p class="muted small">{dica}</p>
  </div>
  <table class="data-table">
    <thead><tr><th>Campo</th><th>Operação</th><th>Natureza</th><th>Tipo</th><th>Tam.</th><th>Título</th><th>Descrição funcional</th></tr></thead>
    <tbody>{rows}</tbody>
  </table>
"""

    # ---------------- SX2 rows ----------------
    sx2_rows = ""
    for e in sx2:
        tabela = get_campo(e["campos"], "Tabela")
        n_campos = len(grupos.get(tabela, []))
        dica = param_por_tabela.get(tabela)
        dica_txt = f"Referenciada pelo parâmetro {', '.join(sorted(set(dica)))}." if dica else "&mdash;"
        ordens_tab = [get_campo(x["campos"], "Ordem") for x in six if get_campo(x["campos"], "Tabela") == tabela]
        extensao_flag = ""
        if ordens_tab and "1" not in ordens_tab:
            extensao_flag = ' <span class="tag tag-existente" title="Ordem 1 nao incluida neste pacote">possível extensão</span>'
        sx2_rows += f"""
    <tr>
      <td class="mono">{esc(tabela)}{extensao_flag}</td>
      <td class="small">{dica_txt}</td>
      <td class="center">{badge_op(e['operacao'])}</td>
      <td class="center">{n_campos}</td>
    </tr>"""

    # ---------------- SIX rows ----------------
    six_rows = ""
    indices_nao_localizados = []
    for e in six:
        tabela = get_campo(e["campos"], "Tabela")
        ordem = get_campo(e["campos"], "Ordem")
        expr, desc = extrair_indice(payload, tabela, ordem)
        if not expr:
            indices_nao_localizados.append(f"{tabela}/{ordem}")
            expr, desc = "N/D", ""
        six_rows += f"""
    <tr>
      <td class="mono">{esc(tabela)}</td>
      <td class="center">{esc(ordem)}</td>
      <td class="mono small">{esc(expr)}</td>
      <td>{esc(desc)}</td>
      <td class="center">{badge_op(e['operacao'])}</td>
    </tr>"""

    # ---------------- SX6 rows ----------------
    sx6_rows = ""
    params_nao_localizados = []
    for item in sx6_enriquecido:
        if item["tipo"] is None:
            params_nao_localizados.append(item["nome"])
        sx6_rows += f"""
    <tr>
      <td class="mono">{esc(item['nome'])}</td>
      <td class="center">{esc(TIPO_DESC.get(item['tipo'], 'N/D'))}</td>
      <td>{esc(item['descricao'] or '')}</td>
      <td class="mono small">{esc(item['padrao'] or '')}</td>
      <td class="center">{badge_op(item['operacao'])}</td>
    </tr>"""

    # ---------------- SXA rows ----------------
    sxa_rows = ""
    for e in sxa:
        tabela = get_campo(e["campos"], "Tabela")
        ordem = get_campo(e["campos"], "Ordem")
        sxa_rows += f"""
    <tr>
      <td class="mono">{esc(tabela)}</td>
      <td class="center">{esc(ordem)}</td>
      <td class="center">{badge_op(e['operacao'])}</td>
    </tr>"""

    # ---------------- SXB agrupado por consulta ----------------
    sxb_por_consulta = {}
    ordem_consultas = []
    for e in sxb:
        consulta = get_campo(e["campos"], "Consulta")
        if consulta not in sxb_por_consulta:
            sxb_por_consulta[consulta] = []
            ordem_consultas.append(consulta)
        sxb_por_consulta[consulta].append(e["operacao"])
    sxb_rows = ""
    for consulta in ordem_consultas:
        ops = sxb_por_consulta[consulta]
        n_incl = sum(1 for o in ops if o != "Exclusao")
        n_excl = sum(1 for o in ops if o == "Exclusao")
        titulo = extrair_consulta_titulo(payload, consulta) or ""
        badges = ""
        if n_incl:
            badges += f'{n_incl} {badge_op("Inclusao_Alteracao")} '
        if n_excl:
            badges += f'{n_excl} {badge_op("Exclusao")}'
        sxb_rows += f"""
    <tr>
      <td class="mono">{esc(consulta)}</td>
      <td class="small">{esc(titulo)}</td>
      <td class="center">{len(ops)}</td>
      <td class="center">{badges}</td>
    </tr>"""

    # ---------------- Helps: estatisticas ----------------
    help_stats_rows = ""
    idiomas = list(helps.keys())
    for idioma in idiomas:
        d = helps[idioma]
        preenchidos = [k for k, v in d.items() if v]
        vazios = [k for k in help_chaves if not d.get(k)]
        identicos_ref = 0
        if idioma != ref_lang:
            identicos_ref = sum(1 for k in preenchidos if d.get(k) == help_ref.get(k) and help_ref.get(k))
        obs = ""
        if idioma == ref_lang:
            obs = "idioma de referência"
        elif preenchidos:
            obs = f"{identicos_ref} de {len(preenchidos)} textos idênticos ao de referência (possível ausência de tradução real)"
        help_stats_rows += f"""
    <tr>
      <td>{esc(idioma)}</td>
      <td class="center">{len(preenchidos)}</td>
      <td class="center">{len(vazios)}</td>
      <td class="small">{esc(obs)}</td>
    </tr>"""

    # ---------------- Contadores gerais / stat cards ----------------
    total_sx2, incl_sx2, excl_sx2 = conta(sx2)
    total_six, incl_six, excl_six = conta(six)
    total_sx3, incl_sx3, excl_sx3 = conta(sx3)
    total_sx6, incl_sx6, excl_sx6 = conta(sx6)
    total_sxa, incl_sxa, excl_sxa = conta(sxa)
    total_sxb, incl_sxb, excl_sxb = conta(sxb)
    total_geral = total_sx2 + total_six + total_sx3 + total_sx6 + total_sxa + total_sxb
    incl_geral = incl_sx2 + incl_six + incl_sx3 + incl_sx6 + incl_sxa + incl_sxb
    excl_geral = excl_sx2 + excl_six + excl_sx3 + excl_sx6 + excl_sxa + excl_sxb

    # ---------------- Callouts de risco (dinamicos) ----------------
    callouts = ""
    excl_itens = []
    for nome, lst in [("SX3 (campo)", sx3), ("SIX (índice)", six), ("SX2 (tabela)", sx2),
                       ("SX6 (parâmetro)", sx6), ("SXA (pasta de campo)", sxa), ("SXB (consulta padrão)", sxb)]:
        for e in lst:
            if e["operacao"] == "Exclusao":
                resumo = ", ".join(f"{k}: {v}" for k, v in e["campos"].items() if v)
                excl_itens.append(f"<li><strong>{esc(nome)}</strong> &mdash; {esc(resumo)}</li>")
    if excl_itens:
        callouts += f"""
  <div class="callout">
    <h4>Itens em Exclusão neste pacote ({len(excl_itens)})</h4>
    <p class="small">Toda exclusão remove definitivamente o item do dicionário do ambiente de destino. Buscar
    referências no código-fonte a cada item abaixo antes de aplicar em produção.</p>
    <ul>{"".join(excl_itens)}</ul>
  </div>"""

    if padrao_tocados:
        prefs = parse_preferencias(manifest.get("_bruto", ""))
        prefs_html = "".join(f"<li>{esc(p)}</li>" for p in prefs) if prefs else ""
        callouts += f"""
  <div class="callout roxo">
    <h4>Reaplicação de propriedades em {len(padrao_tocados)} campo(s) padrão TOTVS (não customizados)</h4>
    <p class="small">Estes campos já existem no dicionário padrão do produto e não têm o sinal de customização
    (<span class="mono">_X_</span>): <span class="mono small">{esc(', '.join(sorted(set(padrao_tocados))))}</span>.
    O manifesto declara reaplicar as seguintes preferências de template sobre eles:</p>
    {"<ul>" + prefs_html + "</ul>" if prefs_html else ""}
    <p class="small">Em ambientes com customizações locais prévias nesses atributos, elas podem ser sobrescritas.
    Recomenda-se conferência pontual antes de aplicar em produção.</p>
  </div>"""

    gaps_extracao = campos_nao_localizados + indices_nao_localizados + params_nao_localizados
    if gaps_extracao:
        callouts += f"""
  <div class="callout roxo">
    <h4>Itens não localizados no payload ({len(gaps_extracao)})</h4>
    <p class="small">Os itens abaixo constam no manifesto mas não foram localizados (ou não puderam ser validados
    com segurança) nos arquivos <span class="mono">sdf*.txt</span> analisados. As colunas Tipo/Tamanho/Título
    aparecem como &ldquo;N/D&rdquo; para eles &mdash; conferir manualmente antes de publicar.</p>
    <p class="mono small">{esc(', '.join(gaps_extracao))}</p>
  </div>"""
        gaps.append(f"{len(gaps_extracao)} item(ns) do manifesto não localizados no(s) payload(s) sdf*.txt: {', '.join(gaps_extracao)}")

    if mnupack_tam is None:
        callouts += """
  <div class="callout roxo"><h4>Pacote de menu não encontrado</h4>
  <p class="small">Arquivo <span class="mono">mnupack.txt</span> não está presente neste diretório.</p></div>"""
    elif mnupack_tam == 0:
        callouts += """
  <div class="callout roxo"><h4>Sem alterações de menu</h4>
  <p class="small"><span class="mono">mnupack.txt</span> está vazio &mdash; nenhum item de menu é criado,
  alterado ou removido por este pacote.</p></div>"""
    else:
        callouts += f"""
  <div class="callout roxo"><h4>Pacote de menu com conteúdo ({mnupack_tam} bytes)</h4>
  <p class="small"><span class="mono">mnupack.txt</span> não está vazio neste pacote. O formato binário de
  itens de menu não é interpretado automaticamente por esta skill &mdash; revisar manualmente o conteúdo do
  arquivo ou validar via importação em ambiente de homologação.</p></div>"""
        gaps.append(f"mnupack.txt possui {mnupack_tam} bytes e não foi interpretado automaticamente (revisão manual necessária).")

    idiomas_vazios_totais = [i for i in idiomas if i != ref_lang and not any(helps[i].values())]
    if idiomas_vazios_totais:
        callouts += f"""
  <div class="callout roxo"><h4>Ajuda de campo sem conteúdo</h4>
  <p class="small">Os idiomas <span class="mono">{esc(', '.join(idiomas_vazios_totais))}</span> não possuem
  nenhum texto de ajuda preenchido neste pacote.</p></div>"""

    if not arquivos_payload:
        callouts += """
  <div class="callout roxo"><h4>Nenhum payload sdf*.txt encontrado</h4>
  <p class="small">Sem um arquivo <span class="mono">sdf&lt;país&gt;.txt</span> no diretório, não foi possível
  enriquecer índices, campos e parâmetros com tipo/tamanho/descrição &mdash; o relatório usa apenas os dados
  declarados no manifesto.</p></div>"""
        gaps.append("Nenhum arquivo sdf*.txt encontrado: enriquecimento de SIX/SX3/SX6 não realizado.")

    # ---------------- Header/meta ----------------
    projeto = header.get("projeto", "N/D")
    descricao = header.get("descricao", "N/D")
    versao = header.get("versao", "N/D")
    release = header.get("release", "N/D")
    data = header.get("data", "N/D")
    hora = header.get("hora", "N/D")
    responsavel = header.get("responsavel", "N/D")

    payload_note = ", ".join(arquivos_payload) if arquivos_payload else "nenhum encontrado"
    idiomas_note = ", ".join(idiomas) if idiomas else "nenhum arquivo hlpdf*.txt encontrado"

    html_out = f"""<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<title>Ficha Técnica de Atualização de Dicionário — {esc(descricao)}</title>
<style>{PALETA_CSS}</style>
</head>
<body>

<div class="capa">
  <span class="selo">Manifesto de Atualização &middot; UPDDISTR</span>
  <h1>Ficha Técnica de Atualização do Dicionário de Dados</h1>
  <p class="subtitulo">Pacote diferencial gerado pelo Configurador &mdash; análise consolidada de todas as
  operações que serão aplicadas ao dicionário de dados (SX2, SX3, SIX, SX6, SXA, SXB) do ambiente de destino.</p>
  <div class="meta-grid">
    <div><div class="k">Projeto</div><div class="v">{esc(projeto)}</div></div>
    <div><div class="k">Descrição</div><div class="v">{esc(descricao)}</div></div>
    <div><div class="k">Versão do pacote</div><div class="v">{esc(versao)}</div></div>
    <div><div class="k">Release de referência</div><div class="v">{esc(release)}</div></div>
    <div><div class="k">Data / hora de geração</div><div class="v">{esc(data)} &middot; {esc(hora)}</div></div>
    <div><div class="k">Responsável</div><div class="v">{esc(responsavel)}</div></div>
  </div>
</div>

<div class="conteudo">

  <h2 class="secao"><span class="num">1.</span> Sumário executivo</h2>
  <p class="lead">
    Este relatório foi gerado automaticamente a partir dos arquivos do pacote de atualização diferencial de
    dicionário de dados do Protheus (rotina <span class="mono">UPDDISTR</span> / Configurador), cruzando o
    manifesto oficial (<span class="mono">manifest_update.txt</span>) com o(s) payload(s) físico(s) de estrutura
    (<span class="mono">{esc(payload_note)}</span>) e os textos de ajuda de campo
    (<span class="mono">{esc(idiomas_note)}</span>).
    {f'Os arquivos foram descompactados automaticamente do pacote <span class="mono">{esc(rar_usado)}</span> antes da análise.' if rar_usado else ''}
  </p>

  <div class="stat-row">
    <div class="stat-card"><div class="num">{total_geral}</div><div class="lbl">Operações no total</div></div>
    <div class="stat-card"><div class="num">{incl_geral}</div><div class="lbl">Inclusão / Alteração</div></div>
    <div class="stat-card"><div class="num">{excl_geral}</div><div class="lbl">Exclusões</div></div>
    <div class="stat-card"><div class="num">{len(tabelas_novas)}</div><div class="lbl">Tabelas novas (SX2)</div></div>
  </div>

  <h2 class="secao"><span class="num">2.</span> Escopo consolidado por dicionário</h2>
  <table class="data-table consolidado">
    <thead><tr><th>Dicionário</th><th>O que controla</th><th>Total</th><th>Inclusão / Alteração</th><th>Exclusão</th></tr></thead>
    <tbody>
      <tr><td class="mono">SX2</td><td>Cadastro de tabelas</td><td>{total_sx2}</td><td>{incl_sx2}</td><td>{excl_sx2}</td></tr>
      <tr><td class="mono">SIX</td><td>Índices das tabelas</td><td>{total_six}</td><td>{incl_six}</td><td>{excl_six}</td></tr>
      <tr><td class="mono">SX3</td><td>Estrutura de campos</td><td>{total_sx3}</td><td>{incl_sx3}</td><td>{excl_sx3}</td></tr>
      <tr><td class="mono">SX6</td><td>Parâmetros de configuração</td><td>{total_sx6}</td><td>{incl_sx6}</td><td>{excl_sx6}</td></tr>
      <tr><td class="mono">SXA</td><td>Pastas de campos</td><td>{total_sxa}</td><td>{incl_sxa}</td><td>{excl_sxa}</td></tr>
      <tr><td class="mono">SXB</td><td>Consultas padrão (F3)</td><td>{total_sxb}</td><td>{incl_sxb}</td><td>{excl_sxb}</td></tr>
      <tr><td class="mono">Menu</td><td>Itens de menu (mnupack.txt)</td><td colspan="3" class="small muted">{'vazio / sem alteração' if mnupack_tam == 0 else (str(mnupack_tam) + ' bytes' if mnupack_tam else 'arquivo não encontrado')}</td></tr>
      <tr><td class="mono">Help F1</td><td>Textos de ajuda contextual</td><td colspan="3" class="small muted">{len(help_chaves)} chave(s) &times; {len(idiomas)} idioma(s) &mdash; ver seção 8</td></tr>
      <tr style="font-weight:700;"><td>Total geral</td><td></td><td>{total_geral}</td><td>{incl_geral}</td><td>{excl_geral}</td></tr>
    </tbody>
  </table>

  <h2 class="secao"><span class="num">3.</span> Tabelas (SX2)</h2>
  <table class="data-table">
    <thead><tr><th>Tabela</th><th>Observação</th><th>Operação</th><th>Campos no pacote</th></tr></thead>
    <tbody>{sx2_rows or '<tr><td colspan="4" class="muted small">Nenhuma operação de tabela (SX2) neste pacote.</td></tr>'}</tbody>
  </table>

  <h2 class="secao"><span class="num">4.</span> Índices (SIX)</h2>
  <table class="data-table">
    <thead><tr><th>Tabela</th><th>Ordem</th><th>Expressão de chave</th><th>Descrição</th><th>Operação</th></tr></thead>
    <tbody>{six_rows or '<tr><td colspan="5" class="muted small">Nenhuma operação de índice (SIX) neste pacote.</td></tr>'}</tbody>
  </table>

  <div class="quebra"></div>
  <h2 class="secao"><span class="num">5.</span> Campos (SX3) &mdash; detalhamento por tabela</h2>
  <p class="lead">A coluna <strong>Natureza</strong> classifica cada campo com base na convenção de nomenclatura
  TOTVS/AdvPL: <span class="tag tag-nova">Tabela custom. (neste pacote)</span> pertence a uma tabela criada/alterada
  neste mesmo pacote; <span class="tag tag-existente">Tabela custom. (pré-existente)</span> pertence a uma tabela
  <span class="mono">Z*</span> já existente no ambiente; <span class="tag tag-custom">Campo custom.</span> é uma
  extensão <span class="mono">_X_</span> em tabela padrão; <span class="tag tag-padrao">Padrão TOTVS</span> é um
  campo nativo do produto que está apenas recebendo ajuste de propriedades.</p>
  {sx3_sections_html or '<p class="muted small">Nenhuma operação de campo (SX3) neste pacote.</p>'}

  <div class="quebra"></div>
  <h2 class="secao"><span class="num">6.</span> Parâmetros de configuração (SX6)</h2>
  <table class="data-table">
    <thead><tr><th>Parâmetro</th><th>Tipo</th><th>Descrição</th><th>Valor padrão</th><th>Operação</th></tr></thead>
    <tbody>{sx6_rows or '<tr><td colspan="5" class="muted small">Nenhum parâmetro (SX6) neste pacote.</td></tr>'}</tbody>
  </table>

  <h2 class="secao"><span class="num">7.</span> Consultas padrão (SXB) e pastas de campos (SXA)</h2>
  <h3 class="subsecao">7.1 Consultas padrão (F3)</h3>
  <table class="data-table">
    <thead><tr><th>Consulta</th><th>Título (quando localizado)</th><th>Operações no pacote</th><th></th></tr></thead>
    <tbody>{sxb_rows or '<tr><td colspan="4" class="muted small">Nenhuma consulta padrão (SXB) neste pacote.</td></tr>'}</tbody>
  </table>
  <h3 class="subsecao">7.2 Pastas de campos (SXA)</h3>
  <p class="lead small">Abas adicionais na tela de manutenção do cadastro, usadas para agrupar visualmente os
  campos customizados criados por este pacote na tabela correspondente.</p>
  <table class="data-table">
    <thead><tr><th>Tabela</th><th>Aba/Ordem</th><th>Operação</th></tr></thead>
    <tbody>{sxa_rows or '<tr><td colspan="3" class="muted small">Nenhuma pasta de campos (SXA) neste pacote.</td></tr>'}</tbody>
  </table>

  <h2 class="secao"><span class="num">8.</span> Ajuda de campo multi-idioma (F1)</h2>
  <table class="data-table">
    <thead><tr><th>Idioma</th><th>Chaves preenchidas</th><th>Chaves vazias</th><th>Observação</th></tr></thead>
    <tbody>{help_stats_rows or '<tr><td colspan="4" class="muted small">Nenhum arquivo hlpdf*.txt encontrado.</td></tr>'}</tbody>
  </table>

  <div class="quebra"></div>
  <h2 class="secao"><span class="num">9.</span> Pontos de atenção e riscos de aplicação</h2>
  {callouts or '<p class="lead">Nenhum item de exclusão, ajuste de campo padrão ou lacuna de extração foi identificado neste pacote.</p>'}

  <h2 class="secao"><span class="num">10.</span> Conclusão</h2>
  <p class="lead">
    Foram identificadas <strong>{total_geral} operações</strong> no manifesto ({incl_geral} em Inclusão/Alteração
    e {excl_geral} em Exclusão), distribuídas entre {len([1 for n,t in [('SX2',total_sx2),('SIX',total_six),('SX3',total_sx3),('SX6',total_sx6),('SXA',total_sxa),('SXB',total_sxb)] if t>0])}
    dicionário(s) de dados. Revisar os itens listados na seção 9 antes de aplicar este pacote em ambiente de produção.
  </p>

  <div class="footer-note">
    <span>Ficha técnica gerada automaticamente pela skill <span class="mono">upddistr-ficha-tecnica</span>.</span>
    <span>{esc(projeto)} &middot; {esc(descricao)} &middot; versão {esc(versao)}</span>
  </div>

</div>
</body>
</html>
"""
    gaps.insert(0, f"{total_geral} operações totais no manifesto ({incl_geral} inclusão/alteração, {excl_geral} exclusão) — todas localizadas nas seções do relatório.")
    return html_out, gaps
