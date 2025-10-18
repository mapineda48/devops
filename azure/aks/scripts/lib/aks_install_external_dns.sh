aks_install_external_dns() {
  log "Installing external-dns (kubernetes-sigs chart + Workload Identity)"

  # ── Requisitos de entorno ────────────────────────────────────────────────────
  : "${AKS_NAME:?missing}"                  # para txtOwnerId
  : "${AKS_WORKLOAD_CLIENT_ID:?missing}"    # clientId de la UAMI (output de TF)
  : "${AZURE_DNS_ZONE:?missing}"            # ej: mapineda48.de
  : "${AZURE_DNS_ZONE_RG:?missing}"         # RG que contiene la zona DNS
  : "${AZURE_SUBSCRIPTION_ID:?missing}"
  : "${AZURE_TENANT_ID:?missing}"

  # ── Repo oficial ─────────────────────────────────────────────────────────────
  helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/ --force-update

  # Namespace requerido
  kubectl get ns external-dns >/dev/null 2>&1 || kubectl create ns external-dns

  # ── Secret con azure.json (requerido por el chart oficial) ───────────────────
  # useWorkloadIdentityExtension:true => usa token OIDC + UAMI (sin secretos de app)
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: external-dns-azure
  namespace: external-dns
type: Opaque
stringData:
  azure.json: |
    {
      "tenantId": "${AZURE_TENANT_ID}",
      "subscriptionId": "${AZURE_SUBSCRIPTION_ID}",
      "resourceGroup": "${AZURE_DNS_ZONE_RG}",
      "useWorkloadIdentityExtension": true
    }
EOF

  # Versión opcional del chart
  local verArgs=()
  [[ -n "${EXTERNALDNS_CHART_VERSION:-}" ]] && verArgs+=(--version "$EXTERNALDNS_CHART_VERSION")

  # ── Install/Upgrade ──────────────────────────────────────────────────────────
  helm upgrade --install external-dns external-dns/external-dns \
    --namespace external-dns --create-namespace --reset-values "${verArgs[@]}" \
    --set provider.name=azure \
    --set sources[0]=ingress \
    --set sources[1]=service \
    --set policy=sync \
    --set registry=txt \
    --set "txtOwnerId=${AKS_NAME}" \
    --set "domainFilters[0]=${AZURE_DNS_ZONE}" \
    --set serviceAccount.create=true \
    --set serviceAccount.name=external-dns-sa \
    --set serviceAccount.annotations."azure\.workload\.identity/client-id"="${AKS_WORKLOAD_CLIENT_ID}" \
    --set serviceAccount.labels."azure\.workload\.identity/use"="true" \
    --set podLabels."azure\.workload\.identity/use"="true" \
    --set extraVolumes[0].name=azure-config-file \
    --set extraVolumes[0].secret.secretName=external-dns-azure \
    --set extraVolumeMounts[0].name=azure-config-file \
    --set extraVolumeMounts[0].mountPath=/etc/kubernetes \
    --set extraVolumeMounts[0].readOnly=true

  # Espera (best-effort)
  kubectl -n external-dns rollout status deploy/external-dns --timeout=180s || true
}
