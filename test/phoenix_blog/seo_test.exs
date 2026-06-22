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

    test "schema leads with a valid Article map" do
      meta = SEO.post_meta(build_post(), canonical_base: "https://x.test", base_path: "/blog")
      [article | _] = meta.schema

      assert article["@type"] == "Article"
      assert article["headline"] == "Hello World"
      assert article["datePublished"] == "2026-01-02"
      assert article["author"]["name"] == "Chris"
      assert article["url"] == "https://x.test/blog/hello-world"
      assert article["mainEntityOfPage"]["@id"] == "https://x.test/blog/hello-world"
    end

    test "dateModified uses updated when set, else the publish date" do
      base = [canonical_base: "https://x.test", base_path: "/blog"]
      [plain | _] = SEO.post_meta(build_post(), base).schema
      [edited | _] = SEO.post_meta(build_post(%{updated: ~D[2026-06-20]}), base).schema

      assert plain["dateModified"] == "2026-01-02"
      assert edited["dateModified"] == "2026-06-20"
    end

    test "publisher Organization is included when configured, omitted otherwise" do
      with_pub =
        SEO.post_meta(build_post(),
          canonical_base: "https://x.test",
          publisher: "Noosa Tint",
          publisher_logo: "/logo.png"
        )

      [article | _] = with_pub.schema
      assert article["publisher"]["@type"] == "Organization"
      assert article["publisher"]["name"] == "Noosa Tint"
      assert article["publisher"]["logo"]["url"] == "https://x.test/logo.png"

      [plain | _] = SEO.post_meta(build_post(), canonical_base: "https://x.test").schema
      refute Map.has_key?(plain, "publisher")
    end

    test "publisher is omitted when only a logo (no name) is configured" do
      meta = SEO.post_meta(build_post(), canonical_base: "https://x.test", publisher_logo: "/logo.png")
      [article | _] = meta.schema
      refute Map.has_key?(article, "publisher")
    end

    test "post schema includes a BreadcrumbList" do
      meta = SEO.post_meta(build_post(), canonical_base: "https://x.test", base_path: "/blog")
      crumbs = Enum.find(meta.schema, &(&1["@type"] == "BreadcrumbList"))

      assert crumbs
      assert List.last(crumbs["itemListElement"])["item"] == "https://x.test/blog/hello-world"
    end

    test "index schema is a CollectionPage, not an Article" do
      [collection | _] = SEO.index_meta(canonical_base: "https://x.test", title: "The Blog").schema
      assert collection["@type"] == "CollectionPage"
      assert collection["name"] == "The Blog"
    end

    test "a noindex post sets robots noindex,follow" do
      meta = SEO.post_meta(build_post(%{noindex: true}), canonical_base: "https://x.test")
      assert meta.robots == "noindex,follow"
    end

    test "absolute image from a relative cover_image, summary_large_image card" do
      meta =
        SEO.post_meta(build_post(%{cover_image: "/img/c.png"}), canonical_base: "https://x.test")

      assert meta.og_image == "https://x.test/img/c.png"
      assert meta.twitter_card == "summary_large_image"
    end
  end

  describe "tag_meta/2" do
    test "canonical points at the facet and schema is a CollectionPage" do
      meta =
        SEO.tag_meta("news", canonical_base: "https://x.test", base_path: "/blog", title: "The Blog")

      assert meta.canonical == "https://x.test/blog/tag/news"
      assert meta.title == "Posts tagged: news"
      assert meta.robots == "index,follow"

      [collection | _] = meta.schema
      assert collection["@type"] == "CollectionPage"
    end

    test "percent-encodes reserved characters in the facet canonical" do
      meta = SEO.tag_meta("a/b", canonical_base: "https://x.test", base_path: "/blog")
      assert meta.canonical == "https://x.test/blog/tag/a%2Fb"
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
      # the JSON-LD renders as real JSON, not a literal {...} expression
      assert html =~ ~s|"@type":"Article"|
      # JSON-LD cannot break out of the script tag
      refute html =~ "</script><"
    end

    test "index_meta renders a CollectionPage, not an Article" do
      seo = SEO.index_meta(canonical_base: "https://x.test", title: "The Blog")
      html = render_component(&SEO.head/1, seo_meta: seo)

      assert html =~ ~s|property="og:type" content="website"|
      assert html =~ "application/ld+json"
      assert html =~ "CollectionPage"
      refute html =~ ~s|"@type":"Article"|
    end
  end
end
