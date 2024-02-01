// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Module, ModuleLib as ML} from "@cavalre/router/Module.sol";
import {IERC20} from "@cavalre/erc20/IERC20.sol";

struct Store {
    bool isInitialized;
    uint256 totalSupply;
    string name;
    string symbol;
    uint8 decimals;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
}

library ERC20Lib {
    // Store
    bytes32 internal constant ERC20_STORE_POSITION =
        keccak256("@cavalre.erc20.depot");

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // Errors
    error ERC20InsufficientAllowance(
        address spender,
        uint256 allowance,
        uint256 needed
    );
    error ERC20InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidSpender(address spender);

    // Selectors
    bytes4 internal constant CLONE = bytes4(keccak256("clone()"));
    bytes4 internal constant INITIALIZE =
        bytes4(keccak256("initialize(string,string,uint8,uint256)"));
    bytes4 internal constant NAME = bytes4(keccak256("name()"));
    bytes4 internal constant SYMBOL = bytes4(keccak256("symbol()"));
    bytes4 internal constant DECIMALS = bytes4(keccak256("decimals()"));
    bytes4 internal constant TOTAL_SUPPLY = bytes4(keccak256("totalSupply()"));
    bytes4 internal constant BALANCE_OF =
        bytes4(keccak256("balanceOf(address)"));
    bytes4 internal constant TRANSFER =
        bytes4(keccak256("transfer(address,uint256)"));
    bytes4 internal constant ALLOWANCE =
        bytes4(keccak256("allowance(address,address)"));
    bytes4 internal constant APPROVE =
        bytes4(keccak256("approve(address,uint256)"));
    bytes4 internal constant TRANSFER_FROM =
        bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 internal constant INCREASE_ALLOWANCE =
        bytes4(keccak256("increaseAllowance(address,uint256)"));
    bytes4 internal constant DECREASE_ALLOWANCE =
        bytes4(keccak256("decreaseAllowance(address,uint256)"));

    function store() internal pure returns (Store storage s) {
        bytes32 position = ERC20_STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

contract ERC20 is Module {
    address private immutable __self = address(this);

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](13);
        _commands[0] = ERC20Lib.CLONE;
        _commands[1] = ERC20Lib.INITIALIZE;
        _commands[2] = ERC20Lib.NAME;
        _commands[3] = ERC20Lib.SYMBOL;
        _commands[4] = ERC20Lib.DECIMALS;
        _commands[5] = ERC20Lib.TOTAL_SUPPLY;
        _commands[6] = ERC20Lib.BALANCE_OF;
        _commands[7] = ERC20Lib.TRANSFER;
        _commands[8] = ERC20Lib.ALLOWANCE;
        _commands[9] = ERC20Lib.APPROVE;
        _commands[10] = ERC20Lib.TRANSFER_FROM;
        _commands[11] = ERC20Lib.INCREASE_ALLOWANCE;
        _commands[12] = ERC20Lib.DECREASE_ALLOWANCE;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) public {
        Store storage s = ERC20Lib.store();
        if (s.isInitialized) {
            revert("ERC20: Already initialized");
        }
        s.name = _name;
        s.symbol = _symbol;
        s.decimals = _decimals;
        s.totalSupply = _totalSupply;
        s.balances[msg.sender] = _totalSupply;
        s.isInitialized = true;
        ML.store().owners[__self] = msg.sender;
    }

    // Functions
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return ERC20Lib.store().name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return ERC20Lib.store().symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     */
    function decimals() external view returns (uint8) {
        return ERC20Lib.store().decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return ERC20Lib.store().totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */

    function balanceOf(address account) external view returns (uint256) {
        return ERC20Lib.store().balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return ERC20Lib.store().allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the ERC. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20Lib.ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20Lib.ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal {
        Store storage s = ERC20Lib.store();
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            s.totalSupply += value;
        } else {
            uint256 fromBalance = s.balances[from];
            if (fromBalance < value) {
                revert ERC20Lib.ERC20InsufficientBalance(
                    from,
                    fromBalance,
                    value
                );
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                s.balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                s.totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                s.balances[to] += value;
            }
        }

        emit ERC20Lib.Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20Lib.ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20Lib.ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal {
        if (owner == address(0)) {
            revert ERC20Lib.ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20Lib.ERC20InvalidSpender(address(0));
        }
        ERC20Lib.store().allowances[owner][spender] = value;
        if (emitEvent) {
            emit ERC20Lib.Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal {
        uint256 currentAllowance = this.allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20Lib.ERC20InsufficientAllowance(
                    spender,
                    currentAllowance,
                    value
                );
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}
