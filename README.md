# 🐧 linux-vm-setup

Shell scripts I use to provision my own **Ubuntu VMs** for hosting **FastAPI** services — from a bare install to a hardened, production-ready server running behind nginx and Supervisor.

[![Bash](https://img.shields.io/badge/Bash-Scripting-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Nginx](https://img.shields.io/badge/Nginx-ReverseProxy-009639?logo=nginx&logoColor=white)](https://nginx.org/)
[![Supervisor](https://img.shields.io/badge/Supervisor-ProcessManager-4B8BBE)](http://supervisord.org/)
[![UFW](https://img.shields.io/badge/UFW-Firewall-2C3E50)](https://help.ubuntu.com/community/UFW)
[![Fail2ban](https://img.shields.io/badge/Fail2ban-SSH%20Protection-0A0A0A)](https://www.fail2ban.org/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue)](LICENSE)

I built these to standardize how I set up every new VM (mainly on Oracle Cloud), instead of repeating the same manual steps each time. Sharing them here in case they're useful to someone else too. 🚀

---

## 📦 What's inside

Each script does **one job** and can be run on its own, or all together via `setup-all.sh`.

| # | Script | What it does |
|---|--------|---------------|
| 1️⃣ | `01-system-update.sh` | Updates & upgrades all system packages, cleans up unused ones |
| 2️⃣ | `02-create-user.sh` | Creates a non-root sudo user and copies your SSH key to it |
| 3️⃣ | `03-setup-swap.sh` | Creates a swap file (handy on low-RAM VMs, e.g. free-tier instances) |
| 4️⃣ | `04-setup-venv.sh` | Creates the app folder, a Python virtual environment, and installs `requirements.txt` |
| 5️⃣ | `05-setup-supervisor.sh` | Configures Supervisor to run your FastAPI app (via `uvicorn`) as a background service |
| 6️⃣ | `06-setup-nginx.sh` | Sets up nginx as a reverse proxy in front of your app |
| 7️⃣ | `07-setup-firewall.sh` | Installs UFW and opens only ports **22** (SSH), **80** (HTTP), **443** (HTTPS) |
| 8️⃣ | `08-setup-fail2ban.sh` | Installs fail2ban to block brute-force SSH login attempts |

🔒 **Note on SSL/HTTPS:** not included here, since a trusted certificate (Let's Encrypt) requires an actual domain pointed at your VM — it can't be issued for a bare IP. If you have a domain, point it at your server and add certbot manually after running `06-setup-nginx.sh` with your domain name.

---

## 🧩 Config templates

The `templates/` folder shows the **exact shape** of the nginx and Supervisor config files that get generated:

```
templates/
├── nginx.conf.template        # what /etc/nginx/sites-available/<app_name> ends up looking like
└── supervisor.conf.template   # what /etc/supervisor/conf.d/<app_name>.conf ends up looking like
```

Each one uses placeholders that map directly to the arguments you pass to the corresponding script:

| Placeholder | Comes from | Example |
|---|---|---|
| `${APP_NAME}` | 1st arg to `05-setup-supervisor.sh` / `06-setup-nginx.sh` | `myapp` |
| `${APP_DIR}` | app folder created by `04-setup-venv.sh` | `/opt/myapp` |
| `${APP_MODULE}` | your uvicorn entrypoint | `main:app` |
| `${PORT}` / `${UPSTREAM_PORT}` | port your app listens on | `8000` |
| `${RUN_USER}` | user created by `02-create-user.sh` | `deploy` |
| `${LOG_DIR}` | log folder used by Supervisor | `/var/log/myapp` |
| `${SERVER_NAME}` | domain, or `_` for catch-all if you don't have one yet | `myapp.example.com` |

**Current behavior:** `05-setup-supervisor.sh` and `06-setup-nginx.sh` currently write the config directly (inline heredoc), they don't read from `templates/*.template`. The template files are there as **reference/documentation** — read them to see what the final config looks like, or copy one to `/etc/...` manually and fill it in by hand if you want to tweak something the scripts don't expose as an argument.

> If you want the scripts to actually generate the file *from* `templates/`, swap the heredoc for `envsubst < templates/nginx.conf.template > "$CONFIG_PATH"` (requires `gettext-base`) — that's the natural next step for this repo.

---

## ⚙️ How to use

Every script works in **two ways**:

- **Non-interactive** — pass all values as CLI arguments (great for automation)
- **Interactive** — leave arguments out and the script will prompt you for what it needs

Every step also prints out **what it's about to do**, and a **confirmation summary** at the end, so nothing runs silently.

### Run everything at once

```bash
sudo ./setup-all.sh deploy myapp /opt/myapp ./requirements.txt main:app 8000
```

Or just run it with no arguments and answer the prompts:

```bash
sudo ./setup-all.sh
```

### Run a single step

```bash
sudo ./scripts/01-system-update.sh
sudo ./scripts/02-create-user.sh deploy
sudo ./scripts/06-setup-nginx.sh myapp 8000 mydomain.com
```

### Make scripts executable

If you get a "permission denied" error:

```bash
chmod +x setup-all.sh scripts/*.sh
```

---

## 🖥️ Requirements & Compatibility

- A fresh **Debian-based** VM — built and tested on **Ubuntu 24.04**. Should also work on Debian with no changes.
- **Not compatible as-is** with RHEL/CentOS/Fedora (`dnf`/`yum`) or Arch — these scripts rely on `apt`, `adduser` and `ufw`, which are Debian/Ubuntu-specific.
- Root access (`sudo`)

---

## 📁 Project structure

```
linux-vm-setup/
├── setup-all.sh
├── scripts/
│   ├── 01-system-update.sh
│   ├── 02-create-user.sh
│   ├── 03-setup-swap.sh
│   ├── 04-setup-venv.sh
│   ├── 05-setup-supervisor.sh
│   ├── 06-setup-nginx.sh
│   ├── 07-setup-firewall.sh
│   └── 08-setup-fail2ban.sh
├── templates/
│   ├── nginx.conf.template
│   └── supervisor.conf.template
├── LICENSE
└── README.md
```

---

## 👨‍💻 Author

Francesco Falone — solo developer building and deploying full-stack projects (FastAPI, Flutter, PostgreSQL/Supabase) on self-managed Linux VMs. These scripts are the setup I actually use for my own servers.

---

## 📄 License

Licensed under the [Apache License 2.0](LICENSE).
