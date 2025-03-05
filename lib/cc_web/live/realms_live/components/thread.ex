defmodule CcWeb.RealmsLive.Components.Thread do
  use CcWeb, :live_component

  import CcWeb.ChatComponents

  def render(assigns) do
    temple do
      div class: ~u"flex flex-col shrink-0
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
        div class: ~u"flex flex-col grow overflow-auto" do
          div class: ~u"border-b border-slate-300" do
            c &message/1,
              in_thread?: true,
              message: @message,
              dom_id: "thread-message",
              current_user: @current_user,
              timezone: @timezone
          end
        end
      end
    end
  end
end
