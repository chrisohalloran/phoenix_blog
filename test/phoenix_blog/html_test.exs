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

    test "shows a non-dead-end empty state when there are no posts" do
      html = render_component(&PhoenixBlog.HTML.index/1, posts: [], tags: [])
      refute html =~ "Check back soon"
      assert html =~ "New articles are on the way"
    end

    test "empty state offers the host CTA when one is configured" do
      html =
        render_component(&PhoenixBlog.HTML.index/1,
          posts: [],
          tags: [],
          cta: %{heading: "We can still help", label: "Get a quote", href: "/contact"}
        )

      assert html =~ "data-phoenix-blog-cta"
      assert html =~ "Get a quote"
      refute html =~ "New articles are on the way"
    end

    test "renders a configured heading and intro" do
      html =
        render_component(&PhoenixBlog.HTML.index/1,
          posts: [build_post()],
          tags: [],
          heading: "Window Tinting Guides",
          intro: "Practical advice from the team."
        )

      assert html =~ "Window Tinting Guides"
      assert html =~ "Practical advice from the team."
    end

    test "labels the topics strip rather than floating bare tags" do
      html =
        render_component(&PhoenixBlog.HTML.index/1,
          posts: [build_post()],
          tags: ["intro"],
          base_path: "/blog"
        )

      assert html =~ "Topics"
    end

    test "links topic chips to their facet pages" do
      html =
        render_component(&PhoenixBlog.HTML.index/1,
          posts: [build_post()],
          tags: ["intro"],
          base_path: "/blog"
        )

      assert html =~ ~s|href="/blog/tag/intro"|
    end

    test "percent-encodes reserved characters in tag chip links" do
      html =
        render_component(&PhoenixBlog.HTML.index/1,
          posts: [build_post()],
          tags: ["a/b"],
          base_path: "/blog"
        )

      # the '/' must be encoded so the chip stays a single routable segment
      assert html =~ ~s|href="/blog/tag/a%2Fb"|
    end

    test "does not show the CTA when posts are present" do
      html =
        render_component(&PhoenixBlog.HTML.index/1,
          posts: [build_post()],
          tags: [],
          cta: %{heading: "H", label: "L", href: "/x"}
        )

      refute html =~ "data-phoenix-blog-cta"
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

    test "reads at a capped measure with forward-looking navigation" do
      html = render_component(&PhoenixBlog.HTML.show/1, post: build_post(), base_path: "/blog")

      # the body keeps the prose reading measure (no max-w-none override)
      refute html =~ "max-w-none"
      # navigation points forward, not "back"
      assert html =~ "All articles"
    end

    test "renders a configured CTA with the analytics hook after the body" do
      html =
        render_component(&PhoenixBlog.HTML.show/1,
          post: build_post(),
          base_path: "/blog",
          cta: %{heading: "Want this done for you?", sub: "We help.", label: "Get a quote", href: "/contact"}
        )

      assert html =~ "Want this done for you?"
      assert html =~ "We help."
      assert html =~ "Get a quote"
      assert html =~ ~s|href="/contact"|
      assert html =~ "data-phoenix-blog-cta"
    end

    test "omits the CTA entirely when none is configured" do
      html = render_component(&PhoenixBlog.HTML.show/1, post: build_post(), base_path: "/blog")
      refute html =~ "data-phoenix-blog-cta"
    end

    test "renders a CTA without a sub line" do
      html =
        render_component(&PhoenixBlog.HTML.show/1,
          post: build_post(),
          base_path: "/blog",
          cta: %{heading: "H", label: "L", href: "/x"}
        )

      assert html =~ "data-phoenix-blog-cta"
      assert html =~ "L"
    end

    test "treats a cta missing href or label as unset (no dead button)" do
      no_href =
        render_component(&PhoenixBlog.HTML.show/1,
          post: build_post(),
          base_path: "/blog",
          cta: %{heading: "H", label: "L"}
        )

      no_label =
        render_component(&PhoenixBlog.HTML.show/1,
          post: build_post(),
          base_path: "/blog",
          cta: %{heading: "H", href: "/x"}
        )

      refute no_href =~ "data-phoenix-blog-cta"
      refute no_label =~ "data-phoenix-blog-cta"
    end

    test "renders an author credibility block with role and link" do
      html =
        render_component(&PhoenixBlog.HTML.show/1,
          post:
            build_post(%{author: "Chris", author_role: "Founder", author_url: "https://x.test/about"}),
          base_path: "/blog"
        )

      assert html =~ "Founder"
      assert html =~ ~s|href="https://x.test/about"|
      assert html =~ "More from Chris"
    end

    test "shows only the author name when role and link are absent" do
      html =
        render_component(&PhoenixBlog.HTML.show/1,
          post: build_post(%{author: "Chris", author_role: nil, author_url: nil}),
          base_path: "/blog"
        )

      assert html =~ "Chris"
      # no author card without role or link
      refute html =~ "More from"
    end

    test "renders the role without a link when only author_role is set" do
      html =
        render_component(&PhoenixBlog.HTML.show/1,
          post: build_post(%{author: "Chris", author_role: "Founder", author_url: nil}),
          base_path: "/blog"
        )

      assert html =~ "Founder"
      # the card renders (role present) but there is no link to follow
      refute html =~ "More from"
    end

    test "renders related posts linking to their slugs" do
      html =
        render_component(&PhoenixBlog.HTML.show/1,
          post: build_post(),
          base_path: "/blog",
          related: [build_post(%{id: "other-post", title: "Other Post"})]
        )

      assert html =~ "Keep reading"
      assert html =~ "Other Post"
      assert html =~ ~s|href="/blog/other-post"|
    end

    test "omits the related section when there are none" do
      html =
        render_component(&PhoenixBlog.HTML.show/1,
          post: build_post(),
          base_path: "/blog",
          related: []
        )

      refute html =~ "Keep reading"
    end

    test "links the post tags to their facet pages" do
      html =
        render_component(&PhoenixBlog.HTML.show/1,
          post: build_post(%{tags: ["news"]}),
          base_path: "/blog"
        )

      assert html =~ ~s|href="/blog/tag/news"|
    end
  end
end
