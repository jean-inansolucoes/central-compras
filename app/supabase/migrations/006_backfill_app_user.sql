-- =============================================================================
-- 006_backfill_app_user.sql
--
-- Preenche APP_USER para contas que já existem em auth.users mas ainda não
-- têm linha correspondente — necessário quando alguém se cadastrou pelo app
-- ANTES do trigger do script 004 (on_auth_user_created) existir, já que o
-- trigger só dispara em INSERT novo, não retroativamente.
--
-- Idempotente: seguro rodar de novo (só insere quem ainda não existe).
-- Rode DEPOIS de confirmar/aplicar o 004_handle_new_user_trigger.sql.
-- =============================================================================

insert into "APP_USER" ("ID", "ROLE", "NAME", "EMAIL")
select
    u.id,
    'external',
    coalesce(u.raw_user_meta_data ->> 'name', ''),
    coalesce(u.email, '')
from auth.users u
where not exists (
    select 1 from "APP_USER" a where a."ID" = u.id
);

-- Confira o resultado:
select "ID", "EMAIL", "ROLE" from "APP_USER";

-- E promova a sua conta a admin, agora que ela existe:
-- update "APP_USER" set "ROLE" = 'admin' where "EMAIL" = 'seu@email-de-teste.com';
