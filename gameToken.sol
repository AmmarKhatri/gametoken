//SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/Counters.sol";
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
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 6;
    }
    function random2() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))) % 6;
    }
    IERC20 token;
    //prices
    uint256 private tree;
    uint256 private sap;
    uint256 private potion;
    uint256 private nut;
    uint256 private farm;
    address private pool;
    address private owner;
    //where data is saved of players
    mapping(address => uint) private trees;
    mapping(address => uint) private saps;
    mapping(address => uint) private potions;
    mapping(address => uint) private nuts;
    mapping(address => mapping(uint => Farm))  private farms;
    constructor(address _address, uint256 _tree, uint256 _sap, uint256 _potion, uint256 _nut, uint256 _farm, address _pool){
        //initializing
        token = IERC20(_address);
        tree = _tree * (10 ** 18);
        sap = _sap * (10 ** 18);
        potion = _potion * (10 ** 18);
        nut = _nut * (10 ** 18);
        farm = _farm * (10 ** 18);
        pool = _pool;
        owner = msg.sender;
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
        return (((farms[msg.sender][index].size + 1) ** 2) - ((farms[msg.sender][index].size) ** 2)) * farm / 25;
    }

    //store functions
    function buyNuts(uint i)external returns (bool){
        //requires approve
        token.transferFrom(msg.sender, address(this),i * nut);
        nuts[msg.sender] += i;
        return true;
    }
    function buySap(uint i)external returns (bool){
        //requires approve
        token.transferFrom(msg.sender, address(this), i * sap);
        saps[msg.sender] += i;
        return true;
    }
    function buyPotion(uint i)external returns (bool){
        //requires approve
        token.transferFrom(msg.sender, pool, i * potion);
        saps[msg.sender] += i;
        return true;
    }

    function buyFarm(uint index) external returns (bool) {
        require(index < 10, "Wrong index passed");
        //requires approve
        token.transferFrom(msg.sender,pool, farm);
        farms[msg.sender][index] = Farm(5,0);
        return true;
    }

    function upgradeFarm(uint index) external returns (bool){
        require(index < 10, "Invalid farm number");
        require(farms[msg.sender][index].size < 10, "Farm is fully upgraded");
        //requires approve
        token.transferFrom(msg.sender, pool,(((farms[msg.sender][index].size + 1) ** 2) - ((farms[msg.sender][index].size) ** 2)) * farm / 25);
        farms[msg.sender][index].size += 1;
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
    /*function getFarm() external view returns (mapping memory){
        return farms[msg.sender];
    }*/
    function getEachFarm(uint index) external view returns (Farm memory) {
        return farms[msg.sender][index];
    }


    //marketplace section
    event TradeCreated (
    uint indexed tradeId,
    uint itemId,
    uint timestamp,
    address s_address,
    uint qty,
    uint price
    );
    event FarmTradeCreated (
    uint indexed farmTradeId,
    address s_address,
    uint timestamp,
    uint size,
    uint price
    );
    struct FarmTrade {
        address s_address;
        uint plot_index;
        uint size;
        uint price;
        address b_address;
        bool sold;
        bool cancelled;
    }
    struct Trade {
        address s_address;
        uint itemId;
        uint qty;
        uint price;
        address b_address;
        bool sold;
        bool cancelled;
    }
    using Counters for Counters.Counter;
    Counters.Counter private _tradeId;
    Counters.Counter private _farmTradeId;
    mapping(uint => Trade) private trades;
    mapping(uint => FarmTrade) private farmtrades;

    function createTrade(uint _itemId, uint _price, uint _qty)external returns(bool){
        if(_itemId == 0) {
            require(saps[msg.sender] >= _qty, "Not enough sap to sell.");
            saps[msg.sender] -= _qty;
        } else if(_itemId == 1){
            require(nuts[msg.sender] >= _qty, "Not enough nuts to sell.");
            nuts[msg.sender] -= _qty;
        } else if(_itemId == 2){
            require(potions[msg.sender] >= _qty, "Not enough potions to sell.");
            potions[msg.sender] -= _qty;
        } else {
            return false;
        }
        _tradeId.increment();
        trades[_tradeId.current()] = Trade(msg.sender,_itemId,_qty,_price, address(0), false, false);
        emit TradeCreated(_tradeId.current(), _itemId,block.timestamp, msg.sender, _qty, _price);
        return true;
    }
    function createFarmTrade(uint _size, uint _price, uint index)external returns(bool){
        require(farms[msg.sender][index].size > 0, "Farm does not exist");
        _farmTradeId.increment();
        farmtrades[_farmTradeId.current()] = FarmTrade(msg.sender,index,_size,_price, address(0), false, false);
        farms[msg.sender][index].size = 0;
        farms[msg.sender][index].planted = 0;
        emit FarmTradeCreated(_farmTradeId.current(), msg.sender, block.timestamp,_size,_price);
        return true;
    }

    function acceptTrade(uint tradeId)external returns(bool){
        if(trades[tradeId].itemId == 0) {
            token.transferFrom(msg.sender, trades[tradeId].s_address, trades[tradeId].price);
            saps[msg.sender] += trades[tradeId].qty;
            trades[tradeId].b_address = msg.sender;
            trades[tradeId].sold = true;
            return true;
        } else if(trades[tradeId].itemId == 1){
            token.transferFrom(msg.sender, trades[tradeId].s_address, trades[tradeId].price);
            nuts[msg.sender] += trades[tradeId].qty;
            trades[tradeId].b_address = msg.sender;
            trades[tradeId].sold = true;
            return true;
        } else if(trades[tradeId].itemId == 2){
            token.transferFrom(msg.sender, trades[tradeId].s_address, trades[tradeId].price);
            potions[msg.sender] += trades[tradeId].qty;
            trades[tradeId].b_address = msg.sender;
            trades[tradeId].sold = true;
            return true;
        } else {
            return false;
        }
    }

    function acceptFarmTrade(uint plot_index, uint farmTradeId) external returns(bool){
        token.transferFrom(msg.sender, farmtrades[farmTradeId].s_address, farmtrades[farmTradeId].price);
        farms[msg.sender][plot_index] = Farm(farmtrades[farmTradeId].size, 0); 
        farmtrades[farmTradeId].sold = true;
        return true;
    }

    function getTrade(uint tradeId)external view returns(Trade memory){
        return trades[tradeId];
    }

    function getFarmTrade(uint farmTradeId)external view returns(FarmTrade memory){
        return farmtrades[farmTradeId];
    }
    //adding back assets to seller remains
    function cancelTrade(uint tradeId)external returns(bool){
        require(trades[tradeId].s_address == msg.sender, "Not authorized to cancel this trade.");
        require(trades[tradeId].sold == false, "Item(s) already sold.");
        if(trades[tradeId].itemId == 0) {
            saps[msg.sender] += trades[tradeId].qty;
        } else if(trades[tradeId].itemId == 1){
            nuts[msg.sender] += trades[tradeId].qty;
        } else if(trades[tradeId].itemId == 2){
            potions[msg.sender] += trades[tradeId].qty;
        } else {
            return false;
        }
        trades[tradeId].cancelled = true;
        return true;
    }
    function cancelFarmTrade(uint farmTradeId)external returns(bool){
        require(farmtrades[farmTradeId].s_address == msg.sender, "Not authorized to cancel this trade.");
        require(farmtrades[farmTradeId].sold == false, "Farm already sold.");
        farms[msg.sender][farmtrades[farmTradeId].plot_index].size = farmtrades[farmTradeId].size;
        farmtrades[farmTradeId].cancelled = true;
        return true;
    }

    // additional functions
    function noOfTrades()external view returns(uint){
        return _tradeId.current();
    }
    function noOfFarmTrades()external view returns(uint){
        return _farmTradeId.current();
    }

    function formNut()external returns(bool){
        require(saps[msg.sender] >= 2 && potions[msg.sender] >= 3, "Not enough resources.");
        saps[msg.sender] -= 2;
        potions[msg.sender] -= 3;
        nuts[msg.sender] += 1;
        return true;
    }

    function plantNut(uint farmId)external returns(bool){
        require(farmId < 10 && nuts[msg.sender] > 0, "Invalid request");
        require(farms[msg.sender][farmId].planted < (farms[msg.sender][farmId].size ** 2), "Maximum occupancy.");
        nuts[msg.sender] -= 1;
        trees[msg.sender] += 1;
        farms[msg.sender][farmId].planted += 1;
        return true;
    }

    function harvestTree(uint farmId) external returns(bool){
        require(farms[msg.sender][farmId].planted > 0, "No trees planted.");
        farms[msg.sender][farmId].planted -= 1;
        trees[msg.sender] += 1;
        return true;
    }

    function extractTree() external returns(bool) {
        require(trees[msg.sender] > 0, "Cannot extract.");
        uint ret1 = random();
        uint ret2 = random2();
        saps[msg.sender] += ret1;
        potions[msg.sender] += ret2;
        trees[msg.sender] -= 1;
        return true;
    }

    function editRates(uint _tree, uint _sap, uint _nut, uint _potion, uint _farm) external returns(bool){
        require(msg.sender == owner, "Only owner can call this function.");
        tree = _tree * (10**18);
        sap = _sap * (10**18);
        nut = _nut * (10**18);
        potion = _potion * (10**18);
        farm = _farm * (10**18);
        return true;
    }

    
}
