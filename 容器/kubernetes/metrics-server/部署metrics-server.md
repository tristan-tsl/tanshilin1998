配置

```
        - --tls-cert-file=/data/tristan/kube-auth/ca.pem
        - --tls-private-key-file=/data/tristan/kube-auth/ca-key.pem
```


```
kubectl -n kube-system get pod -o wide

kubectl -n kube-system describe pod metrics-server-cf87f9b5d-hf8fd

kubectl -n kube-system delete pod metrics-server-5cf8797bb7-69pht
```

查看日志

```
kubectl -n kube-system logs -f --tail 100 metrics-server-cf87f9b5d-hf8fd -c metrics-server
```

进入容器中

```
kubectl -n kube-system exec -it metrics-server-79bcf769c4-tqzgk  -c metrics-server -- sh
```





验证

```
kubectl get apiservice
```



```
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
```

