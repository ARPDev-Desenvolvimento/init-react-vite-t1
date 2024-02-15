#!/bin/bash

# Verifique se o evento foi um pull_request.closed e se o pull request foi fundido
if [[ $GITHUB_EVENT_NAME == "pull_request" && $(jq -r '.pull_request.merged' "$GITHUB_EVENT_PATH") == "true" ]]; then
    # Obtém o número do pull request
    pr_number=$(jq -r '.pull_request.number' "$GITHUB_EVENT_PATH")

    # Obter informações sobre o pull request usando a API do GitHub
    pr_info=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls/$pr_number")

    # Verifique se o pull request foi aprovado
    if [[ $(echo "$pr_info" | jq -r '.merged') == "true" ]]; then
        echo "O pull request #$pr_number foi fundido e aprovado. Executando o script..."

        # Se aprovado, execute o script de sincronização de diretório
        # Defina os diretórios e branches
        source_dir="https://github.com/ARPDev-Desenvolvimento/init-react-vite.git"
        target_dir="https://github.com/ARPDev-Desenvolvimento/init-react-vite-v2.git"
        source_branch="master"
        target_branch="master"

        # Clone o repositório para aplicar as alterações
        git clone . tmp_repo
        cd tmp_repo

        # Atualize o branch de origem
        git checkout $source_branch
        git pull origin $source_branch

        # Aplique as alterações no diretório de destino
        rsync -av --delete $source_dir/ $target_dir/

        # Adicione, commit e envie as alterações para o branch de destino
        git add $target_dir
        git commit -m "Atualizar $target_dir com alterações de $source_dir"
        git push origin $target_branch

        # Limpeza
        cd ..
        rm -rf tmp_repo
    else
        echo "O pull request #$pr_number foi fundido, mas não foi aprovado."
    fi
else
    echo "Este script só deve ser executado quando um pull request é fundido e aprovado."
fi
