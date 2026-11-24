# CN Project - Private Network Service Platform (Team diddybois)

A client resolves `app.diddybois.test` through our own DNS, connects over HTTPS to an nginx edge, and is load-balanced across two REST backends. Phase 1 builds and observes it; Phase 2 hardens it (backup DNS, TTL, isolation, failover, edge migration, troubleshooting).

## Team and machines

| Mac | Person | Role | IP | Port |
|---|---|---|---|---|
| Mac 1 | Yash | Primary DNS, client, standby edge | 10.7.21.158 | 53/UDP, 8443 |
| Mac 2 | Preet | Primary edge / load balancer (nginx + TLS) | 10.7.29.194 | 8443 |
| Mac 3 | Phalak | Backend A | 10.7.26.199 | 3001 |
| Mac 4 | Archit | Backend B, backup DNS | 10.7.21.79 | 3002, 53/UDP |

IPs are DHCP-assigned and change. Edit `team.env`, then run `scripts/render.sh` to regenerate the configs.

## Layout

| Path | What |
|---|---|
| `team.env` | single source of truth for IPs, ports, TTL |
| `configs/templates/` | config templates; `configs/*.conf` are rendered from them |
| `configs/phase1/` | original Phase 1 dnsmasq and nginx configs |
| `source/` | backend applications (`server-a.py`, `server-b.py`) |
| `tls/` | CA certificate and server certificate (private keys are never committed) |
| `scripts/` | run, test, firewall, demo and diagnosis scripts |
| `docs/` | `ARCHITECTURE.md`, `PHASE2_REPORT.md`, diagrams |
| `evidence/` | Phase 1 (01-26) and Phase 2 (27-32) screenshots, captures, per-Mac inventories; see `PHASE2_INDEX.md` |

## Quick start

```bash
git clone https://github.com/OnlineBunker/cn-project.git && cd cn-project
scripts/render.sh                            # after editing team.env
sudo scripts/dns.sh start primary            # Mac 1   (backup on Mac 4: start backup)
scripts/backend.sh start A                   # Mac 3   (B on Mac 4)
scripts/edge.sh start                        # Mac 2; use EDGE_SUDO=1 if backends are unreachable (see report, finding 1)
scripts/lb-test.sh 6                         # from a client: alternating X-Backend A/B, no -k
scripts/diagnose.sh                          # DNS -> TCP -> TLS -> HTTP check
```

Clients must trust `tls/team-ca.crt` and use both DNS servers (`10.7.21.158`, `10.7.21.79`). The edge needs `app.diddybois.test.crt/.key` in `CERT_DIR` (`/opt/homebrew/etc/nginx/certs`); the key is not in the repo.

## Phase 2 demos (match the final demonstration sequence)

| Script | Extension |
|---|---|
| `demo-a-dns-failover.sh` | A backup DNS |
| `demo-b-ttl.sh` | B TTL and record change |
| `demo-c-isolation.sh` | C backend firewall (pf) with rollback |
| `demo-d-ha.sh` | D failover and recovery |
| `demo-e-cutover.sh` | E DNS-based edge migration |
| `demo-f-troubleshoot.sh` | F fault diagnosis |

`scripts/evidence.sh <name> <script> [--sudo]` runs a demo in a Terminal window and saves a screenshot to `evidence/`. `scripts/inventory.sh <name>` records a Mac's network facts.

## Docs
- Architecture, topology and request flow: `docs/ARCHITECTURE.md`
- Phase 2 results, explanations and findings: `docs/PHASE2_REPORT.md`
