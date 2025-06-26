// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAaveIncentivesController} from "@deps/aave/interfaces/IAaveIncentivesController.sol";
import {IPool} from "@deps/aave/interfaces/IPool.sol";
import {IAToken} from "@deps/aave/interfaces/IAToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {WadRayMath} from "@deps/aave/protocol/libraries/math/WadRayMath.sol";

contract ATokenMock is IAToken, ERC20, Ownable {
    error NotImplemented();

    address public immutable underlying;

    constructor(address _owner, address _underlying, string memory _name, string memory _symbol)
        Ownable(_owner)
        ERC20(_name, _symbol)
    {
        underlying = _underlying;
    }

    function initialize(
        IPool,
        address,
        address,
        IAaveIncentivesController,
        uint8,
        string calldata,
        string calldata,
        bytes calldata
    ) external pure {
        revert NotImplemented();
    }

    function mint(address, address onBehalfOf, uint256 amount, uint256) external onlyOwner returns (bool) {
        _mint(onBehalfOf, amount);
        return true;
    }

    function burn(address from, address, uint256 amount, uint256) external onlyOwner {
        _burn(from, amount);
    }

    function balanceOf(address account) public view override(IERC20, ERC20) returns (uint256) {
        return WadRayMath.wadMul(super.balanceOf(account), IPool(owner()).getReserveData(underlying).liquidityIndex);
    }

    function mintToTreasury(uint256, uint256) external pure {
        revert NotImplemented();
    }

    function transferOnLiquidation(address, address, uint256) external pure {
        revert NotImplemented();
    }

    function transferUnderlyingTo(address, uint256) external pure {
        revert NotImplemented();
    }

    function handleRepayment(address, address, uint256) external pure {
        revert NotImplemented();
    }

    function permit(address, address, uint256, uint256, uint8, bytes32, bytes32) external pure {
        revert NotImplemented();
    }

    function UNDERLYING_ASSET_ADDRESS() external pure returns (address) {
        revert NotImplemented();
    }

    function RESERVE_TREASURY_ADDRESS() external pure returns (address) {
        revert NotImplemented();
    }

    function DOMAIN_SEPARATOR() external pure returns (bytes32) {
        revert NotImplemented();
    }

    function nonces(address) external pure returns (uint256) {
        revert NotImplemented();
    }

    function rescueTokens(address, address, uint256) external pure {
        revert NotImplemented();
    }

    function scaledBalanceOf(address) external pure override returns (uint256) {
        revert NotImplemented();
    }

    function getScaledUserBalanceAndSupply(address) external pure returns (uint256, uint256) {
        revert NotImplemented();
    }

    function scaledTotalSupply() external pure returns (uint256) {
        revert NotImplemented();
    }

    function getPreviousIndex(address) external pure returns (uint256) {
        revert NotImplemented();
    }
}
