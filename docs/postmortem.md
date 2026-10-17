# Postmortem: Controlled failure tests (todo-api)

**Date:** <date>   **Type:** planned game day   **Impact:** none for users (lab)

## Summary
<One or two sentences: what you broke and what happened.>

## Timeline
| Time | Event |
|---|---|
| <hh:mm:ss> | Deleted the todo-api pod |
| <hh:mm:ss> | Probe saw first failed request |
| <hh:mm:ss> | Pod Ready, probe returned to 200 |
| <hh:mm:ss> | Pushed bad image tag |
| <hh:mm:ss> | New pod in ImagePullBackOff, old pod kept serving |
| <hh:mm:ss> | Set replicaCount to 0 |
| <hh:mm:ss> | TodoApiDown became Firing |
| <hh:mm:ss> | Reverted in Git, alert cleared |

## Measurements
- Pod deletion: <N> seconds of failed probes.
- Bad tag: <N> failed probes (expected 0).
- Detection time for TodoApiDown: <N> seconds.

## What went well
<for example: rolling update kept the old pod serving during the bad deploy>

## What went poorly / gaps found
<for example: single replica means any pod loss is an outage; no notification channel>

## Actions
- [ ] Run 2 replicas once data moves to a database
- [ ] Add an Alertmanager receiver
- [ ] <your own>
