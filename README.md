# prime-wine (Windows for Linux in Windows Subsystem Linux)
Alternative approach to enable Prime Video HD playback on Linux, using Wine and Brave 📽️
<img width="3824" height="1080" alt="merged_side_by_side_updated" src="https://github.com/user-attachments/assets/7c5bbf9b-fe41-4db5-b70f-2d1d027b8488" />

## Prerequisites
1. Install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) and [Docker](https://docs.docker.com/desktop/setup/install/windows-install/).
2. Download: [Windows X-server](https://github.com/marchaesen/vcxsrv)
3. Run with these settings:
<img src="images/Disable%20Access%20Control.png" alt="Disable access control" width="50%">

## Build
```
docker build --platform linux/amd64 -t wine-tkg-lutris "C:\Docker\Lutris"
```

## Run Lutris
1. Run this in pwsh or cmd:
```
docker run -it -e DISPLAY=host.docker.internal:0 -v /tmp/.X11-unix:/tmp/.X11-unix -v C:\Docker\Lutris\Wine:/data/wine -v lutris-wine-data:/home/lutrisuser wine-tkg-lutris
```
2. No need to wait for wine to update. Click the + in the upper left corner and `Install from a local install script`.
<img src="images/Updating%20wine.png" alt="Updating wine" width="50%">
3. Click through the next screens and install missing packages (`wine-mono` is for Windows compatibility).

## Debugging Command Line
Open a command shell:
```
docker run -it -e DISPLAY=host.docker.internal:0 -v /tmp/.X11-unix:/tmp/.X11-unix -v C:\Docker\Lutris\Wine:/data/wine -v lutris-wine-data:/home/lutrisuser wine-tkg-lutris /bin/bash
```

## Uninstall
Remove everything!
```
# Stop and remove containers using the Lutris image
$containers = docker ps -a --filter "ancestor=wine-tkg-lutris" --format "{{.ID}}"
if ($containers) {
    docker stop $containers
    docker rm $containers
}

# Remove the Lutris image
docker rmi wine-tkg-lutris --force

# Remove the specific Lutris volume
docker volume rm lutris-wine-data -f

# Remove the local project folder
Remove-Item -Recurse -Force "C:\Docker\Lutris"
```


