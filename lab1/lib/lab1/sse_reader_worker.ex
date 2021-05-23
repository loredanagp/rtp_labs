defmodule Lab1.SSEReaderWorker do
  use GenServer

  def init({id, url}) do
    {:ok, {id ,url}}
  end

  def start_link({id, url}) do
    IO.puts("Starting SSEReaderWorker #{inspect via_tuple(id)}")

    GenServer.start_link(
      __MODULE__,
      {id, url},
      name: via_tuple(id)
      )
  end

  def handle_info(:start_reader, {id, url}) do
    IO.puts("Starting SSEReaderWorker stream for #{url}#{id}")
    start_eventsource_stream(id, url)
    {:noreply, []}
  end

  def handle_info(%{data: data}, _) do
    Lab1.MessageProcessor.consume(data)
    {:noreply, data}
  end

  defp start_eventsource_stream(id, url) do
    EventsourceEx.new(
      url <> to_string(id),
      stream_to: self(),
      headers: []
    )
  end

  defp via_tuple(id) do
    Lab1.ProcessRegistry.via_tuple({__MODULE__, id})
  end
end
