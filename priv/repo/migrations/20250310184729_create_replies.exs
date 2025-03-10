defmodule Cc.Repo.Migrations.CreateReplies do
  use Ecto.Migration

  def change do
    create table(:replies) do
      add :body, :text, null: false
      add :message_id, references(:messages, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:replies, [:message_id])
    create index(:replies, [:user_id])
  end
end
