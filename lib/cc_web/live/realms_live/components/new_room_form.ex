defmodule CcWeb.RealmsLive.Components.NewRoomForm do
  use CcWeb, :live_component

  alias Cc.Chat
  alias Cc.Chat.Room

  import CcWeb.RoomComponents

  def render(assigns) do
    temple do
      div id: "new-room-form" do
        c &room_form/1, form: @form, target: @myself
      end
    end
  end

  def mount(socket) do
    socket
    |> assign_form(Chat.get_room_changeset(%Room{}))
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(current_user: assigns.current_user)
    |> ok()
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  def handle_event("validate-room", %{"room" => room_params}, socket) do
    changeset =
      %Room{}
      |> Chat.get_room_changeset(room_params)
      |> Map.put(:action, :validate)

    socket
    |> assign_form(changeset)
    |> noreply()
  end

  def handle_event("save-room", %{"room" => room_params}, socket) do
    case Chat.create_room(room_params) do
      {:ok, room} ->
        Chat.join_room!(room, socket.assigns.current_user)

        socket
        |> put_flash(:info, "Created realm")
        |> push_navigate(to: ~p"/realms/#{room}")
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign_form(changeset)
        |> noreply()
    end
  end
end
