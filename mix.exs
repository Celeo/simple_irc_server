defmodule IRC.MixProject do
  use Mix.Project

  def project do
    [
      app: :irc,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {IRC.Application, []}
    ]
  end

  defp deps do
    [
      {:enum_type, "~> 1.1"}
    ]
  end
end
