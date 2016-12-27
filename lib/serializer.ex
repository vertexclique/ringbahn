defmodule Ringbahn.Serializer do
  @moduledoc """
  Provides serialization interface like mongrel2 for zmq.
  Includes serialization strategy for data dispatch to sockets.
  """

  def serialize(conn, req_body, route_data, conn_id \\ Integer.to_string(Enum.random(1..1_000))) do
    args = [
      route_data.recv_ident,                    # SENDER
      conn_id,                                  # IDENT
      conn.request_path,                        # PATH
      request_headers(conn),                    # REQUEST HEADERS as Netstring
      request_body(req_body),                   # REQUEST BODY as Netstring
    ]

    Enum.join(args, " ")
  end

  # Serialize request body as netstring
  defp request_body(req_body) do
    req_body |> Netstrings.encode
  end

  # Get request header serialized as netstring
  def request_headers(conn) do
    (builtin_headers(conn) ++ conn.req_headers)
    |> create_kv_pair_string
    |> create_request_header_string
    |> Netstrings.encode
  end

  defp builtin_headers(conn) do
    {_, req} = conn.adapter

    [
      {"METHOD", conn.method},
      {"VERSION", version(req)},
      {"URI", uri(conn, req)},
      {"PATH", path(req)},
      {"QUERY", conn.query_string},
      {"PATTERN", conn.request_path <> "/"},
      {"URL_SCHEME", Atom.to_string(conn.scheme)},
      {"REMOTE_ADDR", conn.remote_ip |> Tuple.to_list |> Enum.join(".")}
    ]
  end

  # Header assembly for serialization
  defp create_kv_pair_string(headers) do
    Enum.map headers, fn (kv_pair) ->
      "\"#{elem(kv_pair, 0)}\":\"#{elem(kv_pair, 1)}\""
    end
  end

  # Serializes array of KV-pair strings
  defp create_request_header_string(kv_pair_array) do
    generated_headers = Enum.join(kv_pair_array, ",")
    "{#{generated_headers}}"
  end

  # Option fetchers

  defp path(req) do
    {path, _} = :cowboy_req.path(req)
    path
  end

  defp uri(conn, req) do
    {full_path, _} = :cowboy_req.url(req)
    full_path |> String.replace(conn.host <> ":" <> Integer.to_string(conn.port), "") |> String.replace(Atom.to_string(conn.scheme) <> "://", "")
  end

  defp version(req) do
    {version, _} = :cowboy_req.version(req)
    Atom.to_string(version)
  end
end
