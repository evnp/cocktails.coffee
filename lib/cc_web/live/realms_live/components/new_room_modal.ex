defmodule CcWeb.RealmsLive.Components.NewRoomModal do
  use CcWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.modal id="new-room-modal" show={@show} on_cancel={@on_cancel}>
        <.header>New chat room</.header>
        <.live_component
          id="new-room-form-component"
          module={CcWeb.RealmsLive.Components.NewRoomForm}
          current_user={@current_user}
        />
      </.modal>
    </div>
    """
  end

  def update(assigns, socket) do
    socket
    |> assign(
      current_user: assigns.current_user,
      show: assigns.show,
      on_cancel: assigns.on_cancel
    )
    |> ok()
  end
end
