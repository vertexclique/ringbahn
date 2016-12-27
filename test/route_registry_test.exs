defmodule RouteRegistryTest do
  use ExUnit.Case, async: true
  doctest Ringbahn.RouteRegistry

  def create_test_worker(worker_name) do
    Cachex.start_link(worker_name, [])

    routes_data = Enum.map 1..10, fn (x) ->
      %{"recv_ident" => "016018e0-d1f3-11e3-9c1a-0800200c9a66-2",
        "recv_port" => 10253, "recv_spec" => "127.0.0.1", "route" => "/watchdog" <> Integer.to_string(x),
        "send_ident" => "016018e0-d1f3-11e3-9c1a-0800200c9a66-2",
        "send_port" => 10252, "send_spec" => "127.0.0.1"}
    end

    Ringbahn.RouteRegistry.set_routes worker_name, routes_data
    worker_name
  end

  test "creating ETS workers" do
    worker_count = 4

    workers = Ringbahn.RouteRegistry.create_workers(worker_count)
    assert length(workers) == worker_count
  end

  test "populating routers in ETS table" do
    routes_data = [
      %{"recv_ident" => "016018e0-d1f3-11e3-9c1a-0800200c9a66-2",
        "recv_port" => 10253, "recv_spec" => "127.0.0.1", "route" => "/watchdog",
        "send_ident" => "016018e0-d1f3-11e3-9c1a-0800200c9a66-2",
        "send_port" => 10252, "send_spec" => "127.0.0.1"}
    ]

    route_set = Ringbahn.RouteRegistry.set_routes(:route_registry_0, routes_data)
    assert route_set == [ok: true]
  end

  test "get route data from ETS table" do
    reg_name = :route_registry_0
    reg_data = %{
      "route" => "/watchdog",
      "recv_ident" => "new-ident"
    }

    Cachex.set(reg_name, reg_data["route"], reg_data)
    assert reg_data == Ringbahn.RouteRegistry.get_route(reg_name, reg_data["route"])
  end

  test "get all key list as stream from ETS table" do
    create_test_worker(:ragdoll)
    key_list = Ringbahn.RouteRegistry.get_all_keys_stream :ragdoll
    assert length(key_list |> Enum.to_list) == 10
  end

  test "converts Stream to List convertion should be exactly like the table read sequence" do
    key_list = create_test_worker(:ponyhof)
    |> Ringbahn.RouteRegistry.get_all_keys_stream
    |> Enum.to_list

    assert Ringbahn.RouteRegistry.get_keys_list(:ponyhof) == key_list
  end
end
