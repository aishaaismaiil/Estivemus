# Handoff, Estivemus (22 nov 2026)

## Objetivo
App e site para reencontrar antigos colegas de creche, escola e universidade (por instituição e anos), com fotos de turma. PT/EN/ES. Grátis, Supabase + GitHub.

## Estado atual
- App ligada ao Supabase (login por email) em `app/index.html`. **Não consegui confirmar o link público** (sem rede nesta sessão); provável GitHub Pages `aishaaismaiil.github.io/Estivemus`.
- Esta sessão criou o modo site, privacidade/termos (rascunho), segurança SQL e PWA. **Está só num branch local, ainda sem push** e o `security.sql` **não foi corrido nem testado**.
- Não divulgar antes de correr `security.sql` e preencher os campos amarelos.

## Ficheiros em que trabalhei
`index.html`, `privacidade.html`, `termos.html`, `site.css`, `app/index.html`, `app/manifest.webmanifest`, `app/icons/*`, `supabase/security.sql`, `SECURITY.md`, `DESIGN.md`, `README.md`, `handoff.md`

## Atualização (22 nov, tarde)
- Região do Supabase confirmada: UE (Irlanda). Projeto Estivemus: `ygpntqsliqlpqefdlvcj`. A base tem só 4 linhas de teste e `docs.sql` já foi aplicado.
- Teste do `security.sql` em modo "ensaio" (sem gravar) ficou **à espera de confirmação do utilizador no Supabase**; ainda não foi aplicado.
- App: toque duplo bloqueado, botão voltar fecha janelas (e protege o perfil em edição), teclado sobe a caixa de texto, `color-scheme: light`.
- Site: uma ação principal no topo ("Criar conta"); "Já tenho conta" passou a link.
- Pesquisa: não encontrei app igual em Portugal; marca "Estivemus" sem resultados óbvios (falta consulta oficial INPI/EUIPO). Google Play: conta pessoal nova precisa de 12 testadores durante 14 dias.

## O que mudou nesta sessão
- Site público novo (antes `index.html` só redirecionava) + política de privacidade e termos em PT-PT.
- App: palavra-passe mín. 8, links para termos/privacidade, CSP no modo web, "Descarregar os meus dados", apagar conta também apaga o email de login (função `delete_my_account`), convidar partilha a página inicial, meta de app instalável, `noindex`.
- SQL: perfis escondidos escondidos no servidor, fotos só para quem esteve lá nesse ano, eventos só para membros, não-donos só alteram o próprio voto/marcações, limite de tamanho.

## O que não resultou / limites
- Sem rede: não testei o link nem o SQL; WebFetch foi recusado. Sem Postgres local para validar o SQL.
- Nome completo continua legível via API por utilizadores com conta (ver `SECURITY.md`).

- App alinhada com o style guide do site (castanho/creme/tijolo, sem gradiente) e sem Google Fonts.

## Próximos passos
1. Correr `docs.sql` e `security.sql` no Supabase e fazer os 4 testes com 2-3 contas.
2. Preencher `[NOME]`, `[EMAIL]`, região Supabase, prazos; apagar avisos "Rascunho".
3. Ativar CAPTCHA e confirmação de email no Supabase.
4. Fazer push, confirmar o link público, depois publicar o comentário do TikTok com "link na bio".
5. Mover nome completo para fora do perfil público.
6. Notificações: ainda não existem (sem servidor de push). Só pedir permissão depois do 1.º reconhecimento, quando houver push ou emails de aviso.
