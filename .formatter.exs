defmodule Perl do
  def executable() do
    "perl"
  end

  def args(arguments) do
    List.flatten(arguments)
  end

  def multiline() do
    "-0777" # Causes regex replacements to operate across newlines.
  end

  def replace(pattern, replacement) do
    ["-pe", "s/#{pattern}/#{replacement}/g;"]
  end
end

[
  import_deps: [:ecto, :ecto_sql, :phoenix, :temple],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter, FilterFormatter],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs"
  ],
  # Configure custom FilterFormatter to move "do" onto separate line when it appears
  # after a multi-line keyword list. This greatly improves readability, especially
  # in heavily-nested Temple (template) code.
  filter_formatter: [
    [
      extensions: [".ex", ".exs"],
      executable: Perl.executable(),
      args: Perl.args([
        Perl.multiline(),
        # Trim extraneous whitespace from the beginning of ~u"..." strings:
        Perl.replace(~S'~u\"\s+', "~u\""),
        # Collapse into single multiple spaces/newlines within ~u"..." strings:
        Perl.replace(~S'(?<=~u\"[^"]{1,250}[^"\s])  +', " "),
        # [NOTE] {1,250} limit needed to avoid Perl limitation:
        # "Lookbehind longer than 255 not implemented in regex"

        # Trim extraneous whitespace from the end of ~u"..." strings:
        Perl.replace(~S'(?<=~u\"[^"]{1,250}[^"\s])\s+"', "\""),
        # [NOTE] {1,250} limit needed to avoid Perl limitation:
        # "Lookbehind longer than 255 not implemented in regex"

        # The following regex handles cases where "do" is preceded by any number
        # of closing braces, most commonly "] do", but also cases such as "})] do".
        # Any amount of whitespace can precede the braces in these situations.
        Perl.replace(~S'\n( *)([\]\}\)]+) do\n  ( *)', ~S'\n\1\2\n\3do\n  \3'),
        # The following regex handles all other cases, where a keyword-list key/value
        # is followed directly by "do"; see documentation below for details.
        Perl.replace(
          ~s'\\n( *)([^ ]+|"[^"]*"): ([^ ]+|#{
            ~w"""
            () {} [] <> "" '' || //
            """
            # These open/close chars are handled by constructed regex below:
            |> Enum.map(fn string ->
              open = String.at(string, 0)
              close = String.at(string, 1)
              # Optionally, handle sigil markers prior to open/close chars:
              sigil = "(?:~(?:[a-z]|[A-Z]+))"
              "#{sigil}?\\#{open}[^\\#{open}]*\\#{close}"
            end)
            |> Enum.join("|")
          }) do\\n  ( *)',
          ~S'\n\1\2: \3\n\4do\n  \4'
        ),
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
      ])
    ]
  ]
]
