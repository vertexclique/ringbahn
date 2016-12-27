defmodule Ringbahn.Deserializer do
  @moduledoc """
  Provides deserialization interface like mongrel2 for zmq.
  Includes parsing methodology of data coming from response sockets.
  """

  @typedoc """
  Body response parsed as tuple.
  """
  @type body_tuple :: {integer, List.t, String.t}

  @typedoc """
  Response tuple which will be pushed to response socket.
  """
  @type response_tuple :: {Atom.t, {String.t, integer, body_tuple}}

  @doc ~S"""
  Checks HTTP body exists in incoming data from handlers.

  ## Examples

      iex> Ringbahn.Deserializer.body_check("f983c23e-9058-4c9c-8cec-7f9f9a34c9ab-0 1:1, ")
      false

      iex> Ringbahn.Deserializer.body_check("f983c23e-9058-4c9c-8cec-7f9f9a34c9ab-0 1:1, HTTP/1.1 200 OK")
      true

  """
  @spec body_check(String.t) :: boolean
  def body_check(data) do
    (data |> parse_sender |> List.last) != ""
  end

  @doc """
  Parses serialized response data for replying the connection.
  """
  @spec deserialize(String.t) :: response_tuple
  def deserialize(data) do
    data
    |> parse_sender
    |> parse_response
  end

  @spec parse_sender(String.t) :: List.t
  defp parse_sender(data) do
    String.split(data, ", ", parts: 2)
  end

  @spec parse_response(List.t) :: response_tuple
  defp parse_response(sender_and_body) do
    [sender, body] = sender_and_body
    [sender, ident_netstring] = String.split(sender, " ")
    {[string_ident], _} = Netstrings.decode(ident_netstring <> ",")
    {ident, _} = Integer.parse string_ident

    {:ok, {sender, ident, parse_body(body)}}
  end

  @spec parse_body(String.t) :: body_tuple
  defp parse_body(raw_body) do
    splitted_body = raw_body |> String.split("\r\n", trim: true)

    # Get response code
    [_, code | _] = String.split(List.first(splitted_body), " ")
    {code, _} = Integer.parse code

    # Get response headers
    [_ | tail] = Enum.reverse splitted_body
    [_ | response_headers] = Enum.reverse tail

    response_headers = Enum.map response_headers, fn (header) ->
      [key, value] = String.split(header, ": ")
      key = String.downcase(key)
      {key, value}
    end

    {code, response_headers, List.last(splitted_body)}
  end
end
