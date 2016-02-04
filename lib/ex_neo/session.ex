defmodule ExNeo.Session do
  @moduledoc """
  Defines the structure that holds the relevant data for 
  interacting with a Neo4j rest server.
  """
  defstruct url: "", commit_url: "", transaction_url: ""

  defp commit_url(url),      do: Path.join(url, "/db/data/transaction/commit")
  defp transaction_url(url), do: Path.join(url, "/db/data/transaction/")

  def create(url \\ nil)
  def create(nil) do
    url = Application.get_env(:ex_neo, :url, "http://localhost:7474/")
    create(url)
  end
  def create(url) do
    %ExNeo.Session{
      url: url,
      commit_url: commit_url(url),
      transaction_url: transaction_url(url)
    }
  end

end

