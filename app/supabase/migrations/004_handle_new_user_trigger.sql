-- =============================================================================
-- 004_handle_new_user_trigger.sql
--
-- Cria automaticamente a linha em APP_USER (papel "external" por padrão)
-- assim que alguém termina o cadastro no Supabase Auth — via trigger
-- SECURITY DEFINER, não pelo client Flutter.
--
-- Por quê: se a confirmação de e-mail estiver ativa no projeto (padrão do
-- Supabase), `signUp()` não devolve uma sessão ativa na hora — só depois que
-- a pessoa confirma o e-mail. Um insert feito pelo app nesse meio-tempo
-- rodaria como `anon` (sem auth.uid()) e esbarraria na política de RLS de
-- APP_USER. O trigger no banco não tem esse problema, pois roda com
-- privilégio elevado independentemente de sessão.
-- =============================================================================

create or replace function public.handle_new_app_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into "APP_USER" ("ID", "ROLE", "NAME", "EMAIL")
    values (
        new.id,
        'external',
        coalesce(new.raw_user_meta_data ->> 'name', ''),
        coalesce(new.email, '')
    )
    on conflict ("ID") do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_app_user();
