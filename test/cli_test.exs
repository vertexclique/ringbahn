defmodule CLITest do
  use ExUnit.Case, async: true
  doctest Ringbahn.CLI

  alias Ringbahn.CLI

  test "exit when malformed config fed in" do
    Process.flag(:trap_exit, true)

    app_start = fn ->
      configfile = "test/malformed_config.ring.json"
      CLI.main(["--config=#{configfile}"])
    end

    pid = spawn_link(app_start)

    receive do
      {:EXIT, ^pid, :normal} -> flunk "Abnormal termination expected."
      {:EXIT, ^pid, reason}  -> assert String.contains?(reason, "Config is not valid:") == true
    end
  end

  test "exit when there is no config file is present on FS" do
    Process.flag(:trap_exit, true)

    app_start = fn ->
      configfile = "dataline.ring.json"
      CLI.main(["--config=#{configfile}"])
    end

    pid = spawn_link(app_start)

    receive do
      {:EXIT, ^pid, :normal} -> flunk "Abnormal termination expected."
      {:EXIT, ^pid, reason}  -> assert reason == "Config file not found."
    end
  end
end
