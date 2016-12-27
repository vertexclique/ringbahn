defmodule RingbahnTest do
  use ExUnit.Case
  doctest Ringbahn

  def get_config do
    raw_config = Application.get_all_env(:ringbahn)[:server_config]
    Poison.Parser.parse!(raw_config)
  end

  test "when server manager died supervisor restarts it" do
    manager = :gproc.lookup_pid({:n, :l, {:server_manager_namespace, :"Ringbahn.ServerManager0"}})
    Process.exit manager, :kill

    :timer.sleep(100)

    new_manager = :gproc.lookup_pid({:n, :l, {:server_manager_namespace, :"Ringbahn.ServerManager0"}})
    assert manager != new_manager
  end

  test "server managers are started" do
    config = get_config
    worker_count = config["settings"]["worker_count"]

    workers = Enum.map 0..worker_count - 1, fn (worker_index) ->
      :gproc.lookup_pid({:n, :l, {:server_manager_namespace, String.to_atom("Ringbahn.ServerManager" <> Integer.to_string(worker_index)) }})
    end
    assert length(workers) == worker_count
  end
end
