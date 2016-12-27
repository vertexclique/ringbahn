defmodule Ringbahn do
  @moduledoc """
  Main Supervision tree
  populates the worker structure and launches it.

  Every worker can contain multiple routes.
  Each `server` worker has their own unique `ref` and working under the same supervisor.
  Every `server` worker fires up Ringbahn.Server instance with different ports
  and every `server` has its own `route registry` worker which is basically managing an ETS table.
  Ports are dynamically generated with the `worker_count` in the config.
  Every `Ringbahn.Server` instance handles approx ~16500 simultaneous conns.
  From the concurrency point of view mongrel2 do not go even there...

  Example worker structure is like this:

  children = [
    worker(Cachex, [:route_registry_0],
    worker(Cachex, [:route_registry_1],

     ... more ETS table workers ...

    worker(Ringbahn.Server, [
          [:"/banner", [recv_ident: "blabla1", recv_port: 10371,
                        recv_spec: "tcp://127.0.0.1",
                        send_ident: "blabla1", send_port: 10370,
                        send_spec: "tcp://127.0.0.1", port: 4001]
            ...,
            ...,
          ], id: :server_uuid1),
     worker(Ringbahn.Server, [
           [:"/banner", [recv_ident: "blabla2", recv_port: 10371,
                         recv_spec: "tcp://127.0.0.1",
                         send_ident: "bblabla2", send_port: 10370,
                         send_spec: "tcp://127.0.0.1", port: 4002],
            ...,
            ...,
           ], id: :server_uuid2)
  ]
  """

  use Application

  alias Ringbahn.AppLogger

  def start(_type, cmd_args) do
    import Supervisor.Spec, warn: false

    # Argument parser takes part in
    children = cmd_args
    |> argument_parser
    |> configure_workers

    opts = [strategy: :one_for_one, name: Ringbahn.Supervisor, restart: :permanent]
    Supervisor.start_link(children, opts)
  end

  def argument_parser(args) do
    if args == [] or args[:config] == nil do
      # Show server banner
      {:ok, version} = :application.get_key(:ringbahn, :vsn)
      AppLogger.banner version

      "Switching to default server..."
      |> AppLogger.info
      %{raw_config: get_default_config}
    else
      {_, default_conf} = File.read args[:config]
      %{raw_config: default_conf}
    end
  end

  @spec get_default_config :: List.t
  defp get_default_config do
    Application.get_all_env(:ringbahn)[:server_config]
  end

  @spec configure_workers(Map.t) :: List.t
  defp configure_workers(config) do
    raw_config = config.raw_config

    config = try do
               Poison.Parser.parse!(raw_config)
             rescue
               e -> "Config is not valid... #{e}" |> AppLogger.error
             end

    worker_count = config["settings"]["worker_count"]
    port_offset = config["settings"]["port_offset"]

    # Server config assembly

    # Creates ETS table workers for routes, those are the permanent tables
    route_workers = Ringbahn.RouteRegistry.create_workers(worker_count)

    # Creates server/zeromq manager workers
    server_manager_workers = Enum.map 0..worker_count - 1, fn (worker_index) ->
      config
      |> scale_configuration(worker_index, port_offset)
      |> configure_backend
    end

    route_workers ++ List.flatten server_manager_workers
  end

  defp configure_backend(scaled_config) do
    import Supervisor.Spec, warn: false

    server_uuid = scaled_config["server"]["uuid"]

    case scaled_config["settings"]["backend"] do
      "ZMQ" ->
        zmq_uuid = server_uuid <> "_zmq"

        # Every zmq genserver should start after real server workers.
        [
          worker(Ringbahn.ServerManager, [scaled_config], [id: server_uuid, restart: :permanent]),
          worker(Ringbahn.ZMQ, [scaled_config], [id: zmq_uuid, restart: :permanent])
        ]
      "PROTOBUF" ->
        true
      nil ->
        "Backend protocol haven't specified." |> AppLogger.error |> exit
    end
  end

  def scale_configuration(config, worker_index, port_offset) do
    # Scale handler ports
    host_conf = for {hostname, host} <- config["server"]["hosts"], into: %{}, do: {
      hostname,
      Enum.map(host, fn(handler) ->
        %{handler |
          "send_port" => handler["send_port"] + (worker_index * port_offset),
          "send_ident" => handler["send_ident"] <> "-" <> Integer.to_string(worker_index),
          "recv_port" => handler["recv_port"] + (worker_index * port_offset),
          "recv_ident" => handler["recv_ident"] <> "-" <> Integer.to_string(worker_index)
         }
      end)
    }

    # Scale web endpoint ports and logs
    scaled_server_conf = Map.merge config["server"], %{
      "index" => worker_index,
      "access_log" => config["server"]["access_log"] <> Integer.to_string(worker_index),
      "error_log" => config["server"]["error_log"] <> Integer.to_string(worker_index),
      "port" => config["server"]["port"] + (worker_index * port_offset),
      "uuid" => config["server"]["uuid"] <> "-" <> Integer.to_string(worker_index),
      "hosts" => host_conf
    }

    Map.merge(config, %{"server" => scaled_server_conf})
  end
end
