defmodule CcWeb.RealmsLive.Realm do
  use CcWeb, :live_view

  alias Cc.Accounts
  alias Cc.Accounts.User
  alias Cc.Chat
  alias Cc.Chat.{Room, Message}
  alias CcWeb.OnlineUsers

  import CcWeb.UserComponents

  def render(assigns) do
    temple do
      div class: "flex flex-col flex-shrink-0 w-64 bg-slate-100" do
        div class: [
              "h-16 px-4",
              "flex justify-between items-center flex-shrink-0"
            ] do
          div class: "flex flex-col gap-1.5" do
            h1 class: "text-lg font-bold text-gray-800" do
              "Middle Earth"
            end
          end
        end

        div class: "mt-4 overflow-auto" do
          div class: "flex items-center h-8 px-3 cursor-pointer select-none" do
            c &toggler/1,
              dom_id: "rooms-toggler",
              text: "Realms",
              on_click: toggle_rooms()
          end

          div id: "rooms-list" do
            for {room, unread_count} <- @rooms do
              c &room_link/1,
                room: room,
                unread_count: unread_count,
                active: room.id == @room.id
            end

            button class: [
                     "group relative flex items-center h-8 text-sm",
                     "pl-8 pr-3 hover:bg-slate-300 cursor-pointer w-full"
                   ] do
              c &icon/1, name: "hero-map", class: "h-4 w-4 relative top-px"
              span class: "ml-2 leading-none", do: "Explore"

              div class: [
                    "hidden group-focus:block cursor-default absolute top-8 right-2",
                    "bg-white border-slate-200 border py-3 rounded-lg"
                  ] do
                div class: "w-full text-left" do
                  div class: "hover:bg-sky-600" do
                    div "phx-click": JS.navigate(~p"/realms"),
                        class: [
                          "cursor-pointer whitespace-nowrap text-gray-800",
                          "hover:text-white px-6 py-1"
                        ] do
                      "Shadow Realm"
                    end
                  end
                end

                div class: "hover:bg-sky-600" do
                  div "phx-click": JS.navigate(~p"/realms/#{@room}/new"),
                      class: [
                        "cursor-pointer whitespace-nowrap text-gray-800",
                        "hover:text-white px-6 py-1 block"
                      ] do
                    "New Realm"
                  end
                end
              end
            end
          end

          div class: "mt-4" do
            div class: "flex items-center h-8 px-3 group" do
              div class: "flex items-center flex-grow focus:outline-none" do
                c &toggler/1,
                  dom_id: "users-toggler",
                  text: "Users",
                  on_click: toggle_users()
              end
            end

            div id: "users-list" do
              for user <- @users do
                c &user/1, user: user, online: OnlineUsers.online?(@online_users, user)
              end
            end
          end
        end
      end

      div class: "flex flex-col flex-grow shadow-lg" do
        div class: [
              "h-16 px-4 shadow",
              "flex justify-between items-center flex-shrink-0"
            ] do
          div class: "flex flex-col gap-1.5" do
            h1 class: "text-sm font-bold leading-none" do
              "#" <> @room.name

              if @joined_room? do
                c &link/1,
                  class: "font-normal text-xs text-blue-600 hover:text-blue-700",
                  navigate: ~p"/realms/#{@room}/edit" do
                  c &icon/1, name: "hero-pencil", class: "h-4 w-4 ml-1 -mt-2"
                end
              end
            end

            div class: "text-xs leading-none h-3.5 cursor-pointer",
                "phx-click": "toggle-topic" do
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
            li class: "text-[0.8125rem] leading-6 text-zinc-900" do
              div class: "text-sm leading-10" do
                c &link/1,
                  class: "flex gap-4 items-center",
                  "phx-click": "show-profile",
                  "phx-value-user-id": @current_user.id do
                  c &user_avatar/1, class: "h-8 w-8 rounded", user: @current_user
                  span class: "hover:underline", do: @current_user.username
                end
              end
            end

            li do
              c &link/1,
                href: ~p"/users/settings",
                class: [
                  "text-[0.8125rem] leading-6 text-zinc-900",
                  "font-semibold hover:text-zinc-700"
                ] do
                "Settings"
              end
            end

            li do
              c &link/1,
                href: ~p"/users/logout",
                method: "delete",
                class: [
                  "text-[0.8125rem] leading-6 text-zinc-900",
                  "font-semibold hover:text-zinc-700"
                ] do
                "Log out"
              end
            end
          end
        end

        div id: "room-messages",
            class: "flex flex-col flex-grow overflow-auto",
            "phx-update": "stream",
            "phx-hook": "RoomMessages" do
          for {dom_id, message_or_divider} <- @streams.messages do
            case message_or_divider do
              %Message{} ->
                c &message/1,
                  message: message_or_divider,
                  current_user: @current_user,
                  dom_id: dom_id,
                  timezone: @timezone

              %Date{} ->
                div id: dom_id, class: "flex flex-col items-center mt-6" do
                  hr class: "w-full"

                  span class: [
                         "-mt-3 bg-white h-6 px-3 rounded-full border",
                         "text-xs font-semibold mx-auto",
                         "flex items-center justify-center"
                       ] do
                    format_date(message_or_divider)
                  end
                end

              :unread_marker ->
                div id: dom_id,
                    class: "w-full flex text-red-500 items-center gap-3 pr-5" do
                  div class: "w-full h-px grow bg-red-500"
                  div class: "text-sm", do: "New"
                end
            end
          end
        end

        if @joined_room? do
          div class: "h-14 shadow-2xl border-t" do
            c &form/1,
              id: "new-message-form",
              class: "flex items-center",
              for: @new_message_form,
              "phx-change": "validate-message",
              "phx-submit": "submit-message" do
              textarea id: "chat-message-textarea",
                       class: [
                         "flex-grow text-sm p-4 bg-transparent",
                         "resize-none border-none outline-none ring-0",
                         "focus:border-none focus:outline-none focus:ring-0"
                       ],
                       cols: "",
                       name: @new_message_form[:body].name,
                       placeholder: "Message ##{@room.name}",
                       "phx-debounce": true,
                       "phx-hook": "ChatMessageTextarea",
                       rows: "1" do
                Phoenix.HTML.Form.normalize_value(
                  "textarea",
                  @new_message_form[:body].value
                )
              end

              button class: [
                       "h-8 w-8 mr-2 rounded flex-shrink flex items-center justify-center",
                       "hover:bg-slate-200 transition-colors"
                     ] do
                c &icon/1, name: "hero-paper-airplane", class: "h-4 w-4"
              end
            end
          end
        end

        if !@joined_room? do
          div class: [
                "mx-5 mb-5 p-6 bg-slate-100 border-slate-300 border rounded-lg",
                "flex justify-around"
              ] do
            div class: "max-w-3-xl text-center" do
              div class: "mb-4" do
                h1 class: "text-xl font-semibold", do: "##{@room.name}"

                if @room.topic do
                  p class: "text-sm mt-1 text-gray-600", do: @room.topic
                end
              end

              div class: "flex items-center justify-around" do
                button "phx-click": "join-room",
                       class: [
                         "px-4 py-2 bg-green-600 text-white rounded hover:bg-green-600",
                         "focus:outline-none focus:ring-2 focus:ring-green-500"
                       ] do
                  "Enter realm"
                end
              end

              div class: "mt-4" do
                c &link/1,
                  navigate: ~p"/realms",
                  href: "#",
                  class: "text-sm text-slate-500 underline hover:text-slate-600" do
                  "Go back to the shadow realm "
                  c &icon/1, name: "hero-arrow-uturn-left", class: "h-4 w-4"
                end
              end
            end
          end
        end
      end

      if assigns[:profile] do
        c &live_component/1,
          id: "profile-component",
          module: CcWeb.RealmsLive.Components.Profile,
          user: @profile
      end

      c &live_component/1,
        id: "new-room-modal-component",
        module: CcWeb.RealmsLive.Components.NewRoomModal,
        current_user: @current_user,
        show: @live_action == :new,
        on_cancel: JS.navigate(~p"/realms/#{@room}")
    end
  end

  defp format_date(%Date{} = date) do
    today = Date.utc_today()

    case Date.diff(today, date) do
      0 ->
        "Today"

      1 ->
        "Yesterday"

      _ ->
        format_str = "%A, %B %e#{ordinal(date.day)}#{if today.year != date.year, do: " %Y"}"
        Timex.format!(date, format_str, :strftime)
    end
  end

  defp ordinal(day) do
    cond do
      rem(day, 10) == 1 and day != 11 -> "st"
      rem(day, 10) == 2 and day != 12 -> "nd"
      rem(day, 10) == 3 and day != 13 -> "rd"
      true -> "th"
    end
  end

  attr :dom_id, :string, required: true
  attr :text, :string, required: true
  attr :on_click, JS, required: true

  defp toggler(assigns) do
    temple do
      button id: @dom_id,
             class: "flex items-center flex-grow focus:outline-none",
             "phx-click": @on_click do
        c &icon/1,
          id: @dom_id <> "-chevron-down",
          name: "hero-chevron-down",
          class: "h-4 w-4"

        c &icon/1,
          id: @dom_id <> "-chevron-right",
          name: "hero-chevron-right",
          class: "h-4 w-4",
          style: "display:none;"

        span class: "ml-2 leading-none font-medium text-sm" do
          @text
        end
      end
    end
  end

  defp toggle_rooms() do
    JS.toggle(to: "#rooms-toggler-chevron-down")
    |> JS.toggle(to: "#rooms-toggler-chevron-right")
    |> JS.toggle(to: "#rooms-list")
  end

  defp toggle_users() do
    JS.toggle(to: "#users-toggler-chevron-down")
    |> JS.toggle(to: "#users-toggler-chevron-right")
    |> JS.toggle(to: "#users-list")
  end

  attr :active, :boolean, required: true
  attr :room, Room, required: true
  attr :unread_count, :integer, required: true

  defp room_link(assigns) do
    temple do
      c &link/1,
        patch: ~p"/realms/#{@room}",
        class: [
          "flex items-center h-8 text-sm pl-8 pr-3",
          if(@active, do: "bg-slate-300", else: "hover:bg-slate-300")
        ] do
        c &icon/1, name: "hero-hashtag", class: "h-4 w-4"
        span class: ["ml-2 leading-none", @active && "font-bold"], do: @room.name
        c &unread_message_counter/1, count: @unread_count
      end
    end
  end

  attr :message, Message, required: true
  attr :current_user, User, required: true
  attr :dom_id, :string, required: true
  attr :timezone, :string, required: true

  defp message(assigns) do
    temple do
      div id: @dom_id, class: "group relative flex px-4 py-3" do
        if @current_user.id == @message.user_id do
          button "phx-click": "delete-message",
                 "phx-value-id": @message.id,
                 "data-confirm": "Are you sure?",
                 class: [
                   "absolute top-4 right-4 text-red-500 hover:text-red-800 cursor-pointer",
                   "opacity-0 group-hover:opacity-100 transition"
                 ] do
            c &icon/1, name: "hero-trash", class: "h-4 w-4"
          end
        end

        a class: "flex-shrink-0 cursor-pointer",
          "phx-click": "show-profile",
          "phx-value-user-id": @message.user.id do
          c &user_avatar/1, class: "h-10 w-10 rounded", user: @message.user
        end

        div class: "ml-2" do
          div class: "-mt-1" do
            a class: "text-sm font-semibold hover:underline cursor-pointer",
              "phx-click": "show-profile",
              "phx-value-user-id": @message.user.id,
              do: @message.user.username

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

  attr :count, :integer, required: true

  defp unread_message_counter(assigns) do
    temple do
      if @count > 0 do
        span class: [
               "bg-blue-500 rounded-full font-medium h-5 px-2 ml-auto text-xs text-white",
               "flex items-center justify-center"
             ] do
          @count
        end
      end
    end
  end

  attr :user, User, required: true
  attr :online, :boolean, default: false

  defp user(assigns) do
    temple do
      c &link/1,
        class: "flex items-center h-8 hover:bg-gray-300 text-sm pl-8 pr-3",
        href: "#" do
        div class: "flex justify-center w-4" do
          if @online do
            span class: "w-2 h-2 rounded-full bg-blue-500"
          else
            span class: "w-2 h-2 rounded-full border-2 border-gray-500"
          end
        end

        span class: "ml-2 leading-none" do
          @user.username
        end
      end
    end
  end

  defp message_timestamp(message, timezone) do
    message.inserted_at
    |> Timex.Timezone.convert(timezone)
    |> Timex.format!("%-l:%M %p", :strftime)
  end

  defp insert_date_dividers(messages, nil), do: messages

  defp insert_date_dividers(messages, timezone) do
    messages
    |> Enum.group_by(fn message ->
      message.inserted_at
      |> DateTime.shift_zone!(timezone)
      |> DateTime.to_date()
    end)
    |> Enum.sort_by(fn {date, _msgs} -> date end, &(Date.compare(&1, &2) != :gt))
    |> Enum.flat_map(fn {date, messages} -> [date | messages] end)
  end

  defp maybe_insert_unread_marker(messages, nil), do: messages

  defp maybe_insert_unread_marker(messages, last_read_message_id) do
    {read, unread} =
      Enum.split_while(messages, fn
        %Message{} = message -> message.id <= last_read_message_id
        _ -> true
      end)

    if unread == [] do
      read
    else
      read ++ [:unread_marker] ++ unread
    end
  end

  defp assign_room_form(socket, changeset) do
    socket
    |> assign(new_room_form: to_form(changeset))
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      IO.puts("mounting (websocket connected)")
    else
      IO.puts("mounting (websocket not connected)")
    end

    timezone = get_connect_params(socket)["timezone"]

    if connected?(socket) do
      OnlineUsers.track(self(), socket.assigns.current_user)
    end

    rooms = Chat.list_joined_rooms_with_unread_counts(socket.assigns.current_user)

    OnlineUsers.subscribe()
    Enum.each(rooms, fn {room, _} -> Chat.room_pubsub_subscribe(room) end)

    socket
    |> assign(
      users: Accounts.list_users(),
      rooms: rooms,
      online_users: OnlineUsers.list(),
      timezone: timezone
    )
    |> assign_room_form(Chat.get_room_changeset(%Room{}))
    |> stream_configure(:messages,
      dom_id: fn
        %Message{id: id} -> "messages-#{id}"
        %Date{} = date -> to_string(date)
        :unread_marker -> "messages-unread-marker"
      end
    )
    |> ok()
  end

  def handle_params(params, _session, socket) do
    room =
      case params |> Map.fetch("id") do
        {:ok, id} -> Chat.get_room!(id)
        :error -> Chat.get_first_room!(socket.assigns.rooms)
      end

    messages =
      room
      |> Chat.list_messages_in_room()
      |> insert_date_dividers(socket.assigns.timezone)
      |> maybe_insert_unread_marker(
        Chat.get_last_read_message_id(room, socket.assigns.current_user)
      )

    Chat.update_last_read_message_id(room, socket.assigns.current_user)

    socket
    |> stream(:messages, messages, reset: true)
    |> assign(
      room: room,
      joined_room?: Chat.joined_room?(room, socket.assigns.current_user),
      hide_topic?: false,
      page_title: "##{room.name}",
      new_message_form: to_form(Chat.get_message_changeset(%Message{}))
    )
    |> push_event("scroll_messages_to_bottom", %{})
    |> update(:rooms, fn rooms ->
      room_id = room.id

      Enum.map(rooms, fn
        {%Room{id: ^room_id} = current_room, _} -> {current_room, 0}
        other_room -> other_room
      end)
    end)
    |> noreply()
  end

  def handle_event("show-profile", %{"user-id" => user_id}, socket) do
    socket
    |> assign(profile: Accounts.get_user!(user_id))
    |> noreply()
  end

  def handle_event("close-profile", _, socket) do
    socket
    |> assign(profile: nil)
    |> noreply()
  end

  def handle_event("toggle-topic", _params, socket) do
    socket
    |> assign(hide_topic?: !socket.assigns.hide_topic?)
    |> noreply()
  end

  def handle_event("validate-message", %{"message" => data}, socket) do
    socket
    |> assign(new_message_form: to_form(Chat.get_message_changeset(%Message{}, data)))
    |> noreply()
  end

  def handle_event("submit-message", %{"message" => data}, socket) do
    %{current_user: current_user, room: room} = socket.assigns

    if !Chat.joined_room?(room, current_user) do
      socket
    else
      case Chat.create_message(room, data, current_user) do
        {:ok, _message} ->
          socket
          |> assign(new_message_form: to_form(Chat.get_message_changeset(%Message{})))

        {:error, changeset} ->
          socket
          |> assign(new_message_form: to_form(changeset))
      end
    end
    |> noreply()
  end

  def handle_event("delete-message", %{"id" => id}, socket) do
    Chat.delete_message(id, socket.assigns.current_user)

    socket
    |> noreply()
  end

  def handle_event("join-room", _, socket) do
    current_user = socket.assigns.current_user
    Chat.join_room!(socket.assigns.room, current_user)
    Chat.room_pubsub_subscribe(socket.assigns.room)

    socket
    |> assign(
      joined_room?: true,
      rooms: Chat.list_joined_rooms_with_unread_counts(current_user)
    )
    |> noreply()
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
    case Chat.create_room(room_params) do
      {:ok, room} ->
        Chat.join_room!(room, socket.assigns.current_user)

        socket
        |> put_flash(:info, "Created realm")
        |> push_navigate(to: ~p"/realms/#{room}")
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign_room_form(changeset)
        |> noreply()
    end
  end

  def handle_info({:new_message, message}, socket) do
    room = socket.assigns.room

    cond do
      message.room_id == room.id ->
        Chat.update_last_read_message_id(room, socket.assigns.current_user)

        socket
        |> stream_insert(:messages, message)
        |> push_event("scroll_messages_to_bottom", %{})

      message.user_id != socket.assigns.current_user.id ->
        socket
        |> update(:rooms, fn rooms ->
          Enum.map(rooms, fn
            {%Room{id: id} = room, count} when id == message.room_id ->
              {room, count + 1}

            other ->
              other
          end)
        end)

      true ->
        socket
    end
    |> noreply()
  end

  def handle_info({:message_deleted, message}, socket) do
    socket
    |> stream_delete(:messages, message)
    |> noreply()
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket
    |> assign(online_users: OnlineUsers.update(socket.assigns.online_users, diff))
    |> noreply()
  end
end
