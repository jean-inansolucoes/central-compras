-- =============================================================================
-- 001_app_user_and_roles.sql
--
-- Cria o perfil do usuário do app Flutter (papel admin/external) e o vínculo
-- N:N entre um usuário externo e a(s) empresa(s) CUSTOMER que ele enxerga.
--
-- Pré-requisito: Supabase Auth (e-mail/senha) habilitado no projeto.
-- Este script NÃO altera CUSTOMER/CONTRACT/PRODUCT nem liga RLS em nada
-- (isso fica no script 002).
-- =============================================================================

create table if not exists "APP_USER" (
    "ID"      uuid primary key references auth.users (id) on delete cascade,
    "ROLE"    text not null default 'external' check ("ROLE" in ('admin', 'external')),
    "NAME"    text not null default '',
    "EMAIL"   text not null default '',
    "CREATED" timestamp not null default now()
);

create table if not exists "APP_USER_CUSTOMER" (
    "ID"         bigint generated always as identity primary key,
    "USERID"     uuid not null references "APP_USER" ("ID") on delete cascade,
    "CUSTOMERID" bigint not null references "CUSTOMER" ("ID") on delete cascade,
    unique ("USERID", "CUSTOMERID")
);

-- Todo cadastro feito pelo app (SignupScreen) entra como 'external'. Para
-- promover a equipe INAN a admin, rode manualmente após o primeiro login,
-- por exemplo:
--   update "APP_USER" set "ROLE" = 'admin' where "EMAIL" = 'alguem@inansolucoes.com.br';
--
-- E para liberar um usuário externo a enxergar sua própria empresa:
--   insert into "APP_USER_CUSTOMER" ("USERID", "CUSTOMERID")
--   values ('<uuid do auth.users>', <ID da linha em CUSTOMER>);
