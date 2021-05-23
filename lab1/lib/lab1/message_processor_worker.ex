defmodule Lab1.MessageProcessorWorker do
  use GenServer

  @sleep_range 50..500

  def start_link(id) do
    IO.puts("Starting MessageProcessorWorker with id: #{inspect via_tuple(id)}")

    GenServer.start_link(
      __MODULE__,
      [],
      name: via_tuple(id)
    )
  end

  def process(pid, data) do
    GenServer.call(pid, {:process, data})
    {:noreply, []}
  end

  def handle_call(:process, data) do
    :timer.sleep(Enum.random(@sleep_range))
    IO.puts(data)
    {:noreply, []}
  end

  def worker_identifier(id) do
    {__MODULE__, id}
  end

  defp via_tuple(id) do
    Lab1.ProcessRegistry.via_tuple({__MODULE__, id})
  end
end
