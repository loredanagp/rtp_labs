defmodule Lab1.Application do
  use Application

  def start(_, _) do
    children = [
      Lab1.ProcessRegistry,
      Lab1.MessageProcessor,
      Lab1.SSEReader
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
