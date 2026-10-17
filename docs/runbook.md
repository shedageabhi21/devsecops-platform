# Runbook: todo-api

Namespace `app`, deployment `todo-api`, managed by ArgoCD from `helm/app`.

## TodoApiDown

**Meaning:** Prometheus sees no healthy `todo-api` target.

1. `kubectl get pods -n app` : is a pod running and Ready?
2. `kubectl describe pod -n app -l app=todo-api` : look at Events.
   - `ImagePullBackOff`: wrong or missing image tag. Check `tag:` in `helm/app/values.yaml` against ECR.
   - `CrashLoopBackOff`: `kubectl logs -n app deploy/todo-api --previous`.
   - `Pending`: node capacity. `kubectl describe node` and check requests.
3. `kubectl get applications -n argocd` : is the app Synced and Healthy?
4. **Fix:** revert the last change in Git (`git revert <commit>` in `devsecops-platform`) and push. ArgoCD redeploys. Do not patch the cluster by hand, because self-heal reverts manual changes.

## TodoApiHighErrorRate

**Meaning:** more than 5% of requests return 5xx.

1. `kubectl logs -n app deploy/todo-api --tail=100` : look for stack traces.
2. Did a deploy just happen? Compare the time with the last commit in `helm/app/values.yaml`.
3. **Fix:** if the error began with a deploy, revert it in Git. Otherwise inspect the failing route using `http_requests_total{status_code=~"5.."}` by `route`.

## TodoApiHighLatency

**Meaning:** p95 latency is above 500 ms.

1. `kubectl top pod -n app` (needs metrics-server) or check `container_cpu_usage_seconds_total` : is the pod near its CPU limit (250m)?
2. Check traffic: `sum(rate(http_requests_total{job="todo-api"}[5m]))`.
3. **Fix:** raise the CPU limit in `helm/app/values.yaml`, or investigate the slow route. More replicas will not help while data is stored in memory, because each pod would hold different data.

## Rollback (any alert)

```bash
git -C ~/devsecops-platform revert --no-edit <bad-commit>
git -C ~/devsecops-platform push origin main
```

ArgoCD syncs the revert within about three minutes.
