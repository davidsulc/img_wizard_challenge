import Config

port =
  case System.fetch_env("IMG_WIZARD_PORT") do
    {:ok, port} -> String.to_integer(port)
    :error -> 4040
  end

config :img_wizard, :port, port
