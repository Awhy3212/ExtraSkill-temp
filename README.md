# Extraskill Temp ( SOURCE CODE ) 
``made by ! 0Xploit``

A C++ utility interface providing temporary system spoofing, tracing/cleaning, and hardware serial checking capabilities.

## Features

- **Temp Spoof**: Automatically downloads and maps the necessary `.sys` driver.
- **Clean**: Downloads and executes a system cleanup batch script.
- **Check Serials**: Retrieves and displays various system hardware IDs, including Disk, CPU, BIOS, Motherboard, UUID, and MAC address.

---

## Prerequisites

To compile this project from source, you will need to install the following dependencies on your system:

1. **Visual Studio 2022** (Community, Professional, or Enterprise) or **Build Tools for Visual Studio 2022**.
   - During installation, you **must** select the **Desktop development with C++** workload.
   - Ensure that the **MSVC v143 - VS 2022 C++ x64/x86 build tools** and **Windows 10 SDK** components are checked.
2. **MSBuild** (Automatically included with the Visual Studio C++ workload).
3. **Windows Driver Kit (WDK)** *(If you plan on undertaking any further driver compilation/development)*.

## How to Build

We provide a convenient automated PowerShell script that targets `ExtraskillTemp.slnx` and builds every configuration matrix (Debug/Release across Win32/x64).

1. Clone or download the repository to your local machine.
2. Open **PowerShell**.
3. Navigate to the root folder of the repository.
4. Run the automated build script:

```powershell
.\scripts\build_all.ps1
```

*(Note: Depending on your PowerShell execution policies, you might need to run `powershell -ExecutionPolicy Bypass -File .\scripts\build_all.ps1` instead).*

The script will automatically locate MSBuild and compile the project. Once the process is finished, your final successfully compiled executables will be located in the newly created `build\` folder.

### Manual Build
Alternatively, you can double-click **`ExtraskillTemp.slnx`** to open it natively inside Visual Studio 2022. Select your desired configuration (e.g., Release / Win32) at the top, and press `Ctrl+Shift+B` to build the solution directly from the IDE.

---

## How to Use

1. Navigate to your newly compiled `build/Release/Win32/` or `build/Release/x64/` directory.
2. Launch `ExtraskillTemp.exe`. **(Running it as Administrator is highly recommended for driver mapping & deep HWID querying to succeed)**.
3. Use the numeric keypad to choose an option from the console menu:
   - `[1] Temp Spoof`
   - `[2] Clean`
   - `[3] Check Serials`
   - 
## ⓘ Important Warning:
Using the Spoof or Clean functions will download mapping drivers and batch executables dynamically to protected system paths like `C:\Windows\Temp\` and `C:\Windows\Fonts\`. Please make sure your Windows Defender or antivirus software is turned off or specifically permits the file pathways; otherwise, the processes will fail and be blocked!
