defmodule CCWeb.ChatRoomLive do
  use CCWeb, :live_view

  alias CC.Chat
  alias CC.Chat.Room

  def render(assigns) do
    IO.puts("rendering")
    ~H"""
    <div class="flex flex-col flex-shrink-0 w-64 bg-slate-100">
      <div class="flex justify-between items-center flex-shrink-0 h-16 border-b border-slate-300 px-4">
        <div class="flex flex-col gap-1.5">
          <h1 class="text-lg font-bold text-gray-800">
            Middle Earth
          </h1>
        </div>
      </div>
      <div class="mt-4 overflow-auto">
        <div class="flex items-center h-8 px-3 group">
          <span class="ml-2 leading-none font-medium text-sm">Realms</span>
        </div>
        <div id="rooms-list">
          <.room_link :for={room <- @rooms} room={room} active={room.id == @room.id} />
        </div>
      </div>
    </div>
    <div class="flex flex-col flex-grow shadow-lg">
      <div class="flex justify-between items-center flex-shrink-0 h-16 bg-white border-b border-slate-300 px-4">
        <div class="flex flex-col gap-1.5">
          <h1 class="text-sm font-bold leading-none">
            #<%= @room.name %>
          </h1>
          <div class="text-xs leading-none h-3.5 cursor-pointer" phx-click="toggle-topic">
            <%= if @hide_topic? do %>
              <span class="text-slate-600">[Topic hidden]</span>
            <% else %>
              <%= @room.topic %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :active, :boolean, required: true
  attr :room, Room, required: true
  defp room_link(assigns) do
    ~H"""
    <.link
      patch={~p"/rooms/#{@room}"}
      class={[
        "flex items-center h-8 text-sm pl-8 pr-3",
        (if @active, do: "bg-slate-300", else: "hover:bg-slate-300")
      ]}
    >
      <.icon name="hero-hashtag" class="h-4 w-4" />
      <span class={["ml-2 leading-none", @active && "font-bold"]}>
        <%= @room.name %>
      </span>
    </.link>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      IO.puts("mounting (connected)")
    else
      IO.puts("mounting (not connected)")
    end
    {:ok, assign(socket, rooms: Chat.list_rooms())}
  end

  def handle_params(params, _session, socket) do
    room = case params |> Map.fetch("id") do
      {:ok, id} -> Chat.get_room!(id)
      :error -> Chat.get_first_room!(socket.assigns.rooms)
    end
    {:noreply, socket
      |> assign(room: room)
      |> assign(hide_topic?: false)
      |> assign(page_title: "Cocktails.Coffee. #" <> room.name)
    }
  end

  def handle_event("toggle-topic", _params, socket) do
    {:noreply, socket
      |> assign(hide_topic?: !socket.assigns.hide_topic?)
    }
  end
end
