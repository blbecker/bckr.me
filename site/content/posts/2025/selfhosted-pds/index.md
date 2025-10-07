---
title: "Selfhosted Pds"
date: 2025-10-07T02:37:59Z
draft: true
summary: Selfhost your own Bluesky PDS using Kubernetes, Longhorn, and Cloudflare Tunnel.
tags: selfhost, bluesky, pds, kubernetes, longhorn, cloudflare
categories: tech
---

## Deploy PDS

### Configmap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: bsky-configmap
  namespace: bsky
data:
  PDS_HOSTNAME: pds.example.com
  PDS_EMAIL_FROM_ADDRESS: admin@pds.example.com
  PDS_MODERATION_EMAIL_ADDRESS: admin@pds.example.com
  PDS_DATA_DIRECTORY: /pds
  PDS_BLOBSTORE_DISK_LOCATION: /pds/blocks
  PDS_BLOB_UPLOAD_LIMIT: "52428800"
  PDS_DID_PLC_URL: https://plc.directory
  PDS_BSKY_APP_VIEW_URL: https://api.bsky.app
  PDS_BSKY_APP_VIEW_DID: did:web:api.bsky.app
  PDS_REPORT_SERVICE_URL: https://mod.bsky.app
  PDS_REPORT_SERVICE_DID: did:plc:ar7c4by46qjdydhdevvrndac
  PDS_CRAWLERS: https://bsky.network
  LOG_ENABLED: "false"
```

### Secrets

#### Generate secrets

```bash
echo jwtSecret: $(openssl rand --hex 16)
echo adminPassword: $(openssl rand --hex 16)
echo plcRotationKey: $(openssl ecparam --name secp256k1 \
                        --genkey --noout --outform DER | \
                        tail --bytes=+8 | \
                        head --bytes=32 | \
                        xxd --plain --cols 32)
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: bsky-secrets
  namespace: bsky
stringData:
  PDS_JWT_SECRET: <jwtSecret>
  PDS_ADMIN_PASSWORD: <adminPassword>
  PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX: <plcRotationKey>
  PDS_MODERATION_EMAIL_SMTP_URL: # smtp://<username>:<password@<smtpHost>:<smtpPort>
  PDS_EMAIL_SMTP_URL: # smtp://<username>:<password@<smtpHost>:<smtpPort>
type: Opaque
```

### Workload

#### Configure storage

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: bsky-data
  namespace: bsky
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

#### Configure deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bsky
  namespace: bsky
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: bsky
  template:
    metadata:
      labels:
        app.kubernetes.io/name: bsky
    spec:
      dnsConfig:
        options:
          - name: ndots
            value: "1"
      securityContext:
        readOnlyRootFilesystem: true
      containers:
        - name: bsky
          image: ghcr.io/bluesky-social/pds:0.4.67
          envFrom:
            - configMapRef:
                name: bsky-configmap
            - secretRef:
                name: bsky-secrets
          podSecurityContext:
            fsGroup: 2000
            fsGroupChangePolicy: "Always"
          ports:
            - name: bsky
              containerPort: 3000
              protocol: TCP
          volumeMounts:
            - mountPath: /pds
              name: data
          livenessProbe:
            tcpSocket:
              port: bsky
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /xrpc/_health
              port: bsky
            initialDelaySeconds: 10
            timeoutSeconds: 5
          resources:
            requests:
              memory: "250M"
              cpu: ".5"
            limits:
              memory: "2G"
              cpu: "2"
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: bsky-data
```

### External Connectivity

```yaml
apiVersion: v1
kind: Service
metadata:
  name: bsky
  namespace: bsky
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: bsky
  ports:
    - name: bsky
      port: 6767
      targetPort: bsky
      protocol: TCP
```

#### Cloudflare Tunnel

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloudflared
  namespace: cloudflared
data:
  config.yaml: |
    # Name of the tunnel you want to run
    tunnel: tartarus-home
    credentials-file: /etc/cloudflared/creds/credentials.json
    loglevel: warn

    # Serves the metrics server under /metrics and the readiness server under /ready
    metrics: 0.0.0.0:2000
    no-autoupdate: true

    ingress:
    [...]
    - hostname: pds.example.com
      service: http://bsky.bsky.svc.cluster.local:6767
      originRequest:
        httpHostHeader: "pds.example.com"
        
    # This rule matches any traffic which didn't match a previous rule, and responds with HTTP 404.
    - service: http_status:404
```

```yaml
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: bsky-external-dns
  namespace: bsky
spec:
  endpoints:
    - dnsName: pds.example.com
      recordTTL: 300
      recordType: CNAME
      targets:
        - <your-cloudflare-tunnel>.cfargotunnel.com
      providerSpecific:
        - name: external-dns.alpha.kubernetes.io/cloudflare-proxied
          value: "true"
```

## Use PDS

### Create an Account

#### Export env

```bash
bskyPod="$(kubectl get pod -n bsky | tail -n 1 | awk '{print $1}')"
kubectl exec -it -n bsky ${bskyPod} -- env | tee /path/to/pds.env
```

#### Create account

```bash
./pdsadmin --config /path/to/pds.env account create \
    --email myemail@email.example.com \
    --handle myhandle.bsky.example.com
```

```txt
Using config file: /path/to/pds.env
Invite Code: <inviteCode>
Account created successfully!
-----------------------------
Handle   : myhandle.bsky.example.com
DID      : <did>
Password : <password>
-----------------------------
Save this password, it will not be displayed again.
```

Using these credentials, you can log in to [bsky.app](https://bsky.app) or any other Bluesky client.

### Migrate an account

#### Generate an invite code

```bash
./pdsadmin --config /path/to/pds.env account create-invite-code
```

```txt
Using config file: /path/to/pds/pds.env
Invite Code: <inviteCode>
-----------------------------------
Invite Code generated successfully!
<inviteCode>
-----------------------------------
```

#### Migrate account using goat

Install [goat](https://github.com/bluesky-social/indigo/tree/main/cmd/goat#install).

```bash
goat account login -u $OLDHANDLE -p $OLDPASSWORD
```

```bash
goat account plc request-token
```

```bash
goat account migrate \
    --pds-host $NEWPDSHOST \
    --new-handle $NEWHANDLE \
    --new-password $NEWPASSWORD \
    --new-email $NEWEMAIL \
    --plc-token $PLCTOKEN \
    --invite-code $INVITECODE
```

#### Update DNS TXT Record
