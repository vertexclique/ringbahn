defmodule Ringbahn.Mixfile do
  use Mix.Project

  def project do
    [app: :ringbahn,
     version: "0.1.0",
     elixir: "~> 1.3",
     description: description(),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     test_coverage: [tool: ExCoveralls],
     escript: escript(),
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.html": :test],

     # Documentation related
     name: "Ringbahn",
     source_url: "https://github.com/vertexclique/ringbahn",
     homepage_url: "https://vertexclique.github.io/ringbahn/",
     docs: [main: "Ringbahn",
            logo: "config/ringbahn.png",
            extras: ["README.md"]]
    ]
  end

  defp description do
    """
    High performance multiple backend web server
    """
  end

  defp escript do
    [
      main_module: Ringbahn.CLI,
      app: nil,
      applications: [:logger, :bunt, :gproc, :cachex, :plug, :chumak, :cowboy, :retry],
      included_applications: [:logger, :bunt, :gproc, :cachex, :plug, :chumak, :cowboy, :retry],
      embed_elixir: true,
      language: :elixir
    ]
  end

  defp package do
    [
      licenses: ["GNU AGPLv3"],
      maintainers: ["Mahmut Bulut"],
      links: %{"GitHub" => "https://github.com/vertexclique/ringbahn",
               "Docs" => "https://vertexclique.github.io/ringbahn/"}
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      mod: {Ringbahn, []},
      applications: [:logger, :bunt, :gproc, :cachex, :plug, :chumak, :cowboy, :retry]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:gproc, "~> 0.6.1"},
      {:cowboy, "~> 1.0.4"},
      {:plug, "~> 1.3.0"},
      {:poison, "~> 3.0"},
      {:cachex, "~> 2.0"},
      {:retry, "~> 0.6.0"},
      {:netstrings, "~> 2.0"},
      {:uuid, "~> 1.1"},
      {:bunt, "~> 0.1.0"},
      {:goldrush, "~> 0.1.8"},
      {:lager, "~> 3.2"},
      {:chumak, "~> 1.1"},

      # Dev and test dependencies
      {:ex_doc, "~> 0.14", only: :dev},
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.5", only: :test},
      {:httpoison, "~> 0.10.0", only: :test},
      {:mock, "~> 0.2.0", only: :test}
    ]
  end
end
