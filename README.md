# organize-backend
[organize-backend](https://github.com/High5Apps/organize-backend) is the backend server for the [organize-rn](https://github.com/High5Apps/organize-rn) client.

## Development setup
1. Clone the organize-backend repo from GitHub
    ```sh
    git clone git@github.com:High5Apps/organize-backend.git \
    && cd organize-backend
    ```
2. Run the `dev-setup` script
    ```sh
    # If you don't use ZSH, use your own alias file path (e.g. ~/.bashrc)
    # If you don't want to add aliases at all, remove the --alias-file option
    bin/dev-setup --alias-file ~/.zshrc
    ```
    If you choose not to install aliases, you'll need to fully type out the following commands wherever they appear later on:
    ```sh
    # Instead of dc
    docker compose -f compose.yaml -f compose.override.dev.yaml

    # Instead of drails
    docker compose -f compose.yaml -f compose.override.dev.yaml exec app rails
    ```
3. Download and install the following software, if you don't have it already:
    - [Docker Desktop](https://docs.docker.com/desktop/install/mac-install/)
    - [VS Code](https://code.visualstudio.com/Download)
4. Start Docker Desktop, navigate to the repository root in your terminal, then start the development server with:
    ```sh
    dc up
    ```
5. Launch VS Code by opening a new terminal tab in the repository root with `code .`. If you just installed VS Code, you'll need to follow these instructions on [launching from command line](https://code.visualstudio.com/docs/editor/command-line#_launching-from-command-line) first.

### Ruby IntelliSence and Syntax Highlighting
VS Code [IntelliSense](https://code.visualstudio.com/docs/editor/intellisense) provides code completion and other helpful hints to improve developer experience, but it must be set up before it will work.
1. Follow these instructions to [attach to a Docker container](https://code.visualstudio.com/docs/devcontainers/attach-container#_attach-to-a-docker-container)
2. In the VS Code extensions tab, search for and install `shopify.ruby-extensions-pack` 

## Testing
Run the rails tests with the command below. For more options, see [The Rails Test Runner](https://guides.rubyonrails.org/testing.html#the-rails-test-runner).
```sh
drails test
```

A subset of tests can be run with the `-n /regex/` flag, which will match against the underscored test name. For example:
```sh
# Run model and controller tests relating to ballots
drails t -n /Ballot/

# Run User model tests
drails t -n /UserTest/

# Run a single test by name
drails t -n /OrgTest#test_graph_should_include_blocked_user_ids/
```

## Deploying
Copy/paste the production environment variables into your `.env` file, then:
```sh
bin/deploy org
```

## Rails Tasks

Rails includes many built-in tasks for administering the application service. List them all with `drails -T`. Commonly used custom tasks are detailed below:

### `org:simulation` or `org:sim`

This task randomly simulates an Org at the 10-day mark to simplify development. It's normally used as follows:
1. Use your development client to create a new Org
2. Run `drails org:sim` on your development machine
3. Share your Org's group secret from the development client's development settings menu into the task's input
    - If you're using a simulator or emulator on your development machine, just copy and paste the group secret into the task's input.
    - If you're using a physical development device external to your development machine, share the group secret using a secure meassaging service. For example you could share it from an Android phone to a Mac using the [Signal app](https://signal.org/) "Note to Self" feature, then open the Signal desktop client on your Mac, then copy/paste it into the task's input.
4. Refresh your development client to see the simulated Org

## Physical server setup
To run organize-backend on a Raspberry Pi, perform the following steps:

1. Download the OS image
    - [Raspberry Pi OS (64-bit, lite)](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit)
2. Format the SD card (if needed)
    1. Open Disk Utility
    2. If the SD card isn’t FAT32 formatted, erase and reformat it to FAT32
3. Flash the Raspbian image onto the SD card
    ```sh
    bin/flash ~/Downloads/2024-03-15-raspios-bookworm-arm64-lite.img
    ```
4. Set up the physical Raspberry Pi
    1. Insert the SD card into the Raspberry Pi
    2. Connect an Ethernet cable to the Raspberry Pi
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
    ```
    curl http://getorganize.app # To test connection
    ```
8. Verify that cert setup succeeded
    ```sh
    ssh org
    docker compose logs -f
    ```
    - You can also check that a new entry was added to the [certificate transparency log](https://crt.sh/?q=getorganize.app)
9. Verify that the backend startup succeeded by hitting the new server with the mobile app
