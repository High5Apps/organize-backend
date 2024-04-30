# organize-api
[organize-api](https://github.com/High5Apps/organize-api) is the backend server for the Organize app.

## Development setup
1. Clone the organize-api repo from GitHub
    ```sh
    git clone git@github.com:High5Apps/organize-api.git \
    && cd organize-api
    ```
2. Run the `dev-setup` script
    ```sh
    # If you don't use ZSH, use your own alias file path (e.g. ~/.bashrc)
    # If you don't want to add aliases at all, remove the --alias-file option
    bin/dev-setup --alias-file ~/.zshrc
    ```

## Testing
Run the rails tests with the command below. For more options, see [The Rails Test Runner](https://guides.rubyonrails.org/testing.html#the-rails-test-runner).
```sh
drails test
```

## Deploying
```sh
bin/deploy org
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
    bin/flash ~/Downloads/2024-03-15-raspios-bookworm-arm64-lite.img
    ```
4. Set up the physical Raspberry Pi
    1. Insert the SD card into the Raspberry Pi
    2. Connect an Ethernet cable to the Raspberry Pi (optional if WiFi is enabled)
    3. Connect the power cable to the Raspberry Pi
    4. Turn on the Raspberry Pi
5. Bootstrap the Raspberry Pi's software
    - If `ping raspberrypi.local` doesn't work after a few minutes, your local
    network probably doesn't support multicast DNS. In this case, you'll need to
    add the environment variable `IP=<address>`. Your Pi's IP address can
    usually be found on your router's local configuration page. You should also
    configure your router to give your Pi a static IP address.
    ```sh
    bin/bootstrap org
    ```
6. On your DNS registrar's website, create a new A record pointing from `@` to
your local network's IP address.
7. Set up port forwarding from router to server on 80/TCP and 443/TCP
    - For Xfinity, use Xfinity app / Connect / \<your ssid\> / Advanced settings / Port Forwarding
    - For HOT, open your router config page / Advanced / Forwarding
    ```
    curl http://getorganize.app # To test connection
    ```
8. Verify that cert setup succeeded
    ```sh
    ssh org
    docker compose logs -f
    ```
9. Verify that the backend startup succeeded by hitting the new server with the mobile app
