# Script to be sourced in ~/.bashrc which provides convenient Kuberenetes functionality
alias k='kubectl'

###############################
# AUTOCOMPLETION
#
# Kubernetes autocompletion which works for alias 'k' as well
source <(kubectl completion bash)
complete -o default -F __start_kubectl k

###############################
# Custom convenience functions
#

kHelp() {
  echo "================"
  echo "Commands available:"
  echo "kGetCurrNamespace                    - Get the current context namespace."
  echo "kGetDeploymentYaml <deployment-name> - Get the YAML of the deployment with the given name."
  echo "kGetCronJobs                         - Get a list of cron jobs."
  echo "kGetPod <pod-prefix>                 - Get the name of a pod with the given prefix."
  echo "kSetNamespace <namespace>            - Set the current context's namespace."
  echo "kTailLogForPod <pod-name>            - Follow the logs for the pod."
  echo "eksSetCluster <cluster-name>         - Add entry in ~/.kube/config for an EKS cluster (requires aws cli on path)."

}

kGetCurrNamespace() {
  kubectl config view --minify | grep namespace
}

kSetNamespace() {
  if [ -z "$1" ]; then
    echo "Usage: kSetNamespace <namespace>"
    return 1
  fi

  local namespace="$1"
  kubectl config set-context --current --namespace="$namespace"

  if [ $? -eq 0 ]; then
    echo "Namespace set to '$namespace' for the current context."
  else
    echo "Failed to set namespace."
  fi
}

kGetPod() {
  if [ -z "$1" ]; then
    echo "Usage: kGetPod <pod-name-prefix>"
    return 1
  fi
    kubectl get pods | grep $1 | awk '{print $1}'
}

kGetCronJobs() {
  # Just list the cronjobs available.
  # Note to spawn a new job use:
  #  template: `kubectl create job --from=cronjob/<name-as-appears-on-output> <name-of-pod-which-will-be-spawned>`
  #  e.g.      `kubectl create job --from=cronjob/some-job-name some-job-name-run-1
  kubectl get cronjob
}

kTailLogForPod() {
  if [ -z "$1" ]; then
    echo "Usage: kTailLogForPod <pod-name>"
    return 1
  fi

  kubectl logs -f $1
}

kGetDeploymentYaml() {
  if [ -z "$1" ]; then
    echo "Usage: kGetDeploymentYaml <deployment-name>"
    return 1
  fi

  kubectl get deployment $1 -o yaml
}


eksSetCluster() {
  if [ -z "$1" ]; then
    echo "Usage: eksSetCluster <cluster-name>"
    return 1
  fi

  # This will:
  # 1. Use the AWS CLI to contact EKS (make sure that is available on the path)
  # 2. Update the k8s config in ~/.kube/config so that kubectl knows:
  #    (i) which cluster to connect to, (ii) what credentials to use (AWS IAM),
  #    (iii) what context name to use e.g. rn:aws:eks:region:account-id:cluster/some-cluster
  # After running this you can run commands like `kubectl get nodes` like normal.
  aws eks update-kubeconfig --name $1
}