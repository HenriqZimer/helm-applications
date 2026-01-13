# RomM Helm Chart

A Helm chart for deploying [RomM](https://romm.app/) - a beautiful, powerful, self-hosted ROM manager.

## Features

- 🎮 ROM library management with metadata from IGDB, MobyGames, and ScreenScraper
- 🕹️ Web-based emulation with EmulatorJS
- 🗄️ MariaDB database for metadata storage
- 🔒 Built-in authentication and API key management
- 📦 Flexible storage with PVC, hostPath, or emptyDir support
- 🔐 Support for both internal secrets and ExternalSecrets (Vault integration)

## Installation

### Quick Start (Internal Secrets)

```bash
helm repo add henriqzimer https://henriqzimer.github.io/helm-applications/
helm install romm henriqzimer/romm
```

### Using ExternalSecrets (Vault)

1. Create ExternalSecrets for credentials (see `values-external-secrets-example.yaml`)
2. Deploy with custom values:

```bash
helm install romm henriqzimer/romm \
  -f values-external-secrets-example.yaml \
  --namespace romm --create-namespace
```

## Configuration

### Secrets Management

This chart supports **two modes** for managing secrets:

#### Mode 1: Internal Secrets (Default)
Chart creates secrets from `secrets.data` in values.yaml:

```yaml
secrets:
  enabled: true  # Enable internal secret creation
  name: romm-secrets
  data:
    DB_USER: "romm"
    DB_PASSWD: "your-password"
    ROMM_AUTH_SECRET_KEY: "your-secret-key"
    # ... more secrets
```

#### Mode 2: ExternalSecrets (Vault/AWS Secrets Manager)
Use external secret management:

```yaml
secrets:
  enabled: false  # Disable internal secrets
  name: romm-credentials

romm:
  envFrom:
    - secretRef:
        name: romm-credentials
    - secretRef:
        name: romm-database-credentials
```

See `values-external-secrets-example.yaml` for complete example.

### Database Credentials

**IMPORTANT:** Database variables must match:
- `DB_USER` = `MYSQL_USER`
- `DB_PASSWD` = `MYSQL_PASSWORD`
- `DB_NAME` = `MYSQL_DATABASE`

The `DB_HOST` is automatically generated as `{release-name}-db`.

### Storage

Configure volumes for different data types:

```yaml
persistence:
  library:      # ROM files (large)
    enabled: true
    type: pvc
    size: 500Gi
    existingClaim: "romm-library-pvc"
  
  config:       # Configuration data
    enabled: true
    type: pvc
    size: 5Gi
  
  resources:    # Cover art, screenshots
    enabled: true
    type: pvc
    size: 20Gi
  
  assets:       # EmulatorJS files
    enabled: true
    type: pvc
    size: 10Gi
```

**Storage Types:**
- `pvc` - PersistentVolumeClaim (recommended for production)
- `hostPath` - Mount from node filesystem
- `emptyDir` - Temporary storage (data lost on pod restart)

### Ingress

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: romm.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: romm-tls
      hosts:
        - romm.example.com
```

### Resources

```yaml
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1000m
    memory: 2Gi

mariadb:
  resources:
    requests:
      cpu: 300m
      memory: 512Mi
    limits:
      cpu: 500m
      memory: 1Gi
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `replicaCount` | int | `1` | Number of replicas (should be 1) |
| `image.repository` | string | `"docker.io/rommapp/romm"` | Container image |
| `image.tag` | string | `"4.5.0"` | Image tag |
| `secrets.enabled` | bool | `true` | Enable internal secret creation |
| `secrets.name` | string | `"romm-secrets"` | Secret name |
| `romm.env` | list | `[]` | Additional environment variables |
| `romm.envFrom` | list | `[]` | Load env from ConfigMap/Secret |
| `persistence.library.enabled` | bool | `true` | Enable library storage |
| `persistence.library.size` | string | `"100Gi"` | Library volume size |
| `mariadb.enabled` | bool | `true` | Deploy MariaDB |
| `ingress.enabled` | bool | `true` | Enable Ingress |

See `values.yaml` for all available options.

## Examples

### Example 1: Minimal Installation
```bash
helm install romm henriqzimer/romm
```

### Example 2: With Custom Domain
```bash
helm install romm henriqzimer/romm \
  --set ingress.hosts[0].host=romm.mydomain.com
```

### Example 3: With ExternalSecrets
```bash
# 1. Create ExternalSecrets in cluster
kubectl apply -f external-secrets.yaml

# 2. Install chart with ExternalSecrets mode
helm install romm henriqzimer/romm \
  -f values-external-secrets-example.yaml
```

### Example 4: Using Existing PVCs
```bash
helm install romm henriqzimer/romm \
  --set persistence.library.existingClaim=my-library-pvc \
  --set persistence.config.existingClaim=my-config-pvc
```

## Upgrading

```bash
helm upgrade romm henriqzimer/romm -f values.yaml
```

## Uninstalling

```bash
helm uninstall romm
```

**Note:** PVCs are not deleted automatically. Delete them manually if needed:
```bash
kubectl delete pvc -l app.kubernetes.io/instance=romm
```

## API Keys

Get API keys from:
- **IGDB**: https://api.igdb.com/
- **SteamGridDB**: https://www.steamgriddb.com/profile/preferences/api
- **MobyGames**: https://www.mobygames.com/info/api/

## Troubleshooting

### Database Connection Issues
Check if DB_HOST is correct:
```bash
kubectl get svc -l app.kubernetes.io/instance=romm
# Should show: romm-db service
```

### Check logs
```bash
kubectl logs -l app.kubernetes.io/component=romm --tail=50
```

### Verify secrets
```bash
kubectl get secrets romm-secrets -o yaml
# or for ExternalSecrets:
kubectl get externalsecrets -n romm
```

## Contributing

Contributions are welcome! Please open an issue or pull request.

## License

This chart is provided as-is under the MIT License.

## Links

- **RomM Documentation**: https://docs.romm.app/
- **RomM GitHub**: https://github.com/rommapp/romm
- **Chart Repository**: https://github.com/HenriqZimer/helm-applications
