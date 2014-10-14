defmodule Phoenix.Controller.Connection do
  import Plug.Conn
  alias Phoenix.Controller.Errors

  # TODO: Move everything here to the Phoenix.Controller module?

  @moduledoc """
  Handles Interacting with Plug.Conn and integration with the Controller layer

  Used for sending responses and looking up private Conn assigns
  """

  @doc """
  Returns the Atom action name matched from Router
  """
  def action_name(conn), do: conn.private[:phoenix_action]

  @doc """
  Returns the Atom Controller Module matched from Router
  """
  def controller_module(conn), do: conn.private[:phoenix_controller]

  @doc """
  Returns the Actom Router Module that dispatched the Conn
  """
  def router_module(conn), do: conn.private[:phoenix_router]

  @doc """
  Assign error to phoenix private assigns
  """
  def assign_error(conn, kind, error) do
    put_private(conn, :phoenix_error, {kind, error})
  end

  @doc """
  Retrieve error from phoenix private assigns
  """
  def error(conn), do: Dict.get(conn.private, :phoenix_error)

  @doc """
  Assign layout to phoenix private assigns

  Possible values include any String, as well as the Atom `:none` to
  render without a layout.

  ## Examples

      iex> conn |> put_layout("print")
      iex> conn |> put_layout(:none)

  """
  def put_layout(conn, layout) when is_binary(layout) do
    put_private(conn, :phoenix_layout, layout)
  end
  def put_layout(conn, :none) do
    put_private(conn, :phoenix_layout, :none)
  end

  @doc false
  def assign_layout(conn, layout) do
    IO.write :stderr, "assign_layout/2 is deprecated in favor of put_layout/2\n#{Exception.format_stacktrace}"
    put_layout(conn, layout)
  end

  @doc """
  Retrieve layout from phoenix private assigns
  """
  def layout(conn), do: Dict.get(conn.private, :phoenix_layout, "application")

  @doc false
  def assign_status(conn, status) do
    IO.write :stderr, "assign_status/2 is deprecated in favor of put_status/2\n#{Exception.format_stacktrace}"
    put_status(conn, status)
  end

  @doc """
  Returns the String Mime content-type of response

  Raises Errors.UnfetchedContentType if content type is not yet fetched
  """
  def response_content_type!(conn) do
    case response_content_type(conn) do
      {:ok, resp}   -> resp
      {:error, :unfetched} -> raise Errors.UnfetchedContentType, message: "You must first call Plugs.ContentTypeFetcher.fetch/1"
    end
  end

  @doc """
  Returns the String Mime content-type of response

  ## Examples

      iex> response_content_type(conn)
      {:ok, "text/html"}
      iex> response_content_type(conn)
      {:error, :unfetched}

  """
  def response_content_type(conn) do
    conn
    |> get_resp_header("content-type")
    |> Enum.at(0)
    |> case do
      nil -> {:error, :unfetched }
      headers -> {:ok, headers |> String.split(";") |> Enum.at(0)}
    end
  end

  @doc """
  Upgrades the connection
  """
  def upgrade(conn, [{transport, handler}]) do
    put_private(conn, :upgrade, {transport, handler}) |> halt
  end

  @doc """
  Sends JSON response from provided json String

  ## Examples

      json conn, "{\"id\": 123}"
      json conn, 200, "{\"id\": 123}"

  """
  def json(conn, json), do: json(conn, :ok, json)
  def json(conn, status, json) do
    send_response(conn, status, "application/json", json)
  end

  @doc """
  Sends HTML response from provided html String

  ## Examples

      html conn, "<h1>Hello!</h1>"
      html conn, 200, "<h1>Hello!</h1>"

  """
  def html(conn, html), do: html(conn, :ok, html)
  def html(conn, status, html) do
    send_response(conn, status, "text/html", html)
  end

  @doc """
  Sends text response from provided String

  ## Examples

      text conn, "hello"
      text conn, 200, "hello"

  """
  def text(conn, text), do: text(conn, :ok, text)
  def text(conn, status, text) do
    send_response(conn, status, "text/plain", text)
  end

  @doc """
  Sends response to the client

    * conn - the Plug Connection
    * status - The Integer or Atom http status, ie 200, 400, :ok, :bad_request
    * content_type - The String Mime content type of the response, ie, "text/html"

  """
  def send_response(conn, status, content_type, data) do
    conn
    |> put_resp_content_type(content_type)
    |> send_resp(status, data)
  end

  @doc """
  Sends redirect response to provided url String

  ## Examples

      redirect conn, "http://elixir-lang.org"
      redirect conn, 404, "http://elixir-lang.org"

  """
  def redirect(conn, url), do: redirect(conn, :found, url)
  def redirect(conn, status, url) do
    conn
    |> put_resp_header("Location", url)
    |> html status, """
       <html>
         <head>
            <title>Moved</title>
         </head>
         <body>
           <h1>Moved</h1>
           <p>This page has moved to <a href="#{url}">#{url}</a></p>
         </body>
       </html>
    """
  end
end
