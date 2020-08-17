.DEFAULT_GOAL := run_all

test_version?=$(git branch)

.PHONY: refresh_all_certificates
refresh_all_certificates:
	sudo rm -rf /opt/local_kube/kubernetes/pki /opt/k8sfs/kubernetes/etc/*.kubeconfig
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

.PHONY: multipass_test
multipass_test:
	multipass launch -c 2 -m 6G -d 20G -n master --cloud-init cloud-config-master.yaml 20.04
	multipass launch -c 2 -m 6G -d 20G -n worker --cloud-init cloud-config-worker.yaml 20.04

.PHONY: multipass_clean
multipass_clean:
	rm -rf ~/.cache/multipass/
	multipass delete master || true
	multipass delete node0 || true
	multipass delete node1 || true
	multipass delete node2 || true
	multipass purge

.PHONY: multipass_rerun
multipass_rerun:
	make multipass_clear || true
	make multipass_test || true
	multipass exec master -- tail -f /var/log/cloud-init-output.log


.PHONY: pre_commit_setup
pre_commit_setup:
	  curl https://pre-commit.com/install-local.py | python3 -
	  GO111MODULE=on go get mvdan.cc/sh/v3/cmd/shfmt
