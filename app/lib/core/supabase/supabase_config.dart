/// Credenciais do projeto Supabase usado pelo SmartSupply.
///
/// Os valores padrão abaixo são os mesmos já embutidos em produção no
/// AdvPL (`U_JSGETDB`/`U_JSGETKEY` em `src/main/JSPAIGEN.prw`) — a anon key
/// do Supabase é pública por design (é enviada a cada instalação do
/// Protheus), então repeti-la aqui não expõe nada de novo; quem protege os
/// dados são as políticas de RLS no banco, não o sigilo desta chave.
///
/// Para apontar para outro projeto (ex.: ambiente de homologação), passe
/// via --dart-define na hora do build/run:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mqdxpnvezumlldeusbmh.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xZHhwbnZlenVtbGxkZXVzYm1oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk1NjQxMjIsImV4cCI6MjA1NTE0MDEyMn0._bjK4yUSX6jlkWYKdwg4ou0VUBjJpIHkD5jZb4o3lqY',
  );
}
