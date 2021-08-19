defmodule RTP.Application do
  use Application

  def start(_, _) do
    children = [
      RTP.ProcessRegistry,
      RTP.DbConnector,
      RTP.Sink,
      RTP.MessageProcessor,
      RTP.SSEReader,
      {Task.Supervisor, name: RTP.MessageBroker.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> RTP.MessageBroker.start_listener end}, restart: :permanent)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
