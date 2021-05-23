defmodule Lab1.MessageProcessorWorker do
  use GenServer

  @sleep_range 50..500

  def init(args) do
    {:ok, args}
  end

  def start_link(id) do
    IO.puts("Starting MessageProcessorWorker with id: #{inspect via_tuple(id)}")

    GenServer.start_link(
      __MODULE__,
      [],
      name: via_tuple(id)
    )
  end

  def process(id, data) do
    if data == "{\"message\": panic}" do
      {:stop, :normal, []}
    else
      GenServer.cast(via_tuple(id), {:process, data})
    end
  end

  def handle_cast({:process, data}, state) do
    :timer.sleep(Enum.random(@sleep_range))
    IO.puts(data)
    {:noreply, state}
  end

  def via_tuple(id) do
    Lab1.ProcessRegistry.via_tuple({__MODULE__, id})
  end

  def worker_identifier(id) do
    {__MODULE__, id}
  end
end
