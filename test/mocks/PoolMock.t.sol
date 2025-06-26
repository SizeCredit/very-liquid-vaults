// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IPool} from "@deps/aave/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@deps/aave/interfaces/IPoolAddressesProvider.sol";
import {DataTypes} from "@deps/aave/protocol/libraries/types/DataTypes.sol";

contract PoolMock is IPool {
    error NotImplemented();

    function mintUnbacked(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
        revert NotImplemented();
    }

    function backUnbacked(address asset, uint256 amount, uint256 fee) external returns (uint256) {
        revert NotImplemented();
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
        revert NotImplemented();
    }

    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external {
        revert NotImplemented();
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        revert NotImplemented();
    }

    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external
    {
        revert NotImplemented();
    }

    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
        returns (uint256)
    {
        revert NotImplemented();
    }

    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256) {
        revert NotImplemented();
    }

    function repayWithATokens(address asset, uint256 amount, uint256 interestRateMode) external returns (uint256) {
        revert NotImplemented();
    }

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external {
        revert NotImplemented();
    }

    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external {
        revert NotImplemented();
    }

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external {
        revert NotImplemented();
    }

    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external {
        revert NotImplemented();
    }

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        revert NotImplemented();
    }

    function initReserve(
        address asset,
        address aTokenAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external {
        revert NotImplemented();
    }

    function dropReserve(address asset) external {
        revert NotImplemented();
    }

    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress) external {
        revert NotImplemented();
    }

    function syncIndexesState(address asset) external {
        revert NotImplemented();
    }

    function syncRatesState(address asset) external {
        revert NotImplemented();
    }

    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration) external {
        revert NotImplemented();
    }

    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory) {
        revert NotImplemented();
    }

    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory) {
        revert NotImplemented();
    }

    function getReserveNormalizedIncome(address asset) external view returns (uint256) {
        revert NotImplemented();
    }

    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256) {
        revert NotImplemented();
    }

    function getReserveData(address asset) external view returns (DataTypes.ReserveDataLegacy memory) {
        revert NotImplemented();
    }

    function getVirtualUnderlyingBalance(address asset) external view returns (uint128) {
        revert NotImplemented();
    }

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external {
        revert NotImplemented();
    }

    function getReservesList() external view returns (address[] memory) {
        revert NotImplemented();
    }

    function getReservesCount() external view returns (uint256) {
        revert NotImplemented();
    }

    function getReserveAddressById(uint16 id) external view returns (address) {
        revert NotImplemented();
    }

    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider) {
        revert NotImplemented();
    }

    function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external {
        revert NotImplemented();
    }

    function updateFlashloanPremiums(uint128 flashLoanPremiumTotal, uint128 flashLoanPremiumToProtocol) external {
        revert NotImplemented();
    }

    function configureEModeCategory(uint8 id, DataTypes.EModeCategoryBaseConfiguration memory config) external {
        revert NotImplemented();
    }

    function configureEModeCategoryCollateralBitmap(uint8 id, uint128 collateralBitmap) external {
        revert NotImplemented();
    }

    function configureEModeCategoryBorrowableBitmap(uint8 id, uint128 borrowableBitmap) external {
        revert NotImplemented();
    }

    function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategoryLegacy memory) {
        revert NotImplemented();
    }

    function getEModeCategoryLabel(uint8 id) external view returns (string memory) {
        revert NotImplemented();
    }

    function getEModeCategoryCollateralConfig(uint8 id) external view returns (DataTypes.CollateralConfig memory) {
        revert NotImplemented();
    }

    function getEModeCategoryCollateralBitmap(uint8 id) external view returns (uint128) {
        revert NotImplemented();
    }

    function getEModeCategoryBorrowableBitmap(uint8 id) external view returns (uint128) {
        revert NotImplemented();
    }

    function setUserEMode(uint8 categoryId) external {
        revert NotImplemented();
    }

    function getUserEMode(address user) external view returns (uint256) {
        revert NotImplemented();
    }

    function resetIsolationModeTotalDebt(address asset) external {
        revert NotImplemented();
    }

    function setLiquidationGracePeriod(address asset, uint40 until) external {
        revert NotImplemented();
    }

    function getLiquidationGracePeriod(address asset) external view returns (uint40) {
        revert NotImplemented();
    }

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128) {
        revert NotImplemented();
    }

    function BRIDGE_PROTOCOL_FEE() external view returns (uint256) {
        revert NotImplemented();
    }

    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128) {
        revert NotImplemented();
    }

    function MAX_NUMBER_RESERVES() external view returns (uint16) {
        revert NotImplemented();
    }

    function mintToTreasury(address[] calldata assets) external {
        revert NotImplemented();
    }

    function rescueTokens(address token, address to, uint256 amount) external {
        revert NotImplemented();
    }

    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
        revert NotImplemented();
    }

    function eliminateReserveDeficit(address asset, uint256 amount) external {
        revert NotImplemented();
    }

    function getReserveDeficit(address asset) external view returns (uint256) {
        revert NotImplemented();
    }

    function getReserveAToken(address asset) external view returns (address) {
        revert NotImplemented();
    }

    function getReserveVariableDebtToken(address asset) external view returns (address) {
        revert NotImplemented();
    }

    function getFlashLoanLogic() external view returns (address) {
        revert NotImplemented();
    }

    function getBorrowLogic() external view returns (address) {
        revert NotImplemented();
    }

    function getBridgeLogic() external view returns (address) {
        revert NotImplemented();
    }

    function getEModeLogic() external view returns (address) {
        revert NotImplemented();
    }

    function getLiquidationLogic() external view returns (address) {
        revert NotImplemented();
    }

    function getPoolLogic() external view returns (address) {
        revert NotImplemented();
    }

    function getSupplyLogic() external view returns (address) {
        revert NotImplemented();
    }
}
