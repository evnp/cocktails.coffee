defmodule CcWeb.Sigils.UniqueWords do
  import CcWeb.Util.StringUtils, only: [collapse_whitespace: 1]

  defmacro sigil_u(term, modifiers)

  defmacro sigil_u({:<<>>, _meta, [string]}, modifiers) when is_binary(string) do
    unescaped = :elixir_interpolation.unescape_string(string)
    check_unique_words(unescaped, %MapSet{}, __CALLER__)
    handle_modifiers(unescaped, modifiers)
  end

  defmacro sigil_u({:<<>>, meta, tokens}, modifiers) do
    {tokens, _} = Enum.reduce(tokens, {[], %MapSet{}}, fn token, {tokens, word_set} ->
      if is_binary(token) do
        unescaped = :elixir_interpolation.unescape_string(token)
        word_set = check_unique_words(unescaped, word_set, __CALLER__)
        {[unescaped | tokens], word_set}
      else
        {[token | tokens], word_set}
      end
    end)

    # Reverse tokens here so that we can use more-efficient list-prepend ops above.
    {:<<>>, meta, Enum.reverse(tokens)}
    |> handle_modifiers(modifiers)
  end

  defp handle_modifiers(input, []), do: handle_modifiers(input, [?s])

  defp handle_modifiers(input, [modifier])
       when modifier == ?s or modifier == ?l or modifier == ?a or modifier == ?c do
    if is_binary(input) do
      case modifier do
        ?s -> collapse_whitespace(input)
        ?l -> String.split(input)
        ?a -> :lists.map(&String.to_atom/1, String.split(input))
        ?c -> :lists.map(&String.to_charlist/1, String.split(input))
      end
    else
      case modifier do
        ?s -> quote(do: collapse_whitespace(unquote(input)))
        ?l -> quote(do: String.split(unquote(input)))
        ?a -> quote(do: :lists.map(&String.to_atom/1, String.split(unquote(input))))
        ?c -> quote(do: :lists.map(&String.to_charlist/1, String.split(unquote(input))))
      end
    end
  end

  defp handle_modifiers(_string, _modifiers) do
    raise ArgumentError, "modifier must be one of: s, l, a, c"
  end

  defp check_unique_words(string, word_set, caller) do
    word_list = String.split(string, " ")

    {duplicate_word, word_set} = Enum.reduce_while(word_list, {false, word_set}, fn word, {_, word_set} ->
      cond do
        word == "" -> {:cont, {false, word_set}}
        MapSet.member?(word_set, word) -> {:halt, {word, word_set}}
        true ->
          word_set = MapSet.put(word_set, word)
          {:cont, {false, word_set}}
      end
    end)

    if duplicate_word do
      IO.warn("Duplicate word (#{duplicate_word})", Macro.Env.stacktrace(caller))
    end

    word_set
  end
end
