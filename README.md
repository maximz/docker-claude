```
alias claude-docker='docker run \
  --cap-add=NET_ADMIN \
  --mount type=bind,source="$HOME/.claude",target=/home/node/.claude \
  --mount type=bind,source="$PWD",target=/workspace/project \
  --workdir /workspace/project \
  -it cc';
#  --mount type=bind,source="$HOME/.claude.json",target=/home/node/.claude.json \

alias ccdd='claude-docker claude --dangerously-skip-permissions';
```
