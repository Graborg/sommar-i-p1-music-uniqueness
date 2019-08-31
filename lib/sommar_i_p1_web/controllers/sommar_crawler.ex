defmodule SommarCrawler do
  defp increment_date(%Date{year: year}) when year > 2019, do: []

  defp increment_date(%Date{month: month} = date) when month >= 9,
    do: increment_date(date |> Date.add(288))

  defp increment_date(%Date{} = date) do
    [date | increment_date(date |> Date.add(1))]
  end

  defp get_list_of_possible_speaker_dates(%Date{} = starting_date) do
    increment_date(starting_date)
    |> Stream.map(&Date.to_string/1)
  end

  defp get_speaker(body) do
    body
    |> Floki.find("h1.heading")
    |> Floki.text()
  end

  defp split_song_and_artist(str) do
    str
    |> String.split(" - ")
    |> List.to_tuple()
  end

  def get_songs_from_performance_page(page) do
    with {:ok, %HTTPoison.Response{body: body}} =
           HTTPoison.get("https://sverigesradio.se/#{page}"),
         do:
           body
           |> Floki.find(".track-list")
           |> Floki.find(".heading")
           |> Floki.text(sep: "|")
           |> String.split("|")
           |> Enum.map(&split_song_and_artist/1)
           |> (fn songs -> Map.put_new(%{}, :songs, songs) end).()
           |> Map.put_new(:speaker, get_speaker(body))
  end

  def get_performance_links_for_date(date) do
    url = "https://sverigesradio.se/sommarvinterip1/latlista/#{date}"
    IO.puts(url)

    with {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url),
      do:
        body
        |> Floki.find(".song-list-flow .heading")
        |> Floki.attribute("a", "href")
  end

  defp async_run(pages, fun) do
    pages
    |> Stream.chunk_every(200)
    |> Stream.map(fn chunk ->
      Enum.map(chunk, &Task.async(fn -> fun.(&1) end))
    end)
    |> Enum.flat_map(fn chunk -> Enum.map(chunk, &Task.await(&1, 30000)) end)
  end

  def get_all_songs() do
    File.read!(Path.absname("performances-raw"))
    |> :erlang.binary_to_term()

    # songs =
    #   get_list_of_possible_speaker_dates(~D[2010-06-11])
    #   |> async_run(&get_performance_links_for_date/1)
    #   |> Enum.uniq()
    #   |> async_run(&get_songs_from_performance_page/1)

    # songs
    # |> (fn content -> File.write!("performances-raw", :erlang.term_to_binary(content)) end).()

    # songs
  end
end
