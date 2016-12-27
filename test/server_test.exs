defmodule RingbahnServerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Mock
  doctest Ringbahn.Server

  alias Ringbahn

  @http_ok 200
  @not_found 404

  defmodule RecursionInitiatedError do
    defexception message: "Recursion Initiated"
  end

  def get_config do
    raw_config = Application.get_all_env(:ringbahn)[:server_config]
    config = Poison.Parser.parse!(raw_config)
    worker_index = 0
    port_offset = config["settings"]["port_offset"]

    Ringbahn.scale_configuration config, worker_index, port_offset
  end

  setup do
    config = get_config
    route_config = Ringbahn.Server.init([config])
    {:ok, %{route_config: route_config} }
  end

  def server_stubs do
    [
      version: fn(_req) -> {:"HTTP/1.1", nil} end,
      url: fn(_req) -> {"http://localhost:6767/test?lola=123&uid=ASDF", nil} end,
      path: fn(_req) -> {"/test", nil} end
    ]
  end

  def sockets_ok_stubs do
    [
      recv: fn(_socket_pid) -> {:ok, "f983c23e-9058-4c9c-8cec-7f9f9a34c9ab-0 3:400, HTTP/1.1 200 OK\r\nContent-Length: 313\r\n\r\n<pre>\nSENDER: 'f983c23e-9058-4c9c-8cec-7f9f9a34c9ab-0'\nIDENT:'400'\nPATH: '/test'\nHEADERS:'{\"REMOTE_ADDR\": \"127.0.0.1\", \"PATTERN\": \"/test/\", \"URL_SCHEME\": \"http\", \"URI\": \"/test?lola=123&uid=ASDF\", \"VERSION\": \"HTTP/1.1\", \"QUERY\": \"\", \"PATH\": \"/test\", \"METHOD\": \"POST\"}'\nBODY:''</pre>"} end,
      send: fn(_socket_pid, _data) -> :ok end
    ]
  end

  def recv_socket_malformed_stubs do
    [
      recv: fn(_socket_pid) -> {:ok, "f983c23e-9058-4c9c-8cec-7f9f9a34c9ab-0 3:400, "} end,
      send: fn(_socket_pid, _data) -> :ok end
    ]
  end

  def recv_socket_state_failure_stubs do
    [
      recv: fn(_socket_pid) -> {:error, :efsm} end,
      send: fn(_socket_pid, _data) -> :ok end
    ]
  end

  def send_socket_not_connected_stubs do
    [
      recv: fn(_socket_pid) -> {:ok, "f983c23e-9058-4c9c-8cec-7f9f9a34c9ab-0 3:400, HTTP/1.1 200 OK"} end,
      send: fn(_socket_pid, _data) -> {:error, :no_connected_peers} end
    ]
  end

  test "successfully accepts known paths in connection", context do
    with_mocks([
      {:cowboy_req, [], server_stubs},
      {:chumak, [], sockets_ok_stubs}
    ]) do
      conn = %{conn(:post, "/test") | host: "localhost", port: 6767 }
      response = Ringbahn.Server.call(conn, context.route_config)
      assert response.status == @http_ok
    end
  end

  test "retry when malformed response came from receive socket", context do
    Process.flag(:trap_exit, true)

    with_mocks([
      {:cowboy_req, [], server_stubs},
      {:chumak, [], recv_socket_malformed_stubs}
    ]) do
      conn = %{conn(:post, "/test") | host: "localhost", port: 6767 }

      assert_raise RecursionInitiatedError, fn ->
        spawn fn -> Ringbahn.Server.call(conn, context.route_config) end
        :timer.sleep(1000)
        raise RecursionInitiatedError
      end
    end
  end

  test "retry when receive socket is in transition state", context do
    Process.flag(:trap_exit, true)

    with_mocks([
      {:cowboy_req, [], server_stubs},
      {:chumak, [], recv_socket_state_failure_stubs}
    ]) do
      conn = %{conn(:post, "/test") | host: "localhost", port: 6767 }

      assert_raise RecursionInitiatedError, fn ->
        spawn fn -> Ringbahn.Server.call(conn, context.route_config) end
        :timer.sleep(1000)
        raise RecursionInitiatedError
      end
    end
  end

  test "retry when send socket is not connected", context do
    Process.flag(:trap_exit, true)

    with_mocks([
      {:cowboy_req, [], server_stubs},
      {:chumak, [], send_socket_not_connected_stubs}
    ]) do
      conn = %{conn(:post, "/test") | host: "localhost", port: 6767 }

      assert_raise RecursionInitiatedError, fn ->
        spawn fn -> Ringbahn.Server.call(conn, context.route_config) end
        :timer.sleep(10)
        raise RecursionInitiatedError
      end
    end
  end

  test "return 404 on not matching routes", context do
    conn = %{conn(:post, "/dataline") | host: "localhost", port: 6767 }
    response = Ringbahn.Server.call(conn, context.route_config)
    assert response.status == @not_found
  end
end
