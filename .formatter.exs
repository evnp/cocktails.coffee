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
      preset_trim_sigil_whitespace: [:u],
      preset_collapse_sigil_whitespace: [:u],
      preset_do_on_separate_line_after_multiline_keyword_args: true
    ]
  ]
]
