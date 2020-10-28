boldGreen := $(shell tput bold)$(shell tput setaf 2)
normal := $(shell tput sgr0)

all: note-1 k8s-namespace github-token argocd argocd-app
resume: note-2 github-token argocd argocd-app

note-1:
	@clear
	@echo "$(boldGreen)Starting K8s Installation$(normal)"
	@echo
	@echo "You need the following tools installed on your machine:"
	@echo "	- kubectl (Homebrew: kubernetes-cli)"
	@echo
	@echo "You will also need to provide the access token to your git repo."
	@echo "	For GitHub: https://github.com/settings/tokens/new"
	@echo
	@echo "The following steps will be taken:"
	@echo "	1. Apply prerequisite namespace definition"
	@echo "	2. Set up access token for git repo"
	@echo "	3. Install Argo CD"
	@echo "	4. Set up Argo CD with \`stack\` directory"
	@echo
	@echo "NOTE: If you used template to generate the repo, you need to run the following first:"
	@echo "      	tools/replace-repo-ref.sh"
	@echo "      This will replace all the repository references"
	@echo
	@echo "Current Kubernetes Setup"
	@kubectl cluster-info
	@echo

	@echo "Make sure you are working with the right Kubernetes cluster"
	@echo

	@read -r -p "If you are ready to proceed, press enter. Otherwise exit with Ctrl-C. "

k8s-namespace:
	@clear
	@echo "$(boldGreen)1. Applying K8s namespace for Argo CD...$(normal)"
	@echo
	kubectl apply -f ./init/namespace-argocd.yaml
	@echo
	@read -r -p "completed."

github-token:
	@clear
	@echo "$(boldGreen)2. Setting up access token for git repo...$(normal)"
	@echo
	@echo "NOTE: For using a forked repository, you need to run \`tools/replace-repo-ref.sh\` script before this."
	@echo "      If you have not done this yet, exit with Ctrl-C now, and run the followings"
	@echo "    tools/replace-repo-ref.sh"
	@echo "    make resume"
	@echo
	@echo "If you are ready to proceed, provide the following information:"
# @read -r -p "    Your username: " username; # When user token is used, the username can be any non-empty string
	@read -s -p "    Your token: " userToken;\
		echo "";\
		kubectl -n argocd create secret generic access-secret \
			--from-literal=username=placeholder \
			--from-literal=token=$$userToken
	@echo
	@read -r -p "completed."

argocd:
	@clear
	@echo "$(boldGreen)3. Installing Argo CD...$(normal)"
	@echo
	kubectl apply -f ./stack/argo-cd/argo-cd-install.yaml -n argocd
	@echo
	@read -r -p "completed."

argocd-app:
	@clear
	@echo "$(boldGreen)4. Set up Argo CD with \`stack\` folder$(normal)"
	@echo
	kubectl apply -f ./init/argo-cd-project.yaml
	kubectl apply -f ./init/argo-cd-application.yaml
	@echo
	@read -r -p "completed."

note-2:
	@clear
	@echo "$(boldGreen)Resuming K8s Installation$(normal)"
	@echo
	@echo "You are about to resume the K8s installation"
	@echo
	@echo "The following steps will be taken:"
	@echo "	3. Set up access token for git repo"
	@echo "	4. Install Argo CD"
	@echo "	5. Set up Argo CD with \`stack\` directory"
	@echo
	@read -r -p "If you are ready to get started, press enter "
