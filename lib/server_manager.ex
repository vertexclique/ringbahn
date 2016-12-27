defmodule Ringbahn.ServerManager do
  @moduledoc """
  Server manager module as genserver that manages HTTP server
  """

  alias Ringbahn.AppLogger

  def start_link(config) do
    initial_state = %{
      config: config,
      route_registry: String.to_atom("route_registry_#{config["server"]["index"]}")
    }

    worker_name = String.to_atom("Ringbahn.ServerManager" <> Integer.to_string config["server"]["index"])
    result = {:ok, _pid} = Agent.start_link fn -> initial_state end, name: via_server_tuple(worker_name)

    config
    |> start_server
    |> define_routes

    result
  end

  defp start_server(config) do
    onresponse = fn(status, headers, body, request) ->
      new_headers = List.keyreplace(headers, "server", 0, {"server", "Ringbahn"})
      {:ok, request} = :cowboy_req.reply(status, new_headers, body, request);
      request
    end

    server = config["server"]
    port = server["port"]
    uuid = server["uuid"]
    retval = Plug.Adapters.Cowboy.http Ringbahn.Server, [config], port: port, ref: uuid, protocol_options: [onresponse: onresponse]
    case retval do
      {:ok, _} ->
        "Started server on port #{port}..." |> AppLogger.info
      {:error, {:already_started, _}} ->
        "Port #{port} is already serving!" |> AppLogger.error
    end

    config
  end

  @compile {:nowarn_unused_function, [lookup_pid: 1]}

  # Process registry calls
  def lookup_pid(server_manager_name) do
    :gproc.lookup_pid({:n, :l, {:server_manager_namespace, server_manager_name}})
  end

  defp via_server_tuple(server_manager_name) do
    {:via, :gproc, {:n, :l, {:server_manager_namespace, server_manager_name}}}
  end

  # Route registry calls
  defp define_routes(config) do
    server = config["server"]
    default_host = server["default_host"]
    routes_data = server["hosts"][default_host]
    worker_index = server["index"]
    registry_id = String.to_atom("route_registry_#{worker_index}")

    # Insert to ETS table to share data among matchers and supervisor
    Ringbahn.RouteRegistry.set_routes(registry_id, routes_data)
  end
end
