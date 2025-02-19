Custom Watchtower Image
----

This repository contains the Dockerfile and associated files for building a custom Watchtower image. This image is designed to run Watchtower every time the container is started, with a recurring interval for scheduled updates. Additionally, it allows you to specify a target container name for Watchtower to monitor. (This way, you do not need to keep both a run-once command handy and a container that checks periodically.)

## Description

This custom Watchtower image builds upon the official `containrrr/watchtower` image, adding the ability to specify the update interval and target container name via the `docker run` command. The interval will be used for the immediate, one-time update check when the container starts, as well as for recurring updates.

## Secure Watchtower Installation

The included `install_watchtower.sh` script takes several important steps to ensure the integrity of the downloaded Watchtower binary during the build phase:

1. **Version Determination:** The script retrieves the latest Watchtower release tag from GitHub's API. This ensures you're always installing the most recent version.

2. **Checksum Verification:** Before downloading the Watchtower binary, the script downloads a checksums file corresponding to the release tag. It then extracts the expected SHA256 checksum for the appropriate architecture.

3. **Architecture-Specific Download:** The script downloads the correct Watchtower binary archive (`.tar.gz`) for the target architecture (arm64 or amd64).

4. **Checksum Validation:** After downloading the binary, the script calculates its SHA256 checksum and compares it against the expected checksum from the downloaded checksums file. This crucial step verifies that the downloaded binary has not been tampered with or corrupted during download. If the checksums don't match, the installation process is aborted.

5. **Binary Extraction and Installation:** Only after successful checksum verification is the binary archive extracted and the Watchtower binary installed to `/usr/local/bin/`.

6. **Cleanup:** The script cleans up temporary files (checksums file and binary archive) after installation.

This careful approach to installation ensures that you are running a genuine and untampered Watchtower binary.

## How to Build

1. Clone this repository:

    ```bash
    git clone https://github.com/your_github_username/your_repository_name.git
    cd your_repository_name
    ```

2. Build the Docker image:

    This Dockerfile uses a build argument `TARGETARCH` to build for different architectures (arm64, amd64).

    - **For your current architecture:**

        If you want to build for the architecture of your current machine, you can use the following command:

        ```bash
        docker build -t custom-watchtower .
        ```

        Docker will automatically detect your platform and build accordingly.

    - **For a specific architecture (e.g., arm64):**

        If you want to build for a specific architecture, you can set the `TARGETARCH` argument:

        ```bash
        docker build --build-arg TARGETARCH=linux/arm64/v8 -t custom-watchtower .
        ```

    - **For a specific architecture (e.g., amd64):**

        ```bash
        docker build --build-arg TARGETARCH=linux/amd64 -t custom-watchtower .
        ```

        It is recommended to set the `--platform` flag as well:

        ```bash
        docker build --platform linux/amd64 --build-arg TARGETARCH=linux/amd64 -t custom-watchtower .
        ```

    - **Building for multiple platforms (using Buildx):**

        For building multi-architecture images, it is recommended to use Docker Buildx. First, install Buildx if you don't have it already. Then create a builder instance:

        ```bash
        docker buildx create --use
        ```

        And build the image:

        ```bash
        docker buildx build --platform linux/arm64/v8,linux/amd64 -t custom-watchtower --push .
        ```

        This command will build the image for both arm64 and amd64 architectures and push it to your registry (e.g., Docker Hub or GHCR).

        You can replace `custom-watchtower` with `your_dockerhub_username/custom-watchtower:latest` to build and push the image in one step.

## How to Run

To run the custom Watchtower image, specify the interval (in seconds) and the target container name:

```bash
docker run -d --name watchtower \
    --restart unless-stopped \
    -v /var/run/docker.sock:/var/run/docker.sock \
    custom-watchtower [-i|--interval <seconds>] <target_container_name>
```

- **`<seconds>`**: The interval (in seconds) at which Watchtower should check for updates. If not provided, the default interval of 86400 seconds (24 hours) will be used.
- **`<target_container_name>`**: The name of the container that Watchtower should monitor for updates. This is a required parameter.

### Example

To monitor a container named `my-app` every 12 hours (43200 seconds):

```bash
docker run -d --name watchtower \
    --restart unless-stopped \
    -v /var/run/docker.sock:/var/run/docker.sock \
    custom-watchtower -i 43200 my-app
```

### How to Use the Official Image

If you prefer to use the official `containrrr/watchtower` image, you can run it directly with the following command:

```bash
docker run --rm \
    --name watchtower \
    -v /var/run/docker.sock:/var/run/docker.sock \
    containrrr/watchtower \
    --run-once -i 86400 <target_container_name>
```

## Published Image

This image is also available on Docker Hub under the `robertotomas` account:

```bash
docker pull robertotomas/custom-watchtower:latest
```

You can run it directly using:

```bash
docker run -d --name watchtower \
    --restart unless-stopped \
    -v /var/run/docker.sock:/var/run/docker.sock \
    robertotomas/custom-watchtower -i <interval_in_seconds> <target_container_name>
```

## Files

- **Dockerfile**: The Dockerfile used to build the image.
- **install_watchtower.sh**: Helper script to download, checksum verify, and set up the latest Watchtower binary.
- **entrypoint.sh**: The entrypoint script that handles the initial run and cron setup.
- **watchtower-cron**: The template for the cron job file.

## License

This project is licensed under the terms of the GNU Lesser General Public License v3.0. See the [LICENSE](LICENSE) file for details.
