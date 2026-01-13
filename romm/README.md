# RomM Helm Chart

[![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square)](https://github.com/henriqzimer/k8s/tree/main/helm-applications/romm)
[![AppVersion: 4.5.0](https://img.shields.io/badge/AppVersion-4.5.0-informational?style=flat-square)](https://romm.app/)

A Helm chart for [RomM](https://romm.app/) - Beautiful, powerful, self-hosted ROM manager.

## TL;DR

```bash
# Add the Helm repository
helm repo add henriqzimer https://henriqzimer.github.io/helm-applications
helm repo update

# Install RomM
helm install romm henriqzimer/romm
```

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- A running MariaDB/MySQL database (or use the included MariaDB chart)
- Persistent storage for ROMs, config, and assets
- Ingress controller (nginx-ingress recommended)
- cert-manager (optional, for automatic TLS certificates)

## Installing the Chart

### From Helm Repository

```bash
# Add the repository
helm repo add henriqzimer https://henriqzimer.github.io/helm-applications
helm repo update

# Install RomM
helm install romm henriqzimer/romm
```

### From Source

```bash
# Clone the repository
git clone https://github.com/henriqzimer/k8s.git
cd k8s/helm-applications

# Package the chart
helm package romm/

# Install from local package
helm install romm ./romm-1.0.0.tgz
```

## Configuration

### Required Configuration

Before deploying, you need to configure several required values:

1. **Database Configuration**: Set up MariaDB connection details
2. **Secrets**: Configure authentication secrets and API keys
3. **Storage**: Configure persistent volumes for ROMs and data
4. **Ingress**: Configure domain and TLS settings

### Example values-production.yaml

```yaml
# Database configuration
secrets:
  enabled: true
  data:
    DB_HOST: "romm-mariadb"
    DB_PORT: "3306"
    DB_USER: "romm"
    DB_PASSWD: "your_secure_password"
    DB_NAME: "romm"
    MYSQL_ROOT_PASSWORD: "your_root_password"
    MYSQL_DATABASE: "romm"
    MYSQL_USER: "romm"
    MYSQL_PASSWORD: "your_secure_password"
    ROMM_AUTH_SECRET_KEY: "your_32_char_secret_key"
    IGDB_CLIENT_ID: "your_igdb_client_id"
    IGDB_CLIENT_SECRET: "your_igdb_client_secret"
    STEAMGRIDDB_API_KEY: "your_steamgriddb_api_key"

# Ingress configuration
romm:
  ingress:
    enabled: true
    hosts:
      - host: romm.yourdomain.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: romm-tls
        hosts:
          - romm.yourdomain.com

  # Storage configuration
  persistence:
    config:
      enabled: true
      existingClaim: "romm-config-pvc"
    library:
      enabled: true
      existingClaim: "romm-library-pvc"
    resources:
      enabled: true
      existingClaim: "romm-resources-pvc"
    assets:
      enabled: true
      existingClaim: "romm-assets-pvc"
```

### Using External Secrets

For production deployments, it's recommended to use ExternalSecrets Operator:

```yaml
secrets:
  enabled: false

romm:
  envFrom:
    - secretRef:
        name: romm-external-secrets
```

### Database Options

#### Option 1: Included MariaDB (Development)

```yaml
mariadb:
  enabled: true
  auth:
    rootPassword: "your_root_password"
    database: "romm"
    username: "romm"
    password: "your_password"
```

#### Option 2: External MariaDB (Production)

```yaml
mariadb:
  enabled: false

secrets:
  data:
    DB_HOST: "your-external-mariadb-host"
    DB_PORT: "3306"
    DB_USER: "romm"
    DB_PASSWD: "your_password"
    DB_NAME: "romm"
```

### Storage Configuration

RomM requires several persistent volumes:

```yaml
romm:
  persistence:
    # Configuration data (database connection, API keys, etc)
    config:
      enabled: true
      size: 1Gi
      storageClass: "your-storage-class"
      # OR use existing PVC
      existingClaim: "romm-config-pvc"

    # ROM library storage
    library:
      enabled: true
      size: 100Gi
      storageClass: "your-storage-class"
      existingClaim: "romm-library-pvc"

    # Resources (cover images, screenshots, etc)
    resources:
      enabled: true
      size: 10Gi
      storageClass: "your-storage-class"
      existingClaim: "romm-resources-pvc"

    # Assets (EmulatorJS files, etc)
    assets:
      enabled: true
      size: 5Gi
      storageClass: "your-storage-class"
      existingClaim: "romm-assets-pvc"
```

### TLS Configuration

#### Using cert-manager (Recommended)

```yaml
romm:
  ingress:
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
      nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    tls:
      - secretName: romm-tls
        hosts:
          - romm.yourdomain.com
```

#### Using Existing Certificate

```yaml
romm:
  ingress:
    tls:
      - secretName: your-existing-tls-secret
        hosts:
          - romm.yourdomain.com
```

## API Keys Configuration

RomM integrates with several external services. Get API keys from:

- **IGDB**: https://api.igdb.com/ (for game metadata)
- **SteamGridDB**: https://www.steamgriddb.com/profile/preferences/api (for game artwork)
- **MobyGames**: https://www.mobygames.com/info/api/ (for additional metadata)

## Parameters

### Global Parameters

| Name | Description | Value |
|------|-------------|-------|
| `replicaCount` | Number of RomM replicas | `1` |
| `revisionHistoryLimit` | Number of old ReplicaSets to retain | `3` |
| `imagePullSecrets` | Image pull secrets | `[]` |
| `nameOverride` | Override the default name | `""` |
| `fullnameOverride` | Override the default full name | `""` |

### RomM Application Parameters

| Name | Description | Value |
|------|-------------|-------|
| `romm.image.repository` | RomM image repository | `docker.io/rommapp/romm` |
| `romm.image.tag` | RomM image tag | `4.5.0` |
| `romm.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `romm.service.type` | Service type | `ClusterIP` |
| `romm.service.port` | Service port | `8080` |
| `romm.ingress.enabled` | Enable ingress | `true` |
| `romm.ingress.className` | Ingress class name | `nginx` |

### Database Parameters

| Name | Description | Value |
|------|-------------|-------|
| `mariadb.enabled` | Enable included MariaDB | `true` |
| `mariadb.auth.rootPassword` | MariaDB root password | `""` |
| `mariadb.auth.database` | MariaDB database name | `romm` |
| `mariadb.auth.username` | MariaDB username | `romm` |
| `mariadb.auth.password` | MariaDB password | `""` |

### Persistence Parameters

| Name | Description | Value |
|------|-------------|-------|
| `romm.persistence.config.enabled` | Enable config persistence | `true` |
| `romm.persistence.config.size` | Config PVC size | `1Gi` |
| `romm.persistence.library.enabled` | Enable library persistence | `true` |
| `romm.persistence.library.size` | Library PVC size | `100Gi` |
| `romm.persistence.resources.enabled` | Enable resources persistence | `true` |
| `romm.persistence.resources.size` | Resources PVC size | `10Gi` |
| `romm.persistence.assets.enabled` | Enable assets persistence | `true` |
| `romm.persistence.assets.size` | Assets PVC size | `5Gi` |

## Troubleshooting

### Common Issues

1. **Database Connection Issues**
   - Ensure MariaDB is running and accessible
   - Check DB_HOST, DB_PORT, DB_USER, DB_PASSWD values
   - Verify network policies allow communication

2. **Permission Issues**
   - Ensure PVCs have correct permissions (RomM runs as non-root)
   - Check storage class supports the required access modes

3. **Ingress Issues**
   - Verify ingress controller is installed and running
   - Check DNS resolution for your domain
   - Ensure TLS secret exists and is valid

4. **API Key Issues**
   - Verify API keys are correctly set in secrets
   - Check API service status and rate limits

### Logs

```bash
# View RomM pod logs
kubectl logs -f deployment/romm -n your-namespace

# View MariaDB logs (if using included MariaDB)
kubectl logs -f statefulset/romm-mariadb -n your-namespace
```

### Debugging

```bash
# Check pod status
kubectl get pods -n your-namespace

# Describe pod for detailed information
kubectl describe pod romm-xxxxx -n your-namespace

# Check ingress status
kubectl get ingress -n your-namespace
kubectl describe ingress romm -n your-namespace
```

## Upgrading

```bash
# Update the repository
helm repo update

# Upgrade RomM
helm upgrade romm henriqzimer/romm

# Or upgrade with new values
helm upgrade romm henriqzimer/romm -f your-values.yaml
```

## Uninstalling

```bash
# Uninstall RomM
helm uninstall romm

# Clean up PVCs (if desired)
kubectl delete pvc romm-config-pvc romm-library-pvc romm-resources-pvc romm-assets-pvc
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test your changes
5. Submit a pull request

## License

This chart is licensed under the MIT License.

## Links

- [RomM Official Website](https://romm.app/)
- [RomM GitHub](https://github.com/rommapp/romm)
- [RomM Documentation](https://docs.romm.app/)
- [Helm Documentation](https://helm.sh/docs/)