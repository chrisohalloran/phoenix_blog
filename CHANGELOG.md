# Changelog

## v0.2.0: Conversion architecture

Adds the conversion surfaces every host inherits, plus SEO hardening. All new
config, frontmatter, and assigns are optional, so an existing site renders
unchanged until it opts in.

### Added
- End-of-post **CTA** slot (`:cta` config), with a `data-phoenix-blog-cta`
  analytics hook. Renders only when configured.
- **Author credibility** block from `author_role` / `author_url` frontmatter.
- **Related posts** on each post (same tag first, recency fallback).
- **Index positioning**: `:heading` / `:intro` config and a non-dead-end empty
  state that offers the `:cta`.
- Per-post **`noindex`** frontmatter: reachable but out of search and the sitemap.
- **Tag facet pages** at `/blog/tag/:tag`, linked from every tag chip.
- Richer structured data: `publisher`, `dateModified`, `mainEntityOfPage`, and a
  `BreadcrumbList` on posts; `CollectionPage` on the index and tag facets.

### Fixed
- The fallback `PhoenixBlog.SEO.head/1` emitted literal `{...}` instead of
  JSON-LD, because HEEx does not interpolate inside `<script>` tags. It now
  builds the script tags correctly. Template-family hosts (own root layout) were
  unaffected.

### Changed (visible on bump)
- Post body drops the `max-w-none` override, so it keeps a readable measure.
- The post back-link reads "All articles"; the index tag strip is labelled
  "Topics" and the chips link to tag facet pages.
- The blog index and tag facets now emit `CollectionPage` + `BreadcrumbList`
  JSON-LD (the index previously emitted none), and the individual `:json_ld`
  assign is now populated on the index/tag (was nil). Hosts that already
  hand-author index structured data should check for duplication, and any host
  root rendering `seo_meta[:schema]` must iterate the list rather than
  destructure to a single element.
- The sitemap excludes `noindex` posts. A consumer asserting sitemap length
  against the `published()` count must now filter `noindex` posts.
- Unknown tags at `/blog/tag/:tag` return 404 (was a 200 empty page), so an
  arbitrary URL no longer renders a thin page or reflects its input.

### Security
- `/blog/tag/:tag` now serves only tags that exist, so a visitor-controlled tag
  string never reaches the page or its JSON-LD. The shipped host-layout examples
  encode JSON-LD with `escape: :html_safe`.
