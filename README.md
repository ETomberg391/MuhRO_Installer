# MuhRO Web Installer

This project contains the source code and tools to build the MuhRO web installer. The installer is created using Inno Setup and includes a custom downloader script to fetch the game files from a remote server. 

**Note: This is an open source code from the Ecne Project community, and is not directly related to the MuhRO Project, as a means to learn techniques for bettering the Inno Setup open source compiler with custom solutions to the aging IDP failing module.**
## Features

-   **Web-based Installer**: Downloads the latest game files directly from a URL.
-   **Progress Display**: Shows download progress to the user.
-   **Self-Contained Build Tools**: Includes necessary tools like `7za.exe` and `curl.exe`.
-   **Code Signing Utility**: A batch script is provided to simplify the process of self-signing the installer executable.

## How to Build the Installer

1.  **Install Inno Setup**: You need to have [Inno Setup](https://jrsoftware.org/isinfo.php) installed on your system.
2.  **Compile the Script**: Open the `web_setup.iss` file in the Inno Setup Compiler and compile it.
3.  **Output**: The compiled installer, `MuhRO_Installer.exe`, will be created in the `Output` directory.

## Code Signing

To improve user trust, it is recommended to sign the installer. A utility script is provided to make this process easier.

-   Run `signing_instructions/sign_project.bat`.
-   Follow the on-screen instructions to create a new self-signed certificate or sign an existing executable.

For more details, see [`signing_instructions/signing_instructions.md`](signing_instructions/signing_instructions.md).

## Project Structure

-   `web_setup.iss`: The main Inno Setup script.
-   `progress.vbs`: A VBScript to handle the download and progress reporting.
-   `signing_instructions/`: Contains the code signing utility and instructions.
-   `Output/`: The default directory for the compiled installer.
-   `7za.exe`, `curl.exe`, `libcurl.dll`: Command-line tools used by the installer.
-   `muhro.ico`: The icon file for the installer.
-   `LICENSE`: The project's license file.

## Replicating the Installer

Future updates will include a template or a batch script to simplify the process of customizing the installer for your own projects. This will make it easier to change details such as the application name, download URL, and other settings within the Inno Setup script.
