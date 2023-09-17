tree-sitter uses cmake min versino 3.2 and breaks when using 3.5<cmake version

to fix

```
vim ~/.local/share/nvim/lazy/telescope-fzf-native.nvim/CMakeLists.txt
```

```
cd ~/.local/share/nvim/lazy/telescope-fzf-native.nvim
make clean
make
```
