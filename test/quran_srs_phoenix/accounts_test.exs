defmodule QuranSrsPhoenix.AccountsTest do
  use QuranSrsPhoenix.DataCase

  alias QuranSrsPhoenix.Accounts

  import QuranSrsPhoenix.AccountsFixtures
  alias QuranSrsPhoenix.Accounts.{User, UserToken}

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture() |> set_password()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture() |> set_password()

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users without password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register_user(valid_user_attributes(email: email))
      assert user.email == email
      assert is_nil(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.utc_now()})
      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute Accounts.sudo_mode?(
               %User{authenticated_at: DateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute Accounts.sudo_mode?(%User{})
    end
  end

  describe "change_user_email/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = unconfirmed_user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert {:ok, %{email: ^email}} = Accounts.update_user_email(user, token)
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Accounts.update_user_email(user, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(
          %User{},
          %{
            "password" => "new valid password"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, {user, expired_tokens}} =
        Accounts.update_user_password(user, %{
          password: "new valid password"
        })

      assert expired_tokens == []
      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, {_, _}} =
        Accounts.update_user_password(user, %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"
      assert user_token.authenticated_at != nil

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end

    test "duplicates the authenticated_at of given user in new token", %{user: user} do
      user = %{user | authenticated_at: DateTime.add(DateTime.utc_now(:second), -3600)}
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.authenticated_at == user.authenticated_at
      assert DateTime.compare(user_token.inserted_at, user.authenticated_at) == :gt
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert {session_user, token_inserted_at} = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
      assert session_user.authenticated_at != nil
      assert token_inserted_at != nil
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      dt = ~N[2020-01-01 00:00:00]
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: dt, authenticated_at: dt])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_magic_link_token/1" do
    setup do
      user = user_fixture()
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      %{user: user, token: encoded_token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_magic_link_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_magic_link_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_magic_link_token(token)
    end
  end

  describe "login_user_by_magic_link/1" do
    test "confirms user and expires tokens" do
      user = unconfirmed_user_fixture()
      refute user.confirmed_at
      {encoded_token, hashed_token} = generate_user_magic_link_token(user)

      assert {:ok, {user, [%{token: ^hashed_token}]}} =
               Accounts.login_user_by_magic_link(encoded_token)

      assert user.confirmed_at
    end

    test "returns user and (deleted) token for confirmed user" do
      user = user_fixture()
      assert user.confirmed_at
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      assert {:ok, {^user, []}} = Accounts.login_user_by_magic_link(encoded_token)
      # one time use only
      assert {:error, :not_found} = Accounts.login_user_by_magic_link(encoded_token)
    end

    test "raises when unconfirmed user has password set" do
      user = unconfirmed_user_fixture()
      {1, nil} = Repo.update_all(User, set: [hashed_password: "hashed"])
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)

      assert_raise RuntimeError, ~r/magic link log in is not allowed/, fn ->
        Accounts.login_user_by_magic_link(encoded_token)
      end
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_login_instructions/2" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "login"
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "hafizs" do
    alias QuranSrsPhoenix.Accounts.Hafiz

    import QuranSrsPhoenix.AccountsFixtures, only: [user_scope_fixture: 0]
    import QuranSrsPhoenix.AccountsFixtures

    @invalid_attrs %{name: nil, daily_capacity: nil, effective_date: nil}

    test "list_hafizs/1 returns all scoped hafizs" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      hafiz = hafiz_fixture(scope)
      other_hafiz = hafiz_fixture(other_scope)
      assert Accounts.list_hafizs(scope) == [hafiz]
      assert Accounts.list_hafizs(other_scope) == [other_hafiz]
    end

    test "get_hafiz!/2 returns the hafiz with given id" do
      scope = user_scope_fixture()
      hafiz = hafiz_fixture(scope)
      other_scope = user_scope_fixture()
      assert Accounts.get_hafiz!(scope, hafiz.id) == hafiz
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_hafiz!(other_scope, hafiz.id) end
    end

    test "create_hafiz/2 with valid data creates a hafiz" do
      valid_attrs = %{name: "some name", daily_capacity: 42, effective_date: ~D[2025-07-28]}
      scope = user_scope_fixture()

      assert {:ok, %Hafiz{} = hafiz} = Accounts.create_hafiz(scope, valid_attrs)
      assert hafiz.name == "some name"
      assert hafiz.daily_capacity == 42
      assert hafiz.effective_date == ~D[2025-07-28]
      assert hafiz.user_id == scope.user.id
    end

    test "create_hafiz/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.create_hafiz(scope, @invalid_attrs)
    end

    test "create_hafiz/2 without effective_date defaults to today" do
      scope = user_scope_fixture()
      valid_attrs = %{name: "some name", daily_capacity: 42}
      
      assert {:ok, %Hafiz{} = hafiz} = Accounts.create_hafiz(scope, valid_attrs)
      assert hafiz.name == "some name"
      assert hafiz.daily_capacity == 42
      assert hafiz.effective_date == Date.utc_today()
      assert hafiz.user_id == scope.user.id
    end

    test "update_hafiz/3 with valid data updates the hafiz" do
      scope = user_scope_fixture()
      hafiz = hafiz_fixture(scope)
      update_attrs = %{name: "some updated name", daily_capacity: 43, effective_date: ~D[2025-07-29]}

      assert {:ok, %Hafiz{} = hafiz} = Accounts.update_hafiz(scope, hafiz, update_attrs)
      assert hafiz.name == "some updated name"
      assert hafiz.daily_capacity == 43
      assert hafiz.effective_date == ~D[2025-07-29]
    end

    test "update_hafiz/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      hafiz = hafiz_fixture(scope)

      assert_raise MatchError, fn ->
        Accounts.update_hafiz(other_scope, hafiz, %{})
      end
    end

    test "update_hafiz/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      hafiz = hafiz_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Accounts.update_hafiz(scope, hafiz, @invalid_attrs)
      assert hafiz == Accounts.get_hafiz!(scope, hafiz.id)
    end

    test "delete_hafiz/2 deletes the hafiz" do
      scope = user_scope_fixture()
      hafiz = hafiz_fixture(scope)
      assert {:ok, %Hafiz{}} = Accounts.delete_hafiz(scope, hafiz)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_hafiz!(scope, hafiz.id) end
    end

    test "delete_hafiz/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      hafiz = hafiz_fixture(scope)
      assert_raise MatchError, fn -> Accounts.delete_hafiz(other_scope, hafiz) end
    end

    test "change_hafiz/2 returns a hafiz changeset" do
      scope = user_scope_fixture()
      hafiz = hafiz_fixture(scope)
      assert %Ecto.Changeset{} = Accounts.change_hafiz(scope, hafiz)
    end
  end

  describe "hafiz_users" do
    alias QuranSrsPhoenix.Accounts.HafizUser

    import QuranSrsPhoenix.AccountsFixtures, only: [user_scope_fixture: 0]
    import QuranSrsPhoenix.AccountsFixtures

    @invalid_attrs %{relationship: nil}

    test "list_hafiz_users/1 returns all scoped hafiz_users" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      hafiz_user = hafiz_user_fixture(scope)
      other_hafiz_user = hafiz_user_fixture(other_scope)
      assert Accounts.list_hafiz_users(scope) == [hafiz_user]
      assert Accounts.list_hafiz_users(other_scope) == [other_hafiz_user]
    end

    test "get_hafiz_user!/2 returns the hafiz_user with given id" do
      scope = user_scope_fixture()
      hafiz_user = hafiz_user_fixture(scope)
      other_scope = user_scope_fixture()
      assert Accounts.get_hafiz_user!(scope, hafiz_user.id) == hafiz_user
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_hafiz_user!(other_scope, hafiz_user.id) end
    end

    test "create_hafiz_user/2 with valid data creates a hafiz_user" do
      valid_attrs = %{relationship: :owner}
      scope = user_scope_fixture()

      assert {:ok, %HafizUser{} = hafiz_user} = Accounts.create_hafiz_user(scope, valid_attrs)
      assert hafiz_user.relationship == :owner
      assert hafiz_user.user_id == scope.user.id
    end

    test "create_hafiz_user/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.create_hafiz_user(scope, @invalid_attrs)
    end

    test "update_hafiz_user/3 with valid data updates the hafiz_user" do
      scope = user_scope_fixture()
      hafiz_user = hafiz_user_fixture(scope)
      update_attrs = %{relationship: :parent}

      assert {:ok, %HafizUser{} = hafiz_user} = Accounts.update_hafiz_user(scope, hafiz_user, update_attrs)
      assert hafiz_user.relationship == :parent
    end

    test "update_hafiz_user/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      hafiz_user = hafiz_user_fixture(scope)

      assert_raise MatchError, fn ->
        Accounts.update_hafiz_user(other_scope, hafiz_user, %{})
      end
    end

    test "update_hafiz_user/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      hafiz_user = hafiz_user_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Accounts.update_hafiz_user(scope, hafiz_user, @invalid_attrs)
      assert hafiz_user == Accounts.get_hafiz_user!(scope, hafiz_user.id)
    end

    test "delete_hafiz_user/2 deletes the hafiz_user" do
      scope = user_scope_fixture()
      hafiz_user = hafiz_user_fixture(scope)
      assert {:ok, %HafizUser{}} = Accounts.delete_hafiz_user(scope, hafiz_user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_hafiz_user!(scope, hafiz_user.id) end
    end

    test "delete_hafiz_user/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      hafiz_user = hafiz_user_fixture(scope)
      assert_raise MatchError, fn -> Accounts.delete_hafiz_user(other_scope, hafiz_user) end
    end

    test "change_hafiz_user/2 returns a hafiz_user changeset" do
      scope = user_scope_fixture()
      hafiz_user = hafiz_user_fixture(scope)
      assert %Ecto.Changeset{} = Accounts.change_hafiz_user(scope, hafiz_user)
    end
  end
end
