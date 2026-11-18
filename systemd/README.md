# systemd-managed deployment — DeepSeek V4 Flash Vision Exp

Manage the 2-node tensor-parallel vLLM deployment as a **per-deployment systemd
user unit** on the **head** node (`worley-ai` / `spark-78c4`). This replaces the
fragile NVIDIA Sync custom-job stop (which only tore down the primary) with
deterministic `enable / start / stop / restart`, and it keeps the whole cluster
(including the `worley-aii` worker) in one lifecycle.

The head unit is the **single orchestrator**. It is **not** a generic
`spark-vllm`/`vllm-docker` service — it is specific to this deployment so it is
unambiguous and doesn't manage unrelated clusters.

## Files
- `deepseek-v4-flash-vision-exp.service` — the unit to install on the head.
- `../start-vllm.sh` — foreground launcher (has an `EXIT/INT/TERM` trap → `stop-vllm.sh`).
- `../stop-vllm.sh` — runs `launch-cluster.sh stop`, which reads the pinned `.env`
  (`CLUSTER_NODES=10.20.0.11,10.20.0.12`) and stops **head + worker** over ssh.

## Install (on the head, as `sworley`)
```sh
loginctl enable-linger sworley                       # so the user service starts at boot even before login
mkdir -p ~/.config/systemd/user
cp systemd/deepseek-v4-flash-vision-exp.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now deepseek-v4-flash-vision-exp.service
```

## Operate
```sh
systemctl --user status  deepseek-v4-flash-vision-exp.service
systemctl --user start   deepseek-v4-flash-vision-exp.service
systemctl --user stop    deepseek-v4-flash-vision-exp.service   # stops head + worker (via trap/ExecStop)
systemctl --user restart deepseek-v4-flash-vision-exp.service
journalctl --user -u deepseek-v4-flash-vision-exp.service -f     # logs (or check the recipe logs)
```

## Important notes / gotchas
1. **PATH & env:** systemd strips the login `PATH`. The unit sets
   `Environment=PATH=…:/home/sworley/.pyenv/shims` and `HOME` so `python3`,
   `ssh`, and `docker` resolve. Adjust if your python/docker live elsewhere.
2. **Stop reaches the worker over SSH.** `stop-vllm.sh` → `launch-cluster.sh stop`
   ssh-es to the worker. Ensure passwordless `worley-ai → worley-aii` works, or
   `stop` may hang; `TimeoutStopSec=120` allows for docker stop + ssh.
3. **One control plane.** Don't let both systemd and the NVIDIA Sync custom job
   manage the same containers — they'd race. Use systemd as the manager; treat
   the NVIDIA Sync job as a convenience/read-only view (or remove it).
4. **`Restart=on-failure`**, not `always`: a manual/deliberate stop should not be
   restarted by the unit.
5. If the worker's containers are stopped while the head keeps running
   (the old bug), the model serves a single node with a dangling peer — always
   stop through this unit (or `stop-vllm.sh`) so both go down together.

## Manual teardown (no systemd)
```sh
ssh spark-78c4 '/home/sworley/files/repos/github.com/sworley/spark-vllm-docker/stop-vllm.sh'
# or explicit both-node:
for n in spark-78c4 spark-b33b; do ssh "$n" docker stop vllm_node; done
```
