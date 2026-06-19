defmodule PhoenixBlog.Router do
  @moduledoc """
  Router macro to mount the blog in a host application.

  In your host router, inside a `:browser`-piped scope:

      import PhoenixBlog.Router

      scope "/" do
        pipe_through :browser
        blog_routes "/blog", content: MySite.Blog, web_module: MySiteWeb,
          canonical_base: "https://mysite.com", title: "MySite Blog"
        # ... your catch-all route LAST ...
      end

  > #### Route ordering {: .warning}
  > Mount `blog_routes` **above** any catch-all route (`get "/*path", ...`).
  > A catch-all placed first will swallow `/blog` and `/blog/:slug`.

  Options are passed to `PhoenixBlog.Controller` via route `private` data, so
  each site configures its blog at the mount point. Any option may also be set
  globally under `config :phoenix_blog, key: value`.

    * `:content` (required) - the host content module (`use PhoenixBlog.Content`)
    * `:web_module` - the host web module; its `Layouts.root` wraps blog pages
    * `:canonical_base` - site origin for canonical/OG URLs
    * `:title`, `:description` - index page SEO
  """

  @doc "Mount the blog index and post routes at `path` (default `/blog`)."
  defmacro blog_routes(path \\ "/blog", opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      private = %{phoenix_blog: Keyword.put(opts, :base_path, path)}
      get(path, PhoenixBlog.Controller, :index, private: private)
      get(path <> "/:slug", PhoenixBlog.Controller, :show, private: private)
    end
  end
end
