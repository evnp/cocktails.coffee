defmodule CcWeb.ChatRoomLive do
  use CcWeb, :live_view

  alias Cc.Chat
  alias Cc.Chat.{Room, Message}

  def render(assigns) do
    temple do
      div class: "flex flex-col flex-shrink-0 w-64 bg-slate-100" do
        div class: [
          "h-16 px-4",
          "flex justify-between items-center flex-shrink-0",
        ] do
          div class: "flex flex-col gap-1.5" do
            h1 class: "text-lg font-bold text-gray-800" do
              "Middle Earth"
            end
          end
        end
        div class: "mt-4 overflow-auto" do
          div class: "flex items-center h-8 px-3 group" do
            span class: "ml-2 leading-none font-medium text-sm", do: "Realms"
          end
          div id: "rooms-list" do
            for room <- @rooms do
              c &room_link/1, room: room, active: room.id == @room.id
            end
          end
        end
      end
      div class: "flex flex-col flex-grow shadow-lg" do
        div class: [
          "h-16 px-4 shadow",
          "flex justify-between items-center flex-shrink-0",
        ] do
          div class: "flex flex-col gap-1.5" do
            h1 class: "text-sm font-bold leading-none" do
              "#" <> @room.name
              c &link/1,
                class: "font-normal text-xs text-blue-600 hover:text-blue-700",
                navigate: ~p"/realms/#{@room}/edit"
              do
                c &icon/1, name: "hero-pencil", class: "h-4 w-4 ml-1 -mt-2"
              end
            end
            div class: "text-xs leading-none h-3.5 cursor-pointer",
              "phx-click": "toggle-topic"
            do
              if @hide_topic? do
                span class: "text-slate-600", do: "[Topic hidden]"
              else
                @room.topic
              end
            end
          end
          ul class: [
            "relative z-10 flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end"
          ] do
            if @current_user do
              li class: "text-[0.8125rem] leading-6 text-zinc-900" do
                username(@current_user)
              end
              li do
                c &link/1,
                  href: ~p"/users/settings",
                  class: [
                    "text-[0.8125rem] leading-6 text-zinc-900",
                    "font-semibold hover:text-zinc-700",
                  ]
                do
                  "Settings"
                end
              end
              li do
                c &link/1,
                  href: ~p"/users/logout",
                  method: "delete",
                  class: [
                    "text-[0.8125rem] leading-6 text-zinc-900",
                    "font-semibold hover:text-zinc-700",
                  ]
                do
                  "Log out"
                end
              end
            else
              li do
                c &link/1,
                  href: ~p"/users/register",
                  class: [
                    "text-[0.8125rem] leading-6 text-zinc-900",
                    "font-semibold hover:text-zinc-700",
                  ]
                do
                  "Register"
                end
              end
              li do
                c &link/1,
                  href: ~p"/users/login",
                  class: [
                    "text-[0.8125rem] leading-6 text-zinc-900",
                    "font-semibold hover:text-zinc-700",
                  ]
                do
                  "Log in"
                end
              end
            end
          end
        end
        div id: "room-messages",
          class: "flex flex-col flex-grow overflow-auto",
          "phx-update": "stream"
        do
          for {dom_id, message} <- @streams.messages do
            c &message/1, dom_id: dom_id, message: message, timezone: @timezone
          end
        end
        div class: "h-14 shadow-2xl border-t" do
          c &form/1,
            id: "new-message-form",
            class: "flex items-center",
            for: @new_message_form,
            "phx-change": "validate-message",
            "phx-submit": "submit-message"
          do
            textarea id: "chat-message-textarea",
              class: [
                "flex-grow text-sm p-4 bg-transparent",
                "resize-none border-none outline-none ring-0",
                "focus:border-none focus:outline-none focus:ring-0",
              ],
              cols: "",
              name: @new_message_form[:body].name,
              placeholder: "Message ##{@room.name}",
              "phx-debounce": true,
              rows: "1"
            do
              Phoenix.HTML.Form.normalize_value(
                "textarea", @new_message_form[:body].value
              )
            end
            button class: [
              "h-8 w-8 mr-2 rounded flex-shrink flex items-center justify-center",
              "hover:bg-slate-200 transition-colors",
            ] do
              c &icon/1, name: "hero-paper-airplane", class: "h-4 w-4"
            end
          end
        end
      end
    end
  end

  attr :active, :boolean, required: true
  attr :room, Room, required: true
  defp room_link(assigns) do
    temple do
      c &link/1, patch: ~p"/realms/#{@room}", class: [
        "flex items-center h-8 text-sm pl-8 pr-3",
        (if @active, do: "bg-slate-300", else: "hover:bg-slate-300")
      ] do
        c &icon/1, name: "hero-hashtag", class: "h-4 w-4"
        span class: ["ml-2 leading-none", @active && "font-bold"], do: @room.name
      end
    end
  end

  attr :message, Message, required: true
  attr :dom_id, :string, required: true
  attr :timezone, :string, required: true
  defp message(assigns) do
    temple do
      div id: @dom_id, class: "relative flex px-4 py-3" do
        div class: "h-10 w-10 rounded flex-shrink-0 bg-slate-300"
        div class: "ml-2" do
          div class: "-mt-1" do
            c &link/1, class: "text-sm font-semibold hover:underline" do
              span do: username(@message.user)
            end
            if @timezone do
              span class: "ml-1 text-xs text-gray-500" do
                message_timestamp(@message, @timezone)
              end
            end
            p class: "text-sm", do: @message.body
          end
        end
      end
    end
  end

  defp username(user) do
    user.email |> String.split("@") |> List.first() |> String.capitalize()
  end

  defp message_timestamp(message, timezone) do
    message.inserted_at
    |> Timex.Timezone.convert(timezone)
    |> Timex.format!("%-l:%M %p", :strftime)
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      IO.puts("mounting (websocket connected)")
    else
      IO.puts("mounting (websocket not connected)")
    end

    timezone = get_connect_params(socket)["timezone"]

    {:ok, assign(socket, rooms: Chat.list_rooms(), timezone: timezone)}
  end

  def handle_params(params, _session, socket) do
    room = case params |> Map.fetch("id") do
      {:ok, id} -> Chat.get_room!(id)
      :error -> Chat.get_first_room!(socket.assigns.rooms)
    end

    {:noreply,
      socket
      |> stream(:messages, Chat.list_messages_in_room(room), reset: true)
      |> assign(
        room: room,
        hide_topic?: false,
        page_title: "Cocktails.Coffee. #" <> room.name,
        new_message_form: to_form(Chat.get_message_changeset(%Message{}))
      )
    }
  end

  def handle_event("toggle-topic", _params, socket) do
    {:noreply,
      assign(socket, hide_topic?: !socket.assigns.hide_topic?)
    }
  end

  def handle_event("validate-message", %{"message" => message_params}, socket) do
    {:noreply,
      assign(socket,
        new_message_form:
          to_form(Chat.get_message_changeset(%Message{}, message_params))
      )
    }
  end

  def handle_event("submit-message", %{"message" => message_params}, socket) do
    %{current_user: current_user, room: room} = socket.assigns
    {:noreply,
      case Chat.create_message(room, message_params, current_user) do
        {:ok, message} -> socket
          |> stream_insert(:messages, message)
          |> assign(new_message_form: to_form(Chat.get_message_changeset(%Message{})))
        {:error, changeset} -> socket
          |> assign(new_message_form: to_form(changeset))
      end
    }
  end
end
