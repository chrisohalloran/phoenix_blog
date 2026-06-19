# Rollout

Status of `phoenix_blog` across the Phoenix site family.

| Site | Repo | Status |
|---|---|---|
| noosa_tint | `noosa_tint` | **proof site** — first integration (path dep → github dep) |
| reveille | `cal-to-call` | pending |
| ripasso | `ripasso` | pending |
| leva_web | `leva` (umbrella) | pending — **verify `Layouts.root`/`:app` first** (umbrella, not a template fork) |
| _template_ | `programatic_seo_site_template` | optional — add so new forks inherit the blog |

Non-Phoenix family sites (sondelle, qbcc-calculator, freehold) **cannot** use this
library; they need a separate Next.js/MDX + static-markdown effort sharing the
same frontmatter schema and `/blog` URL shape.

## Per-site recipe

For each Phoenix site, repeat the five steps in `README.md`:

1. Add `{:phoenix_blog, github: "chrisohalloran/phoenix_blog"}` to `mix.exs`, `mix deps.get`.
2. Create `lib/<app>/blog.ex` with `use PhoenixBlog.Content, otp_app: :<app>`.
3. Add `blog_routes "/blog", content: <App>.Blog, web_module: <App>Web, canonical_base: "https://<site>", title: "<Site> Blog"` in the router, **above the `/*path` catch-all**.
4. Add `priv/posts/` with at least one real `YYYY-MM-DD-slug.md` post.
5. Wire `PhoenixBlog.Sitemap.entries/1` into the host `SitemapController`, and add a `/blog` nav link.

### Verify each site before moving on

- `/blog` and `/blog/:slug` render inside that site's own layout (its nav/fonts/colours).
- View-source shows the post `<title>`, meta description, canonical, OG/Twitter, and a JSON-LD `Article`.
- `robots` is `index,follow` on blog pages.
- `sitemap.xml` includes the blog post URLs; drafts and future-dated posts do not appear.
- The site's existing routes (incl. the catch-all) still resolve.

### leva_web note

`leva_web` is an umbrella app, not a template fork, so confirm it exposes
`LevaWeb.Layouts.root` consuming `:seo_meta` (and ideally the same head shape). If
it differs, either adapt its root layout or rely on the fallback
`PhoenixBlog.Layouts` root (no site chrome).
