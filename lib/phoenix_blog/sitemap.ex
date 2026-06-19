defmodule PhoenixBlog.Sitemap do
  @moduledoc """
  Feeds published blog post URLs into a host site's existing sitemap.

  The template family serves a batched `sitemap.xml`; rather than replace it, a
  site adds the blog as one more `<sitemap>` entry pointing at a blog urlset, or
  merges `entries/1` into its own builder.

      # in the host SitemapController:
      PhoenixBlog.Sitemap.entries(content: MySite.Blog, canonical_base: "https://mysite.com")
      #=> [%{loc: "https://mysite.com/blog/hello", lastmod: "2026-01-02"}, ...]

  Only published posts are included (drafts and future-dated are excluded).
  """

  @doc """
  List of `%{loc, lastmod}` for published posts.

  Options: `:content` (required, the host content module), `:canonical_base`,
  `:base_path` (default `/blog`).
  """
  def entries(opts) do
    content = Keyword.fetch!(opts, :content)
    base = Keyword.get(opts, :canonical_base, "")
    base_path = Keyword.get(opts, :base_path, "/blog")

    Enum.map(content.published(), fn post ->
      %{loc: "#{base}#{base_path}/#{post.id}", lastmod: Date.to_iso8601(post.date)}
    end)
  end

  @doc """
  A ready-to-serve `<urlset>` XML document for the published posts. Use when a
  site wants the blog at its own sitemap URL (e.g. `/sitemaps/blog.xml`).
  """
  def urlset_xml(opts) do
    body =
      opts
      |> entries()
      |> Enum.map_join("\n", fn %{loc: loc, lastmod: lastmod} ->
        "  <url>\n    <loc>#{escape(loc)}</loc>\n    <lastmod>#{escape(lastmod)}</lastmod>\n  </url>"
      end)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{body}
    </urlset>
    """
  end

  defp escape(value) do
    value
    |> to_string()
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end
end
