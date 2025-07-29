defmodule QuranSrsPhoenix.Accounts.HafizUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "hafiz_users" do
    field :relationship, Ecto.Enum, values: [:owner, :parent, :teacher, :student, :family]
    field :user_id, :id
    field :hafiz_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hafiz_user, attrs, user_scope) do
    hafiz_user
    |> cast(attrs, [:relationship])
    |> validate_required([:relationship])
    |> put_change(:user_id, user_scope.user.id)
  end
end
