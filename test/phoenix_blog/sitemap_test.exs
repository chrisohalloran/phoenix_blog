defmodule PhoenixBlog.SitemapTest do
  use ExUnit.Case, async: true

  alias PhoenixBlog.Sitemap
  alias PhoenixBlog.Test.FixtureBlog

  test "entries/1 returns published posts as loc + lastmod" do
    entries =
      Sitemap.entries(content: FixtureBlog, canonical_base: "https://x.test", base_path: "/blog")

    assert %{loc: "https://x.test/blog/hello-world", lastmod: "2026-01-02"} in entries
    assert %{loc: "https://x.test/blog/second-post", lastmod: "2026-01-01"} in entries
    assert length(entries) == 2
  end

  test "entries/1 excludes drafts and future-dated posts" do
    locs =
      [content: FixtureBlog, canonical_base: "https://x.test"]
      |> Sitemap.entries()
      |> Enum.map(& &1.loc)

    refute Enum.any?(locs, &String.contains?(&1, "draft-post"))
    refute Enum.any?(locs, &String.contains?(&1, "future-post"))
  end

  test "entries/1 excludes noindex posts but they stay published" do
    locs =
      [content: FixtureBlog, canonical_base: "https://x.test"]
      |> Sitemap.entries()
      |> Enum.map(& &1.loc)

    # internal-post is published (reachable) but noindex, so absent from the sitemap
    assert "internal-post" in Enum.map(FixtureBlog.published(), & &1.id)
    refute Enum.any?(locs, &String.contains?(&1, "internal-post"))
  end

  test "entries/1 honours a custom base_path" do
    locs =
      [content: FixtureBlog, canonical_base: "https://x.test", base_path: "/insights"]
      |> Sitemap.entries()
      |> Enum.map(& &1.loc)

    assert "https://x.test/insights/hello-world" in locs
  end

  test "urlset_xml/1 is well-formed" do
    xml = Sitemap.urlset_xml(content: FixtureBlog, canonical_base: "https://x.test")

    assert xml =~ ~s|<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">|
    assert xml =~ "<loc>https://x.test/blog/hello-world</loc>"
    assert xml =~ "<lastmod>2026-01-02</lastmod>"
  end
end
