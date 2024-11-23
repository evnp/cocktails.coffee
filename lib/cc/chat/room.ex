defmodule Cc.Chat.Room do
  use Ecto.Schema
  import Ecto.Changeset

  alias Cc.Accounts.User
  alias Cc.Chat.{Message, RoomMembership}

  schema "rooms" do
    field :name, :string
    field :topic, :string
    many_to_many :members, User, join_through: RoomMembership
    has_many :memberships, RoomMembership
    has_many :messages, Message
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :topic])
    |> validate_required(:name, message: "You shall not be blank")
    |> validate_length(:name,
      min: 3,
      message: "You shall be a fellowship of greater than three."
    )
    |> validate_length(:name,
      max: 80,
      message: "You shall be a fellowship of fewer than eighty."
    )
    |> validate_format(:name, ~r/\A[a-z0-9-]+\z/, message: "You shall not pass.")
    |> validate_format(:name, ~r/\A((?![A-Z]).)*\z/,
      message: "You shall not contain uppercase letters."
    )
    |> validate_format(:name, ~r/\A((?!\s).)*\z/, message: "You shall not contain spaces.")
    |> validate_format(:name, ~r/\A[\sA-Za-z0-9-]+\z/, message: "You shall not contain symbols.")
    |> validate_length(:topic, max: 200)
    |> unique_constraint(:name)
    |> unsafe_validate_unique(:name, Cc.Repo,
      message: "You shall use a realm name that doesn't yet exist."
    )
  end
end
