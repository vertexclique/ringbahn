defmodule Ringbahn.Server do
  @moduledoc """
  Launches the cowboy server and passes the routes to it
  Ranch pool will pass the connection from genserver tcp to plug.conn
  and it will spawn a process and handle the conn.
  """

  import Plug.Conn
  require Logger

  alias Ringbahn.Serializer
  alias Ringbahn.Deserializer

  use Retry

  def init(options \\ []) do
    routes = get_routes(hd options)
    options ++ %{routes: routes}
  end

  def call(conn, opts) do
    [config | rest] = opts

    routes = rest.routes
    if Enum.member?(routes, conn.request_path) do
      {send_pid, recv_pid, route_data} = get_zmq_socket_pid_with_registry(config, conn.request_path)

      {:ok, req_body, _} = fetch_query_params(conn, opts) |> read_body


      :ok = send_socket(send_pid, conn, req_body, route_data)
      {:ok, {
          _,        # Ignore socket sender
          _,        # Ignore socket ident
          {response_code, response_headers, response_body}
       }
      } = receive_socket(recv_pid)

      conn
      |> merge_resp_headers(response_headers)
      |> send_resp(response_code, response_body)
      |> halt
    else
      conn
      |> send_resp(404, "Not Found")
      |> halt
    end
  end

  # Private calls

  defp get_zmq_socket_pid_with_registry(config, route) do
    server_index = Integer.to_string config["server"]["index"]
    route_data = Ringbahn.RouteRegistry.get_route(String.to_atom("route_registry_" <> server_index), route)
    {:ok, zmq_recv_socket, _} = route_data.receive_socket
    {:ok, zmq_send_socket, _} = route_data.send_socket
    {zmq_send_socket, zmq_recv_socket, route_data}
  end

  defp send_socket(socket_pid, conn, body, route_data) do
    serialized_request = Serializer.serialize(conn, body, route_data)
    case :chumak.send(socket_pid, serialized_request) do
      :ok -> :ok
      {:error, :no_connected_peers} ->
        send_socket(socket_pid, conn, body, route_data)
    end
  end

  defp receive_socket(socket_pid) do
    case :chumak.recv(socket_pid) do
      {:ok, data} ->
        if Deserializer.body_check(data) do
          Deserializer.deserialize(data)
        else
          # Server received malformed response skipping that
          # We are faster than backend probably...
          # Lazy pirating in here without closing the socket.
          # http://zguide.zeromq.org/page:all#Client-Side-Reliability-Lazy-Pirate-Pattern

          wait lin_backoff(1, 0) |> expiry(2) do
            receive_socket(socket_pid)
          end
        end
      {:error, :efsm} ->
        receive_socket(socket_pid)
    end
  end

  defp get_routes(config) do
    default_host = config["server"]["default_host"]
    Enum.map(config["server"]["hosts"][default_host], fn (x) -> x["route"] end)
  end
end
