defmodule CcWeb.Sigils.UniqueWords do
  import CcWeb.Util.StringUtils, only: [collapse_whitespace: 1]

  defmacro sigil_u(term, mod)

  defmacro sigil_u({:<<>>, _meta, [str]}, mod) when is_binary(str) do
    unescaped = :elixir_interpolation.unescape_string(str)

    {duplicate_word, _} = check_unique_words(unescaped, %MapSet{})

    if duplicate_word do
      message = "Duplicate word: #{duplicate_word}"

      if ?w in mod do
        IO.warn(message, Macro.Env.stacktrace(__CALLER__))
      else
        raise message
      end
    end

    handle_modifiers(unescaped, mod)
  end

  defmacro sigil_u({:<<>>, meta, tokens}, mod) do
    {tokens, duplicate_word, _word_set} = Enum.reduce_while(
      tokens,
      {[], false, %MapSet{}},
      fn token, {tokens, _duplicate_word, word_set} ->
        if not is_binary(token) do
          {:cont, {[token | tokens], false, word_set}}
        else
          unescaped = :elixir_interpolation.unescape_string(token)

          {duplicate_word, word_set} = check_unique_words(unescaped, word_set)

          if duplicate_word do
            {:halt, {[unescaped | tokens], duplicate_word, word_set}}
          else
            {:cont, {[unescaped | tokens], false, word_set}}
          end
        end
      end
    )

    if duplicate_word do
      message = "Duplicate word: #{duplicate_word}"

      if ?w in mod do
        IO.warn(message, Macro.Env.stacktrace(__CALLER__))
      else
        raise message
      end
    end

    # Reverse tokens here so that we can use more-efficient list-prepend ops above:
    {:<<>>, meta, Enum.reverse(tokens)}
    |> handle_modifiers(mod)
  end

  defmacro valid_modifiers, do: ~w[s l a c w sw lw aw cw ws wl wa wc]c

  defmacro invalid_modifiers_message do
    "~u sigil modifier(s) must be one of: #{valid_modifiers() |> Enum.join(", ")}"
  end

  defp handle_modifiers(_str, mod)
      when mod != [] and mod not in valid_modifiers() do
    raise ArgumentError, invalid_modifiers_message()
  end

  defp handle_modifiers(str, mod) when is_binary(str) do
    cond do
      mod == [] or mod in ~w[s w sw ws]c ->
        collapse_whitespace(str)
      mod in ~w[l lw wl]c ->
        String.split(str)
      mod in ~w[a aw wa]c ->
        Enum.map(String.split(str), &String.to_atom/1)
      mod in ~w[c cw wc]c ->
        Enum.map(String.split(str), &String.to_charlist/1)
      true ->
        raise ArgumentError, invalid_modifiers_message()
    end
  end

  defp handle_modifiers(str, mod) do
    cond do
      mod == [] or mod in ~w[s w sw ws]c ->
        quote(do: collapse_whitespace(unquote(str)))
      mod in ~w[l lw wl]c ->
        quote(do: String.split(unquote(str)))
      mod in ~w[a aw wa]c ->
        quote(do: Enum.map(String.split(unquote(str)), &String.to_atom/1))
      mod in ~w[c cw wc]c ->
        quote(do: Enum.map(String.split(unquote(str)), &String.to_charlist/1))
      true ->
        raise ArgumentError, invalid_modifiers_message()
    end
  end

  defp check_unique_words(str, word_set) do
    Enum.reduce_while(String.split(str), {false, word_set}, fn word, {_, word_set} ->
      if MapSet.member?(word_set, word) do
        {:halt, {word, word_set}}
      else
        {:cont, {false, MapSet.put(word_set, word)}}
      end
    end)
  end
end
