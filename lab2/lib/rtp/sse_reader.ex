defmodule RTP.SSEReader do
  @tweet_url "http://localhost:4000/tweets/"
  @tweet_stream_ids 1..2

  def start_link do
    IO.puts("Starting SSEReader")
    children = Enum.map(@tweet_stream_ids, &worker_spec/1)
    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
    Enum.each(@tweet_stream_ids, &init_worker_stream/1)
    {:ok, pid}
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def init_worker_stream(id) do
    [{pid, _value}] = Registry.lookup(RTP.ProcessRegistry, {RTP.SSEReaderWorker, id})
    Task.start(fn -> send(pid, :start_reader) end)
  end

  defp worker_spec(id) do
    default_spec = {RTP.SSEReaderWorker, {id, @tweet_url}}
    Supervisor.child_spec(default_spec, id: id)
  end
end
