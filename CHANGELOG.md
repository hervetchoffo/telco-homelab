# Changelog

All notable changes to this project are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org) with project-specific
conventions described in [README.md](README.md#versioning-semver).

---

## [Unreleased]

---

## [1.1.0] — 2025-04-29

### Added
- `README.md`: project overview, hardware architecture diagram, full roadmap table,
  SemVer conventions (MAJOR / MINOR / PATCH / -rc.N / -final)
- `CHANGELOG.md`: version history (this file), Keep a Changelog format
- `LICENSE`: MIT licence
- `.gitignore`: excludes kubeconfig, secrets, `.env` files, build artefacts
- Full repository directory structure:
  `docs/`, `k8s/`, `docker/`, `monitoring/`, `scripts/`, `.github/`
- `docs/adr/ADR-001-k3s-vs-k0s.md`: K3s selected over K0s
- `docs/adr/ADR-002-gitea-vs-gitlab.md`: Gitea selected over GitLab
- `docs/adr/ADR-003-bookworm-vs-trixie.md`: Raspberry Pi OS Trixie selected
- `docs/hld/architecture.md`: HLD stub (to be completed in v1.2.0)
- `docs/PROJECT_CONTEXT.md`: AI session briefing block + project status tracker
- `scripts/init-repo.sh`: self-contained repository initialisation script
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- README stubs for all service directories
- `.gitkeep` placeholders in all empty directories

---

[Unreleased]: https://github.com/hervetchoffo/telco-homelab/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/hervetchoffo/telco-homelab/releases/tag/v1.1.0
