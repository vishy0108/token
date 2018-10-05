pragma solidity 0.4.25;

/**
 * @title PlayerBase
 * @dev Interface of ERC721 PlayerBase Contract
 */
interface PlayerBase {

    /**
     * @notice Get Player from playerId
     * @param _playerId - Token ID of the player
     * @return _name - Name of the player
     * @return _tier - Tier of the player; Determines Base Price
     **/
    function getPlayer(uint _playerId) external view returns(bytes32 _name, bytes1 _tier);

    /**
     * @notice Check if a playerExists using token id
     * @param _playerId - Token ID of the player
     **/
    function playerExists(uint _playerId) external view returns(bool);
}