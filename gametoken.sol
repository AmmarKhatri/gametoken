
//SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract GameToken {
    //managing complexity of farms
    struct Farm{
        uint size;
        uint planted;
    }
    //random number generator
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 5;
    }
    IERC20 token;
    //prices
    uint256 private tree;
    uint256 private sap;
    uint256 private potion;
    uint256 private nut;
    uint256 private farm;
    address private pool;
    //where data is saved of players
    mapping(address => uint) private trees;
    mapping(address => uint) private saps;
    mapping(address => uint) private potions;
    mapping(address => uint) private nuts;
    mapping(address => Farm[])  private farms;
    constructor(address _address, uint256 _tree, uint256 _sap, uint256 _potion, uint256 _nut, uint256 _farm, address _pool){
        //initializing
        token = IERC20(_address);
        tree = _tree;
        sap = _sap;
        potion = _potion;
        nut = _nut;
        farm = _farm;
        pool = _pool;
    }
    //get prices
    function p_nut()external view returns (uint){
        return nut;
    }
    function p_sap()external view returns (uint){
        return sap;
    }
    function p_potion()external view returns (uint){
        return potion;
    }
    function p_farm()external view returns (uint){
        return farm;
    }
    function p_tree()external view returns (uint){
        return tree;
    }

    function get_upgradeCost(uint index) external view returns (uint){
        return ((farms[msg.sender][index].size + 1) ** 2 - (farms[msg.sender][index].size) ** 2 * farm / 25);
    }

    //store functions
    function buyNuts()external returns (bool){
        require(nuts[msg.sender] < 50, "Maximum nuts owned");
        token.transferFrom(msg.sender, address(this), nut);
        nuts[msg.sender] += 1;
        return true;
    }
    function buySap()external returns (bool){
        require(saps[msg.sender] < 50, "Maximum saps owned");
        token.transferFrom(msg.sender, address(this), sap);
        saps[msg.sender] += 1;
        return true;
    }
    function buyPotion()external returns (bool){
        require(potions[msg.sender] < 50, "Maximum potions owned");
        token.transferFrom(msg.sender, pool, potion);
        saps[msg.sender] += 1;
        return true;
    }

    function buyFarm() external returns (bool) {
        require(farms[msg.sender].length < 10, "Maximum amount of farms owned");
        token.transferFrom(msg.sender,pool, farm);
        Farm memory f = Farm(5, 0);
        farms[msg.sender].push(f);
        return true;
    }

    function upgradeFarm(uint i) external returns (bool){
        require(i < 10, "Invalid farm number");
        require(farms[msg.sender][i].size < 10, "Farm is fully upgraded");
        token.transferFrom(msg.sender, pool,((farms[msg.sender][i].size + 1) ** 2 - (farms[msg.sender][i].size) ** 2 * farm / 25));
        farms[msg.sender][i].size += 1;
        return true;
    }
    // view functions
    function getnuts()external view returns (uint){
        return nuts[msg.sender];
    }
    function getSaps()external view returns (uint){
        return saps[msg.sender];
    }
    function getPotions()external view returns (uint){
        return potions[msg.sender];
    }
    function getTrees()external view returns (uint){
        return trees[msg.sender];
    }
    function getFarm() external view returns (Farm[] memory){
        return farms[msg.sender];
    }
    function getEachFarm(uint i) external view returns (Farm memory) {
        return farms[msg.sender][i];
    }


    //marketplace section
    event TradeCreated (
    uint indexed itemId,
    address s_address,
    uint8 qty,
    uint price
    );
    
    event FarmCreated (
    uint indexed farmId,
    address s_address,
    uint8 size,
    uint price
    );

    Trade[] t_sap;
    Trade[] t_nut;
    FarmTrade[] t_farm;
    Trade[] t_potion;
    
    struct FarmTrade {
        address s_address;
        uint8 size;
        uint price;
    }
    struct Trade {
        address s_address;
        uint8 qty;
        uint price;
    }
    mapping(address => FarmTrade[]) private farm_trades;
    mapping(address => Trade[]) private user_trades;
    uint itemId = 0;
    uint farmId = 0;
    //creating listings
    function createSapTrade(uint8 qty, uint price)external returns(bool){
          require(saps[msg.sender] >= qty, "Not enough sap to sell.");
          t_sap.push(Trade(msg.sender, qty, price));
          emit TradeCreated(itemId, msg.sender, qty, price);
          itemId++;
          user_trades[msg.sender].push(Trade(msg.sender, qty, price));
          return true;
    }
    function createNutTrade(uint8 qty, uint price)external returns(bool){
          require(nuts[msg.sender] >= qty, "Not enough nuts to sell.");
          t_nut.push(Trade(msg.sender, qty, price));
          emit TradeCreated(itemId, msg.sender, qty, price);
          itemId++;
          user_trades[msg.sender].push(Trade(msg.sender, qty, price));
          return true;
    }
    function createFarmTrade(uint8 size, uint price)external returns(bool){
          t_farm.push(FarmTrade(msg.sender, size, price));
          emit FarmCreated(farmId, msg.sender, size, price);
          farmId++;
          farm_trades[msg.sender].push(FarmTrade(msg.sender, size, price));
          return true;
    }
    function createPotionTrade(uint8 qty, uint price)external returns(bool){
          require(potions[msg.sender] >= qty, "Not enough potion to sell.");
          t_potion.push(Trade(msg.sender, qty, price));
          emit TradeCreated(itemId, msg.sender, qty, price);
          itemId++;
          user_trades[msg.sender].push(Trade(msg.sender, qty, price));
          return true;
    }
    
}