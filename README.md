# TMNF-Singularity

TMNF-Singularity is a Singularity container environment designed to run
*TrackMania Nations Forever*, with optional mod support. This is the 
Singularity version of the Docker container, which can be found 
[here](https://github.com/SgSiegens/TMNF-Docker). Special thanks go to the 
creators of [singularity-minerl](https://github.com/Sanfee18/singularity-minerl), 
which provided important foundations for the GPU handling used in this setup.

## Table of Contents
- [TMNF-Singularity](#tmnf-singularity)
  * [Prerequisites](#prerequisites)
  * [Building](#building)
    + [Base Image](#base-image)
    + [Vulkan Image](#vulkan-image)
  * [Running](#running)
  * [Sandbox](#sandbox)
  * [Rendering Options](#rendering-options)
  * [Troubleshooting](#troubleshooting)
    + [Namespace Errors](#namespace-errors)
    + [Missing GPU Devices](#missing-gpu-devices)

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

Like the Docker repository this repo also provides two Singularity definition files: `base.def` and 
`vulkan.def`.

The base definition file serves as the primary image. It builds the entire environment, including the game and all 
required software, and uses VirtualGL for rendering.

The Vulkan definition file builds on top of the base image and acts as an extension that installs Vulkan and DXVK into 
the environment. It configures DXVK as the default rendering backend when running TMNF through Wine.

### Base Image
The base Singularity image runs the game using VirtualGL and can be built with the following command.
Include the `-E` flag only if you have set environment variables for Singularity, such as `SINGULARITY_TMPDIR`:

```bash
sudo -E singularity build <image name>.sif base.def
```

### Vulkan Image
The Vulkan image is built using the Base Image as its foundation. This version integrates DXVK, which enables Wine to 
utilize the Vulkan rendering backend rather than the default OpenGL backend.
In order to build the image, you must either have already built the base image locally or, if you prefer to use a 
prebuilt image from a registry like GHCR, manually edit the `vulkan.def` file to point to that remote source before 
starting the build (for more information on how to change the target for buidling [see](https://apptainer.org/docs/user/latest/build_a_container.html#overview)).
Run the following command to build the Vulkan Singularity image:
```bash
sudo -E singularity build <image_name>.sif vulkan.def
```
For more information have a look at the [Vulkan/DXVK section](https://github.com/SgSiegens/TMNF-Docker#vulkan-dxvk) of 
the original Docker repository.

---

**Would you like me to rewrite the "Prerequisites" section to include the specific line of code that needs to be changed in the `.def` file?**
## Running
To launch the game using the image you built, execute the following command. 
```bash 
SINGULARITY_TMPDIR=/path/to/scratch/dir singularity run --fakeroot -w --no-home --nv --no-mount tmp <image name>.sif
```
* --fakeroot: This is essential because running the container requires writing to certain system files.

* -w (writable): This enables the overlay file system, allowing the container to write data (such as game 
configurations) during the session.

* --no-home: This prevents the container from mounting your host’s home directory. It is used for isolation to 
ensure that it cannot accidentally modify your personal host files (optional).

* --nv: This binds the necessary NVIDIA drivers and libraries from your host to the container, which is required 
for hardware-accelerated 3D rendering.

* --no-mount tmp: This prevents the host’s /tmp directory from being mounted. This is necessary because sharing 
the host's temporary files caused some conflicts with Wine during out testing.

## Sandbox
On some systems, the `--fakeroot` flag is not allowed. In these cases, you can use Sandbox Mode. Sandboxes are writable 
by default and don't require "fakeroot" at runtime. To build a sandbox from a definition file:
```bash
sudo -E singularity build --sandbox <sandbox name> <def file name>.def
```
To convert an existing .sif file into a sandbox (sudo is not required):
```bash
singularity build --sandbox <sandbox name> <build image name>.sif 
```
To run the sandbox:
```bash
SINGULARITY_TMPDIR=/path/to/scratch/dir singularity run -w --no-home --nv --no-mount tmp <sandbox name>
```

## Rendering Options
Refer to the TMNF-Docker [rendering section](https://github.com/SgSiegens/TMNF-Docker?tab=readme-ov-file#rendering-options)

## Troubleshooting
### Namespace Errors
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

### Missing GPU Devices
In some cases, not all GPU devices may be correctly mapped into the container. On Linux systems, make sure your user 
belongs to the `video` and `render` groups. You can add your user to these groups by running:
```bash
usermod -aG render,video <your-username>
```

For the changes to take effect, you must **fully reboot** the system.
After rebooting, you can verify that it worked correctly by running:

```bash
groups <your-username>
```

Ensure that both `video` and `render` appear in the list of groups.
