
# mmv
Allows you to rename files interactively using `$EDITOR`. Inspired by [itchyny/mmv](https://github.com/itchyny/mmv).

![mmv](https://user-images.githubusercontent.com/59481467/142784385-12043470-8c38-4370-bbe6-458302e050b3.gif)




## goal
I like [itchyny/mmv](https://github.com/itchyny/mmv) a lot but didn't want to have to have Go on my machine to compile
it. I decided that I wanted that functionality to be in a language that my machine was more likely to understand
immediately upon a new install, so I attempted to reimplement those features in Bash.




## use
- `mmv <filename1> ...`
- `mmv <common substring>*`
- `mmv *`




## behavior
This implementation of mmv can:

- [X] swap file names

- [X] appropriately nest items





## install
```bash
git clone https://github.com/McAuleyPenney/mmv.git ~/.config/mmv
printf "\n# source mmv\n. ~/.config/mmv/mmv.sh\n" >> ~/.bashrc
```
- or just copy and paste the script into the shell functions you already source



## requirements
- `bash 4.0` or greater for associative array support




## TODO
- swap dir names
