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
      executable: "perl",
      args: [
        "-0777", # Turn-on whole-file processing so regex operate over multiple lines.

        # Trim extraneous whitespace from the beginning of ~u"..." strings:
        "-pe",
        ~S"""
        s/~u\"\s+/~u\"/g;
        """,
        # Collapse into single multiple spaces/newlines within ~u"..." strings:
        "-pe",
        ~S"""
        s/(?<=~u\"[^"]{1,250}[^"\s])  +/ /g;
        """,
        # [NOTE] {1,250} limit needed to avoid Perl limitation:
        # "Lookbehind longer than 255 not implemented in regex"

        # Trim extraneous whitespace from the end of ~u"..." strings:
        "-pe",
        ~S"""
        s/(?<=~u\"[^"]{1,250}[^"\s])\s+"/"/g;
        """,
        # [NOTE] {1,250} limit needed to avoid Perl limitation:
        # "Lookbehind longer than 255 not implemented in regex"

        # The following regex handles cases where "do" is preceded by any number
        # of closing braces, most commonly "] do", but also cases such as "})] do".
        # Any amount of whitespace can precede the braces in these situations.
        "-pe",
        ~S"""
        s/\n( *)([\]\}\)]+) do\n  ( *)/\n\1\2\n\3do\n  \3/g;
        """,
        # The following regex handles all other cases, where a keyword-list key/value
        # is followed directly by "do"; see documentation below for details.
        "-pe",
        ~s"""
          s/
            \\n( *)([^ ]+|"[^"]*"): (
              [^ ]+|#{ # This pattern handles unquoted keyword-list values.
                # These open/close chars are handled by constructed regex below:
                ~w"""
                () {} [] <> "" '' || //
                """
                |> Enum.map(fn string ->
                  open = String.at(string, 0)
                  close = String.at(string, 1)
                  # Optionally, handle sigil markers prior to open/close chars:
                  sigil = "(?:~(?:[a-z]|[A-Z]+))"
                  "#{sigil}?\\#{open}[^\\#{open}]*\\#{close}"
                end)
                |> Enum.join("|")
              }
            ) do\\n  ( *)
          /
            \\n\\1\\2: \\3\\n\\4do\\n  \\4
          /g;
        """
        |> String.replace(~r/(\r|\n)+\s*/, ""), # Ignore newlines+indentation above.
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
      ]
    ],
  ]
]
