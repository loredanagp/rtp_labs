defmodule RTP.DbConnector do
  use GenServer

  @address "mongodb://localhost:27017"
  @database "rtp"
  @collection "tweets"

  def init(:ok) do
    IO.puts("Starting DbConnector")
    {:ok, _conn} = Mongo.start_link(url: @address, database: @database)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def store(data) do
    GenServer.cast(__MODULE__, {:store, data})
  end

  def handle_cast({:store, data}, pid) do
    Mongo.insert_many(pid, @collection, data)
    {:noreply, pid}
  end
end
