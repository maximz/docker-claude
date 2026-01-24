# docker-claude

Docker image for running Claude Code with development tools, firewall support, and headless Chrome.

## Puppeteer / Headless Chrome

This image includes Google Chrome Stable and sets `PUPPETEER_EXECUTABLE_PATH` so Puppeteer uses it automatically. However, you **must** pass `--no-sandbox` in your Puppeteer launch args when running inside Docker:

```js
const browser = await puppeteer.launch({
  args: ['--no-sandbox'],
});
```

This is required because Docker containers lack the Linux namespace privileges that Chrome's sandbox needs. See [Puppeteer troubleshooting docs](https://pptr.dev/troubleshooting#setting-up-chrome-linux-sandbox) for details.
