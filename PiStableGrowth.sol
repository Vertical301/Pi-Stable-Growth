## 📌 Smart Contract Code
The full Solidity contract can be found in [`PiStableGrowth.sol`](./PiStableGrowth.sol).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PiStableGrowth {
    address public owner;
    uint256 public initialValue;
    uint256 public lastUpdated;
    uint256 public piBaseRate = 31416;
    uint256 public alpha = 500;  
    uint256 public beta = 50;    
    uint256 public gamma = 300;  

    uint256 public demandFactor;
    uint256 public sellPressure;
    uint256 public utilityFactor;

    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public stakeTimestamp;
    uint256 public stakingRewardRate = 5;

    event PriceUpdated(uint256 newValue, uint256 timestamp);
    event TokensStaked(address indexed staker, uint256 amount);
    event TokensUnstaked(address indexed staker, uint256 amount, uint256 reward);

    constructor(uint256 _initialValue) {
        owner = msg.sender;
        initialValue = _initialValue;
        lastUpdated = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can update parameters");
        _;
    }

    function updateFactors(uint256 _demand, uint256 _sell, uint256 _utility) external onlyOwner {
        demandFactor = _demand;
        sellPressure = _sell;
        utilityFactor = _utility;
    }

    function calculateValue() public view returns (uint256) {
        uint256 timeElapsed = (block.timestamp - lastUpdated) / 1 days;

        int256 growthFactor = int256(piBaseRate) + int256(alpha * demandFactor) - int256(beta * sellPressure) + int256(gamma * utilityFactor);
        if (growthFactor < 0) growthFactor = 0;

        uint256 newValue = initialValue * (1 + uint256(growthFactor) / 1000000) ** timeElapsed;

        return newValue;
    }

    function updateValue() external onlyOwner {
        initialValue = calculateValue();
        lastUpdated = block.timestamp;
        emit PriceUpdated(initialValue, block.timestamp);
    }

    function getCurrentValue() external view returns (uint256) {
        return calculateValue();
    }

    function setAlphaBetaGamma(uint256 _alpha, uint256 _beta, uint256 _gamma) external onlyOwner {
        alpha = _alpha;
        beta = _beta;
        gamma = _gamma;
    }

    function stakeTokens(uint256 _amount) external {
        require(_amount > 0, "Cannot stake zero tokens");
        stakedBalances[msg.sender] += _amount;
        stakeTimestamp[msg.sender] = block.timestamp;
        emit TokensStaked(msg.sender, _amount);
    }

    function unstakeTokens() external {
        require(stakedBalances[msg.sender] > 0, "No staked tokens found");
        uint256 stakedAmount = stakedBalances[msg.sender];
        uint256 stakingDuration = (block.timestamp - stakeTimestamp[msg.sender]) / 1 days;
        uint256 reward = (stakedAmount * stakingRewardRate * stakingDuration) / 36500;

        stakedBalances[msg.sender] = 0;
        emit TokensUnstaked(msg.sender, stakedAmount, reward);
    }
}
