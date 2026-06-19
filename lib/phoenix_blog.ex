defmodule PhoenixBlog do
  @moduledoc """
  A small, reusable markdown blog engine for Phoenix sites.

  The engine lives in this library; each host site keeps its own
  `priv/posts/*.md` and a one-line content module:

      defmodule MySite.Blog do
        use PhoenixBlog.Content, otp_app: :my_site
      end

  Posts are markdown files with frontmatter, compiled to structs at build time
  by NimblePublisher (no database, no runtime file IO). Routes mount with one
  line, rendering inside the host site's own layout.

  See `PhoenixBlog.Content`, `PhoenixBlog.Router`, and `PhoenixBlog.Sitemap`.
  """
end
