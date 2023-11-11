# Terranetes
This is a sample project aimed to automatically deploy k8s cluster with terraform. It will host a sample web-service with Nginx as the LB and reverse proxy. 

## Notes & Pre-reqs
This sample project is designed for learning purposes only, and we will not scale up anything in cloud services. As such, we will leverage minikube to host the k8s cluster on a local linux server.

## Dev Guide
### Basic Commands

Lookup pods, services, service url
```
kubectl get pods
kubectl get service
minikube service <service-name> --url
```
