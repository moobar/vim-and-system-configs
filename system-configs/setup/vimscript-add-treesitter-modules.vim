echo "Running: TSInstall vim"
silent TSInstallSync! vim
echo "Running: TSInstall lua"
silent TSInstallSync! lua
echo "Running: TSInstall json5"
silent TSInstallSync! json5
echo "Running: TSInstall cpp"
silent TSInstallSync! cpp
echo "Running: TSInstall c"
silent TSInstallSync! c
echo "Running: TSInstall java"
silent TSInstallSync! java
echo "Running: TSInstall json"
silent TSInstallSync! json
echo "Running: TSInstall terraform"
silent TSInstallSync! terraform
echo "TreeSitter module install complete"
qall

