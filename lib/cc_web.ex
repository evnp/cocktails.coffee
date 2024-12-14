defmodule CcWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use CcWeb, :controller
      use CcWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths do
    ~w(assets fonts images uploads favicon.ico robots.txt)
  end

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: CcWeb.Layouts]

      import Plug.Conn
      import CcWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {CcWeb.Layouts, :app}

      # Import LiveView-specific utility functions:
      import CcWeb.Util

      unquote(html_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      # Import LiveView-specific utility functions:
      import CcWeb.Util

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML

      # Core UI components and translation
      import CcWeb.CoreComponents
      import CcWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Configure Temple (templating DSL)
      import Temple
      import Phoenix.LiveView.TagEngine, only: [component: 3, inner_block: 2]
      # Second line is necessary to avoid Phoenix errors, eg.
      # "The function "inner_block" cannot handle clauses with the -> operator..."
      # See https://github.com/mhanberg/temple/issues/201
      # and resulting https://github.com/georgevanderson/temple_liveview/pull/1

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: CcWeb.Endpoint,
        router: CcWeb.Router,
        statics: CcWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
