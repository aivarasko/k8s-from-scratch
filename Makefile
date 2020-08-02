.DEFAULT_GOAL := run_all

.PHONY: refresh_all_certificates
refresh_all_certificates:
	sudo rm -rf /opt/local_kube/kubernetes/pki /opt/local_kube/kubernetes/etc/*.kubeconfig
	./run_all.sh

.PHONY: rotate_encryption_keys
rotate_encryption_keys:
	DEBUG=1 ROTATE_KEYS=1 ./3_gen_configs_master.sh
	sudo systemctl daemon-reload
	sudo systemctl restart kube-apiserver
	kubectl get secrets --all-namespaces -o json | kubectl replace -f -

.PHONY: crictl_status
crictl_status:
	sudo env PATH=${PATH} CONTAINER_RUNTIME_ENDPOINT="unix:///var/run/containerd/containerd.sock" crictl ps
	sudo env PATH=${PATH} CONTAINER_RUNTIME_ENDPOINT="unix:///var/run/containerd/containerd.sock" crictl images


.PHONY: run_all
run_all:
	DEBUG=1 ./run_all.sh


.PHONY: pre_commit_checks
pre_commit_checks:
	pre-commit run --all-files
