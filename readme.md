
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


## appviewlite

(very work-in-progress)

```bash
ansible-playbook playbooks/appviewlite.yml -i appviewlite,
```

