defmodule Ringbahn.RouteRegistry do
  @moduledoc """
  Route Registry is the ETS table management module that contains tasks
  for ETS table.
  """

  # Creates ETS workers from route configuration for routes
  def create_workers(worker_count) do
    import Supervisor.Spec, warn: false

    Enum.map 0..worker_count - 1, fn (worker_index) ->
      route_registry_name = String.to_atom("route_registry_#{worker_index}")
      worker(Cachex, [route_registry_name, []], id: route_registry_name, restart: :permanent)
    end
  end

  # Populate routes and their configurations from config
  def set_routes(registry_name, routes_data) do
    Enum.map routes_data, fn (route_data) ->
      key = if route_data["route"] == nil do route_data.route else route_data["route"] end
      Cachex.set(registry_name, key, route_data)
    end
  end

  def get_route(registry_name, route) do
    {:ok, data} = Cachex.get(registry_name, route)
    data
  end

  # Gets all keys from a specific ETS table as stream
  def get_all_keys_stream(registry_name) when is_atom(registry_name) do
    eot = :"$end_of_table"

    Stream.resource(
      fn -> [] end,

      fn acc ->
        case acc do
          [] ->
            case :ets.first(registry_name) do
              ^eot -> {:halt, acc}
              first_key -> {[first_key], first_key}
            end

          acc ->
            case :ets.next(registry_name, acc) do
              ^eot -> {:halt, acc}
              next_key -> {[next_key], next_key}
            end
        end
      end,

      fn _acc -> :ok end
    )
  end

  # Retrieves the list of the keys, don't use it in processes if you don't need it desperately.
  # Allocates memory of the process which is used in.
  def get_keys_list(registry_name) do
    registry_name
    |> get_all_keys_stream
    |> Enum.to_list
  end
end
