defmodule Nostr.MixProject do
  use Mix.Project

  def project do
    [
      app: :nostr,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:dialyxir, "~> 1.2"},
      {:websockex, "~> 0.4.3"},
      {:jason, "~> 1.4"},
      {:k256, git: "https://github.com/davidarmstronglewis/k256.git"},
      {:binary, "~> 0.0.5"}
    ]
  end
end
