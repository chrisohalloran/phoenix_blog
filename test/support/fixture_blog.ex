defmodule PhoenixBlog.Test.FixtureBlog do
  @moduledoc """
  A fixture host module that exercises `PhoenixBlog.Content` against the test
  posts. Proves the keystone: `use NimblePublisher` expands correctly inside a
  host module and the injected query API works. Uses an explicit `:from` because
  the fixtures live under `test/fixtures/posts`, not `priv/posts`.
  """
  use PhoenixBlog.Content,
    otp_app: :phoenix_blog,
    from: Path.expand("../fixtures/posts/**/*.md", __DIR__)
end
