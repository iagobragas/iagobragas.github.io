# iagobragas.com.br

Blog pessoal do Iago Bragas — tecnologia, desenvolvimento e o que mais interessar.

Feito com [Hugo](https://gohugo.io/) e o tema [Hextra](https://github.com/imfing/hextra).
Publicado no GitHub Pages em https://iagobragas.com.br.

## Rodando localmente

Requisitos: [Hugo Extended](https://gohugo.io/installation/) 0.170.0+ e Ruby 3+ (`brew install hugo ruby`).

```bash
./scripts/generate_index.rb   # gera a home e o arquivo de posts
hugo server                   # http://localhost:1313
```

Ou com Docker:

```bash
./scripts/dev.sh start
```

## Novo post

```bash
./scripts/new_post.rb "Título do post" --tags programacao,ferramentas
```

Cria `content/AAAA/MM/DD/slug/index.md` como **rascunho** (`draft: true`); o endereço sai do título sem acentos.
As tags precisam existir em `data/tag_taxonomy.yml` (veja `TAGGING.md`). Para a versão em inglês, crie `index.en.md` na mesma pasta.

1. Escreva o post e preencha `description` e `tags`
2. Veja localmente com `hugo server -D` (o `-D` mostra rascunhos)
3. Para publicar: remova `draft: true`, rode `./scripts/generate_index.rb`, faça commit e push

Para destacar posts no carrossel da home, edite `FEATURED_POSTS` em `scripts/generate_index.rb`.

## Créditos

Os layouts e scripts deste site são adaptados de [akitaonrails.github.io](https://github.com/akitaonrails/akitaonrails.github.io),
de Fabio Akita, licenciado sob [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).
**Modificações:** remoção de todo o conteúdo e da identidade visual do autor original, novo gerador de índice,
fontes hospedadas no próprio site, favicon e configuração próprios, entre outras.

O tema [Hextra](https://github.com/imfing/hextra) (MIT) e as fontes (SIL OFL) mantêm suas próprias licenças;
veja [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Licença

[![CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

© Iago Bragas. Este repositório, incluindo os textos do blog, está licenciado sob
[Creative Commons Atribuição-NãoComercial-CompartilhaIgual 4.0 Internacional](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.pt-br)
(texto completo em [`LICENSE`](LICENSE)), exceto os componentes de terceiros listados em
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
