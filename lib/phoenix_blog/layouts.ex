defmodule PhoenixBlog.Layouts do
  @moduledoc """
  Fallback root layout, used only when no `:web_module` is configured (a host
  without the template family's `Layouts.root`). Template-family sites use their
  own root layout, which already renders the `:seo_meta` map this assigns.
  """
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <PhoenixBlog.SEO.head :if={assigns[:seo_meta]} seo_meta={@seo_meta} />
      </head>
      <body>
        {@inner_content}
      </body>
    </html>
    """
  end
end
