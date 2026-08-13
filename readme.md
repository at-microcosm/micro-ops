# micro-ops

ansible stuff for [microcosm](https://microcosm.blue) infrastructure.

[`legacy/`](./legacy/) has the old playbooks


## hacking

- copy [`secrets.example.yml`](./secrets.example.yml) to `secrets.yml` and edit
- review top-level configs at [`inventory/group_vars/all.yml`](./inventory/group_vars/all.yml)


## hubble

atproto mirror / getRepo offload. [hubble source](https://tangled.org/microcosm.blue/hubble)

- main config: [`inventory/group_vars/hubble.yml`](./inventory/group_vars/hubble.yml)
- per-host config in [`inventory/host_vars/`](./inventory/host_vars/)
- playbook: [`playbooks/hubble.yml`](./playbooks/hubble.yml)

```bash
ansible-playbook -e @secrets.yml playbooks/hubble.yml

# builds are skipped unless the source repo changed; to force:
ansible-playbook -e @secrets.yml -e force_build=1 playbooks/hubble.yml

# limit to one host:
ansible-playbook -e @secrets.yml -l bridgy-hubble playbooks/hubble.yml

# deps + build only
ansible-playbook -l hubble-pi-01 --tags build playbooks/hubble.yml
```

setting `hubble_public_host` gets nginx + certbot TLS going in front.

setting `hubble_storage_device` formats it as xfs (device msut be blank) and
mounts it at `hubble_storage_mount`.
