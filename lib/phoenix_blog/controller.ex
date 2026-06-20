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
        canonical_base: canonical_base(conn),
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
        canonical_base: canonical_base(conn),
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

  # Assign SEO under every convention the site family uses, so the blog renders
  # full SEO on any host root with no per-site edits: the structured :seo_meta
  # map (noosa/pseo) AND the union of individual assigns other roots read
  # (:page_title, :canonical_url, :meta_description, :og_*, :json_ld). Each is
  # harmless to a root that ignores it.
  defp assign_seo(conn, seo, page_title) do
    conn
    |> assign(:seo_meta, seo)
    |> assign(:page_title, page_title)
    |> assign(:canonical_url, seo[:canonical])
    |> assign(:meta_description, seo[:description])
    |> assign(:og_title, seo[:og_title])
    |> assign(:og_description, seo[:og_description])
    |> assign(:og_type, seo[:og_type])
    |> assign(:og_image, seo[:og_image])
    |> assign(:json_ld, encode_json_ld(seo[:schema]))
  end

  # Roots that read an individual :json_ld assign expect a raw JSON string.
  defp encode_json_ld([schema | _]), do: Jason.encode!(schema, escape: :html_safe)
  defp encode_json_ld(_), do: nil

  # The host :app layout is slot-based (incompatible with put_layout), so we set
  # only the root layout and let PhoenixBlog.HTML own its content container.
  defp apply_root_layout(conn) do
    root =
      case config(conn, :web_module) do
        nil -> {PhoenixBlog.Layouts, :root}
        web -> {Module.concat(web, Layouts), :root}
      end

    # Some sites keep chrome (nav/footer) in their root layout (noosa); others put
    # it in an app/public layout (ripasso). `:layout` opts into wrapping blog
    # content in that layout; default false renders into root only.
    conn
    |> put_root_layout(html: root)
    |> put_layout(html: config(conn, :layout, false))
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

  # Absolute origin for canonical/OG/sitemap URLs. Defaults to the host
  # endpoint's configured URL (PHX_HOST in prod), so forks of a starter template
  # get correct canonicals with no per-site config; override with :canonical_base.
  defp canonical_base(conn) do
    case config(conn, :canonical_base) do
      base when is_binary(base) and base != "" -> base
      _ -> Phoenix.Controller.endpoint_module(conn).url()
    end
  end
end
