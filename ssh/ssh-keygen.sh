ssh-keygen -t rsa -C "jarl.andre@gmail.com" -N '' -f ~/.ssh/id_rsa
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
