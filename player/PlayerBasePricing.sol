pragma solidity 0.4.25;

/**
 * @title PlayerBasePricing
 * @dev Implements tier based base pricing for players
 */
contract PlayerBasePricing {
    PlayerBase playerBase;

    mapping(bytes1 => uint) tierPricing;

    /**
     * @dev Check if a tier is valid; Can be one of G, S, B
     * @param _tier - Tier of the respective Player
     **/
    modifier isValidTier(bytes1 _tier) {
        require(_tier==0x47 || _tier==0x53 || _tier==42); // G - 0x47, S - 0x53, B - 0x42
        _;
    }

    /**
     * @dev Set a Base Price for a particular tier of players
     * @param _tier - Tier of the players group
     * @param _price - Base Price to be set
     **/
    function _setBasePrice(bytes1 _tier, uint _price) isValidTier(_tier) internal returns(bool) {
        tierPricing[_tier] = _price;
        return true;
    }
}