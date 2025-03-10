defmodule CcWeb.ChatComponents do
  use CcWeb, :html

  alias Cc.Accounts.User

  import CcWeb.UserComponents

  def message_timestamp(message, timezone) do
    message.inserted_at
    |> Timex.Timezone.convert(timezone)
    |> Timex.format!("%-l:%M %p", :strftime)
  end

  defp thread_avatars(assigns) do
    users =
      assigns.replies
      |> Enum.map(& &1.user)
      |> Enum.uniq_by(& &1.id)

    assigns = assign(assigns, :users, users)

    temple do
      for user <- @users do
        c &user_avatar/1, class: ~u"h-6 w-6 rounded shrink-0 ml-1", user: user
      end
    end
  end

  attr :message_or_reply, :any,  required: true
  attr :current_user, User, required: true
  attr :dom_id, :string, required: true
  attr :in_thread?, :boolean, default: false
  attr :timezone, :string, required: true
  #
  def message_or_reply(assigns) do
    temple do
      div id: @dom_id, class: ~u"group relative flex px-4 py-3" do
        div class: ~u"absolute top-4 right-4 hidden group-hover:block bg-white gap-1
                        shadow-sm px-2 pb-1 rounded border border-px border-slate-300"
        do
          if !@in_thread? do
            button "phx-click": "show-thread",
                   "phx-value-id": @message_or_reply.id,
                   class: ~u"text-slate-500 hover:text-slate-600 cursor-pointer"
            do
              c &icon/1,
                name: "hero-chat-bubble-bottom-center-text",
                class: ~u"h-4 w-4"
            end
          end

          if @current_user.id == @message_or_reply.user_id do
            button "phx-click": "delete-message",
                   "phx-value-id": @message_or_reply.id,
                   "data-confirm": "Are you sure?",
                   class: ~u"text-red-500 hover:text-red-800 cursor-pointer"
            do
              c &icon/1, name: "hero-trash", class: ~u"h-4 w-4"
            end
          end
        end

        a class: ~u"flex-shrink-0 cursor-pointer",
          "phx-click": "show-profile",
          "phx-value-user-id": @message_or_reply.user.id
        do
          c &user_avatar/1, class: ~u"h-10 w-10 rounded", user: @message_or_reply.user
        end

        div class: ~u"ml-2" do
          div class: ~u"-mt-1" do
            a class: ~u"text-sm font-semibold hover:underline cursor-pointer",
              "phx-click": "show-profile",
              "phx-value-user-id": @message_or_reply.user.id,
              do: @message_or_reply.user.username

            if @timezone do
              span class: ~u"ml-1 text-xs text-gray-500" do
                message_timestamp(@message_or_reply, @timezone)
              end
            end

            p class: ~u"text-sm", do: @message_or_reply.body

            if !@in_thread? && Enum.any?(@message_or_reply.replies) do
              div "phx-value-id": @message_or_reply.id,
                "phx-click": "show-thread",
                class: ~u"inline-flex items-center
                          mt-2 py-1 pr-2 box-border cursor-pointer
                          rounded border border-transparent
                          hover:border-slate-200 hover:bg-slate-50"
              do
                c &thread_avatars/1, replies: @message_or_reply.replies

                a class: ~u"inline-block text-blue-600 text-xs font-medium ml-1",
                  href: "#"
                do
                  length(@message_or_reply.replies)
                  if length(@message_or_reply.replies) == 1, do: "reply", else: "replies"
                end
              end
            end
          end
        end
      end
    end
  end
end
