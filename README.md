# Minhas Despesas — Supabase + GitHub Pages

Sistema pessoal de controle de despesas que substitui a planilha (aba **Despesas Gerais**).
HTML/CSS/JS puro, sem backend próprio: dados e login no **Supabase**, site no **GitHub Pages**.

## Arquivos

| Arquivo | O que é |
|---|---|
| `schema.sql` | Cria as tabelas `despesas` e `orcamentos`, índices e as regras de segurança (RLS). |
| `index.html` | O sistema inteiro num arquivo só (visual + lógica). Abre com dois cliques. |
| `config.js` | Opcional: URL e chave *anon* fixas para o site no GitHub Pages. Sem ele, a própria página pede esses dados na primeira vez. |

## Passo a passo

### 1. Banco de dados
1. Abra seu projeto **Despesas pessoais** no Supabase.
2. **SQL Editor → New query**, cole todo o conteúdo de `schema.sql` e clique em **Run**.
3. Confira em **Table Editor** que apareceram `despesas` e `orcamentos` (com o cadeado de RLS ativo).

### 2. Seu usuário (conta única)
1. **Authentication → Users → Add user → Create new user**: seu e-mail e uma senha forte. Marque **Auto Confirm User**.
2. **Authentication → Sign In / Providers → Email**: desligue **Allow new users to sign up**.
   Assim ninguém mais consegue criar conta, mesmo tendo o link do site.

### 3. Conectar a página ao Supabase
**Jeito mais fácil:** abra o `index.html` (dois cliques). Na primeira vez ele pede a **Project URL** e a **chave anon public** — cole e clique em Conectar. Fica salvo naquele navegador.

> Extraia o zip antes de abrir. Abrir o arquivo de dentro do zip também funciona, mas o Windows pode apagar a cópia temporária.

**Para o GitHub Pages** (para não precisar digitar em cada aparelho), preencha o `config.js`. Em **Project Settings → API** copie:
- **Project URL** → `SUPABASE_URL`
- **anon public** → `SUPABASE_ANON_KEY`

> A chave *anon* pode ficar pública — quem protege os dados é o login + RLS.
> **Nunca** use a chave `service_role` no site.

### 4. Publicar no GitHub Pages
1. Crie um repositório (ex.: `minhas-despesas`) e envie `index.html` e `config.js` para a raiz.
2. **Settings → Pages → Build and deployment**: *Deploy from a branch*, branch `main`, pasta `/ (root)`.
3. Em ~1 minuto o site fica em `https://SEU-USUARIO.github.io/minhas-despesas/`.
4. No Supabase, **Authentication → URL Configuration → Site URL**: coloque esse endereço.

### 5. Trazer o histórico da planilha
1. Entre no site com seu e-mail e senha.
2. Clique em **Importar planilha** (ou aba **Dados → Importar**) e escolha o seu `.xlsx`.
3. Ele lê a aba “Despesas Gerais”, mostra quantas linhas vai trazer e pede confirmação.

Na importação:
- Categorias com grafias diferentes são unificadas (`saque`→`Saque`, `beleza`→`Beleza`, `Bens Duravéis`→`Bens Duráveis`, `Cusos`→`Cursos`…). Cartões ficam em maiúsculas (`Neon`→`NEON`).
- As parcelas da mesma compra (mesma data, descrição, valor total, cartão e nº de parcelas) ficam ligadas, para editar ou excluir a compra inteira.
- Pode importar de novo sem medo: linhas que já existem são ignoradas (compras idênticas no mesmo dia continuam contando separadamente).

## Funções

- **Painel** — total do mês x média de 6 meses, pago/em aberto/atrasado, comprometido futuro, gráficos por mês, categoria e cartão, maiores gastos e evolução das categorias.
- **Lançamentos** — busca, filtros, ordenação, mudar status com um clique, seleção em massa, editar/excluir parcela ou compra inteira.
- **Faturas** — matriz mês × cartão; clique para ver a fatura e marcar como paga.
- **Parcelamentos** — compras em andamento, quanto falta e quando termina.
- **Orçamento** — limite mensal por categoria, com a média dos últimos 6 meses como sugestão.
- **Dados** — exportar `.xlsx` (mesmo layout da planilha), backup `.json` (inclui orçamento), importar planilha ou backup, renomear/unificar categorias e cartões.

## Testar a segurança (RLS)

No SQL Editor:

```sql
set local role anon;
select count(*) from public.despesas;   -- deve dar erro de permissão
reset role;
```

E no navegador: abra o site numa janela anônima — sem login, nada é carregado.
