# Handoff — Estivemus

## Objetivo
App + site para reencontrar antigos colegas de creche, escola e universidade (instituição + anos, fotos de turma, "Estive lá" / "Era eu!", contacto só com reconhecimento mútuo, 18+, PT/EN/ES).

## Estado atual (22 nov)
- Site público (landing, privacidade, termos) redesenhado: conceito "caderneta escolar / ficha de turma / bilhete". Sem gradientes, sem emojis. Só "Entrar" no cabeçalho; "Criar conta" é o único botão cheio e está no fim da página.
- App (app/index.html) é PWA instalável; modo site e modo app funcionam.
- Supabase (projeto ygpntqsliqlpqefdlvcj): `supabase/security.sql` JÁ APLICADO e verificado (RLS reforçado, trigger de updates, delete_my_account, revoke anon).
- PR #1 já fundido. Redesenho da landing publicado em main.

## Ficheiros principais
index.html, site.css, privacidade.html, termos.html, app/index.html, app/manifest.webmanifest, app/icons/, supabase/docs.sql, supabase/security.sql, SECURITY.md, DESIGN.md, README.md.
Nota: o script inline do index.html tem hash CSP; não alterar nem um byte sem recalcular o sha256.

## O que mudou nesta sessão
Segurança no Supabase aplicada; landing redesenhada; "Criar conta" movido para o fim; margem da caderneta e carimbo da ficha corrigidos; handoff atualizado.

## O que não resultou
- Criar PR por `gh pr create` (GraphQL bloqueado) → usar `gh api` REST.
- API do GitHub Pages (403) → ativar manualmente (ela diz que já está).
- WebFetch do link público não foi aprovado → site por verificar.

## Por fazer (manual, Aisha)
1. Supabase → Auth: confirmação de email, CAPTCHA (Turnstile), Site URL e Redirect URLs = https://aishaaismaiil.github.io/Estivemus/, password mínima 8, proteção contra passwords vazadas.
2. Preencher os campos amarelos em privacidade.html e termos.html: nome completo, email de contacto, retenção de backups, prazo de contas inativas. Depois remover o aviso "Rascunho por rever".
3. Verificar a marca "Estivemus" (EUIPO TMview, INPI).
4. Abrir o link, criar conta de teste e percorrer a app antes de partilhar no TikTok/Reddit.

## Próximos passos
- Rever visualmente os ecrãs da app com sessão iniciada.
- Notificações: sem servidor de push; o caminho simples é email.
- Limitações: nome completo legível via API por utilizadores autenticados; token em localStorage; fotos em base64; supabase-js sem SRI; projeto grátis pausa após ~7 dias sem uso.
