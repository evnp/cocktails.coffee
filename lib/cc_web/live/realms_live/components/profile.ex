defmodule CcWeb.RealmsLive.Components.Profile do
  use CcWeb, :live_component

  alias Cc.Accounts
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
            if @current_user.id != @user.id do
              c &user_avatar/1, class: "w-48 rounded mx-auto", user: @user
            else
              c &form/1,
                for: %{},
                "phx-change": "validate-avatar",
                "phx-submit": "submit-avatar",
                "phx-target": @myself do

                div class: "mb-4" do
                  if Enum.any?(@uploads.avatar.entries) do
                    div class: "mx-auto mb-2 w-48" do
                      c &live_img_preview/1,
                        class: "rounded",
                        entry: List.first(@uploads.avatar.entries),
                        width: 192,
                        height: 192
                      button type: "submit",
                        class: [
                          "w-full bg-emerald-600 hover:bg-emerald-700",
                          "text-white rounded mt-2 py-1 shadow"
                        ] do
                        "Save"
                      end
                    end
                  else
                    c &user_avatar/1, user: @user, class: "w-48 rounded mx-auto"
                  end
                end

                label class: "block mb-2 font-semibold text-lg text-gray-800" do
                  "Upload avatar"
                end

                c &live_file_input/1, class: "w-full", upload: @uploads.avatar
              end

              hr class: "mt-4"
            end
          end

          h2 class: "text-xl font-bold text-gray-800" do
            @user.username
          end
        end
      end
    end
  end

  def mount(socket) do
    socket
    |> allow_upload(:avatar,
      accept: ~w(.png .jpg),
      max_entries: 1,
      max_file_size: 2 * 1024 * 1024
    )
    |> ok()
  end

  def handle_event("validate-avatar", _, socket) do
    noreply(socket)
  end

  def handle_event("submit-avatar", _, socket) do
    if socket.assigns.user.id != socket.assigns.current_user.id do
      raise "Prohibited"
    end

    avatar_path =
      socket
      |> consume_uploaded_entries(:avatar, fn %{path: path}, _entry ->
        dest = Path.join("priv/static/uploads", Path.basename(path))
        File.cp!(path, dest)
        {:ok, Path.basename(dest)}
      end)
      |> List.first()

    {:ok, _user} = Accounts.save_user_avatar_path(socket.assigns.current_user, avatar_path)

    noreply(socket)
  end
end
