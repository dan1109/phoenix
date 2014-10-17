defmodule Phoenix.Router.Socket do
  # TODO: Move this to Phoenix.Router
  defmacro __using__(options) do
    mount = Dict.fetch! options, :mount

    quote do
      import unquote(__MODULE__)
      get unquote(mount), Phoenix.Transports.WebSocket, :upgrade_conn
      get unquote(mount <> "/poll"), Phoenix.Transports.Longpoller, :poll
      post unquote(mount <> "/poll"), Phoenix.Transports.Longpoller, :open
      put unquote(mount <> "/poll"), Phoenix.Transports.Longpoller, :publish
    end
  end

  defmacro channel(channel, module) do
    quote do
      def match(socket, :socket, unquote(channel), "join", message) do
        apply(unquote(module), :join, [socket, socket.topic, message])
      end
      def match(socket, :socket, unquote(channel), "leave", message) do
        apply(unquote(module), :leave, [socket, message])
      end
      def match(socket, :socket, unquote(channel), event, message) do
        apply(unquote(module), :event, [socket, event, message])
      end
    end
  end
end
