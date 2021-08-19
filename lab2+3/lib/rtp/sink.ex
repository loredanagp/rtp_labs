defmodule RTP.Sink do
  use GenServer

  @batch_size 128
  @max_time 200
  @ets_table :sink

  def init(_) do
    IO.puts("Starting Sink")
    :ets.new(@ets_table, [:named_table, :public, :set])
    :ets.insert(@ets_table, {:qps, :os.system_time(:millisecond)})

    {:ok, {[], 0}}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def add_tweet(tweet) do
    GenServer.cast(__MODULE__, {:add_tweet, tweet})
  end

  def handle_cast({:add_tweet, tweet}, {tweets, tweets_count}) do
    tweets = [tweet | tweets]
    tweets_count = tweets_count + 1

    [{_, time}] = :ets.lookup(@ets_table, :qps)
    time_passed = :os.system_time(:millisecond) - time

    if (tweets_count > @batch_size || time_passed > @max_time) do
      RTP.DbConnector.store(tweets)
      :ets.update_element(@ets_table, :qps, {2, :os.system_time(:millisecond)})
      {:noreply, {[], 0}}
    else
      {:noreply, {tweets, tweets_count}}
    end
  end
end
