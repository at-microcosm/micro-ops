
## relay

this will launch a full-scale validating (sync1.1) atproto relay.

note that bluesky's production relay is still "non-archival" and the sync1.1 fork is in active development. this playbook currently builds off their `main` branch, and might not always be stable.


### pre-ansible prep

- [ ] select a server. 8 cores and 16GB ram are recommended. relays consume a lot of bandwidth: get an unmetered connection (250mbps minimum) if you can. spin it up with ubuntu server 24.04
- [ ] run `apt-get update && apt-get upgrade` and probably `reboot` on it after that.
- [ ] set up DNS: point an A-record (and maybe an AAAA) from your relay domain to your new server.
- [ ] put your SSH pubkey on the new server for root and make sure pubkey auth and root login are enabled. (disable all password auth)
    - note: if you get a message like "please log in as user ubuntu", check `/root/.ssh/authorized_keys` for some garbage to remove
- [ ] install tailscale (probably optional)


### ansible

- [ ] generate two strong passwords: one for the postgresql database, and one for the relay admin interface
- [ ] copy `relay-vars.example.yml` to `relay-vars.yml` and replace the values:
  - [ ] set `relay_db_password` to your newly generated postgres password
  - [ ] set `relay_admin_password` to your newly generated.. you get it
  - [ ] set `relay_host` to the **domain name** that you created the DNS record for in the setup, like `relay.example.com`
- [ ] run the playbook!
  ```bash
  ansible-playbook playbooks/relay2.yml -e "@relay-vars.yml" -i relay2,
  ```

### post-ansible tasks

- [ ] log in to the admin dashboard at `https://<your_domain>/dash`
- [ ] in the top right, change `50 PDS/day` new connections to `5000`
- [ ] run the requestCrawl script to connect to PDSs (todo: include that script here)

you need to tell the relay to actually connect to PDSs


### TODO

- [ ] copy my modified requestCrawl script here.
- [ ] generate postgres password on the server instead of having to do it manually.
- [ ] just use podman, not podman-compose. (or switch to docker tbh). it's a single container.
- [ ] tag container builds with git hash (and add var for non-main git hash)
- [ ] fix container build/restart stuff so it sucks less
- [ ] figure out what probably needs to be done to make it come up automatically on reboot? will it?
- [x] restart policy?
- [ ] set up node exporter metrics
- [ ] fix nginx/https stuff


## appviewlite

(very work-in-progress)

```bash
ansible-playbook playbooks/appviewlite.yml -i appviewlite,
```


## node exporter

```bash
ansible-playbook playbooks/node-exporter.yml -e node_exporter_version=1.8.2 -e node_exporter_arch=linux-amd64 -i appviewlite, -u root
```

### node exporter (raspi)

```bash
ansible-playbook playbooks/node-exporter.yml -e node_exporter_version=1.9.1 -e node_exporter_arch=linux-arm64 -i cassiopeia, -u pi
```

## jetstream

### pre-ansible prep

- [ ] select a server. low-cost VPS is likely sufficient, you need more than 1GB per hour of disk for event TTL (replay from cursor) retention. spin it up with ubuntu server 24.04.
- [ ] run `apt-get update && apt-get upgrade` and probably `reboot` on it after that.
- [ ] set up DNS: point an A-record (and maybe an AAAA) from your relay domain to your new server.
- [ ] put your SSH pubkey on the new server for root and make sure pubkey auth and root login are enabled. (disable all password auth)
    - note: if you get a message like "please log in as user ubuntu", check `/root/.ssh/authorized_keys` for some garbage to remove
- [ ] install tailscale (probably optional)


### ansible

- [ ] copy `jetstream-vars.example.yml` to `jetstream-vars.yml` and replace the values:
- [ ] run the playbook!
  ```bash
  ansible-playbook playbooks/jetstream.yml -e "@jetstream-vars.yml" -i jetstream2,
  ```

  to force rebuilding,
  ```bash
  ansible-playbook playbooks/jetstream.yml -e "@jetstream-vars.yml" -e force_build=1 -i jetstream2,
  ```


## constellation on raspberry pi 5 w/ nvme

- [ ] copy `constellation-vars.example.yml` to `constellation-vars.yml` and replace the values:
- [ ] run the playbook!
  ```bash
  ansible-playbook playbooks/constellation.yml -e "@constellation-vars.yml" -i cassiopeia,
  ```

WARNING: this will OVERWRITE the external device specified!

WARNING: this will build constellation (and so librocksdb) on the pi, which takes an age

NOTE: this will _enable_ a systemd unit, but not start it (so that the backup restore can succeed). when the pi is rebooted it should autostart.

### constellation: restore from backup

after running the main constellation playbook (above),

```bash
ansible-playbook playbooks/constellation.yml -e "@constellation-vars.yml" -e restore_backup=1 -i cassiopeia,
```

WARNING: this can take a whileeeee

## to force building

```bash
ansible-playbook playbooks/constellation.yml -e "@constellation-vars.yml" -e force_build=1 -i cassiopeia, -v
```


## UFOs on raspberry pi 5 w/ nvme

- [ ] copy `ufos-vars.example.yml` to `ufos-vars.yml` and replace the values:
- [ ] run the playbook!
  ```bash
  ansible-playbook playbooks/ufos.yml -e "@ufos-vars.yml" -i cooper,
  ```

WARNING: this will OVERWRITE the external device specified!

WARNING: this will build ufos (and so librocksdb) on the pi, which takes an age

NOTE: this will _enable_ a systemd unit, but not start it (so that the backup restore can succeed). when the pi is rebooted it should autostart.

### ufos: restore from backup

after running the main ufos playbook (above),

```bash
ansible-playbook playbooks/ufos.yml -e "@ufos-vars.yml" -e restore_backup=1 -i cooper,
```

WARNING: this can take a whileeeee

## to force building

```bash
ansible-playbook playbooks/ufos.yml -e "@ufos-vars.yml" -e force_build=1 -i cooper, -v
```


## node-exporter on original raspi model b

```bash
ansible-playbook playbooks/node-exporter.yml -e node_exporter_version=1.9.1 -e node_exporter_arch=linux-armv6 -i <hostname>, -u root
```

## reflector

```bash
ansible-playbook playbooks/reflector.yml -e "@reflector-vars.yml" -i reflector,
```
