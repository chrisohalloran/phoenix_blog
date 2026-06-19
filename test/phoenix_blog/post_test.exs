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
