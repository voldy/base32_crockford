defmodule Base32Crockford.Mixfile do
  use Mix.Project

  @version "0.2.0"

  def project do
    [app: :base32_crockford,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     description: description(),

     name: "Base32-Crockford",
     source_url: "https://githubcom/voldy/base32_crockford",
     docs: docs()
    ]
  end

  def application do
    []
  end

  defp deps do
    [{:ex_doc, "~> 0.18.3", only: :dev, runtime: false}]
  end

  defp description do
    """
    An Elixir Implementation of Douglas Crockford's Base32 Encoding
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "LICENSE", "README.md", "CHANGELOG.md"],
      maintainers: ["Vladimir Zhukov"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/voldy/base32_crockford"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: "https://githubcom/voldy/base32_crockford",
    ]
  end
end
