# MintTracker - Kubernetes Deployment

This directory contains the Kubernetes manifests for deploying the MintTracker coming soon page using ArgoCD and Helm.

## Structure

```
minttracker/
├── values.yaml           # Helm values configuration
├── Dockerfile           # Docker image build configuration
├── nginx.conf          # Nginx server configuration
├── index.html          # Static HTML coming soon page
├── secrets/            # Kubernetes secrets (sealed secrets)
└── README.md          # This file
```

## Prerequisites

- K3S cluster running
- ArgoCD installed and configured
- platform-gitops repository synchronized
- Docker registry access (ghcr.io)

## Deployment Steps

### 1. Build Docker Image

The Docker image needs to be built and pushed to the container registry.

```bash
cd /Users/vaidehimac/IdeaProjects/K3S/Kubernetes-setup/platform-gitops/applications/minttracker

# Build the image
docker build -t ghcr.io/vimleshkpandey/minttracker:latest .

# Login to GitHub Container Registry
echo $GH_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Push to registry
docker push ghcr.io/vimleshkpandey/minttracker:latest
```

### 2. Configure DNS in Cloudflare

1. Go to Cloudflare Dashboard
2. Select `vimleshdev.com`
3. Go to DNS section
4. Add A record:
   - Name: `minttracker`
   - Type: `A`
   - Value: `YOUR_CLUSTER_IP` (K3S LoadBalancer IP)
   - Proxy Status: Proxied (orange cloud)

### 3. Apply ArgoCD Application

The ArgoCD Application is already configured at:
```
/platform-gitops/argocd-apps/applications/minttracker.yaml
```

Once you push the changes to the platform-gitops repository, ArgoCD will automatically deploy:

```bash
# Monitor deployment
kubectl get applications -n argocd
kubectl get pods -n applications -l app=minttracker

# Check logs
kubectl logs -n applications -l app=minttracker -f
```

### 4. Verify Deployment

```bash
# Check service
kubectl get svc -n applications | grep minttracker

# Test the endpoint
curl http://minttracker.vimleshdev.com/health
curl https://minttracker.vimleshdev.com

# Check ingress
kubectl get ingress -n applications
```

## Configuration

### Update Landing Page

Edit `index.html` directly and rebuild the Docker image:

```bash
docker build -t ghcr.io/vimleshkpandey/minttracker:latest .
docker push ghcr.io/vimleshkpandey/minttracker:latest
```

ArgoCD will automatically redeploy the application.

### Modify Helm Values

Edit `values.yaml` to:
- Change resource requests/limits
- Adjust replica count
- Modify domain (ingress.host)
- Update image tag

```bash
git commit -am "Update minttracker helm values"
git push
```

ArgoCD will automatically sync and redeploy.

### Environment Configuration

Non-sensitive config is in `values.yaml`. Sensitive values (if needed) go in `secrets/sealed-secret.yaml`:

```bash
# Create a sealed secret
kubectl create secret generic minttracker-secrets \
  --from-literal=KEY=VALUE \
  --dry-run=client -o yaml | \
  kubeseal -f -
```

## Monitoring

### View Application Status

```bash
# ArgoCD application status
argocd app get minttracker -n argocd

# Kubernetes resources
kubectl get all -n applications -l app=minttracker

# Ingress status
kubectl get ingress -n applications minttracker
```

### View Logs

```bash
# Nginx access logs
kubectl logs -n applications -l app=minttracker -c nginx -f

# Nginx error logs
kubectl logs -n applications -l app=minttracker -c nginx -f --tail=100
```

### Performance Metrics

```bash
# Pod resource usage
kubectl top pods -n applications -l app=minttracker

# Ingress metrics
kubectl get ingress -n applications minttracker -o yaml
```

## Troubleshooting

### Application not syncing

```bash
# Check ArgoCD application status
kubectl get application minttracker -n argocd -o yaml

# Force sync
argocd app sync minttracker -n argocd
```

### Pod not starting

```bash
# Check pod status
kubectl describe pod -n applications -l app=minttracker

# Check events
kubectl get events -n applications --sort-by='.lastTimestamp'
```

### DNS issues

```bash
# Check ingress controller
kubectl get ingress -n applications

# Verify DNS resolution
nslookup minttracker.vimleshdev.com

# Check SSL certificate status
kubectl get certificate -n applications
```

### Image pull failures

```bash
# Verify image secret exists
kubectl get secret ghcr-pull-secret -n applications

# Check image availability
docker pull ghcr.io/vimleshkpandey/minttracker:latest
```

## Updates and Maintenance

### Update Landing Page Content

1. Edit `index.html`
2. Rebuild Docker image
3. Push to registry
4. ArgoCD auto-deploys

### Update Helm Values

1. Edit `values.yaml`
2. Commit and push to git
3. ArgoCD auto-syncs

### Scale the Application

Edit `values.yaml`:
```yaml
replicaCount: 2  # or desired count
```

## Rollback

If needed, rollback to a previous version:

```bash
# List application history
kubectl rollout history deployment/minttracker -n applications

# Rollback to previous version
kubectl rollout undo deployment/minttracker -n applications

# Or via ArgoCD
argocd app rollback minttracker <REVISION> -n argocd
```

## Cleanup

To remove the application:

```bash
# Delete ArgoCD application (deletes all resources)
kubectl delete application minttracker -n argocd

# Or via ArgoCD CLI
argocd app delete minttracker -n argocd
```

## Related Documents

- [Platform GitOps Repository](https://github.com/vimleshkpandey/platform-gitops)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)

---

**Last Updated:** August 1, 2026  
**Deployment Method:** ArgoCD GitOps  
**Environment:** Production (K3S)
