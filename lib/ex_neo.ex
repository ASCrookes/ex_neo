defmodule ExNeo do
  @moduledoc """
  Defines the interface to interact with a neo4j rest server.
  """

  @headers %{"Accept" => "application/json; charset=UTF-8",
             "Content-Type" => "application/json"}

  alias ExNeo.Session
  alias ExNeo.Response

  @doc """
  Commits the statement to the rest server specified by the session.
  Will convert the response data to maps/lists.

  @param session: The session which contains the neo4j server info.
  @param statement: The statement to be sent to the neo4j server.
  @param params: The parameters needed to run the statement.

  @return: The response from the statement mapped from neo4j into
    elixir maps and lists.
  """
  @spec commit_statement(ExNeo.Session, String.t, map) :: any
  def commit_statement(session, statement, params \\ %{})
  def commit_statement(session, statement, params) do
    case commit_statements(session, [{statement, params}]) do
      {:ok, [response]} ->
        response
      {:error, errors} ->
        {:error, errors}
    end
  end


  @doc """
  Executes/commits all of the statements in one request.
  Returns an array or responses.

  @param session: The session which contains the neo4j server info.
  @param statements: A list of tuples such that the first element
    is the statement and the 2nd element are the params for that statement.

  @return: A list of responses from neo4j.
  """
  @spec commit_statements(ExNeo.Session, [{String.t, map}]) :: [any]
  def commit_statements(%Session{commit_url: url}, statements) do
    payload = Poison.encode! %{statements: statements_to_maps(statements)}
    case HTTPoison.post!(url, payload, @headers).body |> Poison.decode! do
      %{"errors"=> [_|_] = errors} ->
        {:errors, errors}
      %{"results" => results} ->
        {:ok, Enum.map(results, fn x -> Response.map_json(x) end)}
    end
  end

  defp statement_to_map(statement, params) do
    %{statement: statement, parameters: params}
  end

  defp statements_to_maps(statements) do
    Enum.map(statements, fn {statement, params} ->
      statement_to_map(statement, params)
    end)
  end
  
end

