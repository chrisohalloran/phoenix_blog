# PhoenixBlog

A small, reusable markdown blog engine for Phoenix sites. The engine lives in
this library; each site keeps its own `priv/posts/*.md`. Posts compile to structs
at build time via [NimblePublisher](https://github.com/dashbitco/nimble_publisher)
— no database, no runtime file IO. Blog pages render inside each site's own
layout, so every site's blog looks native to that site.

Built for a family of Phoenix 1.8 sites that share one starter template. One
engine, many sites: fix once, bump the dep everywhere.

## Install

```elixir
# mix.exs
{:phoenix_blog, github: "chrisohalloran/phoenix_blog"}
```

## Add a blog to a site (5 steps)

1. **Content module** — one file, points the engine at this site's posts:

   ```elixir
   # lib/my_site/blog.ex
   defmodule MySite.Blog do
     use PhoenixBlog.Content, otp_app: :my_site
   end
   ```

2. **Routes** — in your router, inside a `:browser`-piped scope, **above any
   catch-all** (`get "/*path", ...`):

   ```elixir
   import PhoenixBlog.Router

   blog_routes "/blog",
     content: MySite.Blog,
     web_module: MySiteWeb,
     canonical_base: "https://mysite.com",
     title: "MySite Blog"
   ```

3. **Posts** — drop markdown files in `priv/posts/`, named `YYYY-MM-DD-slug.md`:

   ```markdown
   %{
     title: "Window tint and Queensland sun",
     description: "Why ceramic tint pays for itself.",
     tags: ["guides"],
     author: "Chris"
   }
   ---
   Your **markdown** body here.
   ```

   Publishing is `git push` + deploy. `draft: true` or a future date hides a post.

4. **Sitemap** — feed posts into the site's existing sitemap. In the host
   `SitemapController`, add the blog URLs from:

   ```elixir
   PhoenixBlog.Sitemap.entries(content: MySite.Blog, canonical_base: "https://mysite.com")
   #=> [%{loc: "https://mysite.com/blog/...", lastmod: "2026-01-02"}, ...]
   ```

5. **Nav link** — link `/blog` from the site nav.

That's it. No per-site templates, no database, no migrations.

## How it fits together

- **Theming** — the controller renders blog content inside the host site's
  **root** layout (`MySiteWeb.Layouts.root`), so chrome, fonts and colours are
  inherited. The blog content lives in `PhoenixBlog.HTML` (index + article).
- **SEO** — the controller assigns the `:seo_meta` map the template-family root
  layout already consumes (title, description, canonical, OG, Twitter, JSON-LD
  `Article`). Blog pages set `robots: "index,follow"` so they are indexed even
  though the template root defaults to `noindex`.
- **Compile-time content** — `use PhoenixBlog.Content` expands `use
  NimblePublisher` inside your module (the `use Ecto.Repo` pattern), so the post
  glob resolves against your app's `priv/posts`.

## Query API (on your content module)

`all_posts/0`, `published/0`, `get_by_slug!/1`, `recent/1`, `all_tags/0`,
`by_tag/1`. `published/0` excludes drafts and future-dated posts.

## Configuration

Options go on `blog_routes` (per mount) or under `config :phoenix_blog`:

| Key | Purpose |
|---|---|
| `:content` (required) | your content module |
| `:web_module` | host web module; its `Layouts.root` wraps blog pages |
| `:canonical_base` | site origin for canonical / OG URLs |
| `:title`, `:description` | blog index SEO |

A host without the template-family `Layouts.root` falls back to a minimal
built-in root (`PhoenixBlog.Layouts`).

## Caveats

- **Route ordering**: mount `blog_routes` above any `/*path` catch-all.
- **Layout contract**: the host must expose `MySiteWeb.Layouts.root`. Template
  forks do; an unusual app may need the fallback or a small shim.
