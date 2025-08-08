// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {Ghosts} from "@test/recon/Ghosts.sol";
import {Properties} from "@test/recon/Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/SizeMetaVault.sol";

abstract contract ERC4626MustNotRevertTargets is BaseTargetFunctions, Properties {
    function erc4626_asset() public {
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].asset() {
            } catch {
                t(false, ERC4626_MUST_NOT_REVERT);
            }
        }
    }

    function erc4626_totalAssets() public {
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].totalAssets() {
            } catch {
                t(false, ERC4626_MUST_NOT_REVERT);
            }
        }
    }

    function erc4626_convertToShares(uint256 assets) public {
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].convertToShares(assets) {
            } catch {
                t(false, ERC4626_MUST_NOT_REVERT);
            }
        }
    }

    function erc4626_convertToAssets(uint256 shares) public {
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].convertToAssets(shares) {
            } catch {
                t(false, ERC4626_MUST_NOT_REVERT);
            }
        }
    }

    function erc4626_maxDeposit(address receiver) public {
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].maxDeposit(receiver) {
            } catch {
                t(false, ERC4626_MUST_NOT_REVERT);
            }
        }
    }

    function erc4626_previewDeposit(uint256 assets) public {
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].previewDeposit(assets) {
            } catch {
                t(false, ERC4626_MUST_NOT_REVERT);
            }
        }
    }

    function erc4626_maxMint(address receiver) public {
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].maxMint(receiver) {
            } catch {
                t(false, ERC4626_MUST_NOT_REVERT);
            }
        }
    }

    function erc4626_previewMint(uint256 shares) public {
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].previewMint(shares) {
            } catch {
                t(false, ERC4626_MUST_NOT_REVERT);
            }
        }
    }

    function erc4626_maxWithdraw(address owner) public {
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].maxWithdraw(owner) {
            } catch {
                t(false, ERC4626_MUST_NOT_REVERT);
            }
        }
    }

    function erc4626_previewWithdraw(uint256 assets) public {
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].previewWithdraw(assets) {
            } catch {
                t(false, ERC4626_MUST_NOT_REVERT);
            }
        }
    }

    function erc4626_maxRedeem(address owner) public {
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].maxRedeem(owner) {
            } catch {
                t(false, ERC4626_MUST_NOT_REVERT);
            }
        }
    }

    function erc4626_previewRedeem(uint256 shares) public {
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].previewRedeem(shares) {
            } catch {
                t(false, ERC4626_MUST_NOT_REVERT);
            }
        }
    }


}
