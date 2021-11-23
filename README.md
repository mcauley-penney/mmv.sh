
# mmv
Allows you to rename files interactively using `$EDITOR`. A bash reimplemenatation of [itchyny/mmv](https://github.com/itchyny/mmv).

![mmv](https://user-images.githubusercontent.com/59481467/142784385-12043470-8c38-4370-bbe6-458302e050b3.gif)



## use
- `mmv <filename1> ...`
- `mmv *`

## install
```bash
git clone https://github.com/McAuleyPenney/mmv.git ~/.config/mmv
printf "\n# source mmv\n. ~/.config/mmv/mmv.sh\n" >> ~/.bashrc
```
- or just copy and paste the script into the shell functions you already source

## requirements
- `bash 4.0` or greater for associative array support


## TODO
    - only create temp files on demand
