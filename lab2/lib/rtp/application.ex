defmodule RTP.Application do
  use Application

  def start(_, _) do
    children = [
      RTP.ProcessRegistry,
      RTP.DbConnector,
      RTP.Sink,
      RTP.MessageProcessor,
      RTP.SSEReader
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
