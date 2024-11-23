defmodule Cc.Chat do
  import Ecto.Changeset
  import Ecto.Query

  alias Cc.Accounts.User
  alias Cc.Chat.{Room, Message, RoomMembership}
  alias Cc.Repo

  @pubsub Cc.PubSub

  def list_rooms do
    Repo.all(from r in Room, order_by: [asc: :name])
  end

  def list_rooms(%User{} = user) do
    Repo.all(
      from r in Room,
        left_join: m in RoomMembership,
        on: r.id == m.room_id and m.user_id == ^user.id,
        select: {r, not is_nil(m.id)},
        order_by: [asc: :name]
    )
  end

  def list_joined_rooms_with_unread_counts(%User{} = user) do
    # From all rooms:
    Repo.all(
      from room in Room,
        # Select only those rooms for which the user has a membership:
        join: membership in assoc(room, :memberships),
        where: membership.user_id == ^user.id,
        # Additionally select the unread messages in those rooms. Use 'left_join'
        # so that we don't remove rooms which have no unread messages.
        left_join: message in assoc(room, :messages),
        on: message.id > membership.last_read_message_id,
        # Select the room, plus each room's unread message count:
        group_by: room.id,
        select: {room, count(message.id)},
        # Order the results by room name:
        order_by: [asc: room.name]
    )
  end

  def get_room!(id) do
    Repo.get!(Room, id)
  end

  def get_first_room!(rooms) do
    [room | _] = rooms
    room
  end

  def get_first_room!() do
    Repo.one!(from r in Room, limit: 1, order_by: [asc: :name])
  end

  def create_room(attrs) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  def list_messages_in_room(%Room{id: room_id}) do
    Message
    |> where([m], m.room_id == ^room_id)
    |> order_by([m], asc: :inserted_at, asc: :id)
    |> preload(:user)
    |> Repo.all()
  end

  def create_message(room, attrs, user) do
    result =
      %Message{room: room, user: user}
      |> Message.changeset(attrs)
      |> Repo.insert()

    with {:ok, message} <- result do
      Phoenix.PubSub.broadcast!(@pubsub, room_pubsub_topic(room), {:new_message, message})
      {:ok, message}
    end
  end

  def delete_message(id, %User{id: user_id}) do
    # Raise MatchError if message with ID does not have correct user ID:
    message = %Message{user_id: ^user_id} = Repo.get(Message, id)
    result = Repo.delete(message)

    with {:ok, message} <- result do
      Phoenix.PubSub.broadcast!(
        @pubsub,
        room_pubsub_topic(message.room_id),
        {:message_deleted, message}
      )

      {:ok, message}
    end
  end

  def get_room_changeset(room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  def get_message_changeset(message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  def room_pubsub_topic(%Room{id: room_id}) do
    room_pubsub_topic(room_id)
  end

  def room_pubsub_topic(room_id) do
    "chat_room:#{room_id}"
  end

  def room_pubsub_subscribe(room) do
    Phoenix.PubSub.subscribe(@pubsub, room_pubsub_topic(room))
  end

  def room_pubsub_unsubscribe(room) do
    Phoenix.PubSub.unsubscribe(@pubsub, room_pubsub_topic(room))
  end

  def join_room!(room, user) do
    Repo.insert!(%RoomMembership{room: room, user: user})
  end

  def joined_room?(%Room{} = room, %User{} = user) do
    Repo.exists?(
      from rm in RoomMembership,
        where: rm.room_id == ^room.id and rm.user_id == ^user.id
    )
  end

  defp get_room_membership(room, user) do
    Repo.get_by(RoomMembership, room_id: room.id, user_id: user.id)
  end

  def toggle_room_membership(room, user) do
    case get_room_membership(room, user) do
      %RoomMembership{} = membership ->
        Repo.delete(membership)
        {room, false}

      nil ->
        join_room!(room, user)
        {room, true}
    end
  end

  def get_last_read_message_id(%Room{} = room, user) do
    case get_room_membership(room, user) do
      %RoomMembership{} = membership -> membership.last_read_message_id
      nil -> nil
    end
  end

  def update_last_read_message_id(room, user) do
    case get_room_membership(room, user) do
      %RoomMembership{} = membership ->
        last_read_message_id =
          from(m in Message, where: m.room_id == ^room.id, select: max(m.id))
          |> Repo.one()

        membership
        |> change(%{last_read_message_id: last_read_message_id})
        |> Repo.update()

      nil ->
        nil
    end
  end
end
