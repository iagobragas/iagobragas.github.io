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
./scripts/dev.sh new-post "Título do post"
```

Os posts ficam em `content/AAAA/MM/DD/slug/index.md` (com `index.en.md` opcional para a versão em inglês).
As tags precisam existir em `data/tag_taxonomy.yml` (veja `TAGGING.md`).
Depois de criar, rode `./scripts/generate_index.rb` para atualizar a listagem.

Para destacar posts no carrossel da home, edite `FEATURED_POSTS` em `scripts/generate_index.rb`.

## Créditos

Layouts customizados baseados no blog [akitaonrails.github.io](https://github.com/akitaonrails/akitaonrails.github.io),
de Fabio Akita, que por sua vez parte do [Hextra Starter Template](https://github.com/imfing/hextra-starter-template).
