# Trivy Service

This is a simple Trivy server running in Kubernetes in EKS. The infrastructure is held in `infra/` which is spun up with terraform. Normally, this would be added to the CI but I excluded it for simplicity. 

This package is also self scanning. As it is deployed, it is scanned by the previous version of the Trivy Service before deployment. 
