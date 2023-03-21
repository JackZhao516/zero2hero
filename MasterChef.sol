// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./SushiToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


struct UserInfo{
    uint256 amount;
    uint256 rewardDebt;
}

struct PoolInfo{
    IERC20 lpToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accSushiPerShare;
}

contract MasterChef is Ownable{
    SushiToken public sushi;
    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;
    uint256 public startBlock = 0;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);


    constructor (SushiToken _sushi){
        sushi = _sushi;
    }


    function add(IERC20 _lpToken) external {
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + 100;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: 100,
            lastRewardBlock: lastRewardBlock,
            accSushiPerShare: 0
        }));
    }

    function updatePool(uint256 _pool) private {
        PoolInfo storage pool = poolInfo[_pool];
        if (pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blocksSinceLastReward = block.number - pool.lastRewardBlock;
        uint256 rewards = blocksSinceLastReward * 100;
        pool.accSushiPerShare = pool.accSushiPerShare + (rewards * 1e12 / pool.allocPoint);
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount * pool.accSushiPerShare / 1e12 - user.rewardDebt;
            sushi.transfer(msg.sender, pending);
        }
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount + _amount;
        user.rewardDebt = user.amount * pool.accSushiPerShare / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw not good");
        updatePool(_pid);
        uint256 pending = user.amount * pool.accSushiPerShare / 1e12 - user.rewardDebt;
        sushi.transfer(msg.sender, pending);
        user.amount = user.amount - _amount;
        user.rewardDebt = user.amount * pool.accSushiPerShare / 1e12;
        pool.lpToken.transfer(address(msg.sender), _amount);

        emit Withdraw(msg.sender, _pid, _amount);
    }

}


