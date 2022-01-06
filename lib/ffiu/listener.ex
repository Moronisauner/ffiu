defmodule MyListener do
  use GenServer

  alias Ffiu.Schemas.Mirror1
  alias Ffiu.Repo

  def start_link(_) do
    GenServer.start_link(__MODULE__, [channel: ["tb_table1"]], name: __MODULE__)
  end

  def init(args) do
    for channel <- args[:channel] do
      Ffiu.Notifications
      |> Process.whereis()
      |> Postgrex.Notifications.listen!(channel,
        sync_connect: false,
        auto_reconnect: true
      )
    end

    {:ok, nil}
  end

  def handle_info({:notification, _connection_pid, _ref, channel, message}, state) do
    message =
      message
      |> Jason.decode!()
      |> IO.inspect(label: "message")

    action = message["action"]
    row = message["row"]

    resource =
      case channel do
        "tb_table1" -> Mirror1
      end

    if action == "DELETE" do
      resource
      |> Repo.get(row["id"])
      |> Repo.delete()
    else
      resource
      |> struct(%{id: row["id"], field: row["field"]})
      |> Repo.insert(
        conflict_target: [:id],
        on_conflict: :replace_all
      )
    end

    {:noreply, state}
  end
end
