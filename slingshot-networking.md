# slingshot networking

note: this describes the current configuration. the intent in the future is to
set up a centralized acme dns-01 service which provisions tls independently for
all microcosm services, with a vault service providing access to the services
(direct apps like allegedly and slingshot; and nginx for proxied apps like
constellation and ufos) needing to actually terminate tls.

for now, slingshot does TLS via acme-http01 on a primary instance, with
secondaries forwarding challenges to the primary via redirects, and retrieving
certs from the primary over ssh via an rsync task.

slingshot has passive load balancing via per-instance DNS A-records.

currently DNS is handled by namecheap; at some point it will switch to EasyDNS
for their Geo-DNS (and active health checking) feature, when more distributed
edge instances are deployed.


## current instances

- `54.39.105.80` **tls primary** (montreal)
- `66.70.178.28` **tls secondary** (montreal)


## dns

### `slingshot.microcosm.blue`

all instances receive a DNS `A` record for `slingshot.microcosm.blue`, which
provides passive round-robin load-balancing across instances. when hosts become
unavailable, affected clients usually experience a (somewhat long, up to 30s)
connection timeout before trying another host (and hopefully succeeding). other
than the one-time delay, this is usually a transparent/seemless failover.

(matching `AAAA` records are also provided for ipv6).


### acme: `acme.slingshot.microcosm.blue`

an A record points `acme.` to the **tls primary** instance (`54.39.105.80`).
acme http challenges reaching tls secondaries are redirected to the `acme.`
domain so that the tls primary is always be the one responding to challenges.

note that we don't need to provision tls for the `acme` subdomain -- the acme
service (letsencrypt) will ignore cert errors for http challenges, even if
accessing them via port 443.

only the tls primary is configured to initiate certificate provisioning with
poem's autocert feature. secondaries just configure normal tls from local cert
files.


### testing zone: `dev.slingshot.microcosm.blue`

the `dev.slingshot.microcosm.blue` zone is used for testing networking changes.


## cert distribution: ssh to primary

secondary tls instances need access to the acme-provisioned certs that the tls
primary obtains. they do this by copying them with rsync. in order for this to
work, a few things need to happen

- the primary needs to register secondary instances in `authorized_keys`, for
  them to be allowed to connect. see
  [`./slingshot-vars.example.yml`](`./slingshot-vars.example.yml`),
  `authorized_secondary_keys`.

  keys are printed in the ansible output by secondaries when setting them up.

- the secondaries need the primary's ssh identity in order to connect securely.
  find from primary with `cat /etc/ssh/ssh_host_ed25519_key.pub`; and put it in
  `acme_primary_known_hosts` as per
  [`./slingshot-vars.example.yml`](`./slingshot-vars.example.yml`).

secondary tls instances install a cron job to periodically fetch updated certs
from the primary; secondary slingshot application instances periodically poll
the local cert files to update the actual app tls config.


## updating instances


```bash
# updating the primary
ansible-playbook playbooks/slingshot-tls-primary.yml -e "@slingshot-vars.yml" -i 54.39.105.80,

# a secondary
ansible-playbook playbooks/slingshot-tls-secondary.yml -e "@slingshot-vars.yml" -i 66.70.178.28,

# add `-e "start=1"` to force restart if eg., the repo has not changed
# add `-e "force_build=1"` to force rebuilding the service
```

for urgent updates: run these commands directly (sequentially to avoid both
being down for a time as they restart).

for typical deploys:

1. remove the secondary instance from DNS, wait 30m for DNS TTL
2. run the secondary's update command
3. restore secondary DNS
4. leave it up overnight, keep an eye on metrics for any regressions
5. remove the primary instance from DNS, wait 30m for DNS TTL
6. run the primary's update command
7. restore the primary DNS

most clients fail over fine without the long waits, but may encounter one very
slow request for a connection timeout before switching. allowing DNS propagation
time seems to be very effective at completely seamless traffic switching, based
on observing metrics over past deploys.
