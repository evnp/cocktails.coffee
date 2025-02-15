defmodule CcWeb.Util.StringUtils do
  def collapse_whitespace(str) do
    # Replace any runs of whitespace with a single space:
    str = String.replace(str, ~r/\s+/, " ")

    first = String.at(str, 0)
    last = String.at(str, -1)

    # Remove possible leading and trailing single-spaces from string:
    # (use binary char replacement instead of String.trim for performace purposes)
    str = cond do
      first == " " && last == " " ->
        <<_head::binary-1,rest::binary-size(byte_size(str)-2),_tail::binary-1>> = str
        rest
      first == " " ->
        <<_head::binary-1,rest::binary-size(byte_size(str)-1)>> = str
        rest
      last == " " ->
        <<rest::binary-size(byte_size(str)-1),_tail::binary-1>> = str
        rest
      true ->
        str
    end

    str
  end
end
