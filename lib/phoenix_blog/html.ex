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

  def index(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl px-4 py-12">
      <h1 class="text-3xl font-semibold tracking-tight">Blog</h1>

      <div :if={@tags != []} class="mt-4 flex flex-wrap gap-2">
        <span
          :for={tag <- @tags}
          class="rounded-full bg-gray-100 px-3 py-1 text-sm text-gray-600"
        >
          {tag}
        </span>
      </div>

      <p :if={@posts == []} class="mt-10 text-gray-500">No posts yet. Check back soon.</p>

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

  def show(assigns) do
    ~H"""
    <article class="mx-auto max-w-2xl px-4 py-12">
      <a href={@base_path} class="text-sm text-gray-500 hover:underline">&larr; Back to blog</a>

      <header class="mt-6">
        <h1 class="text-3xl font-semibold tracking-tight">{@post.title}</h1>
        <p class="mt-2 text-sm text-gray-500">{format_date(@post.date)} &middot; {@post.author}</p>
        <div :if={@post.tags != []} class="mt-3 flex flex-wrap gap-2">
          <span
            :for={tag <- @post.tags}
            class="rounded-full bg-gray-100 px-3 py-1 text-xs text-gray-600"
          >
            {tag}
          </span>
        </div>
      </header>

      <div class="prose prose-gray mt-8 max-w-none">{Phoenix.HTML.raw(@post.body)}</div>
    </article>
    """
  end

  defp post_path(base_path, post), do: "#{base_path}/#{post.id}"

  defp format_date(%Date{} = date),
    do: "#{date.day} #{Calendar.strftime(date, "%B")} #{date.year}"
end
