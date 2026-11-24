# Phase 2 Report - Harden, Recover, Troubleshoot

Team: Yash (Mac 1, DNS/client/standby edge), Preet (Mac 2, edge), Phalak (Mac 3, Backend A), Archit (Mac 4, Backend B/backup DNS).
All commands, configs and screenshots are in this repository; screenshots are in `evidence/` (27-32).

## What changed from Phase 1
- IPs moved to DHCP-assigned addresses, so all addressing is now in `team.env` and configs are rendered from templates.
- nginx config gained failover (`proxy_next_upstream`, short connect timeout) and an `X-Edge` header naming the edge machine.
- DNS TTL lowered from 60 s to 30 s, records moved to a hosts file so they can be changed live.
- Second DNS server (Mac 4), standby edge (Mac 1), pf rules on both backends, a diagnosis tool, and demo scripts for each extension.

## Results

| Ext | Test | Result | Evidence |
|---|---|---|---|
| A | Stop primary dnsmasq; client still resolves | Direct query to primary timed out; default resolver answered from backup `10.7.21.79`; HTTPS by name kept working (A=1, B=1, 0 failed); primary restored | `27_ext_a_dns_failover.png` |
| B | Change record, watch client cache, then flush | dnsmasq answered the new IP immediately; client cache kept the old IP until the 30 s TTL expired (changed at the 40 s poll); after changing back, a manual flush gave the right answer instantly | `28_ext_b_ttl.png` |
| C | pf: only Mac 2 may reach 3001/3002 | Before: client got 200 from both. After: client connection refused on both. Edge still served A and B (0 failed). Rollback restored original pf state and direct access (200) | `29_ext_c_isolation.png` |
| D | Stop Backend A; restart | 6/6 requests served by B with 0 failures; after restart, load balancing resumed across A and B | `30_ext_d_ha_failover.png` |
| E | Move DNS to standby edge | Cached client kept hitting Mac 2's edge until TTL expiry, then new lookups reached the standby on Mac 1 (`X-Edge` changed); balanced A/B through standby; cut back | `31_ext_e_cutover.png` |
| F | Diagnosis drill | Healthy: all 4 layers OK. Injected wrong DNS record: tool stopped at TCP (nothing listening on :8443 at the wrong IP) and named the layer. Fixed record: healthy again | `32_ext_f_troubleshoot.png` |

### Explanations (viva)
- **DNS service failure vs application failure:** if dnsmasq is down names stop resolving (the query times out) but the servers are fine and reachable by IP; if a backend is down DNS still resolves and TLS still completes at the edge, but the edge returns an upstream error (502) or fails over to the healthy backend.
- **TTL and cutover:** resolvers may keep an answer for up to the TTL, so a DNS change does not take effect everywhere at once. Production migrations lower the TTL ahead of time, change the record, then raise it. Flushing the cache only fixes one machine.
- **Isolation:** `block return` sends a TCP RST so the client sees "connection refused" immediately; the `pass ... from <edge>` rule is evaluated first (`quick`), so only the edge gets through. This is the local equivalent of a cloud security group.
- **HA:** nginx marks an upstream failed after `max_fails` errors for `fail_timeout` and retries the request on the other one, so the client sees no error. The remaining single point of failure is the edge itself, addressed in E.
- **Troubleshooting order:** DNS (does it resolve, to what) -> TCP (can a socket open to the port) -> TLS (handshake, certificate chain) -> HTTP (status). The first failing layer is the answer; `scripts/diagnose.sh` does exactly this.

## Findings and problems encountered
1. **macOS "Local Network" privacy broke outbound connections from user-launched nginx.** An nginx started from an SSH session (or a Terminal without the permission) got `connect() failed (65: No route to host)` to some LAN backends, even though `nc` and `curl` on the same Mac reached them and the macOS firewall was off. The same thing made Homebrew `openssl s_client` fail while Apple's `curl` worked. Running nginx as root (`EDGE_SUDO=1 scripts/edge.sh start`) avoids the restriction. This is a diagnosis lesson: a layer-3-looking error that only affects one program points at the OS, not the network.
2. The standby edge was planned for Mac 3 but ended up on Mac 1 because of finding 1; the assignment allows any other Mac.
3. A teammate's Mac went to sleep during testing (SSH closed, backend unreachable) - the same symptom as a failed backend; `caffeinate` was used to prevent it.
4. Teammates' pre-existing folders (a separate `team5.test` setup) were left untouched; this repository is the source of truth.

## Learning summary (one paragraph per extension)
**A** Backup DNS makes resolution independent of one machine; clients try the next server only after a timeout, so failover is correct but slower. **B** TTL is a cache lifetime chosen by the record owner; the server updates instantly but clients see it later. **C** Host firewalls let us enforce that the edge is the only way in, independent of how the app is written. **D** Passive health checks give failover without extra software, at the cost of one retried request. **E** DNS-based cutover moves traffic between edges without touching clients, bounded by TTL. **F** Fixed-order, layer-by-layer diagnosis finds faults faster than guessing.

## Known gaps
- Backend B is Archit's existing node implementation (same endpoints and headers); `source/server-b.py` is not the one running.
- Wireshark captures for Phase 2 were not recorded (Phase 1 captures are in `evidence/`).
