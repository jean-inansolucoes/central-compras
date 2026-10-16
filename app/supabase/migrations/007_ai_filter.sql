-- =============================================================================
-- 007_ai_filter.sql
--
-- Suporte ao filtro de produtos por IA do SmartSupply (MV_X_PNC21 no Protheus,
-- fonte src/main/JSAIFLT.prw -> Edge Function "ai-filter").
--
-- AI_CUSTOMER: habilitação do recurso por cliente. Fica FORA da tabela
-- CUSTOMER de propósito: CUSTOMER tem a policy "customer_anon_full_access"
-- (002), ou seja, qualquer instalação com a chave anon poderia se
-- auto-habilitar. Esta tabela não tem policy para anon: só a Edge Function
-- (service role, que ignora RLS) e os admins do app enxergam/alteram.
--
-- AI_QUERY: log de cada interpretação (texto, expressão gerada, tokens,
-- latência) — base para controle de cota diária e para melhorar o prompt
-- com frases reais dos clientes.
--
-- Para habilitar um cliente:
--   insert into "AI_CUSTOMER" ("CUSTOMERID", "ENABLED") values (<CUSTOMER.ID>, true)
--   on conflict ("CUSTOMERID") do update set "ENABLED" = excluded."ENABLED";
-- =============================================================================

create table if not exists "AI_CUSTOMER" (
    "CUSTOMERID"  bigint primary key references "CUSTOMER" ("ID") on delete cascade,
    "ENABLED"     boolean not null default false,
    "DAILY_LIMIT" integer not null default 300 check ("DAILY_LIMIT" >= 0),
    "CREATED"     timestamp not null default now()
);

create table if not exists "AI_QUERY" (
    "ID"            bigint generated always as identity primary key,
    "CREATED"       timestamp not null default now(),
    "CUSTOMERID"    bigint not null references "CUSTOMER" ("ID") on delete cascade,
    "USERNAME"      text not null default '',
    "DBMS"          text not null default '',
    "PROMPT"        text not null,
    "WHERE_SQL"     text,
    "SUPPLIER"      text,
    "TYPES"         text,
    "EXPLANATION"   text,
    "STATUS"        text not null check ("STATUS" in ('ok', 'refusal', 'error')),
    "ERROR"         text,
    "MODEL"         text not null default '',
    "INPUT_TOKENS"  integer,
    "OUTPUT_TOKENS" integer,
    "LATENCY_MS"    integer,
    -- feedback do usuário (reservado para evolução: aplicar/ajustar na tela do Protheus)
    "FEEDBACK"      smallint check ("FEEDBACK" in (-1, 1))
);

-- controle de cota diária por cliente (count por CUSTOMERID no dia corrente)
create index if not exists ai_query_customer_created_idx on "AI_QUERY" ("CUSTOMERID", "CREATED");

alter table "AI_CUSTOMER" enable row level security;
alter table "AI_QUERY" enable row level security;

create policy "ai_customer_admin_full_access" on "AI_CUSTOMER"
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());

create policy "ai_query_admin_select" on "AI_QUERY"
    for select to authenticated
    using (public.is_admin());
