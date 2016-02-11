defmodule ExNeo.Transaction do
  require Logger
  @moduledoc """
  """

  alias ExNeo.Transaction
  alias ExNeo.Session
  alias ExNeo.Response

  @headers %{"Accept" => "application/json; charset=UTF-8",
             "Content-Type" => "application/json"}

  defstruct commit_url: nil, expires: nil, execute_url: nil

  @doc """
  Begin the Neo4j transaction. Post zero or more statements to being the transation.
  All the relevant information is returned in an ExNeo.Transaction that allows
  the continuation of ths transaction.

  @param session The ExNeo session that points to a neo4j db.
  @param statement(s) The statement or statements to begin this transaction with.
  @return a tuple that is either {:ok, transation, results} or {:errors, errors}
  """
  @spec begin(ExNeo.Session.t, {String.t, map} | [{String.t, map}]) :: {atom, ExNeo.Transaction, [map]}
  def begin(session, statement \\ [])
  def begin(session, statement) when is_tuple(statement) do
    begin(session, [statement])
  end
  def begin(session, statements) when is_list(statements) do
    payload = Poison.encode! %{statements: ExNeo.statements_to_maps(statements)}
    Logger.debug("#{inspect payload}")
    %Session{transaction_url: url} = session
    case HTTPoison.post!(url, payload, @headers).body |> Poison.decode! do
      %{"errors" => [_|_] = errors} ->
        {:errors, errors}
      %{"results" => results, "commit" => commit_url,
          "transaction" => %{"expires" => expires}} ->
        [_, execute_url] = Regex.run(~r/(http\S+)\/commit\/?/, commit_url)
        transaction = %Transaction{
          commit_url: commit_url,
          execute_url: execute_url,
          expires: expires
        }
        {:ok, transaction, Enum.map(results, fn x -> Response.map_json(x) end)}
    end
  end

  @doc """
  Execute statements in this transaction.

  @param transaction The current transaction struct to execute on.
  @param statements List of statements to be executed.
  @return {:errors, errors} or {:ok, transaction, results}
    it returns a new transaction because the expiration of the transaction changes.
  """
  @spec execute(ExNeo.Transaction, [String.t]) ::
      {:errors, [String.t]} | {:ok, ExNeo.Transaction, [map]}
  def execute(%Transaction{execute_url: url} = transaction, statements)
      when is_list(statements) do
    payload = Poison.encode! %{statements: ExNeo.statements_to_maps(statements)}
    case HTTPoison.post!(url, payload, @headers).body |> Poison.decode! do
      %{"errors" => [_|_] = errors} ->
        {:errors, errors}
      %{"results" => results, "transaction" =>
          %{"expires" => expires}} ->
        transaction = %Transaction{transaction | expires: expires}
        {:ok, transaction, Enum.map(results, fn x -> Response.map_json(x) end)}
    end
  end

  @doc"""
  Commits a transaction. Currently does not accept statements.

  @param transaction The active transaction to be commited.
  @return {:errors, errors} or :ok if it could be committed.
  """
  @spec commit(ExNeo.Transaction) :: {:errors, [String.t]} | :ok
  def commit(%Transaction{commit_url: url}) do
    # Can easily change this to enable committing with statements.
    payload = Poison.encode! %{statements: []}
    case HTTPoison.post!(url, payload, @headers).body |> Poison.decode! do
      %{"errors" => [_|_]} = errors ->
        {:errors, errors}
      _ ->
        :ok
    end
  end

  @doc"""
  Rollback the transaction. The response from neo4j is always the same
  so the response is always a success.

  @param transaction The active transaction.
  @return :ok
  """
  def rollback(%Transaction{execute_url: url}) do
    HTTPoison.delete!(url, @headers)
    :ok
  end

end

