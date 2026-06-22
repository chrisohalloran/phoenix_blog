defmodule PhoenixBlog.ControllerTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest

  @endpoint PhoenixBlog.Test.Endpoint

  setup do
    {:ok, conn: build_conn()}
  end

  test "GET /blog lists published posts inside the host root layout", %{conn: conn} do
    html = conn |> get("/blog") |> html_response(200)

    assert html =~ "TEST-CHROME"
    assert html =~ "Hello World"
    refute html =~ "A Draft In Progress"
    refute html =~ "From The Future"
    # blog index is indexable, overriding the host root's noindex default
    assert html =~ ~s|name="robots" content="index,follow"|
  end

  test "GET /blog/:slug renders the article with SEO + JSON-LD", %{conn: conn} do
    html = conn |> get("/blog/hello-world") |> html_response(200)

    assert html =~ "TEST-CHROME"
    assert html =~ "Hello World"
    assert html =~ "Chris"
    assert html =~ "application/ld+json"
    # the JSON-LD actually renders into the host root (not a literal {...})
    assert html =~ ~s|"@type":"Article"|
    assert html =~ ~s|rel="canonical" href="https://test.example/blog/hello-world"|
    # rendered markdown body
    assert html =~ "<strong>first</strong>"
  end

  test "assigns both :seo_meta and conventional individual SEO assigns", %{conn: conn} do
    conn = get(conn, "/blog/hello-world")

    # structured map (template-family roots)
    assert conn.assigns.seo_meta.og_type == "article"
    # individual assigns (other roots, e.g. reveille / ripasso)
    assert conn.assigns.page_title == "Hello World"
    assert conn.assigns.canonical_url == "https://test.example/blog/hello-world"
    assert is_binary(conn.assigns.meta_description)
    assert conn.assigns.og_type == "article"
    # :json_ld is a raw JSON string for roots that render it directly
    assert conn.assigns.json_ld =~ ~s|"@type":"Article"|
  end

  test "canonical derives from the endpoint URL when :canonical_base is unset", %{conn: conn} do
    conn = get(conn, "/derived/hello-world")
    assert conn.assigns.canonical_url == "http://localhost/derived/hello-world"
  end

  test "renders a configured CTA on a mount that sets :cta", %{conn: conn} do
    html = conn |> get("/derived/hello-world") |> html_response(200)
    assert html =~ "data-phoenix-blog-cta"
    assert html =~ "Work with us"
    assert html =~ "Get in touch"
  end

  test "omits the CTA on a mount without :cta", %{conn: conn} do
    html = conn |> get("/blog/hello-world") |> html_response(200)
    refute html =~ "data-phoenix-blog-cta"
  end

  test "surfaces a tag-sharing post as related, never itself", %{conn: conn} do
    html = conn |> get("/blog/hello-world") |> html_response(200)
    # second-post shares the "news" tag with hello-world
    assert html =~ "Keep reading"
    assert html =~ "Second Post"
    # the current post must not appear in its own related list
    refute html =~ ~s(href="/blog/hello-world")
  end

  test "a noindex post is reachable but marked noindex,follow", %{conn: conn} do
    html = conn |> get("/blog/internal-post") |> html_response(200)
    assert html =~ "Internal Post"
    assert html =~ ~s|name="robots" content="noindex,follow"|
  end

  test "related falls back to recency for a post with no shared tags", %{conn: conn} do
    # internal-post has no tags, so related is filled by the recency fallback
    html = conn |> get("/blog/internal-post") |> html_response(200)
    assert html =~ "Keep reading"
  end

  test "GET /blog/:slug with an unknown slug is a 404", %{conn: conn} do
    assert_error_sent(404, fn -> get(conn, "/blog/nope") end)
  end

  test "GET /blog/:slug for a draft is a 404 (not published)", %{conn: conn} do
    assert_error_sent(404, fn -> get(conn, "/blog/draft-post") end)
  end

  test "GET /blog/tag/:tag lists posts carrying the tag", %{conn: conn} do
    html = conn |> get("/blog/tag/news") |> html_response(200)
    assert html =~ "Posts tagged: news"
    assert html =~ "Hello World"
    assert html =~ "Second Post"
  end

  test "an unknown tag is a 404 (only existing tags are served)", %{conn: conn} do
    assert_error_sent(404, fn -> get(conn, "/blog/tag/nonexistent") end)
  end

  test "a hostile tag string is a 404, never reflected", %{conn: conn} do
    # closes the reflected-input vector: arbitrary visitor strings do not render
    assert_error_sent(404, fn -> get(conn, "/blog/tag/%3Cscript%3Ealert(1)%3C%2Fscript%3E") end)
  end

  test "tag facet canonical + json_ld point at the facet / CollectionPage", %{conn: conn} do
    conn = get(conn, "/blog/tag/news")
    assert conn.assigns.canonical_url == "https://test.example/blog/tag/news"
    assert conn.assigns.json_ld =~ ~s|"@type":"CollectionPage"|
  end

  test "blog routes resolve before the catch-all", %{conn: conn} do
    assert conn |> get("/blog") |> html_response(200) =~ "Hello World"
    # a non-blog path still reaches the catch-all
    assert conn |> get("/something-else") |> text_response(200) =~ "CATCHALL:something-else"
  end
end
