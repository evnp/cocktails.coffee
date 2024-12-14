defmodule CcWeb.RealmsLive.WorldMap do
  use CcWeb, :live_view

  alias Cc.Chat
  alias Cc.Chat.Room

  def render(assigns) do
    temple do
      main class: "flex-1 p-6 max-w-4xl mx-auto" do
        div class: "flex justify-between mb-4 items-center" do
          h1 class: "text-xl font-semibold", do: @page_title

          button "phx-click": JS.navigate(~p"/realms/new"),
                 class: [
                   "bg-white font-semibold py-2 px-4 border border-slate-400",
                   "rounded shadow-sm"
                 ] do
            "Create realm"
          end
        end

        div class: "bg-slate-50 border rounded" do
          div id: "rooms", "phx-update": "stream", class: "divide-y" do
            for {id, {room, joined_room?}} <- @streams.rooms do
              div id: id,
                  class: [
                    "group p-4 cursor-pointer first:rounded-t last:rounded-b",
                    "flex justify-between items-center"
                  ],
                  "phx-value-id": room.id,
                  "phx-click": JS.navigate(~p"/realms/#{room}") do
                div do
                  div class: "font-medium mb-1" do
                    "##{room.name}"

                    span class: [
                           "mx-1 text-gray-500 font-light text-sm",
                           "opacity-0 group-hover:opacity-100"
                         ] do
                      "View room"
                    end
                  end

                  div class: "text-gray-500 text-sm" do
                    if joined_room? do
                      span class: "text-green-600 font-bold", do: "✓ Joined"
                    end

                    if joined_room? && room.topic do
                      span class: "mx-1", do: "·"
                    end

                    if room.topic do
                      room.topic
                    end
                  end
                end

                button "phx-click": "toggle-room-membership",
                       "phx-value-id": room.id,
                       class: [
                         "opacity-0 group-hover:opacity-100 bg-white hover:bg-gray-100",
                         "border border-gray-400 text-gray-700 px-3 py-1.5",
                         "rounded-sm font-bold"
                       ] do
                  if joined_room? do
                    "Leave realm"
                  else
                    "Enter realm"
                  end
                end
              end
            end
          end
        end
      end

      c &live_component/1,
        id: "new-room-modal-component",
        module: CcWeb.RealmsLive.Components.NewRoomModal,
        current_user: @current_user,
        show: @live_action == :new,
        on_cancel: JS.navigate(~p"/realms")
    end
  end

  def mount(_params, _session, socket) do
    changeset = Chat.get_room_changeset(%Room{})

    {:ok,
     socket
     |> assign(page_title: "Shadow Realm")
     |> assign_form(changeset)
     |> stream_configure(:rooms, dom_id: fn {room, _} -> "rooms-#{room.id}" end)
     |> stream(:rooms, Chat.list_rooms(socket.assigns.current_user))}
  end

  def handle_event("toggle-room-membership", %{"id" => id}, socket) do
    {room, joined?} =
      id
      |> Chat.get_room!()
      |> Chat.toggle_room_membership(socket.assigns.current_user)

    {:noreply, stream_insert(socket, :rooms, {room, joined?})}
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
