# Signing Your Project with the Signing Utility

This document explains how to use the `sign_project.bat` utility to create a self-signed certificate and sign your executables. This process helps increase user trust by replacing the "Unknown Publisher" warning with a name you provide.

## Prerequisites

- **Windows SDK**: The script requires `signtool.exe`, which is part of the Windows SDK. If it's not found, the script will display an error and guide you to install it.

## How to Use the Utility

Simply run the `sign_project.bat` file located in the `signing_instructions` directory.

```
.\signing_instructions\sign_project.bat
```

You will be presented with a menu with the following options:

1.  **Create a new signing certificate**: This option will guide you through creating a new self-signed certificate. You will be prompted to enter:
    *   Common Name (CN) - The name of the signer (e.g., your project or company name).
    *   Organization (O) - The name of your organization.
    *   Organizational Unit (OU) - A department, like "Development" or "Production".

    The certificate will be created and stored in your personal certificate store, valid for 5 years.

2.  **Sign an executable**: This option allows you to sign an executable file. The script will:
    *   Automatically find executables in the `../Output` directory.
    *   Allow you to select which executable to sign.
    *   Verify if the executable is already signed.
    *   List all available signing certificates from your personal store.
    *   Prompt you to select a certificate to use for signing.
    *   Sign the executable using the selected certificate and a public timestamp server.

3.  **Quit**: Exits the utility.

This automated script simplifies the signing process, ensuring that your executables are properly signed and timestamped.