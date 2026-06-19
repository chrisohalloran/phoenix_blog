defmodule PhoenixBlog.NotFound do
  @moduledoc """
  Raised when a published post cannot be found by slug.

  Carries `plug_status: 404`, so when it propagates out of a controller action
  Phoenix renders the host app's 404 page automatically (via `Plug.Exception`).
  """
  defexception [:message, plug_status: 404]
end
