-- =============================================================================
-- 005_fix_admin_recursion.sql
--
-- Corrige o erro "infinite recursion detected in policy for relation
-- APP_USER" (Postgres 42P17).
--
-- Causa: as policies "*_admin_full_access" (e "app_user_admin_all",
-- "app_user_customer_admin_all") checavam o papel do usuário fazendo
-- `exists (select 1 from "APP_USER" ...)` dentro da própria policy. Como
-- APP_USER também tem RLS habilitada, essa subconsulta reavalia as
-- policies de APP_USER de novo — inclusive essa mesma — entrando em loop.
--
-- Fix padrão do Supabase para esse caso: mover a checagem de papel para uma
-- function SECURITY DEFINER. Rodando com o privilégio do dono da tabela,
-- ela não reaplica RLS na consulta interna, quebrando o ciclo.
--
-- Rode este script inteiro no SQL Editor do Supabase — ele é seguro de
-- rodar de novo se precisar (idempotente).
-- =============================================================================

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

-- APP_USER
drop policy if exists "app_user_admin_all" on "APP_USER";
create policy "app_user_admin_all" on "APP_USER"
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());

-- APP_USER_CUSTOMER
drop policy if exists "app_user_customer_admin_all" on "APP_USER_CUSTOMER";
create policy "app_user_customer_admin_all" on "APP_USER_CUSTOMER"
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());

-- CUSTOMER
drop policy if exists "customer_admin_full_access" on "CUSTOMER";
create policy "customer_admin_full_access" on "CUSTOMER"
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());

-- CONTRACT
drop policy if exists "contract_admin_full_access" on "CONTRACT";
create policy "contract_admin_full_access" on "CONTRACT"
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());

-- PRODUCT
drop policy if exists "product_admin_full_access" on "PRODUCT";
create policy "product_admin_full_access" on "PRODUCT"
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());
