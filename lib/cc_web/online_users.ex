defmodule CcWeb.OnlineUsers do
  alias Cc.Accounts.User
  alias CcWeb.Presence

  @topic "online_users"

  def list() do
    Presence.list(@topic)
    |> Enum.into(
      %{},
      fn {id, %{metas: metas}} ->
        {String.to_integer(id), length(metas)}
      end
    )
  end

  def track(pid, user) do
    {:ok, _} = Presence.track(pid, @topic, user.id, %{})
    :ok
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(Cc.PubSub, @topic)
  end

  def online?(online_users, %User{id: user_id}) do
    online?(online_users, user_id)
  end

  def online?(online_users, user_id) do
    Map.get(online_users, user_id, 0) > 0
  end

  def update(online_users, %{joins: joins, leaves: leaves}) do
    online_users
    |> process_updates(joins, &(&1 + &2))
    |> process_updates(leaves, &(&1 - &2))
  end

  defp process_updates(online_users, updates, operation) do
    Enum.reduce(updates, online_users, fn {id, %{metas: metas}}, acc ->
      Map.update(
        acc,
        String.to_integer(id),
        length(metas),
        &operation.(&1, length(metas))
      )
    end)
  end
end
