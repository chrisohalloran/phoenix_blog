Application.put_env(:phoenix_blog, PhoenixBlog.Test.Endpoint,
  secret_key_base: String.duplicate("a", 64),
  url: [host: "localhost"],
  render_errors: [formats: [html: PhoenixBlog.Test.ErrorHTML], layout: false],
  server: false
)

{:ok, _} = PhoenixBlog.Test.Endpoint.start_link()

# Keep test output to real signal; the controller exercises Phoenix request logging.
Logger.configure(level: :warning)

ExUnit.start()
