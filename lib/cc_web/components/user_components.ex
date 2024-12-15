defmodule CcWeb.UserComponents do
  use CcWeb, :html

  alias Cc.Accounts.User

  attr :user, User
  attr :class, :string

  def user_avatar(assigns) do
    temple do
      img src: user_avatar_path(@user), class: @class
    end
  end

  defp user_avatar_path(user) do
    if user.avatar_path do
      ~p"/uploads/#{user.avatar_path}"
    else
      ~p"/images/one_ring.jpg"
    end
  end
end
