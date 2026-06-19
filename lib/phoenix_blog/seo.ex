defmodule PhoenixBlog.SEO do
  @moduledoc """
  Builds the `:seo_meta` map the host root layout already consumes.

  The pSEO template family roots render title, description, robots, Open Graph,
  Twitter, canonical, and JSON-LD `:schema` from an `assigns[:seo_meta]` map. The
  blog controller assigns that map, so blog pages get full, on-brand SEO with **no
  root-layout edits**. Note the host root defaults `robots` to `noindex,follow`;
  blog pages set `index,follow` so they are actually indexed.

  For a host without that convention (e.g. a non-template app), `head/1` renders
  the same map and is used by the fallback `PhoenixBlog.Layouts` root.
  """
  use Phoenix.Component

  @doc "seo_meta map for a single post."
  def post_meta(post, opts \\ []) do
    base = Keyword.get(opts, :canonical_base, "")
    base_path = Keyword.get(opts, :base_path, "/blog")
    url = "#{base}#{base_path}/#{post.id}"
    image = absolute(base, post.cover_image)
    desc = post.description || ""

    %{
      title: post.title,
      description: desc,
      canonical: url,
      robots: "index,follow",
      og_type: "article",
      og_title: post.title,
      og_description: desc,
      og_image: image,
      twitter_card: if(image, do: "summary_large_image", else: "summary"),
      twitter_title: post.title,
      twitter_description: desc,
      twitter_image: image,
      schema: [article_schema(post, url, image)]
    }
  end

  @doc "seo_meta map for the blog index page."
  def index_meta(opts \\ []) do
    base = Keyword.get(opts, :canonical_base, "")
    base_path = Keyword.get(opts, :base_path, "/blog")
    title = Keyword.get(opts, :title, "Blog")
    desc = Keyword.get(opts, :description, "")

    %{
      title: title,
      description: desc,
      canonical: "#{base}#{base_path}",
      robots: "index,follow",
      og_type: "website",
      og_title: title,
      og_description: desc,
      twitter_card: "summary",
      twitter_title: title,
      twitter_description: desc,
      schema: []
    }
  end

  defp article_schema(post, url, image) do
    %{
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => post.title,
      "description" => post.description || "",
      "datePublished" => Date.to_iso8601(post.date),
      "author" => %{"@type" => "Person", "name" => post.author},
      "url" => url
    }
    |> maybe_put("image", image)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp absolute(_base, nil), do: nil
  defp absolute(_base, "http" <> _ = url), do: url
  defp absolute(base, path), do: "#{base}#{path}"

  @doc """
  Renders a `:seo_meta` map into head tags. Only used by the fallback
  `PhoenixBlog.Layouts` root; template-family hosts render `:seo_meta` themselves.
  """
  attr(:seo_meta, :map, required: true)

  def head(assigns) do
    ~H"""
    <title>{@seo_meta[:title]}</title>
    <meta :if={@seo_meta[:description]} name="description" content={@seo_meta[:description]} />
    <meta name="robots" content={@seo_meta[:robots] || "index,follow"} />
    <link :if={@seo_meta[:canonical]} rel="canonical" href={@seo_meta[:canonical]} />
    <meta property="og:type" content={@seo_meta[:og_type] || "article"} />
    <meta property="og:title" content={@seo_meta[:og_title] || @seo_meta[:title]} />
    <meta
      :if={@seo_meta[:og_description]}
      property="og:description"
      content={@seo_meta[:og_description]}
    />
    <meta :if={@seo_meta[:canonical]} property="og:url" content={@seo_meta[:canonical]} />
    <meta :if={@seo_meta[:og_image]} property="og:image" content={@seo_meta[:og_image]} />
    <meta name="twitter:card" content={@seo_meta[:twitter_card] || "summary"} />
    <meta name="twitter:title" content={@seo_meta[:twitter_title] || @seo_meta[:title]} />
    <script :for={schema <- @seo_meta[:schema] || []} type="application/ld+json">
      {Phoenix.HTML.raw(Jason.encode!(schema, escape: :html_safe))}
    </script>
    """
  end
end
