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
end
