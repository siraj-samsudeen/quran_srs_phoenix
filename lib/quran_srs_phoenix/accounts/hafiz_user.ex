defmodule QuranSrsPhoenix.Accounts.HafizUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias QuranSrsPhoenix.Accounts.{User, Hafiz}

  schema "hafiz_users" do
    field :relationship, Ecto.Enum, values: [:owner, :parent, :teacher, :student, :family]
    field :user_email, :string, virtual: true
    belongs_to :user, User
    belongs_to :hafiz, Hafiz

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hafiz_user, attrs, user_scope) do
    hafiz_user
    |> cast(attrs, [:relationship, :hafiz_id, :user_email])
    |> validate_required([:relationship, :hafiz_id])
    |> validate_user_email(user_scope)
    |> unique_constraint([:user_id, :hafiz_id], 
         message: "User is already associated with this hafiz")
  end

  defp validate_user_email(changeset, user_scope) do
    case get_change(changeset, :user_email) do
      nil ->
        # For existing records or when user_id is already set
        put_change(changeset, :user_id, changeset.data.user_id || user_scope.user.id)
      
      email when is_binary(email) and email != "" ->
        # Look up user by email
        case QuranSrsPhoenix.Accounts.get_user_by_email(email) do
          %QuranSrsPhoenix.Accounts.User{} = user ->
            put_change(changeset, :user_id, user.id)
          
          nil ->
            add_error(changeset, :user_email, "No user found with this email address")
        end
        
      _ ->
        changeset
    end
  end
end
