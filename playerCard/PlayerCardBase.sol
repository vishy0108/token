pragma solidity 0.4.25;

import "./Governable.sol";
import "./Constants.sol";
import "./PlayerBasePricing.sol";

/**
 * @title PlayerCardBase Contract
 * @dev Implements functions and other validations required before creating a PlayerCard
 */
contract PlayerCardBase is Governable, Constants, PlayerBasePricing {
    using SafeMath for uint;

    struct PlayerCard {
        uint[3] playerIds;

        mapping(uint => uint) playerCombinations;
    }

    PlayerCard[] playerCards; // Central DB of player cards

    mapping(bytes32 => uint) playerNameBasedMapping;

    mapping(bytes4 => mapping(uint => bool)) playerCompositions;

    constructor() public {
        playerBase = PlayerBase(playerBaseAddress);
    }

    /**
     * @dev Set Base Price of all the three tiers
     * @param _tiers - Tiers of the players
     * @param _prices - Base Prices to be set in the order
     **/
    function setBasePrice(bytes1[3] _tiers, uint[3] _prices) public {
        for(uint i=0; i<3; i++) {
            _setBasePrice(_tiers[i], _prices[i]);
        }
    }

    /**
     * @dev Calc. base price for a playerCard
     * @param _playerIds - IDs of the players involved in forming a playerCard
     * @return basePrice - Returns a composite base price as uint
     **/
    function _calcPlayerCardBasePrice(uint[3] _playerIds) internal view returns(uint) {
        uint basePrice = 0;
        for(uint i=0; i<3; i++) {
            bytes1 playerTier;
            bytes32 name;
            (name, playerTier) = playerBase.getPlayer(_playerIds[i]);
            basePrice = basePrice.add(tierPricing[playerTier]);
        }
        return basePrice;
    }

    /**
     * @dev Check if a playerCardExists based on tokenId
     **/
    function playerCardExists(uint _playerCardId) public view returns(bool) {
        return (_playerCardId < playerCards.length);
    }

    /**
     * @dev Expensive function - For viewing only
     * @notice Get all the attributes of a playerCard
     **/
    function getPlayerCard(uint _cardId)
        external
        view
        returns(bytes32 player1_name, uint player1_pct, bytes32 player2_name, uint player2_pct, bytes32 player3_name, uint player3_pct)
        {
        // Fetch the card first
        PlayerCard storage _playerCard = playerCards[_cardId];

        // Return the playercard returned here
        uint player1_id = _playerCard.playerIds[0];
        uint player2_id = _playerCard.playerIds[1];
        uint player3_id = _playerCard.playerIds[2];

        bytes1 player1_tier;
        bytes1 player2_tier;
        bytes1 player3_tier;

        (player1_name, player1_tier) = playerBase.getPlayer(player1_id);
        player1_pct = _playerCard.playerCombinations[player1_id];

        (player2_name, player2_tier) = playerBase.getPlayer(player2_id);
        player2_pct = _playerCard.playerCombinations[player2_id];

        (player3_name, player3_tier) = playerBase.getPlayer(player3_id);
        player3_pct = _playerCard.playerCombinations[player3_id];
    }

    /**
     * @dev Check if all the player compositions total upto 100
     **/
    function checkCompositions(uint256[3] _compositions) internal pure returns(bool) {
        uint sum = 0;
        for (uint i = 0; i < 3; i++) {
            // Require SafeMath as this is a user input based fn
            sum += _compositions[i];
        }
        return (sum == 100);
    }

    /**
     * @dev Implements a validation before creating a PlayerCard from playerIds
     **/
    function checkPlayers(uint[3] _playerIds) internal view returns(bool) {
        // Extract IDs and stores playerUids, playerComps per sort order
        for (uint i = 0; i < 3; i++) {
            playerBase.playerExists(_playerIds[i]);
        }
    }

    mapping(uint => uint) _playerCompstn;

    /**
     * @dev Check if the players requested with paricular combination exists
     * @return compositeId - compositeId for the playerCard; Useful to check playerCard combinations through a mapping
     * @return compositeNum - Stored in the playerCard Combinations mapping
     **/
    function checkPlayerCombinations(uint[3] _playerIds, uint256[3] _compositions) internal returns(bytes4 compositeId, uint256 compositeNumber) {
        // PlayerCompositions if say 20, 30, 40 then the compositeNumber shall be combination of three in some order say 203040
        // Ordering shall be determined by sorting player Ids
        // For e.g., if PlayerCard is composed of Virat Kohli, Jasprit Bumrah, MS Dhoni with playerIds 18, 93, 7
        // with compositions 50, 20, 30
        // The players shall first be sorted per playerIds 7(MS Dhoni), 18(Virat Kohli), 93(Jasprit Bumrah)
        // The compositeNumber shall now be 305020
        // uid shall also be based on the sorted order
        // uid - bytes4(keccak256(<playerNames in sorted order>)

        for (uint i = 0; i < 3; i++) {
            _playerCompstn[_playerIds[i]] = _compositions[i];
        }

        // Easy to sort a tuple than an array
        (uint a, uint b, uint c) = (_playerIds[0], _playerIds[1], _playerIds[2]);

        if (a > c) {
            (a, b, c) = (c, b, a);
        }

        if (a > b) {
            (a, b, c) = (b, a, c);
        }

        if (b > c) {
            (a, b, c) = (a, c, b);
        }

        (bytes32 playera_name, ) = playerBase.getPlayer(a);
        (bytes32 playerb_name, ) = playerBase.getPlayer(b);
        (bytes32 playerc_name, ) = playerBase.getPlayer(c);

        // CompositeID based on Sort Order
        compositeId = bytes4(keccak256(abi.encodePacked(playera_name, playerb_name, playerc_name)));

        // Composite Number based on Sort Order
        compositeNumber = _playerCompstn[a] * 100 + _playerCompstn[b] * 10 + _playerCompstn[c];
        return (compositeId, compositeNumber);
    }

    /**
     * @dev Check if a compositeId and compositeNumber combination already exists
     **/
    function compositionValidator(bytes4 _comp, uint256 _compNum) internal view returns(bool) {
        return (playerCompositions[_comp][_compNum]);
    }

    /**
     * @dev Mathod for creating a PlayerCard
     * Steps Involved:
     *                  Check if the players with the id exists
     *                  Calc. min price for the playerCard based on the input and see if the amount sent satisfies requirement
     *                  Generate a compositeId and compositeNumber based on the playerIds and pcts
     *                  Check if the playerCardCombination with the compositeId and compositeNumber already exists
     *                  If it doesn't, create a new playerCard
     *                  Store the combinations in mapping to prevent replicas of the same
     * @return cardId - Newly generated token ID of the playerCard
     **/
    function _createPlayerCard(uint[3] _playerIds, uint[3] _pcts) internal returns (uint) {
        bytes4 compositeId;
        uint256 compositeNumber;

        assert(checkPlayers(_playerIds));

        assert(msg.value >= _calcPlayerCardBasePrice(_playerIds));

        (compositeId, compositeNumber) = checkPlayerCombinations(_playerIds, _pcts);

        assert(compositionValidator(compositeId, compositeNumber));

        playerCompositions[compositeId][compositeNumber] = true;

        PlayerCard memory _cardInstance = PlayerCard({
             playerIds: _playerIds
        });

        uint cardId = playerCards.push(_cardInstance) - 1;

        for(uint i=0; i<3; i++) {
            playerCards[cardId].playerCombinations[_playerIds[i]] = _pcts[i];
        }

        return cardId;
    }
}