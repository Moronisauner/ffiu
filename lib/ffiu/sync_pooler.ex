defmodule Ffiu.SyncPooler do
  use GenServer

  alias Ffiu.{Repo, RepoMirror}
  alias Ffiu.Schemas.{Consumed, SyncEvent}

  import Ecto.Query

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    delay = Keyword.get(opts, :delay, :timer.seconds(30))

    :timer.send_interval(delay, :sync)

    {:ok, nil}
  end

  def handle_info(:sync, state) do
    new_messages =
      SyncEvent
      |> where(received: false)
      |> order_by(:id)
      |> Repo.all()

    process_messages(new_messages)

    {:noreply, state}
  end

  defp process_messages(messages) do
    received_messages_ids =
      Enum.reduce_while(messages, [], fn msg, acc ->
        case handle(msg) do
          :ok ->
            {:cont, [msg.id | acc]}

          :error ->
            {:halt, acc}
        end
      end)

    if !Enum.empty?(received_messages_ids) do
      SyncEvent
      |> where([sm], sm.id in ^received_messages_ids)
      |> Repo.update_all(set: [received: true])
    end
  end

  defp handle(%SyncEvent{table: "table1"} = msg) do
    RepoMirror.insert(%Consumed{
      result: "#{msg.command} #{Jason.encode!(msg.row)}"
    })

    :ok
  end

  defp handle(msg) do
    Logger.error("Can't handle events from table #{msg.table}")
    :error
  end
end
