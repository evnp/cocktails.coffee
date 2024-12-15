defmodule CcWeb.RealmsLive.Components.Profile do
  use CcWeb, :live_component

  import CcWeb.UserComponents

  def render(assigns) do
    temple do
      div class: "flex flex-col flex-shrink-0 w-1/4 max-w-xs bg-white shadow-xl" do
        div class: "flex items-center h-16 px-4 shadow-md" do
          div do
            h2 class: "text-lg font-bold text-gray-800" do
              "Profile"
            end
          end

          button "phx-click": "close-profile",
                 class: [
                   "w-6 h-6 rounded hover:bg-gray-300 ml-auto",
                   "flex items-center justify-center"
                 ] do
            c &icon/1, name: "hero-x-mark", class: "w-5 h-5"
          end
        end

        div class: "flex flex-col flex-grow overflow-auto p-4" do
          div class: "mb-4" do
            c &user_avatar/1, class: "w-48 rounded mx-auto", user: @user
          end

          h2 class: "text-xl font-bold text-gray-800" do
            @user.username
          end
        end
      end
    end
  end
end
