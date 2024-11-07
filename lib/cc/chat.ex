defmodule CC.Chat do
  alias CC.Chat.Room
  alias CC.Repo
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

  def get_room_changeset(room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end
end
