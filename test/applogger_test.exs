defmodule AppLoggerTest do
  use ExUnit.Case, async: true
  doctest Ringbahn.AppLogger

  alias Ringbahn.AppLogger
  import ExUnit.CaptureLog
  import ExUnit.CaptureIO

  test "debug message should be printed with its label" do
    msg = "a message"

    message_fun = fn ->
      AppLogger.debug msg
    end

    assert String.contains?(capture_log(message_fun), "DEBUG: #{msg}") == true
  end

  test "info message should be printed with its label" do
    msg = "a message"

    message_fun = fn ->
      AppLogger.info msg
    end

    assert String.contains?(capture_log(message_fun), "INFO: #{msg}") == true
  end

  test "warn message should be printed with its label" do
    msg = "a message"

    message_fun = fn ->
      AppLogger.warn msg
    end

    assert String.contains?(capture_log(message_fun), "WARN: #{msg}") == true
  end

  test "error message should be printed with its label" do
    msg = "a message"

    message_fun = fn ->
      AppLogger.error msg
    end

    assert String.contains?(capture_log(message_fun), "ERROR: #{msg}") == true
  end

  test "fatal message should be printed with its label" do
    msg = "a message"

    message_fun = fn ->
      AppLogger.fatal msg
    end

    assert String.contains?(capture_log(message_fun), "FATAL: #{msg}") == true
  end

  test "banner message should be printed with app version" do
    {:ok, vsn} = :application.get_key(:ringbahn, :vsn)

    banner_fun = fn ->
      AppLogger.banner vsn
    end

    assert String.contains?(capture_io(banner_fun), "#{vsn}") == true
  end
end
