#ARCHITECTURE.mdrks Project
# Private Network Service Platform

## Machine / Service Table

| Mac | Role | IP | Service | Port |
|---|---|---|---|---|
| Mac 1 | Private DNS + Client | 10.7.23.146 | dnsmasq | 53/UDP |
| Mac 2 | Edge / Reverse Proxy / Load Balancer | 10.7.10.154 | nginx + TLS | 8443/TCP |
| Mac 3 | Backend A | 10.7.21.102 | HTTP REST | 3001/TCP |
| Mac 4 | Backend B + Client | 10.7.17.77 | HTTP REST + Client | 3002/TCP |

## Main Request Flow

Client
-> DNS Query
-> Mac 1
-> app.diddybois.test resolves to Mac 2
-> HTTPS/TLS
-> Mac 2 nginx
-> Backend A or Backend B
-> HTTP response
-> Client

## Protocol Flow

DNS: UDP/53
TCP: connection to 8443
TLS: ClientHello -> ServerHello -> Certificate -> Key Exchange -> Finished
HTTP: HTTPS request/response
Load Balancing: nginx round-robin
Backend A: TCP/3001
Backend B: TCP/3002

## Cloud Mapping

Mac 1 DNS -> managed DNS service
Mac 2 nginx -> cloud load balancer / edge
Mac 3 -> application instance A
Mac 4 -> application instance B
