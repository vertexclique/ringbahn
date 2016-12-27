defmodule Ringbahn.CLI do
  @moduledoc """
  Starts the Ringbahn server from command line when it is built as Escript.
  """
  alias Ringbahn.AppLogger

  def main(args) do
    parsed_arguments = args |> option_parse

    # Imitates the erlang otp application start
    apps = [:logger, :bunt, :gproc, :cachex, :plug, :chumak, :cowboy, :retry]
    for app <- apps, do: {:ok, _} = Application.ensure_all_started(app)

    AppLogger.info "Starting from Erlang Script..."

    # Start Ringbahn with passed parameters
    Ringbahn.start(:normal, parsed_arguments)
    :timer.sleep(:infinity)
  end

  def option_parse(args) do
    {options, _, _} = OptionParser.parse(args)
    options
  end
end
