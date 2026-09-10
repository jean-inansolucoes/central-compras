-- =============================================================================
-- 002_rls_policies.sql
--
-- ATENÇÃO — LEIA ANTES DE RODAR:
-- Este script assume que hoje CUSTOMER/CONTRACT estão SEM RLS restritiva,
-- ou seja, o papel `anon` (usado por TODO o AdvPL em produção, via
-- src/supabase/JSSUPABASE.prw, em cada instalação Protheus no campo) tem
-- acesso irrestrito de leitura/escrita. Se isso não for verdade, ajuste as
-- policies "*_anon_full_access" abaixo para replicar o comportamento REAL
-- antes de habilitar RLS — senão o check de licença do AdvPL
-- (JSGLBPAR.prw / getCustomer, getContract, setLastAcc) para de funcionar
-- em produção, para todo cliente, assim que RLS for ligado.
--
-- Rode isto em janela de baixo tráfego e valide manualmente logo em
-- seguida, ex.:
--   curl "$SUPABASE_URL/rest/v1/CUSTOMER?CGCCPF=eq.<algum cnpj real>&DELETED=eq.N" \
--        -H "apikey: $ANON_KEY"
-- ainda deve retornar o registro normalmente.
-- =============================================================================

-- ---------- APP_USER / APP_USER_CUSTOMER ----------
alter table "APP_USER" enable row level security;
alter table "APP_USER_CUSTOMER" enable row level security;

-- Checagem de papel usada pelas policies "*_admin_full_access" abaixo. Tem
-- que ser uma function SECURITY DEFINER: se a checagem fosse inline
-- (`exists (select 1 from "APP_USER" ...)`) dentro da própria policy de
-- APP_USER, a subconsulta reavaliaria as policies de APP_USER de novo e
-- entraria em recursão infinita (Postgres 42P17) — rodando com o
-- privilégio do dono da tabela, esta function não reaplica RLS na consulta
-- interna, quebrando o ciclo.
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
    select exists (
        select 1 from "APP_USER" where "ID" = auth.uid() and "ROLE" = 'admin'
    );
$$;

grant execute on function public.is_admin() to authenticated;

create policy "app_user_select_self" on "APP_USER"
    for select to authenticated
    using ("ID" = auth.uid());

create policy "app_user_update_self" on "APP_USER"
    for update to authenticated
    using ("ID" = auth.uid())
    with check ("ID" = auth.uid());

-- fallback defensivo: o perfil normalmente já é criado pelo trigger
-- SECURITY DEFINER do script 004 (que roda independente de RLS/sessão),
-- mas mantemos esta policy para permitir um insert manual de autocorreção
-- caso o trigger falhe por algum motivo.
create policy "app_user_insert_self" on "APP_USER"
    for insert to authenticated
    with check ("ID" = auth.uid());

create policy "app_user_admin_all" on "APP_USER"
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());

create policy "app_user_customer_self_select" on "APP_USER_CUSTOMER"
    for select to authenticated
    using ("USERID" = auth.uid());

create policy "app_user_customer_admin_all" on "APP_USER_CUSTOMER"
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());


-- ---------- CUSTOMER ----------
alter table "CUSTOMER" enable row level security;

-- preserva o acesso atual do AdvPL em produção — NÃO REMOVER sem plano de migração do addon.
create policy "customer_anon_full_access" on "CUSTOMER"
    for all to anon
    using (true)
    with check (true);

create policy "customer_admin_full_access" on "CUSTOMER"
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());

create policy "customer_external_select_own" on "CUSTOMER"
    for select to authenticated
    using (exists (
        select 1 from "APP_USER_CUSTOMER" auc
        where auc."USERID" = auth.uid() and auc."CUSTOMERID" = "CUSTOMER"."ID"
    ));

create policy "customer_external_update_own" on "CUSTOMER"
    for update to authenticated
    using (exists (
        select 1 from "APP_USER_CUSTOMER" auc
        where auc."USERID" = auth.uid() and auc."CUSTOMERID" = "CUSTOMER"."ID"
    ))
    with check (exists (
        select 1 from "APP_USER_CUSTOMER" auc
        where auc."USERID" = auth.uid() and auc."CUSTOMERID" = "CUSTOMER"."ID"
    ));


-- ---------- CONTRACT ----------
alter table "CONTRACT" enable row level security;

-- preserva o acesso atual do AdvPL em produção — NÃO REMOVER sem plano de migração do addon.
create policy "contract_anon_full_access" on "CONTRACT"
    for all to anon
    using (true)
    with check (true);

create policy "contract_admin_full_access" on "CONTRACT"
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());

create policy "contract_external_select_own" on "CONTRACT"
    for select to authenticated
    using (exists (
        select 1 from "APP_USER_CUSTOMER" auc
        where auc."USERID" = auth.uid() and auc."CUSTOMERID" = "CONTRACT"."CUSTOMERID"
    ));

create policy "contract_external_update_own" on "CONTRACT"
    for update to authenticated
    using (exists (
        select 1 from "APP_USER_CUSTOMER" auc
        where auc."USERID" = auth.uid() and auc."CUSTOMERID" = "CONTRACT"."CUSTOMERID"
    ))
    with check (exists (
        select 1 from "APP_USER_CUSTOMER" auc
        where auc."USERID" = auth.uid() and auc."CUSTOMERID" = "CONTRACT"."CUSTOMERID"
    ));


-- ---------- PRODUCT ----------
-- Nenhuma rotina AdvPL encontrada no addon lê/escreve PRODUCT hoje (ver
-- exploração inicial), então o risco de regressão em produção aqui é bem
-- menor que em CUSTOMER/CONTRACT — mesmo assim, mantemos o mesmo padrão de
-- não restringir o que já existe para `anon`, por precaução.
alter table "PRODUCT" enable row level security;

create policy "product_anon_full_access" on "PRODUCT"
    for all to anon
    using (true)
    with check (true);

create policy "product_admin_full_access" on "PRODUCT"
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());

-- catálogo é de leitura liberada para qualquer usuário autenticado (admin ou externo)
create policy "product_authenticated_select" on "PRODUCT"
    for select to authenticated
    using (true);
