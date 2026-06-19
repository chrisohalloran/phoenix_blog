defmodule PhoenixBlog.SEOTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias PhoenixBlog.{Post, SEO}

  defp build_post(overrides \\ %{}) do
    struct(
      Post,
      Map.merge(
        %{
          id: "hello-world",
          title: "Hello World",
          description: "A first post.",
          date: ~D[2026-01-02],
          tags: ["intro"],
          author: "Chris",
          body: "<p>x</p>",
          draft?: false,
          cover_image: nil
        },
        Map.new(overrides)
      )
    )
  end

  describe "post_meta/2" do
    test "builds canonical from base + base_path + slug and sets index,follow" do
      meta =
        SEO.post_meta(build_post(),
          canonical_base: "https://noosatint.com.au",
          base_path: "/blog"
        )

      assert meta.canonical == "https://noosatint.com.au/blog/hello-world"
      assert meta.og_type == "article"
      assert meta.og_title == "Hello World"
      # blog posts must be indexable (host root layout defaults to noindex)
      assert meta.robots == "index,follow"
    end

    test "schema is a list with a valid Article map" do
      meta = SEO.post_meta(build_post(), canonical_base: "https://x.test", base_path: "/blog")
      [article] = meta.schema

      assert article["@type"] == "Article"
      assert article["headline"] == "Hello World"
      assert article["datePublished"] == "2026-01-02"
      assert article["author"]["name"] == "Chris"
      assert article["url"] == "https://x.test/blog/hello-world"
    end

    test "absolute image from a relative cover_image, summary_large_image card" do
      meta =
        SEO.post_meta(build_post(%{cover_image: "/img/c.png"}), canonical_base: "https://x.test")

      assert meta.og_image == "https://x.test/img/c.png"
      assert meta.twitter_card == "summary_large_image"
    end
  end

  describe "head/1 fallback component" do
    test "renders seo_meta into head tags incl. JSON-LD, escaped" do
      seo = SEO.post_meta(build_post(%{title: "Pwn </script>"}), canonical_base: "https://x.test")
      html = render_component(&SEO.head/1, seo_meta: seo)

      assert html =~ ~s|<link rel="canonical" href="https://x.test/blog/hello-world"|
      assert html =~ ~s|name="robots" content="index,follow"|
      assert html =~ ~s|property="og:type" content="article"|
      assert html =~ ~s|type="application/ld+json"|
      # JSON-LD cannot break out of the script tag
      refute html =~ "</script><"
    end

    test "index_meta omits article schema" do
      seo = SEO.index_meta(canonical_base: "https://x.test", title: "The Blog")
      html = render_component(&SEO.head/1, seo_meta: seo)

      assert html =~ ~s|property="og:type" content="website"|
      refute html =~ "application/ld+json"
    end
  end
end
