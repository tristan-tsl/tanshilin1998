### kubernetes deployments编排文件方式

sentinel-deployment.yaml

```
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: wjh-prod
  name: sentinel
  labels:
    app: sentinel
spec:
  replicas: 1
  template:
    metadata:
      name: sentinel
      labels:
        app: sentinel
    spec:
      containers:
        - name: sentinel
          image: registry.cn-shenzhen.aliyuncs.com/wjh-public/sentinel:1.8.0
          imagePullPolicy: IfNotPresent
          env:
          - name: JAVA_OPTS
            value: "-Dserver.port=8080 -Dcsp.sentinel.dashboard.server=localhost:8080 -Dproject.name=sentinel-dashboard -Dsentinel.dashboard.auth.username=admin -Dsentinel.dashboard.auth.password=tristan666"
          livenessProbe:
            tcpSocket:
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 45
      restartPolicy: Always
  selector:
    matchLabels:
      app: sentinel
```

sentinel-service.yaml

```
---
apiVersion: v1
kind: Service
metadata:
  name: sentinel
  namespace: wjh-prod
spec:
  selector:
    app: sentinel
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
```

部署

```
kubectl delete -f sentinel-deployment.yaml
kubectl apply -f sentinel-deployment.yaml

kubectl delete -f sentinel-service.yaml
kubectl apply -f sentinel-service.yaml

kubectl -n wjh-prod get deployment|grep sentinel
kubectl -n wjh-prod describe deployment/sentinel
kubectl -n wjh-prod get pod |grep sentinel

kubectl -n wjh-prod logs -f --tail 100 sentinel-85bffd5f98-cltr9
```

服务端访问地址:

```
# 内部
kubectl delete deployments/load-generator
kubectl run -i --tty load-generator --image=busybox /bin/sh
kubectl delete deployments/load-generator

wget sentinel.wjh-prod.svc

# 外部
# 打一个高位端口
kubectl -n wjh-prod expose deployment sentinel --port=8080 --type=NodePort --name=sentinel-out
kubectl -n wjh-prod describe services sentinel-out
```

外部: 192.168.2.20:

内部: sentinel.wjh-prod.svc

