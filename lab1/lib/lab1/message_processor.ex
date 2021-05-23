defmodule Lab1.MessageProcessor do
  use GenServer
  @max_children 10
  @ets_table :message_processor
  @qps_counter :qps_counter

  def start_link(_) do
    IO.puts("Starting Message Processor")
    :ets.new(@ets_table, [:named_table, :public, :set])
    :ets.insert(@ets_table, {:round_robin, -1})
    :ets.insert(@ets_table, {:qps, -1, :os.system_time(:millisecond), 0})

    children = [{DynamicSupervisor, name: __MODULE__, strategy: :one_for_one, max_children: @max_children}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def consume(data) do
    current_load = count_load()
    IO.puts("current_load: #{current_load}")
    pid = choose_worker(current_load)
    Lab1.MessageProcessorWorker.process(pid, data)
  end

  defp choose_worker(current_load) do
    %{active: active} = DynamicSupervisor.count_children(Lab1.MessageProcessor)
    counter = :ets.update_counter(@ets_table, :round_robin, {2, 1, current_load, -1})

    if current_load > active || active == 0 do
      IO.puts("counter: #{counter}")
      DynamicSupervisor.start_child(__MODULE__, worker_spec(counter))
    end

    processes = Registry.lookup(Lab1.ProcessRegistry, {Lab1.MessageProcessorWorker, counter})
    {pid, _} = Enum.at(processes, counter)
    pid
  end

  defp count_load do
    [{_, _, time, qps}] = :ets.lookup(@ets_table, :qps)
    time_passed = :os.system_time(:millisecond) - time

    request_count = :ets.update_counter(@ets_table, :qps, {2, 1})

    qps = if time_passed > 1000 do
      :ets.update_element(@ets_table, :qps, {3, :os.system_time(:millisecond)})
      :ets.update_element(@ets_table, :qps, {4, qps})
      (qps + request_count) / 2
    else
      request_count
    end

    ceil(qps / 100)
  end

  defp worker_spec(id) do
    IO.puts("self: #{inspect self()}; id: #{id}")
    default_spec = {Lab1.MessageProcessorWorker, id}
    Supervisor.child_spec(default_spec, id: id)
  end
end
