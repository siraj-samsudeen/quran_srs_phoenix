defmodule QuranSrsPhoenixWeb.HafizLive.Form do
  use QuranSrsPhoenixWeb, :live_view

  alias QuranSrsPhoenix.Accounts
  alias QuranSrsPhoenix.Accounts.Hafiz

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage hafiz records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="hafiz-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:daily_capacity]} type="number" label="Daily capacity" />
        <.input field={@form[:effective_date]} type="date" label="Effective date" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Hafiz</.button>
          <.button navigate={return_path(@current_scope, @return_to, @hafiz)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    hafiz = Accounts.get_hafiz!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Hafiz")
    |> assign(:hafiz, hafiz)
    |> assign(:form, to_form(Accounts.change_hafiz(socket.assigns.current_scope, hafiz)))
  end

  defp apply_action(socket, :new, _params) do
    hafiz = %Hafiz{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Hafiz")
    |> assign(:hafiz, hafiz)
    |> assign(:form, to_form(Accounts.change_hafiz(socket.assigns.current_scope, hafiz)))
  end

  @impl true
  def handle_event("validate", %{"hafiz" => hafiz_params}, socket) do
    changeset = Accounts.change_hafiz(socket.assigns.current_scope, socket.assigns.hafiz, hafiz_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"hafiz" => hafiz_params}, socket) do
    save_hafiz(socket, socket.assigns.live_action, hafiz_params)
  end

  defp save_hafiz(socket, :edit, hafiz_params) do
    case Accounts.update_hafiz(socket.assigns.current_scope, socket.assigns.hafiz, hafiz_params) do
      {:ok, hafiz} ->
        {:noreply,
         socket
         |> put_flash(:info, "Hafiz updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, hafiz)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_hafiz(socket, :new, hafiz_params) do
    case Accounts.create_hafiz(socket.assigns.current_scope, hafiz_params) do
      {:ok, hafiz} ->
        {:noreply,
         socket
         |> put_flash(:info, "Hafiz created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, hafiz)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _hafiz), do: ~p"/hafizs"
  defp return_path(_scope, "show", hafiz), do: ~p"/hafizs/#{hafiz}"
end
