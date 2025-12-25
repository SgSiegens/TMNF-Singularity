# TMNF-Singularity

TMNF-Singularity is a Singularity container environment designed to run
*TrackMania Nations Forever*, with optional mod support. This is the 
Singularity version of the Docker container, which can be found 
[here](https://github.com/SgSiegens/TMNF-Docker). Special thanks go to the 
creators of [singularity-minerl](https://github.com/Sanfee18/singularity-minerl), 
which provided important foundations for the GPU handling used in this setup.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Building](#building)
3. [Running](#running)

## Prerequisites

To install Singularity, follow the instructions in the [Quick Start Guide](https://docs.sylabs.io/guides/main/user-guide/quick_start.html). 
This project primarily focuses on NVIDIA GPUs, as other GPU vendors have not been tested. 
You will also need to install the NVIDIA Container Toolkit if you haven’t already, which can be found 
[here](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

## Building

> [!WARNING]
> We strongly recommend creating a dedicated scratch directory for temporary files during builds.
> By default, Singularity mounts the host system’s `/tmp` directory into the container. Running builds with
> elevated privileges may execute commands like `rm -rf /tmp/*`, which could be catastrophic for your host
> system, as explained in [this issue](https://github.com/apptainer/singularity/issues/2538).
> To avoid this risk, create a scratch directory and set the `SINGULARITY_TMPDIR` environment variable to
> point to it before building.
> For more details, see [this related issue](https://github.com/apptainer/singularity/issues/5791) and the
> official documentation on temporary directories [here](https://docs.sylabs.io/guides/main/user-guide/build_env.html#temporary-folders).

The base Singularity image, which runs the game via VirtualGL, can be built with the following command.
Include the `-E` flag only if you have set environment variables for Singularity, such as `SINGULARITY_TMPDIR`:

```bash
sudo -E singularity build <image name>.sif base-singularity.def
```
When building, you may encounter the following error:
```bash
ERROR: Failed to create mount namespace: mount namespace requires privileges, check Apptainer/Singularity installation
```
One solution that worked for us is:
```bash
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
```
If this doesn’t resolve check [this issue](https://github.com/apptainer/apptainer/issues/2360) for additional
 suggestions.

## Running