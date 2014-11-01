defmodule Phoenix.Socket.SocketTest do
  use ExUnit.Case
  alias Phoenix.Socket
  doctest Socket

  def new_socket do
    %Socket{pid: self}
  end

  test "set_current_channel/3 sets the current channel" do
    socket = new_socket |> Socket.set_current_channel("somechan", "sometopic")
    assert socket.channel == "somechan"
    assert socket.topic == "sometopic"
  end

  test "authorized?/3 returns true if socket belongs to channel scoped to topic" do
    socket = new_socket
    socket = Socket.authorize(socket, "channel", "topic")
    assert Socket.authorized?(socket, "channel", "topic")
    refute Socket.authorized?(socket, "channel", "othertopic")
  end

  test "authorized?/3 returns false if socket does not belong to channel" do
    socket = new_socket
    refute Socket.authorized?(socket, "chan", "topic")
  end

  test "deauthorize/1 deletes channel" do
    socket = new_socket |> Socket.authorize("test", "topic")
    assert Socket.authorized?(socket, "test", "topic")
    socket = Socket.deauthorize(socket)
    refute Socket.authorized?(socket, "test", "topic")
  end

  test "get_assign/2 and assign/3 assigns into the assigns map" do
    socket = new_socket |> Socket.set_current_channel("rooms", "lobby")
    refute Socket.get_assign(socket, :foo) == "bar"
    socket = Socket.assign(socket, :foo, "bar")
    assert Socket.get_assign(socket, :foo) == "bar"
  end

  test "socket assigns can be accessed from assigns map" do
    socket = new_socket |> Socket.assign(:key, :val)
    assert socket.assigns[:key] == :val
  end
end
