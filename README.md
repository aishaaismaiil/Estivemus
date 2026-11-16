# Estivemus

*Reencontra quem também esteve.* / *We were there.* / *Estuvimos allí.*

Reencontra antigos colegas de creche, escola e universidade pelo sítio e pelos anos em que lá estiveste.
Find old classmates from nursery, school and university by place and years. / Encuentra a antiguos compañeros de guardería, colegio y universidad.

Idiomas / Languages / Idiomas: **PT-PT · EN · ES**

![Estivemus](assets/logo/estivemus-logo.svg)

## Estado / Status

- `app/index.html`: a app completa num só ficheiro (HTML + JS, sem build). Corre hoje como artefacto no claude.ai, onde guarda os dados na base de dados do artefacto (só para quem for convidado: teste fechado).
- `supabase/schema.sql`: esquema de base de dados Postgres (Supabase) com regras de acesso por linha (RLS), para o lançamento público. **Ainda não foi executado nem testado.**
- Falta, para lançar ao público: ligar a app a uma base de dados pública (ver abaixo), login (e-mail ou Google), termos e política de privacidade, e domínio.

## Funcionalidades

- Perfil com foto, nome e percurso: creche, pré-escolar, 1.º/2.º/3.º ciclo, secundário e superior, com anos e turma.
- Foto da época por instituição.
- Sugestões em cartas ("reconheço / não reconheço"; botão "Estive lá" no início e "Era eu!" nas fotos); quem não reconheces continua nas procuras.
- Procura por nome, instituição, ano, nível e turma.
- Turmas com fotos antigas (marcações só com aprovação) e reencontros com votação de datas.
- Só maiores de 18 anos. Sem reconhecimento facial. Nome abreviado por defeito.

## Passar para base de dados pública (Supabase)

1. Criar um projeto em supabase.com e correr `supabase/schema.sql` no SQL Editor.
2. Ativar o login por e-mail/Google em Authentication.
3. Trocar as chamadas `S.db.doc(...)`/`S.db.collection(...)` em `app/index.html` por um adaptador para Supabase (as chamadas estão todas na secção `actions` e `boot`).
4. Alojar `app/index.html` em Netlify, Vercel ou GitHub Pages.

## RGPD (resumo)

Dados pessoais de adultos, consentimento explícito no registo, apagar conta a um clique, sem biometria, fotos só visíveis a quem esteve na mesma instituição nesse ano. Antes de lançar, rever com um jurista e consultar a CNPD.
