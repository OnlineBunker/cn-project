# Private Network Service Platform - Architecture (Phase 1 + Phase 2)

Domain: `app.diddybois.test`, `api.diddybois.test` (reserved `.test` namespace). Edge port 8443 (non-privileged substitute for 443).
All addresses live in `team.env`; `scripts/render.sh` regenerates the configs from `configs/templates/`.

## Machine / service table (Phase 2)

| Mac | Owner | Role | IP | Services | Port |
|---|---|---|---|---|---|
| Mac 1 | Yash | Primary DNS, client, **standby edge** | 10.7.21.158 | dnsmasq (primary), nginx (standby edge, run as root) | 53/UDP, 8443/TCP |
| Mac 2 | Preet | Primary edge / reverse proxy / load balancer | 10.7.29.194 | nginx + TLS | 8443/TCP |
| Mac 3 | Phalak | Backend A | 10.7.26.199 | Python REST (`source/server-a.py`), pf isolation | 3001/TCP |
| Mac 4 | Archit | Backend B, **backup DNS** | 10.7.21.79 | REST backend, dnsmasq (backup), pf isolation | 3002/TCP, 53/UDP |

Phase 1 used different DHCP addresses (10.7.23.146 / .10.154 / .21.102 / .17.77); the table above is the current Phase 2 inventory.

## Request flow

```
Client -> DNS (UDP/53) primary Mac 1, then backup Mac 4 if primary is down
       -> app.diddybois.test = Mac 2 (TTL 30 s)
       -> TCP 8443 -> TLS 1.2/1.3 handshake (cert from Team Local CA) terminated at nginx
       -> HTTP/1.1 proxy, round-robin
       -> Backend A (Mac 3 :3001) or Backend B (Mac 4 :3002) -> response with X-Backend, X-Edge
```

Protocol layers: DNS (application, UDP 53) - HTTP (application) - TLS (between application and transport) - TCP (transport) - IP (network) - Ethernet/Wi-Fi (link).

## Phase 2 additions

| Extension | What was added | Files |
|---|---|---|
| A Backup DNS | dnsmasq on Mac 4 with identical records; clients list `10.7.21.158, 10.7.21.79` | `configs/dnsmasq-backup.conf`, `scripts/dns.sh`, `scripts/demo-a-dns-failover.sh` |
| B TTL | `local-ttl=30`, records in a hosts file changed live with SIGHUP | `configs/dnsmasq-primary.conf`, `scripts/demo-b-ttl.sh` |
| C Isolation | pf rules on Mac 3 and Mac 4: only Mac 2 may reach 3001/3002; rollback copy of `/etc/pf.conf`, live rules, and on/off state | `scripts/isolate.sh`, `scripts/demo-c-isolation.sh` |
| D HA | nginx passive health checks (`max_fails=1 fail_timeout=5s`) + `proxy_next_upstream` retry | `configs/nginx-edge.conf`, `scripts/demo-d-ha.sh` |
| E Edge migration | Same nginx config on Mac 1 as standby; DNS record moved to it | `scripts/demo-e-cutover.sh` |
| F Troubleshooting | Layer-by-layer diagnosis tool: DNS -> TCP -> TLS -> HTTP | `scripts/diagnose.sh`, `scripts/demo-f-troubleshoot.sh` |

Single point of failure: the edge nginx on Mac 2 (and the one DNS name pointing at it). Extension E removes it by running a standby edge and repointing the name; fully removing it would need a floating/virtual IP (VRRP/keepalived) or DNS with health checks, so cutover is automatic rather than manual.

## Cloud mapping

Mac 1 DNS -> Route 53 (managed DNS, health-checked failover). Mac 2/standby nginx -> ALB / CDN edge. Mac 3/4 -> application instances in a target group. pf rules -> security groups. DNS TTL cutover -> weighted/failover routing records.

## Running it

```
scripts/render.sh                         # regenerate configs after editing team.env
sudo scripts/dns.sh start primary|backup  # DNS (Mac 1 / Mac 4)
scripts/backend.sh start A|B              # backends
scripts/edge.sh start                     # edge on :8443; use EDGE_SUDO=1 (see report, finding 1)
scripts/lb-test.sh 6                      # client-side load-balancing check, by name, no -k
scripts/diagnose.sh                       # DNS/TCP/TLS/HTTP layer check
```
