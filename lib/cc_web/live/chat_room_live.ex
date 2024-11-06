defmodule CCWeb.ChatRoomLive do
  use CCWeb, :live_view

  alias CC.Repo
  alias CC.Chat.Room

  def render(assigns) do
    IO.puts("rendering")
    ~H"""
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

  def mount(_params, _session, socket) do
    if connected?(socket) do
      IO.puts("mounting (connected)")
    else
      IO.puts("mounting (not connected)")
    end

    room = Room |> Repo.all() |> List.first()

    {:ok, socket
      |> assign(:room, room)
      |> assign(:hide_topic?, false)
    }
  end

  def handle_event("toggle-topic", _params, socket) do
    {:noreply, socket
      |> assign(:hide_topic?, !socket.assigns.hide_topic?)
    }
  end
end
