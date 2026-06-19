defmodule PhoenixBlog.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/chrisohalloran/phoenix_blog"

  def project do
    [
      app: :phoenix_blog,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "A reusable markdown blog engine for Phoenix sites, backed by NimblePublisher.",
      package: package(),
      name: "PhoenixBlog",
      source_url: @source_url,
      docs: [main: "PhoenixBlog", source_url: @source_url]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  # test/support holds the fixture host module + test endpoint/router (U3, U6).
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:nimble_publisher, "~> 2.0"},
      {:jason, "~> 1.4"},
      # Phoenix bits are optional: every host site already provides them, so we
      # avoid forcing a version. They are still fetched for this library's own
      # build + test run.
      {:phoenix, "~> 1.8", optional: true},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0", optional: true},
      {:floki, ">= 0.30.0", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib mix.exs README.md .formatter.exs)
    ]
  end
end
