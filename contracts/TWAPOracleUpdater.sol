// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./ERC20Permit.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

/**
 * @dev Intended to update the TWAP for a token based on accepting an update call from that token.
 *  expectation is to have this happen in the _beforeTokenTransfer function of ERC20.
 *  Provides a method for a token to register its price sourve adaptor.
 *  Provides a function for a token to register its TWAP updater. Defaults to token itself.
 *  Provides a function a tokent to set its TWAP epoch.
 *  Implements automatic closeing and opening up a TWAP epoch when epoch ends.
 *  Provides a function to report the TWAP from the last epoch when passed a token address.
 */
interface ITWAPOracle {
    function uniV2CompPairAddressForLastEpochUpdateBlockTimstamp(address) external returns (uint32);

    function priceTokenAddressForPricingTokenAddressForLastEpochUpdateBlockTimstamp(
        address tokenToPrice_,
        address tokenForPriceComparison_,
        uint256 epochPeriod_
    ) external returns (uint32);

    function pricedTokenForPricingTokenForEpochPeriodForPrice(
        address,
        address,
        uint256
    ) external returns (uint256);

    function pricedTokenForPricingTokenForEpochPeriodForLastEpochPrice(
        address,
        address,
        uint256
    ) external returns (uint256);

    function updateTWAP(address uniV2CompatPairAddressToUpdate_, uint256 eopchPeriodToUpdate_) external returns (bool);
}

contract MinterOwned is Ownable {
    address internal _minter;

    event MinterSet(address oldMinter, address indexed newMinter);

    function setMinter(address minter_) external onlyOwner() returns (bool) {
        require(minter_ != address(0), "Minter cannot be address zero");
        address oldMinter = _minter;
        _minter = minter_;

        emit MinterSet(oldMinter, _minter);

        return true;
    }

    /**
     * @dev Returns the address of the current minter.
     */
    function minter() public view returns (address) {
        return _minter;
    }

    /**
     * @dev Throws if called by any account other than the minter.
     */
    modifier onlyMinter() {
        require(_minter == msg.sender, "Caller is not the minter");
        _;
    }
}

contract TWAPOracleUpdater is ERC20Permit, MinterOwned {
    using EnumerableSet for EnumerableSet.AddressSet;

    event TWAPOracleChanged(address indexed previousTWAPOracle, address indexed newTWAPOracle);
    event TWAPEpochChanged(uint256 previousTWAPEpochPeriod, uint256 newTWAPEpochPeriod);
    event TWAPSourceAdded(address indexed newTWAPSource);
    event TWAPSourceRemoved(address indexed removedTWAPSource);

    EnumerableSet.AddressSet private _dexPoolsTWAPSources;

    ITWAPOracle public twapOracle;

    uint256 public twapEpochPeriod;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_, decimals_) {} // solhint-disable-line no-empty-blocks

    function changeTWAPOracle(address newTWAPOracle_) external onlyOwner() {
        emit TWAPOracleChanged(address(twapOracle), newTWAPOracle_);
        twapOracle = ITWAPOracle(newTWAPOracle_);
    }

    function changeTWAPEpochPeriod(uint256 newTWAPEpochPeriod_) external onlyOwner() {
        require(newTWAPEpochPeriod_ > 0, "TWAPOracleUpdater: TWAP Epoch period must be greater than 0.");
        emit TWAPEpochChanged(twapEpochPeriod, newTWAPEpochPeriod_);
        twapEpochPeriod = newTWAPEpochPeriod_;
    }

    function addTWAPSource(address newTWAPSourceDexPool_) external onlyOwner() {
        require(_dexPoolsTWAPSources.add(newTWAPSourceDexPool_), "TWAP Source already stored.");
        emit TWAPSourceAdded(newTWAPSourceDexPool_);
    }

    function removeTWAPSource(address twapSourceToRemove_) external onlyOwner() {
        require(_dexPoolsTWAPSources.remove(twapSourceToRemove_), "TWAP source not present.");
        emit TWAPSourceRemoved(twapSourceToRemove_);
    }

    function _updateTWAPOracle(address dexPoolToUpdateFrom_, uint256 twapEpochPeriodToUpdate_) internal {
        if (_dexPoolsTWAPSources.contains(dexPoolToUpdateFrom_)) {
            // slither-disable-next-line unused-return
            twapOracle.updateTWAP(dexPoolToUpdateFrom_, twapEpochPeriodToUpdate_);
        }
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256
    ) internal virtual override {
        if (_dexPoolsTWAPSources.contains(from_)) {
            _updateTWAPOracle(from_, twapEpochPeriod);
        } else {
            if (_dexPoolsTWAPSources.contains(to_)) {
                _updateTWAPOracle(to_, twapEpochPeriod);
            }
        }
    }
}