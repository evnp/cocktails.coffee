defmodule CCWeb.ChatRoomLive do
  use CCWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>Welcome to the chat!</div>
    """
  end
end
