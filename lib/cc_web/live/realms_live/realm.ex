defmodule CcWeb.RealmsLive.Realm do
  use CcWeb, :live_view

  alias Cc.Accounts
  alias Cc.Accounts.User
  alias Cc.Chat
  alias Cc.Chat.{Room, Message}
  alias CcWeb.OnlineUsers

  import CcWeb.UserComponents
  import CcWeb.ChatComponents

  def render(assigns) do
    temple do
      div class: ~u"flex flex-col flex-shrink-0 w-64 bg-slate-100" do
        div class: ~u"flex justify-between items-center flex-shrink-0 h-16 px-4" do
          div class: ~u"flex flex-col gap-1.5" do
            h1 class: ~u"text-lg font-bold text-gray-800" do
              "Middle Earth"
            end
          end
        end

        div class: ~u"mt-4 overflow-auto" do
          div class: ~u"flex items-center h-8 px-3 cursor-pointer select-none" do
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

            button class: ~u"flex items-center group relative h-8 text-sm
                             pl-8 pr-3 hover:bg-slate-300 cursor-pointer w-full"
            do
              c &icon/1, name: "hero-map", class: ~u"h-4 w-4 relative top-px"
              span class: ~u"ml-2 leading-none", do: "Explore"

              div class: ~u"hidden group-focus:block cursor-default absolute top-8
                            right-2 bg-white border-slate-200 border py-3 rounded-lg"
              do
                div class: ~u"w-full text-left" do
                  div class: ~u"hover:bg-sky-600" do
                    div "phx-click": JS.navigate(~p"/realms"),
                        class: ~u"cursor-pointer whitespace-nowrap text-gray-800
                                  hover:text-white px-6 py-1"
                    do
                      "Shadow Realm"
                    end
                  end
                end

                div class: ~u"hover:bg-sky-600" do
                  div "phx-click": JS.navigate(~p"/realms/#{@room}/new"),
                      class: ~u"cursor-pointer whitespace-nowrap text-gray-800
                                hover:text-white px-6 py-1 block"
                  do
                    "New Realm"
                  end
                end
              end
            end
          end

          div class: ~u"mt-4" do
            div class: ~u"flex items-center h-8 px-3 group" do
              div class: ~u"flex items-center flex-grow focus:outline-none" do
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

      div class: ~u"flex flex-col flex-grow shadow-lg" do
        div class: ~u"flex justify-between items-center flex-shrink-0
                      h-16 px-4 shadow"
        do
          div class: ~u"flex flex-col gap-1.5" do
            h1 class: ~u"text-sm font-bold leading-none" do
              "#" <> @room.name

              if @joined_room? do
                c &link/1,
                  class: ~u"font-normal text-xs text-blue-600 hover:text-blue-700",
                  navigate: ~p"/realms/#{@room}/edit"
                do
                  c &icon/1, name: "hero-pencil", class: ~u"h-4 w-4 ml-1 -mt-2"
                end
              end
            end

            div class: ~u"text-xs leading-none h-3.5 cursor-pointer",
                "phx-click": "toggle-topic"
            do
              if @hide_topic? do
                span class: ~u"text-slate-600", do: "[Topic hidden]"
              else
                @room.topic
              end
            end
          end

          ul class: ~u"flex items-center gap-4
                       relative z-10 px-4 sm:px-6 lg:px-8 justify-end"
          do
            li class: ~u"text-[0.8125rem] leading-6 text-zinc-900" do
              div class: ~u"text-sm leading-10" do
                c &link/1,
                  class: ~u"flex gap-4 items-center",
                  "phx-click": "show-profile",
                  "phx-value-user-id": @current_user.id
                do
                  c &user_avatar/1, class: ~u"h-8 w-8 rounded", user: @current_user
                  span class: ~u"hover:underline", do: @current_user.username
                end
              end
            end

            li do
              c &link/1,
                href: ~p"/users/settings",
                class: ~u"text-[0.8125rem] leading-6 text-zinc-900
                          font-semibold hover:text-zinc-700"
              do
                "Settings"
              end
            end

            li do
              c &link/1,
                href: ~p"/users/logout",
                method: "delete",
                class: ~u"text-[0.8125rem] leading-6 text-zinc-900
                          font-semibold hover:text-zinc-700"
              do
                "Log out"
              end
            end
          end
        end

        div id: "room-messages",
            class: ~u"flex flex-col flex-grow overflow-auto",
            "phx-update": "stream",
            "phx-hook": "RoomMessages"
        do
          for {dom_id, message_or_divider} <- @streams.messages do
            case message_or_divider do
              %Message{} ->
                c &message_or_reply/1,
                  message_or_reply: message_or_divider,
                  current_user: @current_user,
                  dom_id: dom_id,
                  timezone: @timezone

              %Date{} ->
                div id: dom_id, class: ~u"flex flex-col items-center mt-6" do
                  hr class: ~u"w-full"

                  span class: ~u"-mt-3 bg-white h-6 px-3 rounded-full border
                                 text-xs font-semibold mx-auto
                                 flex items-center justify-center"
                  do
                    format_date(message_or_divider)
                  end
                end

              :unread_marker ->
                div id: dom_id,
                    class: ~u"w-full flex text-red-500 items-center gap-3 pr-5"
                do
                  div class: ~u"w-full h-px grow bg-red-500"
                  div class: ~u"text-sm", do: "New"
                end
            end
          end
        end

        if @joined_room? do
          div class: ~u"h-14 shadow-2xl border-t" do
            c &form/1,
              id: "new-message-form",
              class: ~u"flex items-center",
              for: @new_message_form,
              "phx-change": "validate-message",
              "phx-submit": "submit-message"
            do
              textarea id: "chat-message-textarea",
                       class: ~u"flex-grow text-sm p-4 bg-transparent
                                 resize-none border-none outline-none ring-0
                                 focus:border-none focus:outline-none focus:ring-0",
                       cols: "",
                       name: @new_message_form[:body].name,
                       placeholder: "Message ##{@room.name}",
                       "phx-debounce": true,
                       "phx-hook": "ChatMessageTextarea",
                       rows: "1"
              do
                Phoenix.HTML.Form.normalize_value(
                  "textarea",
                  @new_message_form[:body].value
                )
              end

              button class: ~u"flex-shrink flex items-center justify-center rounded
                               hover:bg-slate-200 transition-colors h-8 w-8 mr-2"
              do
                c &icon/1, name: "hero-paper-airplane", class: ~u"h-4 w-4"
              end
            end
          end
        end

        if !@joined_room? do
          div class: ~u"flex justify-around
                        mx-5 mb-5 p-6 bg-slate-100 border-slate-300 border rounded-lg"
          do
            div class: ~u"max-w-3-xl text-center" do
              div class: ~u"mb-4" do
                h1 class: ~u"text-xl font-semibold", do: "##{@room.name}"

                if @room.topic do
                  p class: ~u"text-sm mt-1 text-gray-600", do: @room.topic
                end
              end

              div class: ~u"flex items-center justify-around" do
                button "phx-click": "join-room",
                       class: ~u"px-4 py-2 bg-green-600 text-white rounded
                                 focus:outline-none focus:ring-2 focus:ring-green-500
                                 hover:bg-green-600"
                do
                  "Enter realm"
                end
              end

              div class: ~u"mt-4" do
                c &link/1,
                  navigate: ~p"/realms",
                  href: "#",
                  class: ~u"text-sm text-slate-500 underline hover:text-slate-600"
                do
                  "Go back to the shadow realm "
                  c &icon/1, name: "hero-arrow-uturn-left", class: ~u"h-4 w-4"
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
          user: @profile,
          current_user: @current_user
      end

      if assigns[:thread] do
        c &live_component/1,
          id: "thread-component",
          module: CcWeb.RealmsLive.Components.Thread,
          current_user: @current_user,
          message: @thread,
          room: @room,
          timezone: @timezone
      end

      c &modal/1,
        id: "new-room-modal",
        show: @live_action == :new,
        on_cancel: JS.navigate(~p"/realms/#{@room}")
      do
        c &header/1, do: "New chat room"
        c &live_component/1,
          id: "new-room-form-component",
          module: CcWeb.RealmsLive.Components.NewRoomForm,
          current_user: @current_user
      end
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
             class: ~u"flex items-center flex-grow focus:outline-none",
             "phx-click": @on_click
      do
        c &icon/1,
          id: @dom_id <> "-chevron-down",
          name: "hero-chevron-down",
          class: ~u"h-4 w-4"

        c &icon/1,
          id: @dom_id <> "-chevron-right",
          name: "hero-chevron-right",
          class: ~u"h-4 w-4",
          style: "display:none;"

        span class: ~u"ml-2 leading-none font-medium text-sm" do
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
        class: ~u"flex items-center h-8 text-sm pl-8 pr-3
          #{if(@active, do: ~u"bg-slate-300", else: ~u"hover:bg-slate-300")}"
      do
        c &icon/1, name: "hero-hashtag", class: ~u"h-4 w-4"

        span class: ~u"ml-2 leading-none #{if(@active, do: ~u"font-bold")}" do
          @room.name
        end

        c &unread_message_counter/1, count: @unread_count
      end
    end
  end

  attr :count, :integer, required: true
  defp unread_message_counter(assigns) do
    temple do
      if @count > 0 do
        span class: ~u"flex items-center justify-center
                       bg-blue-500 rounded-full font-medium h-5 px-2ml-auto
                       text-xs text-white"
        do
          @count
        end
      else # TODO(temple) remove when resolved: mhanberg/temple/issues/264
        span # TODO(temple) remove when resolved: mhanberg/temple/issues/264
      end
    end
  end

  attr :user, User, required: true
  attr :online, :boolean, default: false
  defp user(assigns) do
    temple do
      c &link/1,
        class: ~u"flex items-center h-8 hover:bg-gray-300 text-sm pl-8 pr-3",
        href: "#"
      do
        div class: ~u"flex justify-center w-4" do
          if @online do
            span class: ~u"w-2 h-2 rounded-full bg-blue-500"
          else
            span class: ~u"w-2 h-2 rounded-full border-2 border-gray-500"
          end
        end

        span class: ~u"ml-2 leading-none" do
          @user.username
        end
      end
    end
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
    Accounts.subscribe_to_user_avatars()
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
    |> assign(thread: nil)
    |> noreply()
  end

  def handle_event("close-profile", _, socket) do
    socket
    |> assign(profile: nil)
    |> noreply()
  end

  def handle_event("show-thread", %{"id" => message_id}, socket) do
    socket
    |> assign(thread: Chat.get_message!(message_id))
    |> assign(profile: nil)
    |> noreply()
  end

  def handle_event("close-thread", _, socket) do
    socket |> assign(:thread, nil) |> noreply()
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

  def handle_info({:updated_avatar, user}, socket) do
    socket
    |> maybe_update_profile(user)
    |> maybe_update_current_user(user)
    |> push_event("update_avatar", %{user_id: user.id, avatar_path: user.avatar_path})
    |> noreply()
  end

  defp maybe_update_current_user(socket, user) do
    if socket.assigns.current_user.id == user.id do
      assign(socket, :current_user, user)
    else
      socket
    end
  end

  defp maybe_update_profile(socket, user) do
    if socket.assigns[:profile] && socket.assigns.profile.id == user.id do
      assign(socket, :profile, user)
    else
      socket
    end
  end
end
