defmodule CcWeb.RealmsLive.Components.Thread do
  use CcWeb, :live_component

  alias Cc.Chat
  alias Cc.Chat.Reply

  import CcWeb.ChatComponents

  def render(assigns) do
    temple do
      div id: "thread-component",
        "phx-hook": "Thread",
        class: ~u"flex flex-col shrink-0
                    w-1/4 max-w-xs border-l border-slate-300 bg-slate-100"
      do
        div class: ~u"flex items-center shrink-0 h-16 px-4 shadow" do
          div do
            h2 class: ~u"text-sm font-semibold leading-none", do: "Thread"
            a class: ~u"text-xs leading-none", href: "#", do: "##{@room.name}"
          end
          button "phx-click": "close-thread",
            class: ~u"flex items-center justify-center
                      w-6 h-6 rounded hover:bg-gray-300 ml-auto"
          do
            c &icon/1, name: "hero-x-mark", class: ~u"w-5 h-5"
          end
        end
        div id: "thread-message-with-replies",
          class: ~u"flex flex-col grow overflow-auto"
        do
          div class: ~u"border-b border-slate-300" do
            c &message_or_reply/1,
              in_thread?: true,
              message_or_reply: @message,
              dom_id: "thread-message",
              current_user: @current_user,
              timezone: @timezone
          end

          div id: "thread-replies", "phx-update": "stream" do
            for {dom_id, reply} <- @streams.replies do
              c &message_or_reply/1,
                in_thread?: true,
                message_or_reply: reply,
                current_user: @current_user,
                dom_id: dom_id,
                timezone: @timezone
            end
          end
        end
        div class: ~u"bg-slate-100 px-4 pt-3 mt-auto" do
          if @joined_room? do
            div class: ~u"h-12 pb-4" do
              c &form/1,
                class: ~u"flex items-center border-2 border-slate-300 rounded-sm p-1",
                for: @form,
                id: "new-reply-form",
                "phx-change": "validate-reply",
                "phx-submit": "submit-reply",
                "phx-target": @myself
              do
                textarea id: "thread-message-textarea",
                  cols: "",
                  rows: "1",
                  name: @form[:body].name,
                  "phx-debounce": true,
                  "phx-hook": "ChatMessageTextarea",
                  placeholder: "Reply…",
                  class: ~u"grow text-sm px-3 border-l border-slate-300
                            mx-1 resize-none bg-slate-50"
                do
                  Phoenix.HTML.Form.normalize_value("textarea", @form[:body].value)
                end
                button class: ~u"shrink flex items-center justify-center
                                 h-6 w-6 rounded hover:bg-slate-200"
                do
                  c &icon/1, name: "hero-paper-airplane", class: ~u"h-4 w-4"
                end
              end
            end
          end
        end
      end
    end
  end

  def update(assigns, socket) do
    socket
    |> stream(:replies, assigns.message.replies, reset: true)
    |> assign_form(Chat.get_reply_changeset(%Reply{}))
    |> assign(assigns)
    |> ok()
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  def handle_event("submit-reply", %{"reply" => message_params}, socket) do
    %{current_user: current_user, room: room} = socket.assigns

    if !Chat.joined_room?(room, current_user) do
      raise "not allowed"
    end

    case Chat.create_reply(
           socket.assigns.message,
           message_params,
           socket.assigns.current_user
         )
    do
      {:ok, _message} ->
        assign_form(socket, Chat.get_reply_changeset(%Reply{}))

      {:error, changeset} ->
        assign_form(socket, changeset)
    end
    |> noreply()
  end

  def handle_event("validate-reply", %{"reply" => message_params}, socket) do
    changeset = Chat.get_reply_changeset(%Reply{}, message_params)

    {:noreply, assign_form(socket, changeset)}
  end
end
