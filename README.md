# Deploy and Host botmux on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/botmux?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=botmux)

botmux connects Feishu and Lark chats to AI coding CLIs. Every direct message, group or topic thread gets its own live Claude Code, Codex or OpenCode session: you type in the chat, the agent works in a real terminal on the server, and its output streams back into the chat as cards. It adds a web dashboard, scheduled tasks, webhook and API triggers, and a browser terminal for each session. This template runs botmux 3.59.19 on Railway with Claude Code, Codex and OpenCode installed, a token-protected dashboard, and a volume that keeps bots, sessions, CLI logins and projects across redeploys.

This is a community template, not made or supported by the botmux project. It is not affiliated with ByteDance, Feishu, Lark, Anthropic or OpenAI.

## About Hosting botmux

botmux, its dashboard and the coding CLIs run in one container. Each bot keeps a long-lived WebSocket connection to Feishu or Lark, so you don't need a callback URL or event subscription URL.

**Open the dashboard:** go to `https://YOUR-DOMAIN/?t=DASHBOARD_TOKEN`, using the token from the service's **Variables** tab. The browser keeps a cookie, so the plain domain works after that. Without the token, the dashboard shows nothing: sessions, groups, settings and the host terminal all need it. To sign everyone out, change `DASHBOARD_TOKEN` and redeploy.

**Add a bot.** There are two ways to do it:

- **From the dashboard.** Click **Create bot** and scan the QR code with the Feishu app. botmux creates the Feishu app for you and makes you its owner.
- **From your own app.** Create a custom app in the [Feishu](https://open.feishu.cn/app) or [Lark](https://open.larksuite.com/app) developer console. Turn on the bot feature, grant the permissions in [botmux's guide](https://deepcoldy.github.io/botmux/en/quickstart), and choose **long connection** for event delivery. Then set these variables:
  - `FEISHU_APP_ID` and `FEISHU_APP_SECRET`;
  - `FEISHU_DOMAIN`: `feishu` for China, `lark` for international;
  - `FEISHU_OWNER`: your work email or phone.

  The pair is checked on every boot. If Feishu rejects it, the bot is set aside and the deploy logs say what to fix. The dashboard keeps running, so the service never crash-loops on a bad secret.

**Set `FEISHU_OWNER`.** Without it, a bot runs in botmux's open mode: anyone in your organisation who can see the app can start sessions and run commands on this server.

**Sign in the coding CLIs.** Use either a variable or a shell:

- **Claude Code:** `ANTHROPIC_API_KEY`, or `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token` for a Claude subscription.
- **Codex:** `OPENAI_API_KEY`, which signs Codex in on every boot. For a ChatGPT plan, run `railway ssh` and then `codex login --device-auth`.
- **OpenCode:** `OPENROUTER_API_KEY`, `ANTHROPIC_API_KEY` or `OPENAI_API_KEY`. You can also run `opencode auth login` in a shell.

Logins done in a shell are saved on the volume. They survive redeploys.

## Common Use Cases

- Run Claude Code or Codex from your phone through Feishu or Lark, with the full terminal one tap away
- Give a team group chat one coding agent per topic, each in its own repository and worktree
- Schedule agent jobs (daily reports, dependency checks) and trigger them from webhooks or CI

## Dependencies for botmux Hosting

- A Feishu or Lark account that can create a custom app.
- An API key or subscription for at least one coding CLI: Claude Code, Codex or OpenCode.

### Deployment Dependencies

- [botmux on GitHub](https://github.com/deepcoldy/botmux)
- [botmux documentation](https://deepcoldy.github.io/botmux/en/)
- [Feishu developer console](https://open.feishu.cn/app) / [Lark developer console](https://open.larksuite.com/app)
- [Template source](https://github.com/two-workspaces/botmux)

### Implementation Details

- **Not tested with a real Feishu or Lark account.** We have none, so no real chat went through this template. With made-up Feishu and Lark app credentials, the bots kept retrying the connection, and botmux and the dashboard stayed up. A first real chat may need tweaks to the app's permissions or events.
- **What was tested on Railway:**
  - booting with no credentials;
  - booting with made-up Feishu and Lark credentials;
  - the dashboard token: without it, the API answers 401;
  - bots and settings surviving a redeploy and a restart;
  - Claude Code, Codex and OpenCode starting and reaching their APIs.
- **Memory:** idle with one bot, botmux used about 180 MB in our test (about 250 MB with two bots), so it boots on a 0.5 GB plan. Each running agent session adds a CLI process, usually a few hundred MB, so give it 1 GB or more for real work.
- **Your data** lives on the volume at `/data`, which is also the home directory:
  - `~/.botmux`: bots, sessions, schedules, logs and the dashboard token;
  - `~/.claude`, `~/.codex` and `~/.local/share/opencode`: CLI logins;
  - `~/projects`: the default working directory for new sessions. Clone your repositories there.

  Turn on volume backups in the service's **Backups** tab.
- **Agents have full access to the container.** botmux starts Claude Code and Codex without their permission prompts, which is upstream's default. Codex's own sandbox can't start on Railway because user namespaces are blocked, so the container is the boundary. Keep `FEISHU_OWNER` set.
- **Variables and the dashboard:**
  - The bot from `FEISHU_APP_ID` is added once. Afterwards, its CLI, model and other settings are edited in the dashboard and kept.
  - `FEISHU_APP_SECRET`, `FEISHU_DOMAIN` and `FEISHU_OWNER` are applied on every boot.
  - Bots made in the dashboard are never touched.
- **Card links:**
  - Terminal and dashboard links in cards use your Railway domain (`RAILWAY_PUBLIC_DOMAIN`, or `PUBLIC_URL` for a custom domain).
  - Each session's browser terminal is served at `/s/SESSION` on the same domain, behind the same token.
- **Updates:** botmux's self-update is off. The template pins botmux and each CLI, and new versions come as template updates.
- **Shell access:** in a `railway ssh` shell the home directory is the volume, so `botmux status`, `botmux logs`, `botmux dashboard` (which prints the login link), `claude`, `codex login` and `opencode auth login` work on the same files as the service.

## 中文说明

这是 botmux 的 Railway 一键部署模板。它把飞书（Feishu）或 Lark 的会话接到 Claude Code、Codex 和 OpenCode：每个私聊、群或话题都有自己的会话。

- 部署后打开 `https://你的域名/?t=DASHBOARD_TOKEN`（令牌在 Variables 里）进入控制台。
- 添加机器人有两种方式：
  - 在控制台点「Create bot」，用飞书扫码创建；
  - 或者填写 `FEISHU_APP_ID`、`FEISHU_APP_SECRET`、`FEISHU_DOMAIN`（国内填 `feishu`，海外 Lark 填 `lark`）。
- 务必填写 `FEISHU_OWNER`（你的工作邮箱或手机号），否则组织内任何人都能操作这台服务器。
- 凭证错误时服务不会崩溃：控制台继续运行，日志里会写明需要修改的地方。
- 模板作者没有飞书或 Lark 账号，真实聊天未经测试。

## Why Deploy botmux on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying botmux on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
