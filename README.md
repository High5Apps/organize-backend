# organize-api
[organize-api](https://github.com/High5Apps/organize-api) is the backend server for the Organize app.

## Development setup
1. Clone organize-api
```sh
git clone git@github.com:High5Apps/organize-api.git \
&& cd organize-api
```
2. (Optional) Add Shell Aliases to ~/.zshrc
```sh
alias dc='docker compose -f docker/compose.yaml -f docker/compose.override.dev.yaml'
alias drails='dc exec app rails'
# Don't forget to run source ~/.zshrc
```
3. Create .env file with example values
```sh
cp .env.example .env
```
4. Create secrets
```sh
# ORGANIZE_DATABASE_PASSWORD has a max length of 99 characters
dc build \
&& dc up --detach \
&& dc exec app rails secret | head -c 99 && echo \
&& dc exec app rails secret \
&& dc down
```
5. Add secrets to .env file
6. Rebuild and smoke test
```sh
# Increase the sleep duration if db initialization takes longer than 30s
rm -rf tmp/db \
&& dc build \
&& dc up --detach \
&& echo 'Waiting 30s for db initialization...' \
&& sleep 30 \
&& drails db:reset \
&& drails test \
&& dc down \
&& echo 'Succeeded'
```

## Physical server setup
To run organize-api on a Raspberry Pi, perform the following steps:

1. Download the OS image
    - [Raspberry Pi OS (64-bit, lite)](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit)
2. Format the SD card (if needed)
    1. Open Disk Utility
    2. If the SD card isn’t FAT32 formatted, erase and reformat it to FAT32
3. Flash the Raspbian image onto the SD card (and optionally enable WiFi)
    - To optionally enable WiFi, add environment variables `SSID=<network> PSK=<password>`
    - To optionally use an insecure but easy-to-type password, use `INSECURE=true`
```sh
bin/flash ~/Downloads/2022-09-06-raspios-bullseye-arm64-lite.img
```
4. Set up the physical Raspberry Pi
    1. Insert the SD card into the Raspberry Pi
    2. Connect an Ethernet cable to the Raspberry Pi (optional if WiFi is enabled)
    3. Connect the power cable to the Raspberry Pi
    4. Turn on the Raspberry Pi
5. Bootstrap the Raspberry Pi's software
```sh
bin/bootstrap org
```
6. Set up port forwarding from router to server on 80/TCP and 443/TCP
  - For Xfinity, use Xfinity app / Connect / \<your ssid\> / Advanced settings / Port Forwarding
```
curl http://getorganize.app # To test connection
```
7. Verify that cert setup succeeded
```sh
ssh org
docker compose logs -f
```
8. Verify that the backend startup succeeded by hitting the new server with the mobile app

## Testing
Run the rails tests with the command below. For more options, see [The Rails Test Runner](https://guides.rubyonrails.org/testing.html#the-rails-test-runner).
```sh
drails test
```

## Deploying
```sh
bin/deploy org
```
