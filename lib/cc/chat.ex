defmodule CC.Chat do
  alias CC.Chat.Room
  alias CC.Repo

  def list_rooms do
    Repo.all(Room)
  end

  def get_room!(id) do
    Repo.get!(Room, id)
  end

  def get_first_room!(rooms) do
    [room | _] = rooms
    room
  end

  def get_first_room!() do
    [room | _] = list_rooms()
    room
  end
end
