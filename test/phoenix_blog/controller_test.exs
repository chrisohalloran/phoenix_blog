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
    assert html =~ ~s|rel="canonical" href="https://test.example/blog/hello-world"|
    # rendered markdown body
    assert html =~ "<strong>first</strong>"
  end

  test "GET /blog/:slug with an unknown slug is a 404", %{conn: conn} do
    assert_error_sent(404, fn -> get(conn, "/blog/nope") end)
  end

  test "GET /blog/:slug for a draft is a 404 (not published)", %{conn: conn} do
    assert_error_sent(404, fn -> get(conn, "/blog/draft-post") end)
  end

  test "blog routes resolve before the catch-all", %{conn: conn} do
    assert conn |> get("/blog") |> html_response(200) =~ "Hello World"
    # a non-blog path still reaches the catch-all
    assert conn |> get("/something-else") |> text_response(200) =~ "CATCHALL:something-else"
  end
end
