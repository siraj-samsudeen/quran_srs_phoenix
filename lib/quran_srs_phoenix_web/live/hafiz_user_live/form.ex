defmodule QuranSrsPhoenixWeb.HafizUserLive.Form do
  use QuranSrsPhoenixWeb, :live_view

  alias QuranSrsPhoenix.Accounts
  alias QuranSrsPhoenix.Accounts.HafizUser
  alias QuranSrsPhoenix.Permissions

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title} for "<%= @hafiz.name %>"
        <:subtitle>
          Add or modify user access to this hafiz profile with a specific relationship type.
        </:subtitle>
        <:actions>
          <.button variant="outline" navigate={~p"/hafizs/#{@hafiz.id}/users"}>
            <.icon name="hero-arrow-left" /> Back to Users
          </.button>
        </:actions>
      </.header>

      <div class="max-w-2xl">
        <.form for={@form} id="hafiz_user-form" phx-change="validate" phx-submit="save">
          <div class="grid gap-6">
            <div class="card bg-base-100 shadow-md">
              <div class="card-body">
                <div class="flex items-center gap-3 mb-4">
                  <.icon name="hero-user-plus" class="w-6 h-6 text-primary" />
                  <h3 class="text-lg font-semibold">User Information</h3>
                </div>
                
                <div :if={@live_action == :new}>
                  <.input
                    field={@form[:user_email]}
                    type="email"
                    label="User Email"
                    placeholder="Enter the email address of the user to add"
                    required
                  />
                  <p class="text-sm text-base-content/70 mt-2">
                    The user must already have an account on the system. They will gain access based on the relationship type you select below.
                  </p>
                </div>
                
                <div :if={@live_action == :edit}>
                  <div class="alert alert-info">
                    <.icon name="hero-information-circle" />
                    <span>Editing access for: <strong><%= @hafiz_user.user.email %></strong></span>
                  </div>
                </div>
              </div>
            </div>

            <div class="card bg-base-100 shadow-md">
              <div class="card-body">
                <div class="flex items-center gap-3 mb-4">
                  <.icon name="hero-user-group" class="w-6 h-6 text-primary" />
                  <h3 class="text-lg font-semibold">Relationship Type</h3>
                </div>
                
                <.input
                  field={@form[:relationship]}
                  type="select"
                  label="What is this user's relationship to the hafiz?"
                  prompt="Select relationship type"
                  options={[
                    {"Parent - Parent or guardian with oversight", :parent},
                    {"Teacher - Educational supervisor with authority", :teacher}, 
                    {"Student - The hafiz themselves", :student},
                    {"Family - Family member with supportive access", :family}
                  ]}
                />
                
                <div class="mt-4 p-4 bg-base-200 rounded-lg">
                  <h4 class="font-medium mb-2">Relationship Permissions:</h4>
                  <div :if={@selected_relationship_permissions} class="grid grid-cols-2 gap-2 text-sm">
                    <div class="flex items-center gap-2">
                      <.icon name={if @selected_relationship_permissions.can_view_progress, do: "hero-check-circle", else: "hero-x-circle"} 
                             class={["w-4 h-4", if(@selected_relationship_permissions.can_view_progress, do: "text-success", else: "text-error")]} />
                      <span>View Progress</span>
                    </div>
                    <div class="flex items-center gap-2">
                      <.icon name={if @selected_relationship_permissions.can_edit_details, do: "hero-check-circle", else: "hero-x-circle"} 
                             class={["w-4 h-4", if(@selected_relationship_permissions.can_edit_details, do: "text-success", else: "text-error")]} />
                      <span>Edit Details</span>
                    </div>
                    <div class="flex items-center gap-2">
                      <.icon name={if @selected_relationship_permissions.can_manage_users, do: "hero-check-circle", else: "hero-x-circle"} 
                             class={["w-4 h-4", if(@selected_relationship_permissions.can_manage_users, do: "text-success", else: "text-error")]} />
                      <span>Manage Users</span>
                    </div>
                    <div class="flex items-center gap-2">
                      <.icon name={if @selected_relationship_permissions.can_edit_preferences, do: "hero-check-circle", else: "hero-x-circle"} 
                             class={["w-4 h-4", if(@selected_relationship_permissions.can_edit_preferences, do: "text-success", else: "text-error")]} />
                      <span>Edit Preferences</span>
                    </div>
                  </div>
                  <p class="text-xs text-base-content/70 mt-2">
                    These permissions can be customized in the Permission Configuration section.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <footer class="flex gap-3 mt-6">
            <.button phx-disable-with="Saving..." variant="primary">
              <.icon name="hero-check" />
              <%= if @live_action == :new, do: "Add User", else: "Update Access" %>
            </.button>
            <.button type="button" variant="outline" navigate={~p"/hafizs/#{@hafiz.id}/users"}>
              <.icon name="hero-x-mark" /> Cancel
            </.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"hafiz_id" => hafiz_id} = params, _session, socket) do
    scope = socket.assigns.current_scope
    hafiz = Accounts.get_hafiz!(scope, hafiz_id)
    
    {:ok,
     socket
     |> assign(:hafiz, hafiz)
     |> assign(:selected_relationship_permissions, nil)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    scope = socket.assigns.current_scope
    hafiz_user = Accounts.get_hafiz_user!(scope, id)
    permissions = Permissions.get_relationship_permission(scope, hafiz_user.relationship)

    changeset = Accounts.change_hafiz_user(scope, hafiz_user)
    form = to_form(changeset)

    socket
    |> assign(:page_title, "Edit User Access")
    |> assign(:hafiz_user, hafiz_user)
    |> assign(:form, form)
    |> assign(:selected_relationship_permissions, permissions)
  end

  defp apply_action(socket, :new, %{"hafiz_id" => hafiz_id}) do
    scope = socket.assigns.current_scope
    hafiz_user = %HafizUser{hafiz_id: String.to_integer(hafiz_id)}

    changeset = 
      Accounts.change_hafiz_user(scope, hafiz_user, %{})
      |> Ecto.Changeset.put_change(:user_email, "")
    
    form = to_form(changeset)

    socket
    |> assign(:page_title, "Add User Access")
    |> assign(:hafiz_user, hafiz_user)
    |> assign(:form, form)
    |> assign(:selected_relationship_permissions, nil)
  end

  @impl true
  def handle_event("validate", %{"hafiz_user" => hafiz_user_params}, socket) do
    scope = socket.assigns.current_scope
    changeset = Accounts.change_hafiz_user(scope, socket.assigns.hafiz_user, hafiz_user_params)
    
    # Update permissions preview when relationship changes
    permissions = case hafiz_user_params["relationship"] do
      relationship when relationship in ["parent", "teacher", "student", "family"] ->
        relationship_atom = String.to_atom(relationship)
        Permissions.get_relationship_permission(scope, relationship_atom)
      _ -> 
        nil
    end
    
    socket = assign(socket, :selected_relationship_permissions, permissions)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"hafiz_user" => hafiz_user_params}, socket) do
    save_hafiz_user(socket, socket.assigns.live_action, hafiz_user_params)
  end

  defp save_hafiz_user(socket, :edit, hafiz_user_params) do
    scope = socket.assigns.current_scope
    hafiz = socket.assigns.hafiz
    
    case Accounts.update_hafiz_user(scope, socket.assigns.hafiz_user, hafiz_user_params) do
      {:ok, _hafiz_user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User access updated successfully")
         |> push_navigate(to: ~p"/hafizs/#{hafiz.id}/users")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_hafiz_user(socket, :new, hafiz_user_params) do
    scope = socket.assigns.current_scope
    hafiz = socket.assigns.hafiz
    
    case Accounts.create_hafiz_user(scope, hafiz_user_params) do
      {:ok, _hafiz_user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User access added successfully")
         |> push_navigate(to: ~p"/hafizs/#{hafiz.id}/users")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
