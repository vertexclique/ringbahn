defmodule Ringbahn.ZMQ do
  @moduledoc """
  Contains ZMQ socket management interface and socket pairs.

  Parses route data and creates sockets and updates the
  ETS table registry with socket pids which will be used
  for later with connection matching in `Ringbahn.Server`.
  """

  use GenServer
  require Logger

  alias Ringbahn.AppLogger

  def start_link(config) do
    socket_data =
      config
      |> routes_data
      |> create_socket_pairs

    initial_state = %{
      config: config,
      route_registry: String.to_atom("route_registry_#{config["server"]["index"]}"),
      socket_data: socket_data
    }

    worker_index = config["server"]["index"]

    registry_id = String.to_atom("route_registry_#{worker_index}")
    Ringbahn.RouteRegistry.set_routes registry_id, socket_data

    worker_name = String.to_atom("Ringbahn.ZMQ" <> Integer.to_string worker_index)
    result = {:ok, _pid} = Agent.start_link fn -> initial_state end, name: via_server_tuple(worker_name)

    result
  end

  def routes_data(config) do
    server = config["server"]
    default_host = server["default_host"]
    server["hosts"][default_host]
  end

  defp create_socket_pairs(routes_data) do
    Enum.map routes_data, fn (route) ->
      send_ident = route["send_ident"] <> "_" <> route["route"] <> "_send"
      recv_ident = route["recv_ident"] <> "_" <> route["route"] <> "_recv"

      send_socket = bind_push_socket(route["send_spec"], send_ident, route["send_port"])
      receive_socket = bind_sub_socket(route["recv_spec"], recv_ident, route["recv_port"], route["recv_ident"])
      %{
        route: route["route"],
        send_socket: send_socket,
        receive_socket: receive_socket,
        send_ident: route["send_ident"],
        recv_ident: route["recv_ident"]
      }
    end
  end

  def bind_push_socket(host, identity, port) do
    {:ok, socket} = :chumak.socket(:push, to_charlist identity)
    case :chumak.bind(socket, :tcp, to_charlist(host), port) do
      {:ok, _pid} ->
        {:ok, socket, {host, port}}
      {:error, :eaddrinuse} ->
        "ZMQ PUSH port #{port} is in use." |> AppLogger.fatal |> exit
    end
  end

  def bind_sub_socket(host, identity, port, topic_name) do
    {:ok, socket} = :chumak.socket(:sub, to_charlist identity)
    :ok = :chumak.subscribe(socket, topic_name)
    case :chumak.bind(socket, :tcp, to_charlist(host), port) do
      {:ok, _pid} ->
        {:ok, socket, {host, port}}
      {:error, :eaddrinuse} ->
        "ZMQ SUB port #{port} is in use." |> AppLogger.fatal |> exit
    end
  end

  @compile {:nowarn_unused_function, [lookup_pid: 1]}

  # Registry calls
  def lookup_pid(zeromq_server_name) do
    :gproc.lookup_pid({:n, :l, {:zeromq_namespace, zeromq_server_name}})
  end

  defp via_server_tuple(zeromq_server_name) do
    {:via, :gproc, {:n, :l, {:zeromq_namespace, zeromq_server_name}}}
  end
end
