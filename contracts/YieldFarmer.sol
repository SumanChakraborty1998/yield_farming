// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "@studydefi/money-legos/dydx/contracts/DydxFlashloanBase.sol";
import "@studydefi/money-legos/dydx/contracts/ICallee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YieldFarmer is ICallee, DydxFlashloanBase {
    enum Direction {
        Deposit,
        Withdraw
    }

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    struct Operation {
        address token;
        address cToken;
        Direction direction;
        uint256 amountProvided;
        uint256 amountBorrowed;
    }

    // function callFunction(
    //     address sender,
    //     Account.Info memory account,
    //     bytes memory data
    // ) public {

    // }

    function _initiateFlashloan(
        address _solo,
        address _token,
        address _cToken,
        Direction _direction,
        uint256 _amountProvided,
        uint256 _amountBorrowed
    ) internal {
        ISoloMargin solo = ISoloMargin(_solo);
        uint256 marketId = _getMarketIdFromTokenAddress(_solo, _token);

        //Get the repayment amount (_amount + 2 wei)
        uint256 repayAmount = _getRepaymentAmountInternal(_amountBorrowed);
        IERC20 token = IERC20(_token);
        token.approve(_solo, repayAmount);

        //Withdraw the funds from dydx =>get the flash loan
        //Call the callback
        //Reemburse the loan

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _amountBorrowed);
        operations[1] = _getCallAction(
            abi.encode(
                Operation({
                    token: _token,
                    cToken: _cToken,
                    direction: _direction,
                    amountProvided: _amountProvided,
                    amountBorrowed: _amountBorrowed
                })
            )
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.info[] memory accountInfos = new Account.info[](1);
        solo.operate(accountInfos, operations);
    }
}
