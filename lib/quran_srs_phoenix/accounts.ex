defmodule QuranSrsPhoenix.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias QuranSrsPhoenix.Repo

  alias QuranSrsPhoenix.Accounts.{User, UserToken, UserNotifier}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.email_changeset(attrs)
    |> Repo.insert()
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `QuranSrsPhoenix.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `QuranSrsPhoenix.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  alias QuranSrsPhoenix.Accounts.Hafiz
  alias QuranSrsPhoenix.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any hafiz changes.

  The broadcasted messages match the pattern:

    * {:created, %Hafiz{}}
    * {:updated, %Hafiz{}}
    * {:deleted, %Hafiz{}}

  """
  def subscribe_hafizs(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(QuranSrsPhoenix.PubSub, "user:#{key}:hafizs")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(QuranSrsPhoenix.PubSub, "user:#{key}:hafizs", message)
  end

  @doc """
  Returns the list of hafizs.

  ## Examples

      iex> list_hafizs(scope)
      [%Hafiz{}, ...]

  """
  def list_hafizs(%Scope{} = scope) do
    Repo.all_by(Hafiz, user_id: scope.user.id)
  end

  @doc """
  Gets a single hafiz.

  Raises `Ecto.NoResultsError` if the Hafiz does not exist.

  ## Examples

      iex> get_hafiz!(123)
      %Hafiz{}

      iex> get_hafiz!(456)
      ** (Ecto.NoResultsError)

  """
  def get_hafiz!(%Scope{} = scope, id) do
    Repo.get_by!(Hafiz, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a hafiz.

  ## Examples

      iex> create_hafiz(%{field: value})
      {:ok, %Hafiz{}}

      iex> create_hafiz(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_hafiz(%Scope{} = scope, attrs) do
    with {:ok, hafiz = %Hafiz{}} <-
           %Hafiz{}
           |> Hafiz.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, hafiz})
      {:ok, hafiz}
    end
  end

  @doc """
  Updates a hafiz.

  ## Examples

      iex> update_hafiz(hafiz, %{field: new_value})
      {:ok, %Hafiz{}}

      iex> update_hafiz(hafiz, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_hafiz(%Scope{} = scope, %Hafiz{} = hafiz, attrs) do
    true = hafiz.user_id == scope.user.id

    with {:ok, hafiz = %Hafiz{}} <-
           hafiz
           |> Hafiz.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, hafiz})
      {:ok, hafiz}
    end
  end

  @doc """
  Deletes a hafiz.

  ## Examples

      iex> delete_hafiz(hafiz)
      {:ok, %Hafiz{}}

      iex> delete_hafiz(hafiz)
      {:error, %Ecto.Changeset{}}

  """
  def delete_hafiz(%Scope{} = scope, %Hafiz{} = hafiz) do
    true = hafiz.user_id == scope.user.id

    with {:ok, hafiz = %Hafiz{}} <-
           Repo.delete(hafiz) do
      broadcast(scope, {:deleted, hafiz})
      {:ok, hafiz}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking hafiz changes.

  ## Examples

      iex> change_hafiz(hafiz)
      %Ecto.Changeset{data: %Hafiz{}}

  """
  def change_hafiz(%Scope{} = scope, %Hafiz{} = hafiz, attrs \\ %{}) do
    true = hafiz.user_id == scope.user.id

    Hafiz.changeset(hafiz, attrs, scope)
  end

  alias QuranSrsPhoenix.Accounts.HafizUser
  alias QuranSrsPhoenix.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any hafiz_user changes.

  The broadcasted messages match the pattern:

    * {:created, %HafizUser{}}
    * {:updated, %HafizUser{}}
    * {:deleted, %HafizUser{}}

  """
  def subscribe_hafiz_users(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(QuranSrsPhoenix.PubSub, "user:#{key}:hafiz_users")
  end

  @doc """
  Returns the list of hafiz_users.

  ## Examples

      iex> list_hafiz_users(scope)
      [%HafizUser{}, ...]

  """
  def list_hafiz_users(%Scope{} = scope) do
    HafizUser
    |> where([hu], hu.user_id == ^scope.user.id)
    |> preload([:user, :hafiz])
    |> Repo.all()
  end

  @doc """
  Returns the list of hafiz_users for a specific hafiz.

  ## Examples

      iex> list_hafiz_relationships(scope, hafiz_id)
      [%HafizUser{}, ...]

  """
  def list_hafiz_relationships(%Scope{} = scope, hafiz_id) do
    # First verify the user owns the hafiz
    _ = get_hafiz!(scope, hafiz_id)
    
    HafizUser
    |> where([hu], hu.hafiz_id == ^hafiz_id)
    |> preload([:user, :hafiz])
    |> Repo.all()
  end

  @doc """
  Gets a single hafiz_user.

  Raises `Ecto.NoResultsError` if the Hafiz user does not exist.

  ## Examples

      iex> get_hafiz_user!(123)
      %HafizUser{}

      iex> get_hafiz_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_hafiz_user!(%Scope{} = scope, id) do
    HafizUser
    |> where([hu], hu.id == ^id and hu.user_id == ^scope.user.id)
    |> preload([:user, :hafiz])
    |> Repo.one!()
  end

  @doc """
  Creates a hafiz_user.

  ## Examples

      iex> create_hafiz_user(%{field: value})
      {:ok, %HafizUser{}}

      iex> create_hafiz_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_hafiz_user(%Scope{} = scope, attrs) do
    with {:ok, hafiz_user = %HafizUser{}} <-
           %HafizUser{}
           |> HafizUser.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, hafiz_user})
      {:ok, hafiz_user}
    end
  end

  @doc """
  Updates a hafiz_user.

  ## Examples

      iex> update_hafiz_user(hafiz_user, %{field: new_value})
      {:ok, %HafizUser{}}

      iex> update_hafiz_user(hafiz_user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_hafiz_user(%Scope{} = scope, %HafizUser{} = hafiz_user, attrs) do
    true = hafiz_user.user_id == scope.user.id

    with {:ok, hafiz_user = %HafizUser{}} <-
           hafiz_user
           |> HafizUser.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, hafiz_user})
      {:ok, hafiz_user}
    end
  end

  @doc """
  Deletes a hafiz_user.

  ## Examples

      iex> delete_hafiz_user(hafiz_user)
      {:ok, %HafizUser{}}

      iex> delete_hafiz_user(hafiz_user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_hafiz_user(%Scope{} = scope, %HafizUser{} = hafiz_user) do
    true = hafiz_user.user_id == scope.user.id

    with {:ok, hafiz_user = %HafizUser{}} <-
           Repo.delete(hafiz_user) do
      broadcast(scope, {:deleted, hafiz_user})
      {:ok, hafiz_user}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking hafiz_user changes.

  ## Examples

      iex> change_hafiz_user(hafiz_user)
      %Ecto.Changeset{data: %HafizUser{}}

  """
  def change_hafiz_user(%Scope{} = scope, %HafizUser{} = hafiz_user, attrs \\ %{}) do
    # Only check user_id for existing records (not new ones)
    if hafiz_user.id do
      true = hafiz_user.user_id == scope.user.id
    end

    HafizUser.changeset(hafiz_user, attrs, scope)
  end
end
