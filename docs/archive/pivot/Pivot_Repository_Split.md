# Choir: Harmonic Intelligence Platform

VERSION harmonic_system:
invariants: {
"Wave resonance",
"Energy conservation",
"Pattern emergence"
}
assumptions: {
"Apple ecosystem excellence",
"Swift implementation",
"Natural harmonics"
}
docs_version: "0.3.0"  # Post-alignment vision, Nov 2024
# Repository Split Strategy

## Overview

Split current monorepo into three focused repositories:

```
choir-collective/
├── api/          -> choir-api/
├── anchor/       -> choir-anchor/
└── src/          -> choir-website/
```

## 1. choir-api (Python Backend)

```bash
choir-api/
├── app/
│   ├── chorus_cycle.py
│   ├── database.py
│   ├── models.py
│   └── websocket_handler.py
├── tests/
├── pyproject.toml
└── README.md

Key Dependencies:
- FastAPI
- Qdrant
- LiteLLM
- WebSockets
```

## 2. choir-anchor (Solana Programs)

```bash
choir-anchor/
├── programs/
│   └── thread/
│       ├── src/
│       └── Cargo.toml
├── tests/
├── Anchor.toml
└── README.md

Key Dependencies:
- Anchor
- Solana CLI
- Rust toolchain
```

## 3. choir-website (Static Marketing Site)

Recommended: [Zola](https://www.getzola.org/)

```bash
choir-website/
├── content/           # Markdown files
│   ├── _index.md     # Homepage
│   ├── about.md
│   └── docs/
├── templates/
│   └── base.html
├── static/
│   ├── images/
│   └── styles/
├── config.toml
└── README.md

Benefits of Zola:
1. Single binary (Rust-based)
2. Lightning fast
3. Simple markdown -> site
4. Great templating
5. Zero JavaScript by default
6. Built-in syntax highlighting
7. Hot reloading
```

## Migration Steps

1. **API Split**

```bash
# Create new repo
mkdir choir-api
cd choir-api

# Copy API files
cp -r ../choir-collective/api/* .

# Update dependencies
poetry init
poetry add fastapi qdrant-client litellm

# Setup GitHub Actions
mkdir -p .github/workflows
```

2. **Anchor Split**

```bash
# Create new repo
mkdir choir-anchor
cd choir-anchor

# Copy Anchor files
cp -r ../choir-collective/anchor/* .

# Update configs
# - Update Anchor.toml paths
# - Update deployment scripts
```

3. **Website Creation**

```bash
# Install Zola
brew install zola  # macOS
apt install zola   # Ubuntu

# Create new site
zola init choir-website

# Setup content structure
mkdir -p content/docs
mkdir -p templates/shortcodes
```

## Website Workflow

1. **Content Updates**

```markdown
# content/docs/overview.md

+++
title = "Overview"
weight = 1
+++

# Choir Platform

Content here...
```

2. **Automatic Deployment**

```yaml
# .github/workflows/deploy.yml
name: Deploy Website
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and deploy
        uses: shalzz/zola-deploy-action@v0.17.2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

3. **Local Development**

```bash
zola serve  # Hot reloading at http://localhost:1111
```

## Benefits of Split

1. **Focused Repositories**

   - Clean separation of concerns
   - Simpler CI/CD pipelines
   - Easier to maintain
   - Better team scaling

2. **Optimized Tooling**

   - Python-specific tools for API
   - Rust/Anchor tools for programs
   - Static site tools for website

3. **Performance**

   - No JavaScript bloat
   - Fast static site
   - Efficient deployments

4. **Documentation**
   - Marketing site from markdown
   - Easy content updates
   - Version controlled
   - Automated deployment

## Next Steps

1. Create new repositories
2. Setup CI/CD pipelines
3. Migrate code and dependencies
4. Update documentation
5. Setup monitoring
6. Configure deployments
