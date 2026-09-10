# SmartSupply Back-office (Flutter)

App interno da INAN Soluções para gerenciar Clientes (empresas-tenant do
SmartSupply), Contratos (assinaturas SaaS) e Produtos, direto no mesmo
Supabase que o addon AdvPL (`src/supabase/JSSUPABASE.prw`) já usa em
produção. Contexto completo da decisão em
`.claude/plans/qual-seria-o-esfor-o-staged-pretzel.md` (na raiz do repo).

## Antes de rodar em produção

As tabelas `CUSTOMER`/`CONTRACT`/`PRODUCT` já existem e já são usadas pelo
AdvPL em produção. Este app só funciona de verdade depois que os scripts em
`supabase/migrations/` (001, 002, 003, 004 — nessa ordem) forem revisados e
executados no **SQL Editor do painel do Supabase** por alguém com acesso ao
projeto `mqdxpnvezumlldeusbmh`. Leia o cabeçalho de cada script antes de
rodar — o 002 em especial mexe em RLS de tabelas que o AdvPL já lê/escreve
em produção.

## Rodando localmente

```bash
cd app
flutter pub get
flutter run                 # escolhe o device conectado (emulador Android, simulador iOS, Chrome...)
```

Por padrão o app aponta para o mesmo projeto Supabase que o AdvPL usa hoje
(`lib/core/supabase/supabase_config.dart`). Para apontar para outro projeto
(ex.: homologação):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
```

## Primeiro admin

Todo cadastro feito pela tela "Criar conta" entra com papel `external`. Para
promover alguém a `admin` (acesso total), rode no SQL Editor do Supabase:

```sql
update "APP_USER" set "ROLE" = 'admin' where "EMAIL" = 'alguem@inansolucoes.com.br';
```

## Estrutura

```
lib/
  core/            # tema, config do Supabase, roteamento (go_router)
  features/
    auth/          # login, cadastro, recuperar senha, papel do usuário
    clientes/       # CRUD de Clientes (tabela CUSTOMER)
    contratos/       # CRUD de Contratos (tabela CONTRACT)
    produtos/         # CRUD de Produtos (tabela PRODUCT)
  shared/widgets/   # AppDrawer (menu lateral) e componentes reutilizados
supabase/migrations/ # scripts SQL para rodar manualmente no painel do Supabase
```

## Ambiente de desenvolvimento (verificado nesta máquina)

- Flutter/Dart: atualizado via `flutter upgrade` durante o scaffold inicial.
- Android: build funcional. O JDK padrão do sistema (26) quebra o build do
  Gradle/AGP — o projeto está configurado (`android/gradle.properties`,
  `org.gradle.java.home`) para usar o OpenJDK 17 instalado via
  `brew install openjdk@17`, sem alterar a JDK padrão do sistema.
- iOS: requer o Xcode completo (via App Store) — só as Command Line Tools
  estavam instaladas. Depois de instalado:
  ```bash
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -runFirstLaunch
  cd app/ios && pod install
  ```
