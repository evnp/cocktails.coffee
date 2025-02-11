defmodule CcWeb.Sigils.UniqueWords do
  defmacro sigil_u(term, modifiers)

  defmacro sigil_u({:<<>>, _meta, [string]}, modifiers) when is_binary(string) do
    check_unique_words(:elixir_interpolation.unescape_string(string), __CALLER__)
    |> handle_modifiers(modifiers)
  end

  defmacro sigil_u({:<<>>, meta, tokens}, modifiers) do
    checked_escaped_tokens = Enum.map(
      tokens,
      fn token ->
        if is_binary(token) do
          check_unique_words(:elixir_interpolation.unescape_string(token), __CALLER__)
        else
          token
        end
      end
    )

    {:<<>>, meta, checked_escaped_tokens}
    |> handle_modifiers(modifiers)
  end

  defp handle_modifiers(input, []), do: handle_modifiers(input, [?s])

  defp handle_modifiers(input, [modifier])
       when modifier == ?s or modifier == ?l or modifier == ?a or modifier == ?c do
    if is_binary(input) do
      case modifier do
        ?s -> String.replace(input, ~r"\s+", " ")
        ?l -> String.split(input)
        ?a -> :lists.map(&String.to_atom/1, String.split(input))
        ?c -> :lists.map(&String.to_charlist/1, String.split(input))
      end
    else
      case modifier do
        ?s -> quote(do: String.replace(unquote(input), ~r"\s+", " "))
        ?l -> quote(do: String.split(unquote(input)))
        ?a -> quote(do: :lists.map(&String.to_atom/1, String.split(unquote(input))))
        ?c -> quote(do: :lists.map(&String.to_charlist/1, String.split(unquote(input))))
      end
    end
  end

  defp handle_modifiers(_string, _modifiers) do
    raise ArgumentError, "modifier must be one of: s, l, a, c"
  end

  defp check_unique_words(string, caller) do
    words = String.split(string, " ")

    has_duplicates = true == Enum.reduce_while(words, %MapSet{}, fn word, acc ->
      cond do
        word == "" -> {:cont, acc}
        MapSet.member?(acc, word) -> {:halt, true}
        true -> {:cont, MapSet.put(acc, word)}
      end
    end)

    if has_duplicates do
      joined = Enum.join(words, " ")
      IO.warn("Duplicate words in '#{joined}'", Macro.Env.stacktrace(caller))
    end

    string
  end
end
