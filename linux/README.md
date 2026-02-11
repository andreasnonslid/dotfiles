tree-sitter uses cmake min version 3.2 and breaks when using cmake version < 3.5

to fix

```
vim ~/.local/share/nvim/lazy/telescope-fzf-native.nvim/CMakeLists.txt
```

```
cd ~/.local/share/nvim/lazy/telescope-fzf-native.nvim
make clean
make
```
