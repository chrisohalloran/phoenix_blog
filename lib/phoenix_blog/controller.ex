defmodule PhoenixBlog.Controller do
  @moduledoc """
  Serves the blog index and post pages.

  Reads its config from the route's `private` data (set by
  `PhoenixBlog.Router.blog_routes/2`) with a fallback to `config :phoenix_blog`.
  Renders the `PhoenixBlog.HTML` components inside the host site's **root**
  layout, and assigns `:seo_meta` (consumed by the host root) and `:page_title`.

  A missing post raises `PhoenixBlog.NotFound` (`plug_status: 404`), so Phoenix
  renders the host's 404 page.
  """
  use Phoenix.Controller, formats: [:html]

  import Plug.Conn

  alias PhoenixBlog.SEO

  def index(conn, _params) do
    content = fetch_config!(conn, :content)
    base_path = config(conn, :base_path, "/blog")
    title = config(conn, :title, "Blog")

    seo =
      SEO.index_meta(
        canonical_base: config(conn, :canonical_base, ""),
        base_path: base_path,
        title: title,
        description: config(conn, :description, "")
      )

    conn
    |> apply_root_layout()
    |> put_view(html: PhoenixBlog.HTML)
    |> assign(:posts, content.published())
    |> assign(:tags, content.all_tags())
    |> assign(:base_path, base_path)
    |> assign_seo(seo, title)
    |> render(:index)
  end

  def show(conn, %{"slug" => slug}) do
    content = fetch_config!(conn, :content)
    base_path = config(conn, :base_path, "/blog")
    # raises PhoenixBlog.NotFound (plug_status 404) when absent or unpublished
    post = content.get_by_slug!(slug)

    seo =
      SEO.post_meta(post,
        canonical_base: config(conn, :canonical_base, ""),
        base_path: base_path
      )

    conn
    |> apply_root_layout()
    |> put_view(html: PhoenixBlog.HTML)
    |> assign(:post, post)
    |> assign(:base_path, base_path)
    |> assign_seo(seo, post.title)
    |> render(:show)
  end

  # Assign SEO under both conventions so the blog works on any host root:
  # the structured :seo_meta map (template-family roots) AND the common
  # individual assigns (:page_title, :canonical_url, :meta_description,
  # :og_image) that other roots read. Harmless to a root that ignores either.
  defp assign_seo(conn, seo, page_title) do
    conn
    |> assign(:seo_meta, seo)
    |> assign(:page_title, page_title)
    |> assign(:canonical_url, seo[:canonical])
    |> assign(:meta_description, seo[:description])
    |> assign(:og_image, seo[:og_image])
  end

  # The host :app layout is slot-based (incompatible with put_layout), so we set
  # only the root layout and let PhoenixBlog.HTML own its content container.
  defp apply_root_layout(conn) do
    root =
      case config(conn, :web_module) do
        nil -> {PhoenixBlog.Layouts, :root}
        web -> {Module.concat(web, Layouts), :root}
      end

    conn
    |> put_root_layout(html: root)
    |> put_layout(html: false)
  end

  defp config(conn, key, default \\ nil) do
    route_opts = conn.private[:phoenix_blog] || []

    case Keyword.fetch(route_opts, key) do
      {:ok, value} -> value
      :error -> Application.get_env(:phoenix_blog, key, default)
    end
  end

  defp fetch_config!(conn, key) do
    config(conn, key) ||
      raise "phoenix_blog: missing required config #{inspect(key)}; set it in blog_routes opts or under config :phoenix_blog"
  end
end
