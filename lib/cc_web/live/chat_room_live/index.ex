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
          div id: "rooms", class: "divide-y", "phx-update": "stream" do
            for {id, room} <- @streams.rooms do
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
                    if room.topic do
                      room.topic
                    end
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
      |> stream(:rooms, Chat.list_rooms())
    }
  end
end
