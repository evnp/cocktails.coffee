defmodule RegexFormatter do
  @moduledoc """
  RegexFormatter
  --------------
  Don't fear the regex.
  Make `mix format` more malleable through easy regex search/replace customizations.

  Usage
  -----
  Configure and run Regex Formatter in three steps:

  1. Add `RegexFormatter` to `plugins` list in `.formatter.exs`.
  2. Add `regex_formatter` config to `.formatter.exs` following examples below.
  3. Run `mix format` — Regex Formatter rules will run after normal format operations.

  ```elixir
  [                                        #  ┌── [1] Add RegexFormatter to plugins.
    ...                                    #  │
    plugins: [Phoenix.LiveView.HTMLFormatter, RegexFormatter],
    regex_formatter: [  #  <───── [2] Add configuration for RegexFormatter.
      [
        extensions: [".ex", ".exs"],  #  <─── [3] Configure file types to replace on.
        replacements: [
          {
            ~r/~u["]\\s+/s,  #  <───── [4] Define search pattern.
            "~u\\""          #  <───── [5] Define replacement pattern.
          },
          {
            ~r/(~u["][^"]+[^"\\s])  +([^"\\s])/s,
            ~S'\\1 \\2',   #  <─────── [6] Replace with matched groups.
            repeat: 100,
            # Repeat substitutions to correctly handle overlapping matches.
            # (repeated substitution will stop as soon as text stops changing)
          },
        ]
      ],
      [
        sigils: [:SQL],  #  <───────── [7] Also try substitution within sigils.
        replacements: [
          {
            ~r/(~u["][^"]+[^"\\s])\\s+"/s,
            ~S'\\1"'
          },
        ]
      ]
    ]
  ]
  ```
  """

  @behaviour Mix.Tasks.Format

  require Logger

  @impl Mix.Tasks.Format
  def features(options) do
    [
      sigils: Enum.flat_map(
        options[:regex_formatter] || [], &(&1[:sigils] || [])
      ),
      extensions: Enum.flat_map(
        options[:regex_formatter] || [], &(&1[:extensions] || [])
      )
    ]
  end

  @impl Mix.Tasks.Format
  def format(text, options) do
    formatter_config = options[:regex_formatter]

    matching_replacement_configs =
      if options[:sigil] do
        Enum.filter(formatter_config, &(options[:sigil] in &1[:sigils]))
      else
        Enum.filter(formatter_config, &(options[:extension] in &1[:extensions]))
      end

    Enum.reduce(matching_replacement_configs, text, fn config, text ->
      replacements = Enum.map(config[:replacements], fn replacement ->
        case replacement do
          {search, replace} -> {search, replace, []}
          {search, replace, options} -> {search, replace, options}
          _ -> {
            :error,
            "Each entry in 'replacements' should be a 2 to 3 length tuple."
          }
        end
      end)

      error = Enum.find(replacements, &match?({:error, _}, &1))

      if error do
        {_, error_message} = error
        Logger.warning("RegexFormatter.format/2: " <> error_message)
        text
      else
        Enum.reduce_while(replacements, text, fn {search, replace, options}, text ->
          regex = case search do
            %Regex{} -> search
            _ -> Regex.compile!(search)
          end

          # Convert double-escaped newlines ("\\n") to single-escaped ("\n").
          # This allows mixing newlines and group substitutions (\1, \2, \3, etc.)
          # within a single string, generally using ~S to avoid double-slash escapes.
          # Without this replacement ~S will render literal "\n" strings in output
          # instead of actual newline chars.
          unescaped_newline_replace = String.replace(replace, "\\n", "\n")

          cond do
            options[:repeat] == nil ->
              # If `repeat` option not specified, just run regex replacement once.
              {:cont, Regex.replace(regex, text, unescaped_newline_replace)}

            is_integer(options[:repeat]) ->
              # If `repeat` integer option specified, re-run regex
              # replacements at most `repeat` times until text stops changing.
              # This properly handles cases where regex patterns overlap causing only
              # one instead of multiple instances of a pattern to be replaced.
              {:cont, Enum.reduce_while(1..options[:repeat], text, fn _, prev ->
                next = Regex.replace(regex, prev, unescaped_newline_replace)
                if next == prev, do: {:halt, next}, else: {:cont, next}
              end)}

            true ->
              Logger.warning(
                "RegexFormatter.format/2: " <>
                "Expected 'repeat' to be integer, not 'repeat: #{options[:repeat]}'"
              )
              {:halt, text}
          end
        end)
      end
    end)
  end
end

open_close_chars = ~w"""
() {} [] <> "" '' || //
"""

[
  import_deps: [:ecto, :ecto_sql, :phoenix, :temple],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter, RegexFormatter],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs"
  ],
  # Configure custom FilterFormatter to move "do" onto separate line when it appears
  # after a multi-line keyword list. This greatly improves readability, especially
  # in heavily-nested Temple (template) code.
  regex_formatter: [
    [
      extensions: [".ex", ".exs"],
      replacements: [
        # Trim extraneous whitespace from the beginning of ~u"..." strings:
        {
          ~r/~u["]\s+/s,
          "~u\""
        },

        # Collapse into single multiple spaces/newlines within ~u"..." strings:
        {
          ~r/(~u["][^"]+[^"\s])  +([^"\s])/s,
          ~S'\1 \2',
          repeat: 100, # Repeat substitution to correctly handle overlapping matches.
        },

        # Trim extraneous whitespace from the end of ~u"..." strings:
        {
          ~r/(~u["][^"]+[^"\s])\s+"/s,
          ~S'\1"'
        },

        # The following regex handles cases where "do" is preceded by any number
        # of closing braces, most commonly "] do", but also cases such as "})] do".
        # Any amount of whitespace can precede the braces in these situations.
        {
          ~S'\n( *)([\]\}\)]+) do\n  ( *)',
          ~S'\n\1\2\n\3do\n  \3'
        },

        # The following regex handles all other cases, where a keyword-list key/value
        # is followed directly by "do"; see documentation below for details.
        {
          ~s'\\n( *)([^ ]+|"[^"]*"): ([^ ]+|#{
            open_close_chars |> Enum.map(fn string ->
              open = String.at(string, 0)
              close = String.at(string, 1)
              # Optionally, handle sigil markers prior to open/close chars:
              sigil = "(?:~(?:[a-z]|[A-Z]+))"
              "#{sigil}?\\#{open}[^\\#{open}]*\\#{close}"
            end)
            |> Enum.join("|")
          }) do\\n  ( *)',
          ~S'\n\1\2: \3\n\4do\n  \4'
        },
        # Above regex handles unquoted or quoted keyword-list keys.
        # Above regex handles these types of keyword-list values:
        #
        # unquoted    "quoted"    (parenthesized)      [bracketed]      <caretted>
        #   ~s"quoted sigil"    ~s(parenthesized)    ~s[bracketed]    ~s<caretted>
        # ~ABC"quoted sigil"  ~ABC(parenthesized)  ~ABC[bracketed]  ~ABC<caretted>
        #
        # NOTE: For performance reasons triple-quoted sigils (heredocs) aren't handled.
        #       In practice, keyword-list use-cases for these don't appear significant.
        #
        # Further notes:
        # Both regexps above look at the line following "do" to determine correct level
        # of indentation after each "do" newline insertion. The number of spaces before
        # "do" will always be set as 2 spaces less than the number of spaces at the
        # start of the following line.

        # The following regex handles cases where a sigil value is split onto
        # multiple lines, eg.
        # div class: ~u\"this is a multiline
        #               sigil value\"  do
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~>
        # div class: ~u\"this is a multiline
        #               sigil value\"
        # do
        {
          ~s'(#{
            open_close_chars |> Enum.map(fn string ->
              open = String.at(string, 0)
              close = String.at(string, 1)
              "\\n\\s*[^\\#{open}\\#{close}]*\\#{close}"
            end)
            |> Enum.join("|")
          }) do\\n  ( *)',
          ~S'\1\n\2do\n  \2'
        }
      ]
    ]
  ]
]
