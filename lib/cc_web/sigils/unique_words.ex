defmodule CcWeb.Sigils.UniqueWords do
  import CcWeb.Util.StringUtils, only: [collapse_whitespace: 1]

  defmacro sigil_u(term, modifiers)

  defmacro sigil_u({:<<>>, _meta, [string]}, modifiers) when is_binary(string) do
    unescaped = :elixir_interpolation.unescape_string(string)
    warn = modifiers != [] && ?w in modifiers
    check_unique_words(unescaped, %MapSet{}, __CALLER__, warn: warn)
    handle_modifiers(unescaped, modifiers)
  end

  defmacro sigil_u({:<<>>, meta, tokens}, modifiers) do
    warn = modifiers != [] && ?w in modifiers
    {tokens, _} = Enum.reduce(tokens, {[], %MapSet{}}, fn token, {tokens, word_set} ->
      if is_binary(token) do
        unescaped = :elixir_interpolation.unescape_string(token)
        word_set = check_unique_words(unescaped, word_set, __CALLER__, warn: warn)
        {[unescaped | tokens], word_set}
      else
        {[token | tokens], word_set}
      end
    end)

    # Reverse tokens here so that we can use more-efficient list-prepend ops above.
    {:<<>>, meta, Enum.reverse(tokens)}
    |> handle_modifiers(modifiers)
  end

  defmacro valid_modifiers, do: ~w[s l a c w sw lw aw cw ws wl wa wc]c

  defmacro invalid_modifier_message do
    "~u sigil modifiers must be one of: #{valid_modifiers() |> Enum.join(", ")}"
  end

  defp handle_modifiers(_string, modifiers)
      when modifiers != [] and modifiers not in valid_modifiers() do
    raise ArgumentError, invalid_modifier_message()
  end

  defp handle_modifiers(input, modifiers) when is_binary(input) do
    cond do
      modifiers == [] or modifiers in ~w[s w sw ws]c ->
        collapse_whitespace(input)
      modifiers in ~w[l lw wl]c ->
        String.split(input)
      modifiers in ~w[a aw wa]c ->
        Enum.map(String.split(input), &String.to_atom/1)
      modifiers in ~w[c cw wc]c ->
        Enum.map(String.split(input), &String.to_charlist/1)
      true ->
        raise ArgumentError, invalid_modifier_message()
    end
  end

  defp handle_modifiers(input, modifiers) do
    cond do
      modifiers == [] or modifiers in ~w[s w sw ws]c ->
        quote(do: collapse_whitespace(unquote(input)))
      modifiers in ~w[l lw wl]c ->
        quote(do: String.split(unquote(input)))
      modifiers in ~w[a aw wa]c ->
        quote(do: Enum.map(String.split(unquote(input)), &String.to_atom/1))
      modifiers in ~w[c cw wc]c ->
        quote(do: Enum.map(String.split(unquote(input)), &String.to_charlist/1))
      true ->
        raise ArgumentError, invalid_modifier_message()
    end
  end

  defp check_unique_words(string, word_set, caller, options) do
    word_list = String.split(string)

    {duplicate_word, word_set} = Enum.reduce_while(
      word_list,
      {false, word_set},
      fn word, {_, word_set} ->
        if MapSet.member?(word_set, word) do
          {:halt, {word, word_set}}
        else
          {:cont, {false, MapSet.put(word_set, word)}}
        end
      end
    )

    if duplicate_word do
      message = "Duplicate word: #{duplicate_word}"

      if !!options[:warn] do
        IO.warn(message, Macro.Env.stacktrace(caller))
      else
        raise message
      end
    end

    word_set
  end
end
