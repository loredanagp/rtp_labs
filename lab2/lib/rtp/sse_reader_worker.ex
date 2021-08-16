defmodule RTP.SSEReaderWorker do
  use GenServer

  def init({id, url}) do
    state = %{id: id, url: url}
    {:ok, state}
  end

  def start_link({id, url}) do
    IO.puts("Starting SSEReaderWorker #{inspect via_tuple(id)}")

    GenServer.start_link(
      __MODULE__,
      {id, url},
      name: via_tuple(id)
      )
  end

  def handle_info(:start_reader, state) do
    IO.puts("Starting SSEReaderWorker stream for #{state[:url]}#{state[:id]}")
    start_eventsource_stream(state[:id], state[:url])
    {:noreply, state}
  end

  def handle_info(msg, state) do
    %{data: data} = msg

    RTP.MessageProcessor.consume(data)
    {:noreply, state}
  end

  defp start_eventsource_stream(id, url) do
    EventsourceEx.new(
      url <> to_string(id),
      stream_to: self(),
      headers: []
    )
  end

  defp via_tuple(id) do
    RTP.ProcessRegistry.via_tuple({__MODULE__, id})
  end
end
