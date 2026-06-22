defmodule PhoenixBlog.HTML do
  @moduledoc """
  Default index and article components for the blog.

  These render blog *content* only - no `<html>`/`<head>`/`<body>`, no site nav.
  The host site's root and app layouts provide the chrome (see
  `PhoenixBlog.Controller`), so each site's blog inherits that site's look. The
  Tailwind utility classes here lean on neutral tokens that fit most sites; a
  site that wants something bespoke can render its own templates instead.

  Links are built from `:base_path` as plain strings, so these components do not
  depend on any host router or verified routes.
  """
  use Phoenix.Component

  attr(:posts, :list, required: true, doc: "published posts to list")
  attr(:tags, :list, default: [], doc: "all tags, for the filter strip")
  attr(:base_path, :string, default: "/blog", doc: "mount path of the blog")
  attr(:heading, :string, default: "Blog", doc: "on-page H1 for the index")
  attr(:intro, :string, default: nil, doc: "optional one-line positioning intro")

  attr(:cta, :map,
    default: nil,
    doc: "optional call to action shown when the index is empty: %{heading, sub, label, href}"
  )

  def index(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl px-4 py-12">
      <h1 class="text-3xl font-semibold tracking-tight">{@heading}</h1>
      <p :if={present?(@intro)} class="mt-3 text-lg text-gray-600">{@intro}</p>

      <div :if={@tags != []} class="mt-4 flex flex-wrap items-center gap-2">
        <span class="text-sm font-medium text-gray-500">Topics:</span>
        <a
          :for={tag <- @tags}
          href={tag_path(@base_path, tag)}
          class="rounded-full bg-gray-100 px-3 py-1 text-sm text-gray-600 hover:bg-gray-200"
        >
          {tag}
        </a>
      </div>

      <.cta_block :if={@posts == []} cta={@cta} class="mt-10" />
      <p :if={@posts == [] && not cta_ready?(@cta)} class="mt-10 text-gray-500">
        New articles are on the way.
      </p>

      <ul :if={@posts != []} class="mt-10 space-y-10">
        <li :for={post <- @posts}>
          <article>
            <p class="text-sm text-gray-500">{format_date(post.date)}</p>
            <h2 class="mt-1 text-xl font-medium">
              <a href={post_path(@base_path, post)} class="hover:underline">{post.title}</a>
            </h2>
            <p :if={post.description} class="mt-2 text-gray-600">{post.description}</p>
            <div :if={post.tags != []} class="mt-3 flex flex-wrap gap-2">
              <span :for={tag <- post.tags} class="text-xs text-gray-400">#{tag}</span>
            </div>
          </article>
        </li>
      </ul>
    </div>
    """
  end

  attr(:post, :map, required: true, doc: "a PhoenixBlog.Post")
  attr(:base_path, :string, default: "/blog", doc: "mount path of the blog")

  attr(:cta, :map,
    default: nil,
    doc: "optional end-of-post call to action: %{heading, sub, label, href}"
  )

  attr(:related, :list, default: [], doc: "related posts to surface below the article")

  def show(assigns) do
    ~H"""
    <article class="mx-auto max-w-2xl px-4 py-12">
      <a href={@base_path} class="text-sm text-gray-500 hover:underline">&larr; All articles</a>

      <header class="mt-6">
        <h1 class="text-3xl font-semibold tracking-tight">{@post.title}</h1>
        <p class="mt-2 text-sm text-gray-500">
          {format_date(@post.date)} &middot; <.author_byline post={@post} />
        </p>
        <div :if={@post.tags != []} class="mt-3 flex flex-wrap gap-2">
          <a
            :for={tag <- @post.tags}
            href={tag_path(@base_path, tag)}
            class="rounded-full bg-gray-100 px-3 py-1 text-xs text-gray-600 hover:bg-gray-200"
          >
            {tag}
          </a>
        </div>
      </header>

      <div class="prose prose-gray prose-lg mt-8">{Phoenix.HTML.raw(@post.body)}</div>

      <.cta_block cta={@cta} class="mt-12" />

      <aside :if={@post.author_role || @post.author_url} class="mt-12 border-t border-gray-200 pt-6">
        <p class="text-sm font-semibold text-gray-900">
          {@post.author}<span :if={@post.author_role} class="font-normal text-gray-500">, {@post.author_role}</span>
        </p>
        <a
          :if={@post.author_url}
          href={@post.author_url}
          class="mt-1 inline-block text-sm text-gray-600 hover:underline"
        >
          More from {@post.author} &rarr;
        </a>
      </aside>

      <section :if={@related != []} class="mt-12 border-t border-gray-200 pt-6">
        <h2 class="text-sm font-semibold uppercase tracking-wide text-gray-500">Keep reading</h2>
        <ul class="mt-4 space-y-4">
          <li :for={rel <- @related}>
            <a href={post_path(@base_path, rel)} class="font-medium text-gray-900 hover:underline">
              {rel.title}
            </a>
            <p :if={rel.description} class="text-sm text-gray-600">{rel.description}</p>
          </li>
        </ul>
      </section>
    </article>
    """
  end

  attr(:cta, :map, default: nil)
  attr(:class, :string, default: "mt-12")

  # The end-of-post / empty-index call to action. Renders only when the config
  # carries a usable href AND label, so a missing or mis-keyed :cta never ships
  # a dead, label-less button.
  defp cta_block(assigns) do
    ~H"""
    <div
      :if={cta_ready?(@cta)}
      data-phoenix-blog-cta
      class={"rounded-2xl border border-gray-200 bg-gray-50 p-6 #{@class}"}
    >
      <p :if={present?(@cta[:heading])} class="text-lg font-semibold text-gray-900">{@cta[:heading]}</p>
      <p :if={present?(@cta[:sub])} class="mt-1 text-gray-600">{@cta[:sub]}</p>
      <a
        href={@cta[:href]}
        class="mt-4 inline-block rounded-full bg-gray-900 px-5 py-2.5 text-sm font-medium text-white hover:bg-gray-700"
      >
        {@cta[:label]}
      </a>
    </div>
    """
  end

  attr(:post, :map, required: true)

  # Author name (linked when author_url is set) plus an optional role.
  defp author_byline(assigns) do
    ~H"""
    <a
      :if={@post.author_url}
      href={@post.author_url}
      class="hover:underline"
    >{@post.author}</a><span :if={is_nil(@post.author_url)}>{@post.author}</span><span :if={present?(@post.author_role)}>, {@post.author_role}</span>
    """
  end

  defp cta_ready?(nil), do: false
  defp cta_ready?(cta), do: present?(cta[:href]) and present?(cta[:label])

  defp present?(value) when is_binary(value), do: value != ""
  defp present?(_), do: false

  defp post_path(base_path, post), do: "#{base_path}/#{post.id}"

  # Encode the tag as a single path segment: percent-encode everything that is
  # not unreserved, so reserved chars (/, ?, #) cannot split the segment or
  # break the route. Plug URI-decodes the segment back on the way in.
  defp tag_path(base_path, tag), do: "#{base_path}/tag/#{URI.encode(tag, &URI.char_unreserved?/1)}"

  defp format_date(%Date{} = date),
    do: "#{date.day} #{Calendar.strftime(date, "%B")} #{date.year}"
end
