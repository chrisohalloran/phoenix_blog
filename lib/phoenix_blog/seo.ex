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
    title = Keyword.get(opts, :title, "Blog")
    url = "#{base}#{base_path}/#{post.id}"
    image = absolute(base, post.cover_image)
    desc = post.description || ""

    %{
      title: post.title,
      description: desc,
      canonical: url,
      robots: if(post.noindex, do: "noindex,follow", else: "index,follow"),
      og_type: "article",
      og_title: post.title,
      og_description: desc,
      og_image: image,
      twitter_card: if(image, do: "summary_large_image", else: "summary"),
      twitter_title: post.title,
      twitter_description: desc,
      twitter_image: image,
      schema: [
        article_schema(post, url, image, opts),
        breadcrumb_schema([{title, "#{base}#{base_path}"}, {post.title, url}])
      ]
    }
  end

  @doc "seo_meta map for the blog index page."
  def index_meta(opts \\ []) do
    base = Keyword.get(opts, :canonical_base, "")
    base_path = Keyword.get(opts, :base_path, "/blog")
    title = Keyword.get(opts, :title, "Blog")
    desc = Keyword.get(opts, :description, "")
    url = "#{base}#{base_path}"

    %{
      title: title,
      description: desc,
      canonical: url,
      robots: "index,follow",
      og_type: "website",
      og_title: title,
      og_description: desc,
      twitter_card: "summary",
      twitter_title: title,
      twitter_description: desc,
      schema: [
        collection_schema(title, desc, url, opts),
        breadcrumb_schema([{title, url}])
      ]
    }
  end

  @doc "seo_meta map for a tag facet page (/blog/tag/:tag)."
  def tag_meta(tag, opts \\ []) do
    base = Keyword.get(opts, :canonical_base, "")
    base_path = Keyword.get(opts, :base_path, "/blog")
    blog_title = Keyword.get(opts, :title, "Blog")
    url = "#{base}#{base_path}/tag/#{URI.encode(tag, &URI.char_unreserved?/1)}"
    title = "Posts tagged: #{tag}"

    %{
      title: title,
      description: "",
      canonical: url,
      robots: "index,follow",
      og_type: "website",
      og_title: title,
      og_description: "",
      twitter_card: "summary",
      twitter_title: title,
      twitter_description: "",
      schema: [
        collection_schema(title, "", url, opts),
        breadcrumb_schema([{blog_title, "#{base}#{base_path}"}, {title, url}])
      ]
    }
  end

  defp article_schema(post, url, image, opts) do
    %{
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => post.title,
      "description" => post.description || "",
      "datePublished" => Date.to_iso8601(post.date),
      "dateModified" => Date.to_iso8601(post.updated || post.date),
      "author" => %{"@type" => "Person", "name" => post.author},
      "mainEntityOfPage" => %{"@type" => "WebPage", "@id" => url},
      "url" => url
    }
    |> maybe_put("image", image)
    |> maybe_put("publisher", publisher_node(opts))
  end

  defp collection_schema(title, desc, url, opts) do
    %{
      "@context" => "https://schema.org",
      "@type" => "CollectionPage",
      "name" => title,
      "url" => url
    }
    |> maybe_put("description", blank_to_nil(desc))
    |> maybe_put("publisher", publisher_node(opts))
  end

  defp breadcrumb_schema(items) do
    %{
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" =>
        items
        |> Enum.with_index(1)
        |> Enum.map(fn {{name, item}, position} ->
          %{"@type" => "ListItem", "position" => position, "name" => name, "item" => item}
        end)
    }
  end

  # An Organization publisher node from host config, or nil when unset.
  defp publisher_node(opts) do
    case Keyword.get(opts, :publisher) do
      name when is_binary(name) and name != "" ->
        %{"@type" => "Organization", "name" => name}
        |> maybe_put("logo", logo_node(Keyword.get(opts, :canonical_base, ""), Keyword.get(opts, :publisher_logo)))

      _ ->
        nil
    end
  end

  defp logo_node(_base, nil), do: nil
  defp logo_node(base, path), do: %{"@type" => "ImageObject", "url" => absolute(base, path)}

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

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
    {json_ld_tags(@seo_meta[:schema])}
    """
  end

  # HEEx renders `<script>` bodies verbatim and does NOT evaluate `{...}` inside
  # them, so the JSON-LD must be built as a raw string and interpolated outside a
  # literal script tag. Each schema is html-safe escaped so it cannot break out.
  defp json_ld_tags(nil), do: Phoenix.HTML.raw("")

  defp json_ld_tags(schemas) do
    schemas
    |> Enum.map_join("\n", fn schema ->
      ~s|<script type="application/ld+json">| <>
        Jason.encode!(schema, escape: :html_safe) <> "</script>"
    end)
    |> Phoenix.HTML.raw()
  end
end
