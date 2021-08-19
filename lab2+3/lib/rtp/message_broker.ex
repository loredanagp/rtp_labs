defmodule RTP.MessageBroker do
  @port 7123
  @ets_table :message_cache

  def start_listener do
    IO.puts("Starting MessageBroker")
    :ets.new(@ets_table, [:named_table, :public, :set])
    :ets.insert(@ets_table, {:tweets, []})
    {:ok, socket} = :gen_tcp.listen(
      @port,
      [:binary, packet: :line, active: false, reuseaddr: true]
    )
    loop_acceptor(socket)
  end

  def insert_messages(table, tweet) do
    case table do
      :tweets -> update_message_list(table, tweet)
    end
  end

  defp update_message_list(table, tweet) do
    [{_, tweets}] = :ets.lookup(@ets_table, table)
    :ets.update_element(@ets_table, table, {2, [tweet | tweets]})
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(RTP.MessageBroker.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    {:ok, message} = :gen_tcp.recv(socket, 0)

    sanitized_message = String.trim(message)

    cond do
      String.contains?(sanitized_message, "subscribe") ->
        result = String.split(sanitized_message, " ")
        table  = Enum.at(result, -1)

        if length(result) == 2 do
          :gen_tcp.send(socket, "Subscribed to #{table}!\r\n")
          handle_subscription(socket, table)
        end
      message == "close" ->
        :gen_tcp.close(socket)
    end

    serve(socket)
  end

  defp handle_subscription(socket, table) do
    {:ok, message} = :gen_tcp.recv(socket, 0)

    sanitized_message = String.trim(message)

    case sanitized_message do
      "get message" ->
        return_message_from_table(socket, sanitized_message)
        handle_subscription(socket, table)
      "unsubscribe" ->
        :gen_tcp.send(socket, "Unsubscribed from #{table}!\r\n")
      "close" ->
        :gen_tcp.close(socket)
      _ ->
        handle_subscription(socket, table)
    end
  end

  defp return_message_from_table(socket, table_name) do
    atomized_table_name = String.to_atom(table_name)

    [{_, tweets}] = :ets.lookup(@ets_table, atomized_table_name)
    {item, tweets} = List.pop_at(tweets, 0)
    :ets.update_element(@ets_table, atomized_table_name, {2, tweets})

    :gen_tcp.send(socket, item)
  end
end
