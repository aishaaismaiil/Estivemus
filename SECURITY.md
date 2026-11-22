# Segurança e privacidade: lista de verificação

## 1. Base de dados (Supabase > SQL Editor)
1. Correr `supabase/docs.sql` e depois `supabase/security.sql` (não foram testados contra a base real; seguir os 4 testes no topo do `security.sql`).
2. Confirmar que as tabelas têm RLS ativa (Table Editor > docs > "RLS enabled").

## 2. Supabase > Authentication
- Ativar confirmação de email.
- Palavra-passe mínima de 8 caracteres (a app já exige 8).
- Ativar CAPTCHA (Cloudflare Turnstile, grátis) contra contas falsas.
- Em URL Configuration, colocar só o endereço real do site em Site URL e Redirect URLs.
- Rever limites de envio de emails e tentativas.

## 3. Limitações conhecidas
- O nome completo vai no perfil e a abreviatura é feita na app: um utilizador com conta e conhecimentos técnicos pode ler nomes completos pela API. Solução futura: guardar o nome completo à parte (como o contacto) e só mostrar abreviado.
- Fotos em base64 dentro da base de dados (máx. ~240 KB por foto): passar para Supabase Storage quando houver muitos utilizadores.
- A biblioteca do Supabase vem de jsDelivr sem SRI; fixar a versão e acrescentar `integrity`.
- Google Fonts na app: substituir por fontes alojadas no repositório.
- Dono da foto pode editar tudo nela, incluindo aprovar marcações sem passar pela pessoa marcada (a app não o faz).
- As denúncias ficam na base de dados (coleção `reports/...`); não há painel, vê-las no Table Editor.

## 4. Antes de divulgar
- Preencher os campos amarelos em `privacidade.html` e `termos.html` e apagar o aviso "Rascunho".
- Criar 2 contas de teste e confirmar os 4 testes do `security.sql`.
