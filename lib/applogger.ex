defmodule Ringbahn.AppLogger do
  @moduledoc """
  Supplies logging functionality and colorful outputs
  """
  require Logger

  def debug(message) do
    [:darkorange, "DEBUG: " <> message]
    |> Bunt.ANSI.format
    |> Logger.debug

    message
  end

  def info(message) do
    [:color27, "INFO: " <> message]
    |> Bunt.ANSI.format
    |> Logger.info

    message
  end

  def warn(message) do
    [:gold, "WARN: " <> message]
    |> Bunt.ANSI.format
    |> Logger.warn

    message
  end

  def error(message) do
    [:color196, "ERROR: " <> message]
    |> Bunt.ANSI.format
    |> Logger.error

    message
  end

  def fatal(message) do
    [:darkred, "FATAL: " <> message]
    |> Bunt.ANSI.format
    |> Logger.error

    message
  end

  def banner(version) do
    banner_raw = File.read! "config/ringbahn.banner"
    banner = banner_raw <> "Ringbahn Server — Version #{version}"

    [:springgreen, banner]
    |> Bunt.puts
  end
end
