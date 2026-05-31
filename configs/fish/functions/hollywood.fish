function hollywood --wraps='podman run -it --rm cgr.dev/chainguard/hollywood' --description 'alias hollywood=podman run -it --rm cgr.dev/chainguard/hollywood'
    podman run -it --rm cgr.dev/chainguard/hollywood $argv
end
