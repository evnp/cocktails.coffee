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
        "-0777",
        "-pe",
        "s/\\n( *)([\\]\\}\\)]+) do\\n  ( *)/\\n\\1\\2\\n\\3do\\n  \\3/g;",
        # Above regex handles cases where "do" is preceded by any number of closing
        # braces, most commonly "] do", but also cases such as "})] do".
        # Any amount of whitespace can precede the braces in these situations.
        "-pe",
        ~s"""
          s/
            \\n( *)([^ ]+|\"[^\"]*\"): (
              [^ ]+
              |{SIGIL}?\"[^\"]*\"
              |{SIGIL}?\\([^\\)]*\\)
              |{SIGIL}?\\[[^\\]]*\\]
              |{SIGIL}?<[^>]*>
            ) do\\n  ( *)
          /
            \\n\\1\\2: \\3\\n\\4do\\n  \\4
          /g;
        """
        |> String.replace("{SIGIL}", "(?:~(?:[a-z]|[A-Z]+))")
        |> String.replace(~r/(\r|\n)+\s*/, "")
        # Above regex handles standard unquoted keyword-list keys (without spaces).
        # Above regex handles these types of keyword-list values:
        # unquoted "quoted"    (parenthesized)     [bracketed]     <caretted>
        # ~s"quoted sigil"   ~s(parenthesized)   ~s[bracketed]   ~s<caretted>
        # ~ABC"quoted sigil" ~ABC(parenthesized) ~ABC[bracketed] ~ABC<caretted>
        # Further notes:
        # Both regexps above look at the line following "do" to determine correct level
        # of indentation after each "do" newline insertion. The number of spaces before
        # "do" will always be set as 2 spaces less than the number of spaces at the
        # start of the following line.
      ]
    ]
  ]
]
