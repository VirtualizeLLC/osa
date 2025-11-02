# OSA Snippet Profiles

OSA uses profiles to filter which snippet types get loaded into your shell. This lets each developer get only the tools and aliases relevant to their work.

## Available Profile Types

| Profile | Purpose | Best For |
|---------|---------|----------|
| **web** | Frontend/web development | React, Vue, Svelte, npm, webpack, build tools |
| **backend** | Backend/polyglot development | APIs, databases, microservices, Docker |
| **react-native** | Mobile app development | iOS/Android with React Native, Expo |
| **node** | Node.js specific | Node development, npm/yarn/pnpm, ts-node |
| **everything** | All profiles combined | Need all development tools |

## Combining Profiles

You can combine multiple profiles (comma-separated):

```json
{
  "profile": "web,backend"
}
```

This loads snippets from both `web/` and `backend/` directories.

### Common Combinations

```bash
# Full stack development
"profile": "web,backend"

# Mobile + web
"profile": "react-native,web"

# Everything
"profile": "everything"
```

## How Profiles Work

1. **Specified in config** → User selects profile during setup or in JSON config
2. **Saved to ~/.osaconfig** → `OSA_PROFILE="web,backend"`
3. **osa-snippets reads it** → Only sources snippets from those profile directories
4. **Snippets loaded at shell init** → User gets only relevant aliases and functions

## Default Profiles by Config

| Config | Profile | Description |
|--------|---------|-------------|
| `minimal.json` | `web` | Core shell with basic web snippets |
| `web.json` | `web` | Frontend-focused setup |
| `backend.json` | `backend` | Backend/polyglot development |
| `react-native.json` | `react-native,node` | Mobile + Node development |
| `ios.json` | `react-native,web` | iOS development with web tools |
| `android.json` | `react-native,web` | Android development with web tools |
| `everything.json` | `everything` | All available profiles |

## Directory Structure

Snippets are organized by profile:

```
src/zsh/plugins/
├── shared/              # Always loaded (git, oh-my-zsh, etc)
│   ├── git-setup.zsh
│   └── oh-my-zsh-setup.zsh
├── web/                 # If profile contains "web"
│   ├── npm-aliases.zsh
│   └── webpack.zsh
├── backend/             # If profile contains "backend"
│   ├── docker-aliases.zsh
│   └── database-tools.zsh
├── react-native/        # If profile contains "react-native"
│   ├── android-setup.zsh
│   └── emulator-aliases.zsh
└── node/                # If profile contains "node"
    ├── nodemon-aliases.zsh
    └── ts-node-setup.zsh
```

## Setting Profile During Setup

### Interactive Setup

```bash
./osa-cli.zsh --interactive
```

You'll be prompted:
```
What development profiles do you use?
(web, backend, react-native, node, everything)

Enter comma-separated profiles: web,backend
```

### Using a Preset Config

```bash
# Automatically uses the profile from the config
./osa-cli.zsh --config web
./osa-cli.zsh --config backend
./osa-cli.zsh --config react-native
```

### Custom Config

Create a config with your desired profile:

```json
{
  "version": "1.0",
  "profile": "web,backend",
  "components": { ... }
}
```

Then run:
```bash
./osa-cli.zsh --config-file my-config.json
```

## View Current Profile

Check what profile is set:

```bash
grep OSA_PROFILE ~/.osaconfig
# Output: OSA_PROFILE="web,backend"
```

## Changing Profile Later

Edit `~/.osaconfig` and update the `OSA_PROFILE` line:

```bash
# Before
OSA_PROFILE="web"

# After
OSA_PROFILE="web,backend"
```

Then restart your shell or run:
```bash
source ~/.osaconfig
```

## What Gets Loaded

When you set `profile: "web,backend"`, OSA loads:

1. **Shared snippets** (always):
   - Core OSA setup
   - Oh My Zsh configuration
   - Git configuration
   - Common aliases

2. **Web snippets**:
   - npm aliases (npm-audit, npm-outdated, etc)
   - webpack shortcuts
   - React/Vite/build tool aliases

3. **Backend snippets**:
   - Docker aliases (docker-clean, docker-logs, etc)
   - Database connection tools
   - API testing shortcuts (curl-json, curl-post, etc)

Users don't load snippets they don't need, keeping shells lean and fast.

## FAQ

**Q: Can I change my profile later?**
A: Yes, edit `~/.osaconfig` and restart your shell.

**Q: What if I select a profile I don't need?**
A: Extra snippets won't hurt, but you'll have unnecessary aliases. Change to a profile that matches your work.

**Q: Can I have multiple profiles on one machine?**
A: Currently, you get one profile per shell configuration. You could maintain different OSA installations for different profiles, or just use `everything`.

**Q: Do profiles affect which runtimes are installed?**
A: No, profiles only filter snippets. Runtimes are controlled by the `runtimes` section in your config file.

**Q: What about my constructors?**
A: Constructors are always loaded (in `src/zsh/constructors/`). Profiles don't affect them. You have full control via constructors.
