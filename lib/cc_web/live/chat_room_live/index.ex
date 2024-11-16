defmodule CcWeb.ChatRoomLive.Index do
  use CcWeb, :live_view

  alias Cc.Chat

  def render(assigns) do
    temple do
      main class: "flex-1 p-6 max-w-4xl mx-auto" do
        div class: "mb-4" do
          h1 class: "text-xl font-semibold" do
            @page_title
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
                "phx-click": JS.navigate(~p"/realms/#{room}")
              do
                div do
                  div class: "font-medium mb-1" do
                    "##{room.name}"
                    span class: [
                      "mx-1 text-gray-500 font-light text-sm",
                      "opacity-0 group-hover:opacity-100",
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
                    "rounded-sm font-bold",
                  ]
                do
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
    end
  end

  def mount(_params, _session, socket) do
    {:ok, socket
      |> assign(page_title: "Realms")
      |> stream_configure(:rooms, dom_id: fn {room, _} -> "rooms-#{room.id}" end)
      |> stream(:rooms, Chat.list_rooms(socket.assigns.current_user))
    }
  end

  def handle_event("toggle-room-membership", %{"id" => id}, socket) do
    {room, joined?} =
      id
      |> Chat.get_room!()
      |> Chat.toggle_room_membership(socket.assigns.current_user)

    {:noreply, stream_insert(socket, :rooms, {room, joined?})}
  end
end
