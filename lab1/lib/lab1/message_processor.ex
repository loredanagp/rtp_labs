defmodule Lab1.MessageProcessor do
  use GenServer
  @max_children 10
  @ets_table :message_processor

  def init(args) do
    {:ok, args}
  end

  def start_link(_) do
    IO.puts("Starting Message Processor")
    :ets.new(@ets_table, [:named_table, :public, :set])
    :ets.insert(@ets_table, {:round_robin, -1})
    :ets.insert(@ets_table, {:qps, 0, :os.system_time(:millisecond), 0})

    children = [{DynamicSupervisor, name: __MODULE__, strategy: :one_for_one, max_children: @max_children}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def consume(data) do
    current_load = count_load()
    counter = choose_worker(current_load)
    Lab1.MessageProcessorWorker.process(counter, data)
  end

  defp count_load do
    [{_, _, time, qps}] = :ets.lookup(@ets_table, :qps)
    time_passed = :os.system_time(:millisecond) - time

    request_count = :ets.update_counter(@ets_table, :qps, {2, 1})

    qps = if time_passed > 1000 do
      current_request_count = request_count
      :ets.update_element(@ets_table, :qps, {2, 0})
      :ets.update_element(@ets_table, :qps, {3, :os.system_time(:millisecond)})
      :ets.update_element(@ets_table, :qps, {4, qps})
      (qps + current_request_count) / 2
    else
      request_count
    end

    ceil(qps / 100)
  end

  defp choose_worker(current_load) do
    %{active: active} = DynamicSupervisor.count_children(__MODULE__)
    counter = :ets.update_counter(@ets_table, :round_robin, {2, 1, current_load, 0})

    IO.puts("\n\nactive: #{active}; counter: #{counter}; current_load: #{current_load}\n\n")

    cond do
      current_load > active or active == 0 ->
        DynamicSupervisor.start_child(__MODULE__, worker_spec(counter))
        counter
      active > current_load or active > 2 ->
        pid = GenServer.whereis(Lab1.MessageProcessorWorker.via_tuple(counter))
        case is_pid(pid) do
          true -> DynamicSupervisor.terminate_child(__MODULE__, pid)
          false -> {:error, :not_found}
        end
        :ets.update_counter(@ets_table, :round_robin, {2, 1, current_load + 1, 0})
      true ->
        counter
    end
  end

  defp worker_spec(id) do
    default_spec = {Lab1.MessageProcessorWorker, id}
    Supervisor.child_spec(default_spec, id: id)
  end
end
