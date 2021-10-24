// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import "./libraries/Base64.sol";

contract MyEpicGame is ERC721 {
    struct ItemAttributes {
        uint256 itemIndex;
        string name;
        string imageURI;
        uint256 uses;
        uint256 maxUses;
        uint256 power;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    ItemAttributes[] defaultItems;

    mapping(uint256 => ItemAttributes) public nftHolderAttributes;
    mapping(address => uint256) public nftHolders;

    struct Patient {
        string name;
        string imageURI;
        uint256 hp;
        uint256 maxHp;
        uint256 illnessDamage;
    }

    Patient public patient;

    // Data passed in to the contract when it's first created initializing the characters.
    // We're going to actually pass these values in from from run.js.
    constructor(
        string[] memory _names,
        uint256[] memory _uses,
        uint256[] memory _power,
        string[] memory _imageURIs,
        string memory patientName, // These new variables would be passed in via run.js or deploy.js.
        string memory patientImageURI,
        uint256 patientMaxHp,
        uint256 patientIllnessDamage
    ) ERC721("Health Tools", "MEDS") {
        patient = Patient({
            name: patientName,
            imageURI: patientImageURI,
            hp: patientMaxHp / 2,
            maxHp: patientMaxHp,
            illnessDamage: patientIllnessDamage
        });

        console.log(
            "Done initializing patient %s w/ max HP %s, img %s",
            patient.name,
            patient.maxHp,
            patient.imageURI
        );

        // Loop through all the characters, and save their values in our contract so
        // we can use them later when we mint our NFTs.
        for (uint256 i = 0; i < _names.length; i += 1) {
            defaultItems.push(
                ItemAttributes({
                    itemIndex: i,
                    name: _names[i],
                    imageURI: _imageURIs[i],
                    uses: _uses[i],
                    maxUses: _uses[i],
                    power: _power[i]
                })
            );

            ItemAttributes memory c = defaultItems[i];
            console.log(
                "Done initializing %s w/ uses %s, img %s",
                c.name,
                c.uses,
                c.imageURI
            );
        }

        _tokenIds.increment();
    }

    function mintItem(uint256 _itemIndex) external {
        uint256 newItemId = _tokenIds.current();
        console.log("Token ID in blockchain: ", newItemId);
        _safeMint(msg.sender, newItemId);

        nftHolderAttributes[newItemId] = ItemAttributes({
            itemIndex: _itemIndex,
            name: defaultItems[_itemIndex].name,
            uses: defaultItems[_itemIndex].uses,
            maxUses: defaultItems[_itemIndex].uses,
            power: defaultItems[_itemIndex].power,
            imageURI: defaultItems[_itemIndex].imageURI
        });

        console.log(
            "Minted NFT w/ tokenId %s and itemIndex %s",
            newItemId,
            _itemIndex
        );
        nftHolders[msg.sender] = newItemId;

        _tokenIds.increment();
    }

    function healPatient() public {
        uint256 playerItemTokenId = nftHolders[msg.sender];
        
        require(playerItemTokenId != 0, "You must have some medical equipment!");

        ItemAttributes storage playerItem = nftHolderAttributes[playerItemTokenId];

        require(
            playerItem.uses > 0,
            string(abi.encodePacked("Ew, you can't use this anymore."))
        );

        require(
            patient.hp < 100,
            string(abi.encodePacked("Good job, you've already ", patient.name, "'s case of illness."))
        );

        require(
            patient.hp != 0,
            string(abi.encodePacked("Oh dear, you didn't save ", patient.name, "!"))
        );

        console.log("Player is about to use their %s on the patient. Healing Power: %s", playerItem.name, playerItem.power);
        uint256 newHp = patient.hp;
        console.log("The %s heals %s by %s hp!", playerItem.name, patient.name, playerItem.power);
        newHp = newHp + playerItem.power;
        if (newHp < patient.illnessDamage) {
            newHp = 0;
            console.log("%s didn't make it.", patient.name);
        } else {
            newHp = newHp - patient.illnessDamage;
            console.log("%s's illness damaged them by %s hp!", patient.name, patient.illnessDamage);
        }
        patient.hp = newHp;

        console.log("%s's health is now %s/%s", patient.name, patient.hp, patient.maxHp);

        if (playerItem.uses == 1) {
            playerItem.uses = 0;
        } else {
            playerItem.uses = playerItem.uses - 1;
        }

        console.log ("%s uses Left: %s/%s", playerItem.name, playerItem.uses, playerItem.maxUses);  
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        ItemAttributes memory itemAttributes = nftHolderAttributes[_tokenId];

        string memory strUses = Strings.toString(itemAttributes.uses);
        string memory strMaxUses = Strings.toString(itemAttributes.maxUses);
        string memory strPower = Strings.toString(itemAttributes.power);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        itemAttributes.name,
                        " -- NFT #: ",
                        Strings.toString(_tokenId),
                        '", "description": "This is an NFT that lets people play in the game Doctor Stuff!", "image": "',
                        itemAttributes.imageURI,
                        '", "attributes": [ { "trait_type": "Uses", "value": ',
                        strUses,
                        ', "max_value":',
                        strMaxUses,
                        '}, { "trait_type": "Power", "value": ',
                        strPower,
                        "} ]}"
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }
}
