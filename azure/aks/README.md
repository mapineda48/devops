
az aks get-credentials -g "mapineda48-aks" -n "aks-ephemeral" --overwrite-existing
kubectl apply -f cluster-issuer.yaml 
kubectl apply -f hello-world.yaml 
kubectl get pods -n external-dns
kubectl logs -n external-dns external-dns-5ccf86fb9-c62gx