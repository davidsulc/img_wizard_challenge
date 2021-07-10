defmodule ImgWizard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    port = Application.get_env(:img_wizard, :port)
    Logger.info("Starting API on port #{port}")

    children = [
      {Plug.Cowboy, scheme: :http, plug: ImgWizardApi.Endpoint, options: [port: port]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ImgWizard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
