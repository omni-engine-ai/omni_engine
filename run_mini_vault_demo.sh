#!/usr/bin/env bash
set -e

# ==============================================================================
# Sovereign MiniVault Autonomous Verification & Demo Harness
# Omni Engine v2.2.3 | Pure Rust Offline Commodity Hardware Demonstration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_PATH="${SCRIPT_DIR}/bin/omni_engine"
PLAN_PATH="${SCRIPT_DIR}/examples/mini_vault_maestro_plan.json"
MODEL_PATH="${SCRIPT_DIR}/models/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"
OUTPUT_DIR="${HOME}/mini_vault_demo_run"

echo "================================================================================"
echo "  OMNI ENGINE v2.2.3 - SOVEREIGN OFFLINE GENERATION REHEARSAL"
echo "  Model: Qwen2.5-Coder-1.5B (Offline CPU Standalone)"
echo "  Plan : Sovereign MiniVault Pure Rust Blueprint"
echo "================================================================================"

# 1. Clean output workspace
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# 2. Run Omni Engine Swarm
"${BIN_PATH}" run "Build Sovereign MiniVault pure Rust encryption crate" \
  --plan-file "${PLAN_PATH}" \
  --model "${MODEL_PATH}" \
  --output-dir "${OUTPUT_DIR}" \
  --steps 5 \
  -y \
  --allow-unsandboxed

# 3. Locate and unpack delivered archive
cd "${OUTPUT_DIR}"
ARCHIVE=$(ls omni_deliverables_*.tar.gz | head -n 1)
if [ -z "${ARCHIVE}" ]; then
  echo "[-] ERROR: Deliverables archive not found in output directory!"
  exit 1
fi

echo ""
echo "[+] Unpacking delivered archive: ${ARCHIVE}..."
tar -zxvf "${ARCHIVE}"

# 4. Host Integration Verification Test
echo ""
echo "[+] Running Host Integration Test on verified deliverable..."
cat << 'EOF' > /tmp/host_integration_test.rs
use mini_vault::MiniVault;
use std::path::Path;

fn main() {
    let password = "SovereignMasterKey2026!";
    let secret = b"TOP_SECRET_OMNI_DATA";
    
    // Test 1: Creation & Persistence
    let vault = MiniVault::create(password, secret);
    let path = Path::new("/tmp/test_vault.db");
    vault.save(path).expect("Failed to save vault to disk");
    
    // Test 2: Loading & Unlocking
    let loaded = MiniVault::load(path).expect("Failed to load vault from disk");
    let decrypted = loaded.unlock(password).expect("Failed to unlock vault with correct password");
    
    assert_eq!(decrypted, secret, "Decrypted plaintext must match original payload");
    println!("  [TEST 1 PASSED] MiniVault created, saved, loaded, and decrypted successfully!");
    
    // Test 3: Unauthorized Access Prevention
    assert!(loaded.unlock("WrongPassword").is_none(), "Vault must reject invalid password");
    println!("  [TEST 2 PASSED] Invalid password strictly rejected (Access Denied)!");
    
    println!("\n  >>> VERIFICATION COMPLETE: 100% HOST TEST PASS <<<");
}
EOF

rustc --edition=2021 --crate-type=lib src/lib.rs -o /tmp/libmini_vault_demo.rlib
rustc --edition=2021 /tmp/host_integration_test.rs --extern mini_vault=/tmp/libmini_vault_demo.rlib -o /tmp/host_integration_test
/tmp/host_integration_test

echo ""
echo "================================================================================"
echo "  DEMONSTRATION COMPLETE: 100% CLEANROOM & HOST COMPILE SUCCESSFUL"
echo "================================================================================"
