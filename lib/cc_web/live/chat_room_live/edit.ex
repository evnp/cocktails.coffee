defmodule CCWeb.ChatRoomLive.Edit do
  use CCWeb, :live_view

  alias CC.Chat

  def render(assigns) do
    temple do
      div class: "mx-auto w-96 mt-12" do
        c &header/1 do
          slot :actions do
            c &link/1,
              class: "font-normal text-xs text-blue-600 hover:text-blue-700",
              navigate: ~p"/realms/#{@room}"
            do
              c &icon/1, name: "hero-arrow-uturn-left", class: "h-4 w-4"
            end
          end
          @page_title
        end
        c &simple_form/1,
          id: "room-form",
          for: @form,
          "phx-change": "validate-room",
          "phx-submit": "save-room"
        do
          slot :actions do
            c &button/1, "phx-disable-with": "Saving...", class: "w-full", do: "Save"
          end
          c &input/1,
            field: @form[:name],
            type: "text",
            label: "Name",
            "phx-debounce": true
          c &input/1,
            field: @form[:topic],
            type: "text",
            label: "Topic",
            "phx-debounce": true
        end
      end
    end
  end

  def mount(%{"id" => id}, _session, socket) do
    room = Chat.get_room!(id)
    {:ok, socket
      |> assign(page_title: "Edit chat room", room: room)
      |> assign_form(Chat.get_room_changeset(room))
    }
  end

  def handle_event("validate-room", %{"room" => room_params}, socket) do
    changeset = socket.assigns.room
      |> Chat.get_room_changeset(room_params)
      |> Map.put(:action, :validate)
    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save-room", %{"room" => room_params}, socket) do
    case Chat.update_room(socket.assigns.room, room_params) do
      {:ok, room} -> {:noreply, socket
        |> put_flash(:info, "Room updated successfully")
        |> push_navigate(to: ~p"/realms/#{room}")
      }
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply,
        assign_form(socket, changeset)
      }
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
