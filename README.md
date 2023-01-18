# FLAME GPU 2 Template for CUDA C++

This repository can be used as a template for creating your own FLAME GPU 2 simulations or ensembles using the C++ (CUDA) interface.

[FLAMEGPU/FLAMEGPU2](https://github.com/FLAMEGPU/FLAMEGPU2) is downloaded via CMake and configured as a dependency of the project, as precompiled binary releases are not yet available.

The version of FLAME GPU fetched is pinned to a specific release of FLAME GPU, in case of API breaking changes.
This is controlled using the `FLAMEGPU_VERSION` CMake variable, which can be modified in `CMakeLists.txt`, or as a configuration argument.

For details on how to develop a model using FLAME GPU 2, refer to the [userguide & API documentation](https://docs.flamegpu.com/).

## Python Interface

FLAME GPU 2 also provides a python-based interface for writing models. If you wish to use this instead of the CUDA C++ interface, see [FLAMEGPU/FLAMEGPU2-model-template-python](https://github.com/FLAMEGPU/FLAMEGPU2-model-template-python).

## Requirements

Building FLAME GPU from source has the following requirements. There are also optional dependencies which are required for some components, such as Documentation or Python bindings, however these are not strictly required, and are not required for this standalone example.

Building FLAME GPU has the following requirements. There are also optional dependencies which are required for some components, such as Documentation or Python bindings.

+ [CMake](https://cmake.org/download/) `>= 3.18`
  + `>= 3.20` if building python bindings using a multi-config generator (Visual Studio, Eclipse or Ninja Multi-Config)
+ [CUDA](https://developer.nvidia.com/cuda-downloads) `>= 11.0` and a [Compute Capability](https://developer.nvidia.com/cuda-gpus) `>= 3.5` NVIDIA GPU.
+ C++17 capable C++ compiler (host), compatible with the installed CUDA version
  + [Microsoft Visual Studio 2019 or 2022](https://visualstudio.microsoft.com/) (Windows)
    + *Note:* Visual Studio must be installed before the CUDA toolkit is installed. See the [CUDA installation guide for Windows](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/index.html) for more information.
  + [make](https://www.gnu.org/software/make/) and [GCC](https://gcc.gnu.org/) `>= 8.1` (Linux)
+ [git](https://git-scm.com/)

Optionally:

+ [cpplint](https://github.com/cpplint/cpplint) for linting code
+ [Doxygen](http://www.doxygen.nl/) to build the documentation
+ [Python](https://www.python.org/) `>= 3.7` for python integration
  + With `setuptools`, `wheel`, `build` and optionally `venv` python packages installed
+ [swig](http://www.swig.org/) `>= 4.0.2` for python integration
  + Swig `4.x` will be automatically downloaded by CMake if not provided (if possible).
+ [FLAMEGPU2-visualiser](https://github.com/FLAMEGPU/FLAMEGPU2-visualiser) dependencies (fetched if possible)
  + [SDL](https://www.libsdl.org/)
  + [GLM](http://glm.g-truc.net/) *(consistent C++/GLSL vector maths functionality)*
  + [GLEW](http://glew.sourceforge.net/) *(GL extension loader)*
  + [FreeType](http://www.freetype.org/)  *(font loading)*
  + [DevIL](http://openil.sourceforge.net/)  *(image loading)*
  + [Fontconfig](https://www.fontconfig.org/)  *(Linux only, font detection)*


## Building with CMake

Building via CMake is a three step process, with slight differences depending on your platform.

1. Create a build directory for an out-of tree build
2. Configure CMake into the build directory
    + Using the CMake GUI or CLI tools
    + Specifying build options such as the CUDA Compute Capabilities to target, the inclusion of Visualisation or Python components, or performance impacting features such as `FLAMEGPU_SEATBELTS`. See [CMake Configuration Options](#CMake-Configuration-Options) for details of the available configuration options
    + CMake will automatically find and select compilers, libraries and python interpreters based on current environmental variables and default locations. See [Mastering CMake](https://cmake.org/cmake/help/book/mastering-cmake/chapter/Getting%20Started.html#specifying-the-compiler-to-cmake) for more information.
        + Python dependencies must be installed in the selected python environment. If needed you can instruct CMake to use a specific python implementation using the `Python_ROOT_DIR` and `Python_Executable` CMake options at configure time.
3. Build compilation targets using the configured build system
    + See [Available Targets](#Available-targets) for a list of available targets.

### Linux

To build under Linux using the command line, you can perform the following steps.

For example, to configure CMake for `Release` builds, for consumer Pascal GPUs (Compute Capability `61`), with python bindings enabled, producing the static library and `boids_bruteforce` example binary.

```bash
# Create the build directory and change into it
mkdir -p build && cd build

# Configure CMake from the command line passing configure-time options. 
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES=61 -DFLAMEGPU_BUILD_PYTHON=ON

# Build the required targets. In this case all targets
cmake --build . --target flamegpu boids_bruteforce -j 8

# Alternatively make can be invoked directly
make flamegpu boids_bruteforce -j8

```

### Windows

Under Windows, you must instruct CMake on which Visual Studio and architecture to build for, using the CMake `-A` and `-G` options.
This can be done through the GUI or the CLI.

I.e. to configure CMake for consumer Pascal GPUs (Compute Capability `61`), with python bindings enabled, and build the producing the static library and `boids_bruteforce` example binary in the Release configuration:

```cmd
REM Create the build directory 
mkdir build
cd build

REM Configure CMake from the command line, specifying the -A and -G options. Alternatively use the GUI
cmake .. -A x64 -G "Visual Studio 16 2019" -DCMAKE_CUDA_ARCHITECTURES=61 -DFLAMEGPU_BUILD_PYTHON=ON

REM You can then open Visual Studio manually from the .sln file, or via:
cmake --open . 
REM Alternatively, build from the command line specifying the build configuration
cmake --build . --config Release --target flamegpu boids_bruteforce --verbose
```

### CMake Configuration Options

| Option                               | Value                       | Description                                                                                                |
| -------------------------------------| --------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `CMAKE_BUILD_TYPE`                   | `Release` / `Debug` / `MinSizeRel` / `RelWithDebInfo` | Select the build configuration for single-target generators such as `make`   |
| `CMAKE_CUDA_ARCHITECTURES`           | e.g `60`, `"60;70"`         | [CUDA Compute Capabilities][cuda-CC] to build/optimise for, as a `;` separated list. See [CMAKE_CUDA_ARCHITECTURES][cmake-CCA]. Defaults to `all-major` or equivalent. Alternatively use the `CUDAARCHS` environment variable. |
| `FLAMEGPU_SEATBELTS`                 | `ON`/`OFF`                  | Enable / Disable additional runtime checks which harm performance but increase usability. Default `ON`     |
| `FLAMEGPU_VISUALISATION`             | `ON`/`OFF`                  | Enable Visualisation. Default `OFF`.                                                                       |
| `FLAMEGPU_VISUALISATION_ROOT`        | `path/to/vis`               | Provide a path to a local copy of the visualisation repository.                                            |
| `FLAMEGPU_ENABLE_NVTX`               | `ON`/`OFF`                  | Enable NVTX markers for improved profiling. Default `OFF`                                                  |
| `FLAMEGPU_WARNINGS_AS_ERRORS`        | `ON`/`OFF`                  | Promote compiler/tool warnings to errors are build time. Default `OFF`                                     |
| `FLAMEGPU_RTC_EXPORT_SOURCES`        | `ON`/`OFF`                  | At runtime, export dynamic RTC files to disk. Useful for debugging RTC models. Default `OFF`               |
| `FLAMEGPU_RTC_DISK_CACHE`            | `ON`/`OFF`                  | Enable/Disable caching of RTC functions to disk. Default `ON`.                                             |
| `FLAMEGPU_VERBOSE_PTXAS`             | `ON`/`OFF`                  | Enable verbose PTXAS output during compilation. Default `OFF`.                                             |
| `FLAMEGPU_CURAND_ENGINE`             | `XORWOW` / `PHILOX` / `MRG` | Select the CUDA random engine. Default `XORWOW`                                                            |
| `FLAMEGPU_ENABLE_GLM`                | `ON`/`OFF`                  | Experimental feature for GLM type support in RTC models. Default `OFF`.                                    |
| `FLAMEGPU_SHARE_USAGE_STATISTICS`    | `ON`/`OFF`                  | Share usage statistics ([telemetry](https://docs.flamegpu.com/guide/telemetry)) to support evidencing usage/impact of the software. Default `ON`. |
| `FLAMEGPU_TELEMETRY_SUPPRESS_NOTICE` | `ON`/`OFF`                  | Suppress notice encouraging telemetry to be enabled, which is emitted once per binary execution if telemetry is disabled. Defaults to `OFF`, or the value of a system environment variable of the same name. |
 
[cuda-CC]: https://developer.nvidia.com/cuda-gpus
[cmake-CCA]: https://cmake.org/cmake/help/latest/prop_tgt/CUDA_ARCHITECTURES.html

For a list of available CMake configuration options, run the following from the `build` directory:

```bash
cmake -LH ..
```

### Available Targets

| Target         | Description                                                                                                   |
| -------------- | ------------------------------------------------------------------------------------------------------------- |
| `all`          | Linux target containing default set of targets, including everything but the documentation and lint targets   |
| `ALL_BUILD`    | The windows equivalent of `all`                                                                               |
| `flamegpu`     | Build FLAME GPU static library                                                                                |
| `template`     | Each individual flamegpu_add_executable has it's own target. I.e. `template`                                  |
| `all_lint`     | Run all available Linter targets                                                                              |

For a full list of available targets, run the following after configuring CMake:

```bash
cmake --build . --target help
```

## Usage

Once compiled individual models can be executed from the command line, with a range of default command line arguments depending on whether the model implements a single Simulation, or an Ensemble of simulations.

To see the available command line arguments use the `-h` or `--help` options, for either C++ or python models.

I.e. for a `Release` build of the `template` model, run:

```bash
./bin/Release/template --help
```

### Visual Studio

If wishing to run examples within Visual Studio it is necessary to right click the desired example in the Solution Explorer and select `Debug > Start New Instance`.
Alternatively, if `Set as StartUp Project` is selected, the main debugging menus can be used to initiate execution.
To configure command line argument for execution within Visual Studio, right click the desired example in the Solution Explorer and select `Properties`, in this dialog select `Debugging` in the left hand menu to display the entry field for `command arguments`.
Note, it may be necessary to change the configuration as the properties dialog may be targeting a different configuration to the current build configuration.

### Environment Variables

Several environmental variables are used or required by FLAME GPU 2.

| Environment Variable                 | Description |
|--------------------------------------|-------------|
| `CUDA_PATH`                          | Required when using RunTime Compilation (RTC), pointing to the root of the CUDA Toolkit where NVRTC resides. <br /> i.e. `/usr/local/cuda-11.0/` or `C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.0`. <br /> Alternatively `CUDA_HOME` may be used if `CUDA_PATH` was not set. |
| `FLAMEGPU_INC_DIR`                   | When RTC compilation is required, if the location of the `include` directory cannot be found it must be specified using the `FLAMEGPU_INC_DIR` environment variable. |
| `FLAMEGPU_TMP_DIR`                   | FLAME GPU may cache some files to a temporary directory on the system, using the temporary directory returned by [`std::filesystem::temp_directory_path`](https://en.cppreference.com/w/cpp/filesystem/temp_directory_path). The location can optionally be overridden using the `FLAMEGPU_TMP_DIR` environment variable. |
| `FLAMEGPU_RTC_INCLUDE_DIRS`          | A list of include directories that should be provided to the RTC compiler, these should be separated using `;` (Windows) or `:` (Linux). If this variable is not found, the working directory will be used as a default. |
| `FLAMEGPU_SHARE_USAGE_STATISTICS`    | Enable / Disable sending of telemetry data, when set to `ON` or `OFF` respectively. |
| `FLAMEGPU_TELEMETRY_SUPPRESS_NOTICE` | Enable / Disable a once per execution notice encouraging the use of telemetry, if telemetry is disabled, when set to `ON` or `OFF` respectively. |

## Usage Statistics (Telemetry)

Support for academic software is dependant on evidence of impact. Without evidence it is difficult/impossible to justify investment to add features and provide maintenance. We collect a minimal amount of anonymous usage data so that we can gather usage statistics that enable us to continue to develop the software under a free and permissible licence.

Information is collected when a simulation, ensemble or test suite run have completed.

The [TelemetryDeck](https://telemetrydeck.com/) service is used to store telemetry data. 
All data is sent to their API endpoint of https://nom.telemetrydeck.com/v1/ via https. For more details please review the [TelmetryDeck privacy policy](https://telemetrydeck.com/privacy/).

We do not collect any personal data such as usernames, email addresses or machine identifiers.

More information can be found in the [FLAMEGPU documentation](https://docs.flamegpu.com/guide/telemetry).

Telemetry is enabled by default, but can be opted out by:

+ Setting an environment variable `FLAMEGPU_SHARE_USAGE_STATISTICS` to `OFF`, `false` or `0` (case insensitive).
  + If this is set during the first CMake configuration it will be used for all subsequent CMake configurations until the CMake Cache is cleared, or it is manually changed.
  + If this is set during simulation, ensemble or test execution (i.e. runtime) it will also be respected
+ Setting the `FLAMEGPU_SHARE_USAGE_STATISTICS` CMake option to `OFF` or another false-like CMake value, which will default telemetry to be off for executions.
+ Programmatically overriding the default value by:
  + Calling `flamegpu::io::Telemetry::disable()` or `pyflamegpu.Telemetry.disable()` prior to the construction of any `Simulation`, `CUDASimulation` or `CUDAEnsemble` objects.
  + Setting the `telemetry` config property of a `Simulation.Config`, `CUDASimulation.SimulationConfig` or `CUDAEnsemble.EnsembleConfig` to `false`.

## Authors and Acknowledgment

See [Contributors](https://github.com/FLAMEGPU/FLAMEGPU2/graphs/contributors) for a list of contributors towards this project.

If you use this software in your work, please cite DOI [10.5281/zenodo.5428984](https://doi.org/10.5281/zenodo.5428984). Release specific DOI are also provided via Zenodo.

Alternatively, [CITATION.cff](https://github.com/FLAMEGPU/FLAMEGPU2/blob/master/CITATION.cff) provides citation metadata, which can also be accessed from [GitHub](https://github.com/FLAMEGPU/FLAMEGPU2).

## License

FLAME GPU is distributed under the [MIT Licence](https://github.com/FLAMEGPU/FLAMEGPU2/blob/master/LICENSE.md).
