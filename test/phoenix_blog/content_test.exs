defmodule PhoenixBlog.ContentTest do
  use ExUnit.Case, async: true

  alias PhoenixBlog.Test.FixtureBlog

  test "keystone: the macro compiles markdown into posts inside a host module" do
    posts = FixtureBlog.all_posts()
    assert length(posts) == 3
    # all_posts is newest-first and includes the draft + future-dated fixtures
    assert hd(posts).date == ~D[2030-01-01]
  end

  test "published/0 excludes drafts and future-dated posts" do
    slugs = Enum.map(FixtureBlog.published(), & &1.id)
    assert "hello-world" in slugs
    refute "draft-post" in slugs
    refute "future-post" in slugs
  end

  test "get_by_slug!/1 returns a published post" do
    assert FixtureBlog.get_by_slug!("hello-world").title == "Hello World"
  end

  test "get_by_slug!/1 raises NotFound for unknown or unpublished slugs" do
    assert_raise PhoenixBlog.NotFound, fn -> FixtureBlog.get_by_slug!("nope") end
    assert_raise PhoenixBlog.NotFound, fn -> FixtureBlog.get_by_slug!("draft-post") end
  end

  test "body is rendered from markdown to HTML" do
    post = FixtureBlog.get_by_slug!("hello-world")
    assert post.body =~ "<h1>"
    assert post.body =~ "<strong>first</strong>"
  end

  test "all_tags/0 is unique + sorted across published posts only" do
    # only hello-world is published; its tags are intro + news
    assert FixtureBlog.all_tags() == ["intro", "news"]
  end

  test "by_tag/1 filters published posts" do
    assert Enum.map(FixtureBlog.by_tag("news"), & &1.id) == ["hello-world"]
    assert FixtureBlog.by_tag("nonexistent") == []
  end

  test "recent/1 returns the n newest published posts" do
    assert Enum.map(FixtureBlog.recent(1), & &1.id) == ["hello-world"]
  end
end
