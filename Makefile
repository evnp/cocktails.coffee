h help :: .usage

s  start :: #  start application
	@make kill
	@bash -c \
		'trap "loading fin" EXIT; loading; tmex phoenix -qd "mix phx.server"; sleep 5'
	@make client

k   kill :: #   kill application
	@pkill -f phx.server || true # ignore errors
	@tmex phoenix -qk    || true # ignore errors

c client :: #   open client
	@open http://localhost:4000

s server :: # attach to server
	@tmex phoenix --reattach

r   repl :: #  start shell
	@iex -S mix

.usage:
	@grep -E '^[^@]*:.*#' $(MAKEFILE_LIST) | sed -E 's/(.*):(.*):.*#(.*)/	\1·\2\3/'
