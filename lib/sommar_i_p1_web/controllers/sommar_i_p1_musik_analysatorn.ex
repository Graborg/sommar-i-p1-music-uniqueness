defmodule SommarIP1MusikAnalysatorn do
  require TimeFrame
  require SommarCrawler

  def main do
    TimeFrame.execute "get_all_songs", :second do
      songs =
        SommarCrawler.get_all_songs()
        |> Enum.filter(fn
          %{songs: [{""} | _tail]} -> false
          _ -> true
        end)
        |> Enum.map(&reformat_dirty_performances/1)
        |> Enum.flat_map(fn show -> Map.get(show, :songs) end)
        |> Enum.group_by(&performance_to_string/1, fn tuple -> tuple end)
        |> Enum.map(fn {_song_artist_name, list} -> list end)

      popularities =
        songs
        |> group_by_jaro()
        |> Enum.flat_map(fn l -> l end)
        |> Enum.reduce(%{}, fn songs, acc_1 ->
          IO.puts("making final map..")

          map =
            Enum.reduce(songs, %{}, fn performance, acc_2 ->
              key = performance |> performance_to_string()
              Map.put_new(acc_2, key, length(songs))
            end)

          Map.merge(map, acc_1)
        end)

      File.write!("popularity-map", :erlang.term_to_binary(popularities))
    end
  end

  def rank_speaker(songs) do
    popularities =
      File.read!(Path.absname("popularity-map"))
      |> :erlang.binary_to_term()

    # popularities
    # |> Enum.each(&IO.inspect/1)

    songs
    |> Enum.map(&performance_to_string/1)
    |> Enum.uniq()
    |> Enum.map(&get_popularity(&1, popularities))
  end

  def get_popularity(performance, popularities) do
    case Map.get(popularities, performance, nil) do
      nil -> performance
      popularity -> popularity - 1
    end
  end

  def get_speaker_rank() do
    SommarCrawler.get_all_songs()
    |> Enum.filter(fn
      %{songs: [{""} | _tail]} -> true
      _ -> false
    end)
    |> Enum.map(&Map.get(&1, :speaker))
    |> Enum.join(", ")
    |> (fn e -> IO.puts("speakers without songs: #{e}") end).()

    SommarCrawler.get_all_songs()
    |> Enum.filter(fn
      %{songs: [{""} | _tail]} -> false
      _ -> true
    end)
    |> Enum.map(fn %{songs: songs} = show ->
      %{
        show
        | songs:
            Enum.filter(songs, fn song ->
              Tuple.to_list(song)
              |> Enum.join()
              |> (&Regex.match?(~r{sommar sommar}i, &1)).()
              |> Kernel.not()
            end)
      }
    end)
    |> Enum.map(&reformat_dirty_performances/1)
    |> Enum.reduce(%{}, fn %{speaker: speaker, songs: songs}, acc ->
      popularity_list = rank_speaker(songs)
      # IO.puts("#{speaker} songs: #{Enum.join(popularity_list, ",")}")
      Map.put_new(acc, speaker, songs_data_map(popularity_list, songs))
    end)
    |> Enum.map(fn {key, val} -> Map.put_new(%{}, key, val) end)
    |> Enum.filter(fn map ->
      Map.keys(map) |> List.first() |> String.contains?("Årets Sommarvärdar") |> Kernel.not()
    end)
    |> Enum.sort_by(fn map -> Map.values(map) |> List.first() |> Map.get(:total_rank) end)
  end

  def reformat_dirty_performances(e), do: run_reformat_dirty_performances(e, [])

  def run_reformat_dirty_performances(%{speaker: speaker, songs: []}, remapped),
    do: %{speaker: speaker, songs: remapped}

  def run_reformat_dirty_performances(%{speaker: speaker, songs: [song | tail]}, remapped)
      when tuple_size(song) !== 2 do
    # make changes to song
    cleaned = clean_performance(speaker, song)
    run_reformat_dirty_performances(%{speaker: speaker, songs: tail}, [cleaned | remapped])
  end

  def run_reformat_dirty_performances(%{speaker: speaker, songs: [song | tail]}, remapped) do
    run_reformat_dirty_performances(%{speaker: speaker, songs: tail}, [song | remapped])
  end

  def clean_performance(speaker, song) do
    initials =
      speaker
      |> String.split()
      |> Enum.map(fn name -> String.first(name) end)
      |> Enum.take(2)
      |> Enum.join()

    cleaned =
      song
      |> Tuple.to_list()
      |> Enum.filter(fn s -> s !== initials end)
      |> Enum.filter(fn s -> s !== "" end)
      |> Enum.uniq()
      |> IO.inspect()

    case cleaned do
      cleaned when length(cleaned) !== 2 ->
        cleaned
        |> List.pop_at(length(cleaned) - 1)
        |> (fn {song_name, artist} -> {artist |> Enum.join("-"), song_name} end).()

      cleaned ->
        cleaned |> List.to_tuple()
    end
  end

  def songs_data_map([], songs), do: %{total_rank: nil, songs: songs}

  def songs_data_map(popularity_list, songs) do
    %{
      total_rank:
        popularity_list
        |> Enum.filter(&(!is_nil(&1)))
        |> (&(Enum.sum(&1) / Enum.count(&1))).(),
      songs:
        Enum.zip(popularity_list, songs)
        |> Enum.map(fn {song_rank, song} ->
          song_name = elem(song, tuple_size(song) - 1) |> String.trim()

          artist =
            song
            |> Tuple.delete_at(tuple_size(song) - 1)
            |> Tuple.to_list()
            |> Enum.join("-")
            |> String.trim()

          Map.put(%{}, :song_name, song_name)
          |> Map.put(:artist, artist)
          |> Map.put(:times_played, song_rank)
        end)
    }
  end

  def group_by_jaro([]), do: []

  def group_by_jaro([performances | tail]) do
    [performance | _] = performances
    {matches, non_matches} = find_matches(performance, tail)
    new_group = [performances | matches]
    [new_group | group_by_jaro(non_matches)]
  end

  def find_matches(_performance_1, []), do: {[], []}

  def find_matches(performance_1, [performances_2 | tail]) do
    s_1 = performance_1 |> performance_to_string()

    first_performance_2 = performances_2 |> Enum.at(0)

    {matches, non_matches} = find_matches(performance_1, tail)

    if String.jaro_distance(s_1, first_performance_2 |> performance_to_string()) > 0.95 do
      IO.puts("#{s_1} matched with #{first_performance_2 |> performance_to_string()}")
      {[performances_2 | matches], non_matches}
    else
      {matches, [performances_2 | non_matches]}
    end
  end

  def performance_to_string({artist, song}) do
    (artist <> "-" <> song)
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r{[^[:alnum:][:blank:]]}u, "")
  end
end

# songs played 6703
# unique songs with lowering 6588
# unique songs with lowering&trim 6494
# group by jaro uniques -> 4759
