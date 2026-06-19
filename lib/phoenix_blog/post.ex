defmodule PhoenixBlog.Post do
  @moduledoc """
  A single compiled blog post.

  NimblePublisher calls `build/3` once per markdown file at compile time, passing
  the filename, the parsed frontmatter map (atom keys), and the rendered HTML
  body. The filename carries the publish date and slug:

      priv/posts/2026-01-02-hello-world.md  ->  date 2026-01-02, id "hello-world"

  Frontmatter keys: `title` (required), `description`, `tags`, `author`,
  `draft`, `cover_image`.
  """

  @default_author "Staff"

  @enforce_keys [:id, :title, :date, :body]
  defstruct [
    :id,
    :title,
    :description,
    :date,
    :tags,
    :author,
    :body,
    :draft?,
    :cover_image
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          description: String.t() | nil,
          date: Date.t(),
          tags: [String.t()],
          author: String.t(),
          body: String.t(),
          draft?: boolean(),
          cover_image: String.t() | nil
        }

  @doc """
  Build a post from its filename, parsed frontmatter `attrs`, and rendered `body`.

  Raises `KeyError` when the required `:title` key is missing, and
  `ArgumentError` when the filename is not `YYYY-MM-DD-slug.md`.
  """
  @spec build(String.t(), map(), String.t()) :: t()
  def build(filename, attrs, body) do
    {date, slug} = parse_filename(filename)

    struct!(__MODULE__,
      id: slug,
      date: date,
      title: Map.fetch!(attrs, :title),
      description: Map.get(attrs, :description),
      tags: normalize_tags(Map.get(attrs, :tags, [])),
      author: Map.get(attrs, :author) || @default_author,
      draft?: Map.get(attrs, :draft, false) == true,
      cover_image: Map.get(attrs, :cover_image),
      body: body
    )
  end

  defp parse_filename(filename) do
    name = filename |> Path.basename() |> Path.rootname()

    case Regex.run(~r/^(\d{4})-(\d{2})-(\d{2})-(.+)$/, name) do
      [_, y, m, d, slug] ->
        {Date.from_iso8601!("#{y}-#{m}-#{d}"), slug}

      _ ->
        raise ArgumentError,
              "post filename must be YYYY-MM-DD-slug.md, got: #{Path.basename(filename)}"
    end
  end

  defp normalize_tags(nil), do: []
  defp normalize_tags(tags) when is_list(tags), do: Enum.map(tags, &to_string/1)
  defp normalize_tags(tag) when is_binary(tag), do: [tag]
  defp normalize_tags(other), do: [to_string(other)]
end
