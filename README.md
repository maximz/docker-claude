# docker-claude

Docker image for running Claude Code with development tools, firewall support, and headless Chrome.

```bash
docker run \
  --cap-add=NET_ADMIN \
  --mount type=bind,source="$HOME/.claude",target=/home/node/.claude \
  --mount type=bind,source="$PWD",target=/workspace/project \
  --workdir /workspace/project \
  -it cc claude --dangerously-skip-permissions;
```

## Puppeteer / Headless Chrome

This image includes Google Chrome Stable and sets `PUPPETEER_EXECUTABLE_PATH` so Puppeteer uses it automatically. However, you **must** pass `--no-sandbox` in your Puppeteer launch args when running inside Docker:

```js
const browser = await puppeteer.launch({
  args: ['--no-sandbox'],
});
```

This is required because Docker containers lack the Linux namespace privileges that Chrome's sandbox needs. See [Puppeteer troubleshooting docs](https://pptr.dev/troubleshooting#setting-up-chrome-linux-sandbox) for details.
