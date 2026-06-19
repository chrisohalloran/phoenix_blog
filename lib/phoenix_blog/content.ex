defmodule PhoenixBlog.Content do
  @moduledoc """
  Turns a host module into a compiled, queryable blog.

  Each site defines one module:

      defmodule MySite.Blog do
        use PhoenixBlog.Content, otp_app: :my_site
      end

  This expands `use NimblePublisher` *inside the host module* (the same way
  `use Ecto.Repo` works), so the markdown glob resolves against that site's
  own `priv/posts/`. The content is compiled to `PhoenixBlog.Post` structs at
  build time and the following query functions are injected:

    * `all_posts/0` - every post, newest first (drafts and future-dated included)
    * `published/0` - posts that are not drafts and not future-dated, newest first
    * `get_by_slug!/1` - a published post by slug, or raises `PhoenixBlog.NotFound`
    * `recent/1` - the N most recent published posts
    * `all_tags/0` - unique, sorted tags across published posts
    * `by_tag/1` - published posts carrying a tag

  ## Options

    * `:otp_app` (required) - the host application, used to locate `priv/posts`
    * `:from` - override the markdown glob (defaults to
      `priv/posts/**/*.md` under the app). Tests and non-standard layouts use this.
    * `:comrak_options` - passed through to NimblePublisher's markdown renderer
  """

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    from = Keyword.get(opts, :from) || Application.app_dir(otp_app, "priv/posts/**/*.md")

    np_opts =
      [build: PhoenixBlog.Post, from: from, as: :posts]
      |> maybe_put(:comrak_options, Keyword.get(opts, :comrak_options))

    quote do
      use NimblePublisher, unquote(np_opts)

      @doc "All posts, newest first (drafts and future-dated included)."
      def all_posts, do: Enum.sort_by(@posts, & &1.date, {:desc, Date})

      @doc """
      Published posts only: not drafts, date on or before today, newest first.
      This is what listings, routes, and the sitemap use.
      """
      def published do
        today = Date.utc_today()

        all_posts()
        |> Enum.reject(& &1.draft?)
        |> Enum.reject(&(Date.compare(&1.date, today) == :gt))
      end

      @doc "Fetch a published post by slug. Raises `PhoenixBlog.NotFound` if absent."
      def get_by_slug!(slug) do
        case Enum.find(published(), &(&1.id == slug)) do
          nil -> raise PhoenixBlog.NotFound, "no published post with slug #{inspect(slug)}"
          post -> post
        end
      end

      @doc "The `n` most recent published posts (default 5)."
      def recent(n \\ 5), do: Enum.take(published(), n)

      @doc "Unique, sorted tags across published posts."
      def all_tags do
        published()
        |> Enum.flat_map(& &1.tags)
        |> Enum.uniq()
        |> Enum.sort()
      end

      @doc "Published posts carrying `tag`."
      def by_tag(tag), do: Enum.filter(published(), &(tag in &1.tags))
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
