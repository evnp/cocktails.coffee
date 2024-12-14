defmodule CcWeb.RealmsLive.Edit do
  use CcWeb, :live_view

  alias Cc.Chat

  import CcWeb.RoomComponents

  def render(assigns) do
    temple do
      div class: "mx-auto w-96 mt-12" do
        c &header/1 do
          slot :actions do
            c &link/1,
              class: "font-normal text-xs text-blue-600 hover:text-blue-700",
              navigate: ~p"/realms/#{@room}" do
              c &icon/1, name: "hero-arrow-uturn-left", class: "h-4 w-4"
            end
          end

          @page_title
        end

        c &room_form/1, form: @edit_room_form
      end
    end
  end

  def mount(%{"id" => id}, _session, socket) do
    room = Chat.get_room!(id)

    if Chat.joined_room?(room, socket.assigns.current_user) do
      socket
      |> assign(page_title: "Edit chat room", room: room)
      |> assign_room_form(Chat.get_room_changeset(room))
      |> ok()
    else
      socket
      |> put_flash(:error, "You shall not pass.")
      |> push_navigate(to: ~p"/")
      |> ok()
    end
  end

  def handle_event("validate-room", %{"room" => room_params}, socket) do
    socket
    |> assign_room_form(
      socket.assigns.room
      |> Chat.get_room_changeset(room_params)
      |> Map.put(:action, :validate)
    )
    |> noreply()
  end

  def handle_event("save-room", %{"room" => room_params}, socket) do
    case Chat.update_room(socket.assigns.room, room_params) do
      {:ok, room} ->
        socket
        |> put_flash(:info, "Room updated successfully")
        |> push_navigate(to: ~p"/realms/#{room}")
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign_room_form(changeset)
        |> noreply()
    end
  end

  defp assign_room_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(edit_room_form: to_form(changeset))
  end
end
