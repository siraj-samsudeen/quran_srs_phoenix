defmodule QuranSrsPhoenix.Accounts.Hafiz do
  use Ecto.Schema
  import Ecto.Changeset

  schema "hafizs" do
    field :name, :string
    field :daily_capacity, :integer
    field :effective_date, :date
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hafiz, attrs, user_scope) do
    hafiz
    |> cast(attrs, [:name, :daily_capacity, :effective_date])
    |> validate_required([:name, :daily_capacity])
    |> put_default_effective_date()
    |> put_change(:user_id, user_scope.user.id)
  end
  
  defp put_default_effective_date(changeset) do
    case get_field(changeset, :effective_date) do
      nil -> put_change(changeset, :effective_date, Date.utc_today())
      _ -> changeset
    end
  end
end
