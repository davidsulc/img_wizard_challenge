import Config

default_port = fn ->
  case config_env() do
    :test -> 4041
    _ -> 4040
  end
end

port =
  case System.fetch_env("IMG_WIZARD_PORT") do
    {:ok, port} -> String.to_integer(port)
    :error -> default_port.()
  end

config :img_wizard, :port, port
