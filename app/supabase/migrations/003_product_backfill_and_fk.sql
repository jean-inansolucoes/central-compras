-- =============================================================================
-- 003_product_backfill_and_fk.sql
--
-- CONTRACT.PRODUCTID hoje não tem FK real — é só a constante APP_ID = 1 usada
-- pelo AdvPL (ver src/dbstruct/JSGLBPAR.prw). Antes de criar uma FK de
-- verdade, garanta que a linha id=1 exista em PRODUCT, senão os contratos já
-- existentes (todos com PRODUCTID=1) quebram a constraint.
-- =============================================================================

insert into "PRODUCT" ("ID", "NAME", "PRICE", "DELETED")
select 1, 'SmartSupply', 0, 'N'
where not exists (select 1 from "PRODUCT" where "ID" = 1);

-- Antes de adicionar a constraint abaixo, confirme que TODO CONTRACT.PRODUCTID
-- já existe em PRODUCT.ID (a query deve retornar zero linhas):
--   select distinct "PRODUCTID" from "CONTRACT" where "PRODUCTID" not in (select "ID" from "PRODUCT");
--
-- Só então descomente e rode:
-- alter table "CONTRACT"
--   add constraint contract_productid_fkey foreign key ("PRODUCTID") references "PRODUCT" ("ID");
