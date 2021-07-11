defmodule ImgWizardApi.Endpoint do
  use Plug.Router

  alias ImgWizard.MetaInfo
  alias ImgWizardApi.NoImageUploaded

  plug(:match)
  plug(Plug.Parsers, parsers: [:multipart])
  plug(:dispatch)

  put "/info" do
    with {:ok, path} <- get_image_path(conn),
         {:ok, %MetaInfo{} = info} <- metadata_extractor(conn).(path) do
      send_resp(conn, 200, info |> Map.from_struct() |> Jason.encode!())
    else
      {:error, error} -> send_error(conn, error)
    end
  end

  match _ do
    send_resp(conn, 404, "Not implemented")
  end

  defp send_error(conn, %type{} = error) do
    result =
      error
      |> Map.from_struct()
      |> Map.delete(:__exception__)
      |> Map.put(:error, format_error_name(type))
      |> Jason.encode!()

    send_resp(conn, status(type), result)
  end

  defp metadata_extractor(conn) do
    case conn.assigns[:metadata_extractor] do
      nil -> &ImgWizard.metadata/1
      extractor -> extractor
    end
  end

  defp get_image_path(%Plug.Conn{body_params: %{"image" => %{path: path}}}), do: {:ok, path}
  defp get_image_path(_), do: {:error, NoImageUploaded.exception()}

  defp status(NoImageUploaded), do: 400
  defp status(ImgWizard.UnhandledFileTypeError), do: 422
  defp status(_), do: 500

  defp format_error_name(error_module) when is_atom(error_module) do
    error_module
    |> Atom.to_string()
    |> String.replace(~r/^Elixir\.ImgWizard[^\.]*\./, "")
  end
end
