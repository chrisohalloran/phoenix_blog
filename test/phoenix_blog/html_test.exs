defmodule PhoenixBlog.HTMLTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias PhoenixBlog.Post

  defp build_post(overrides \\ %{}) do
    struct(
      Post,
      Map.merge(
        %{
          id: "hello-world",
          title: "Hello World",
          description: "desc here",
          date: ~D[2026-01-02],
          tags: ["intro", "news"],
          author: "Chris",
          body: "<p>Body <strong>here</strong></p>",
          draft?: false,
          cover_image: nil
        },
        Map.new(overrides)
      )
    )
  end

  describe "index/1" do
    test "renders a card per post linking to its slug" do
      html =
        render_component(&PhoenixBlog.HTML.index/1,
          posts: [build_post()],
          tags: ["intro"],
          base_path: "/blog"
        )

      assert html =~ "Hello World"
      assert html =~ ~s|href="/blog/hello-world"|
      assert html =~ "desc here"
      assert html =~ "2 January 2026"
    end

    test "shows an empty state when there are no posts" do
      html = render_component(&PhoenixBlog.HTML.index/1, posts: [], tags: [])
      assert html =~ "No posts yet"
    end
  end

  describe "show/1" do
    test "renders the article with raw body, author and tags" do
      html = render_component(&PhoenixBlog.HTML.show/1, post: build_post(), base_path: "/blog")

      assert html =~ "Hello World"
      assert html =~ "Chris"
      assert html =~ "2 January 2026"
      # body is injected raw, not HTML-escaped
      assert html =~ "<strong>here</strong>"
      assert html =~ "intro"
    end

    test "omits the tag row gracefully when a post has no tags" do
      html =
        render_component(&PhoenixBlog.HTML.show/1,
          post: build_post(%{tags: []}),
          base_path: "/blog"
        )

      assert html =~ "Hello World"
      refute html =~ "rounded-full bg-gray-100"
    end
  end
end
