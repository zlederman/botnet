#!/bin/bash
set -euo pipefail # Exit on error, exit on unset variables, fail on pipe errors

UV_INSTALL_SCRIPT="https://astral.sh/uv/install.sh"
YOUR_GO_BINARY_URL="https://your-domain.com/downloads/your-go-app-$(uname -s)-$(uname -m)" # Example URL, adjust as needed
INSTALL_DIR="${HOME}/.local/bin" # Or ~/.cargo/bin if you want to use the default uv location

echo "--- Starting installation ---"

# Ensure install directory exists and is in PATH for current session
mkdir -p "${INSTALL_DIR}"
if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
  echo "Adding ${INSTALL_DIR} to PATH for this session."
  export PATH="${INSTALL_DIR}:$PATH"
fi

# 1. Install uv
echo "Installing uv..."
if ! command -v uv >/dev/null 2>&1; then
    # More secure: download first, then execute
    echo "Downloading uv install script..."
    UV_TMP_SCRIPT=$(mktemp)
    curl -LsSf "${UV_INSTALL_SCRIPT}" -o "${UV_TMP_SCRIPT}"
    chmod +x "${UV_TMP_SCRIPT}"
    echo "Executing uv install script..."
    "${UV_TMP_SCRIPT}" --force # --force ensures it runs even if detected
    rm "${UV_TMP_SCRIPT}"
    echo "uv installation complete."
else
    echo "uv already found. Skipping fresh installation."
    # Optional: run uv self update
    # echo "Attempting to update uv..."
    # uv self update || echo "Failed to update uv. You might need to run 'uv self update' manually."
fi

# Verify uv is now in PATH (for new shell sessions, it's usually handled by the uv installer itself)
# For the current script, the uv install script usually adds it to PATH internally,
# but if it puts it in ~/.cargo/bin and that's not in the original PATH, you might
# need to add ~/.cargo/bin to PATH here as well.
# For simplicity, we assume uv's installer adds it to a common PATH location, or
# you explicitly add the uv install path if different from INSTALL_DIR.

# A common uv install path is ~/.cargo/bin, let's ensure it's in our script's PATH
UV_DEFAULT_INSTALL_BIN="${HOME}/.cargo/bin"
if [[ -d "${UV_DEFAULT_INSTALL_BIN}" && ":$PATH:" != *":${UV_DEFAULT_INSTALL_BIN}:"* ]]; then
    echo "Adding ${UV_DEFAULT_INSTALL_BIN} to PATH for this script."
    export PATH="${UV_DEFAULT_INSTALL_BIN}:$PATH"
fi

if ! command -v uv >/dev/null 2>&1; then
    echo "Error: uv command not found after installation. Please check the uv installer's output."
    exit 1
fi
echo "uv is now available: $(command -v uv)"
uv --version # Test uv

# 2. Download and install your Go binary
echo "Downloading your Go application binary..."
GO_BINARY_NAME="your-go-app" # Replace with your actual binary name

curl -LsSf "${YOUR_GO_BINARY_URL}" -o "${INSTALL_DIR}/${GO_BINARY_NAME}"
chmod +x "${INSTALL_DIR}/${GO_BINARY_NAME}"

if ! command -v "${GO_BINARY_NAME}" >/dev/null 2>&1; then
    echo "Error: Your Go application binary '${GO_BINARY_NAME}' not found after download."
    exit 1
fi

echo "Your Go application installed to: $(command -v "${GO_BINARY_NAME}")"
echo "--- Installation complete! ---"
echo "You can now run: ${GO_BINARY_NAME}"
echo "You may need to restart your terminal or source your shell config (e.g., 'source ~/.bashrc') for 'uv' to be permanently in your PATH."

# Optional: Run your Go application immediately
# echo "Running your Go application:"
# "${GO_BINARY_NAME}" run-some-command