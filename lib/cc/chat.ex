defmodule Cc.Chat do
  alias Cc.Accounts.User
  alias Cc.Chat.{Room, Message}
  alias Cc.Repo
  import Ecto.Query

  def list_rooms do
    Repo.all(from r in Room, order_by: [asc: :name])
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
    %Message{room: room, user: user}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def delete_message(id, %User{id: user_id}) do
    # Raise MatchError if message with ID does not have correct user ID:
    message = %Message{user_id: ^user_id} = Repo.get(Message, id)
    Repo.delete(message)
  end

  def get_room_changeset(room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  def get_message_changeset(message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
