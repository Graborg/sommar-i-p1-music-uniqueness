defmodule SommarIP1Web.PageController do
  use SommarIP1Web, :controller
  require SommarIP1MusikAnalysatorn
  @list SommarIP1MusikAnalysatorn.get_speaker_rank()

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(@list)
  end
end
