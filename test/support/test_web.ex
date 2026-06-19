# Minimal Phoenix host used to integration-test the controller + router macro.
# Mirrors how a template-family site consumes :seo_meta and {@inner_content}.

defmodule PhoenixBlog.Test.Web do
  @moduledoc false
end

defmodule PhoenixBlog.Test.Web.Layouts do
  @moduledoc false
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <title>{assigns[:seo_meta][:title] || assigns[:page_title] || "Test Site"}</title>
        <meta :if={assigns[:seo_meta][:robots]} name="robots" content={@seo_meta[:robots]} />
        <link :if={assigns[:seo_meta][:canonical]} rel="canonical" href={@seo_meta[:canonical]} />
        <meta :if={assigns[:seo_meta][:og_type]} property="og:type" content={@seo_meta[:og_type]} />
        <script
          :for={schema <- assigns[:seo_meta][:schema] || []}
          type="application/ld+json"
        >
          {Phoenix.HTML.raw(Jason.encode!(schema))}
        </script>
      </head>
      <body>
        <header>TEST-CHROME</header>
        {@inner_content}
      </body>
    </html>
    """
  end
end

defmodule PhoenixBlog.Test.ErrorHTML do
  @moduledoc false
  # Minimal error view so the endpoint can render 404/500 (real sites ship their own).
  def render(template, _assigns), do: Phoenix.Controller.status_message_from_template(template)
end

defmodule PhoenixBlog.Test.CatchAllController do
  @moduledoc false
  use Phoenix.Controller, formats: [:html]

  def show(conn, params) do
    text(conn, "CATCHALL:" <> Enum.join(params["path"] || [], "/"))
  end
end

defmodule PhoenixBlog.Test.Router do
  @moduledoc false
  use Phoenix.Router

  import PhoenixBlog.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/" do
    pipe_through(:browser)

    blog_routes("/blog",
      content: PhoenixBlog.Test.FixtureBlog,
      web_module: PhoenixBlog.Test.Web,
      canonical_base: "https://test.example",
      title: "Test Blog"
    )

    # Deliberately AFTER blog_routes, to prove the catch-all does not swallow /blog.
    get("/*path", PhoenixBlog.Test.CatchAllController, :show)
  end
end

defmodule PhoenixBlog.Test.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :phoenix_blog

  plug(PhoenixBlog.Test.Router)
end
