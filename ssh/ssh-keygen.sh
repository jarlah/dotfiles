ssh-keygen -t rsa -C "jarl.andre@gmail.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
