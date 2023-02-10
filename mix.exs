defmodule Nostr.MixProject do
  use Mix.Project

  @version "0.1.3"

  def project do
    [
      app: :nostr,
      version: @version,
      description: "Connect to the nostr network with Elixir",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Nostr",
      source_url: "https://github.com/RooSoft/nostr",
      homepage_url: "https://github.com/RooSoft/nostr",
      package: package(),
      docs: docs()
    ]
  end

  def package do
    [
      maintainers: ["Marc Lacoursière"],
      licenses: ["UNLICENCE"],
      links: %{"GitHub" => "https://github.com/RooSoft/nostr"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: docs_extras(),
      assets: "/guides/assets",
      source_ref: @version,
      source_url: "https://github.com/RooSoft/nostr"
    ]
  end

  def docs_extras do
    [
      "README.md"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.29.1", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:hammox, "~> 0.7", only: :test},
      {:mint_web_socket, "~> 1.0"},
      {:nostr_basics, "~> 0.0.13"}
    ]
  end
end
