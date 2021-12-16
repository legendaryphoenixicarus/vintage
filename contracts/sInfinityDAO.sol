// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./SafeMath.sol";
// import "./Address.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Permit.sol";

contract sInfinityDao is ERC20Permit, Ownable {
    using SafeMath for uint256;

    modifier onlyVault() {
        require(msg.sender == vault);
        _;
    }

    address public vault;
    address public initializer;

    event LogSupply(uint256 indexed epoch, uint256 timestamp, uint256 totalSupply);
    event LogRebase(uint256 indexed epoch, uint256 rebase, uint256 index);
    event LogVaultChanged(address vault);

    struct Rebase {
        uint256 epoch;
        uint256 rebase; // 18 decimals
        uint256 totalStakedBefore;
        uint256 totalStakedAfter;
        uint256 amountRebased;
        uint256 index;
        uint256 blockNumberOccured;
    }
    Rebase[] public rebases;

    uint256 public INDEX;

    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 5000000 * 10**9;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0); // (2^128) - 1

    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping(address => mapping(address => uint256)) private _allowedValue;

    constructor() ERC20("Staked Gyro", "sInfinityDAO", 9) ERC20Permit() {
        initializer = msg.sender;
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
    }

    function initialize(address vault_) external {
        require(msg.sender == initializer, "Only initializer");
        require(vault_ != address(0), "Vault cannot be zero");
        vault = vault_;
        _gonBalances[vault] = TOTAL_GONS;

        emit Transfer(address(0x0), vault, _totalSupply);
        emit LogVaultChanged(vault_);

        initializer = address(0);
    }

    function setIndex(uint256 _INDEX) external onlyOwner() returns (bool) {
        require(INDEX == 0);
        INDEX = gonsForBalance(_INDEX);
        return true;
    }

    /**
        @notice increases sInfinityDAO supply to increase staking balances relative to profit_
        @param profit_ uint256
        @param epoch_ uint256
        @return uint256
     */
    function rebase(uint256 profit_, uint256 epoch_) public onlyVault() returns (uint256) {
        uint256 rebaseAmount;
        uint256 rebasePercent;
        uint256 previousCirculating = circulatingSupply();

        if (profit_ == 0) {
            emit LogSupply(epoch_, block.timestamp, _totalSupply);
            emit LogRebase(epoch_, 0, index());
            return _totalSupply;
        }

        if (previousCirculating > 0) {
            rebaseAmount = profit_.mul(_totalSupply).div(previousCirculating);
            rebasePercent = profit_.mul(1e18).div(previousCirculating);
        } else {
            rebaseAmount = profit_;
            rebasePercent = ~uint256(0);
        }

        _totalSupply = _totalSupply.add(rebaseAmount);

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        uint256 currIndex = index();

        rebases.push(
            Rebase({
                epoch: epoch_,
                rebase: rebasePercent, // 18 decimals
                totalStakedBefore: previousCirculating,
                totalStakedAfter: circulatingSupply(),
                amountRebased: profit_,
                index: currIndex,
                blockNumberOccured: block.number
            })
        );

        emit LogSupply(epoch_, block.timestamp, _totalSupply);
        emit LogRebase(epoch_, rebasePercent, currIndex);

        return _totalSupply;
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function gonsForBalance(uint256 amount) public view returns (uint256) {
        return amount.mul(_gonsPerFragment);
    }

    function balanceForGons(uint256 gons) public view returns (uint256) {
        return gons.div(_gonsPerFragment);
    }

    function circulatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(vault));
    }

    function index() public view returns (uint256) {
        return balanceForGons(INDEX);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowedValue[owner_][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        _allowedValue[from][msg.sender] = _allowedValue[from][msg.sender].sub(value);
        emit Approval(from, msg.sender, _allowedValue[from][msg.sender]);

        uint256 gonValue = gonsForBalance(value);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _allowedValue[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // What gets called in a permit
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual override {
        _allowedValue[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _allowedValue[msg.sender][spender] = _allowedValue[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedValue[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 oldValue = _allowedValue[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedValue[msg.sender][spender] = 0;
        } else {
            _allowedValue[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedValue[msg.sender][spender]);
        return true;
    }
}