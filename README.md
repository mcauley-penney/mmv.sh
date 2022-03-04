
# mmv
Allows you to rename files interactively using `$EDITOR`. Inspired by [itchyny/mmv](https://github.com/itchyny/mmv).
![mmv_basic_change](https://user-images.githubusercontent.com/59481467/143089045-19c01b41-f682-4391-a90f-faad99439a78.gif)




## goal
I like [itchyny/mmv](https://github.com/itchyny/mmv) a lot but didn't want to have to have Go on my machine to compile
it. I decided that I wanted that functionality to be in a language that my machine was more likely to understand
immediately upon a new install, so I attempted to reimplement those features in Bash.

#### comparison with itchyny/mmv functionality
This implementation lacks more checks than it possesses. For example, it does not check for duplicate inputs. I typically don't make the mistake of passing it duplicate inputs, so it's not something I wanted to worry about.




## use
- `mmv <filename1> ...`
- `mmv <common substring>*`
- `mmv *`




## behavior
This implementation of mmv can:

- [X] swap file names

![mmv_swap](https://user-images.githubusercontent.com/59481467/143089095-6bee9a87-185d-4e87-8af5-e40dbd7b2742.gif)


- [X] appropriately nest items

![nesting](https://user-images.githubusercontent.com/59481467/143089178-05fe9d18-aed8-4370-ab75-d5da95974680.gif)




## install
```bash
git clone https://github.com/McAuleyPenney/mmv.git ~/.config/mmv
printf "\n# source mmv\n. ~/.config/mmv/mmv.sh\n" >> ~/.bashrc
```
- or just copy and paste the script into the shell functions you already source




## requirements
- `bash 4.0` or greater for associative array support
