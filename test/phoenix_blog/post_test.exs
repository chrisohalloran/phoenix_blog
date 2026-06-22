defmodule PhoenixBlog.PostTest do
  use ExUnit.Case, async: true

  alias PhoenixBlog.Post

  describe "build/3" do
    test "parses date and slug from the filename" do
      post = Post.build("priv/posts/2026-01-02-hello-world.md", %{title: "Hello"}, "<p>hi</p>")

      assert post.id == "hello-world"
      assert post.date == ~D[2026-01-02]
      assert post.title == "Hello"
      assert post.body == "<p>hi</p>"
    end

    test "slug may contain dashes" do
      post =
        Post.build("priv/posts/2026-05-09-noosa-window-tint-guide.md", %{title: "T"}, "")

      assert post.id == "noosa-window-tint-guide"
      assert post.date == ~D[2026-05-09]
    end

    test "merges optional frontmatter" do
      post =
        Post.build(
          "2026-01-02-x.md",
          %{title: "X", description: "desc", author: "Chris", cover_image: "/c.png"},
          "body"
        )

      assert post.description == "desc"
      assert post.author == "Chris"
      assert post.cover_image == "/c.png"
    end

    test "defaults author when absent" do
      post = Post.build("2026-01-02-x.md", %{title: "X"}, "")
      assert post.author == "Staff"
    end

    test "draft? defaults to false and reads draft: true" do
      assert Post.build("2026-01-02-x.md", %{title: "X"}, "").draft? == false
      assert Post.build("2026-01-02-x.md", %{title: "X", draft: true}, "").draft? == true
    end

    test "normalises tags to a list of strings" do
      assert Post.build("2026-01-02-x.md", %{title: "X", tags: ["a", "b"]}, "").tags == ["a", "b"]
      assert Post.build("2026-01-02-x.md", %{title: "X", tags: "solo"}, "").tags == ["solo"]
      assert Post.build("2026-01-02-x.md", %{title: "X"}, "").tags == []
    end

    test "reads optional author_role and author_url" do
      post =
        Post.build(
          "2026-01-02-x.md",
          %{title: "X", author: "Chris", author_role: "Founder", author_url: "https://x.test/about"},
          ""
        )

      assert post.author_role == "Founder"
      assert post.author_url == "https://x.test/about"
    end

    test "author_role, author_url and updated default to nil" do
      post = Post.build("2026-01-02-x.md", %{title: "X"}, "")
      assert post.author_role == nil
      assert post.author_url == nil
      assert post.updated == nil
    end

    test "noindex defaults to false and only true reads true" do
      assert Post.build("2026-01-02-x.md", %{title: "X"}, "").noindex == false
      assert Post.build("2026-01-02-x.md", %{title: "X", noindex: true}, "").noindex == true
      # any non-true value is false (strict coercion, like draft?)
      assert Post.build("2026-01-02-x.md", %{title: "X", noindex: "yes"}, "").noindex == false
    end

    test "updated accepts a Date or an ISO-8601 string" do
      from_date = Post.build("2026-01-02-x.md", %{title: "X", updated: ~D[2026-06-20]}, "")
      from_string = Post.build("2026-01-02-x.md", %{title: "X", updated: "2026-06-20"}, "")

      assert from_date.updated == ~D[2026-06-20]
      assert from_string.updated == ~D[2026-06-20]
    end

    test "updated raises a clear error when the string is not a date" do
      assert_raise ArgumentError, fn ->
        Post.build("2026-01-02-x.md", %{title: "X", updated: "not-a-date"}, "")
      end
    end

    test "raises a clear error when title is missing" do
      assert_raise KeyError, fn ->
        Post.build("2026-01-02-x.md", %{description: "no title"}, "")
      end
    end

    test "raises when the filename is not YYYY-MM-DD-slug" do
      assert_raise ArgumentError, ~r/YYYY-MM-DD-slug/, fn ->
        Post.build("priv/posts/hello-world.md", %{title: "X"}, "")
      end
    end
  end
end
