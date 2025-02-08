defmodule CcWeb.RealmsLive.Component.Thread do
  use CcWeb, :live_component

  def render(assigns) do
    temple do
      div class: ~w"flex flex-col shrink-0
                    w-1/4 max-w-xs border-l border-slate-300 bg-slate-100"
      do
        div class: ~w"flex items-center shrink-0 h-16 border-b border-slate-300 px-4"
        do
          div do
            h2 class: ~w"text-sm font-semibold leading-none", do: "Thread"
            a class: ~w"text-xs leading-none", href: "#", do: @room.name
          end
          button "phx-click": "close-thread",
            class: ~w"flex items-center justify-center
                      w-6 h-6 rounded hover:bg-gray-300 ml-auto"
          do
            c &icon/1, name: "hero-x-mark", class: ~w"w-5 h-5"
          end
        end
      end
    end
  end
end
