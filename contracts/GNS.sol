pragma solidity ^0.4.25;

contract GNS {
    
    struct Record{
        uint8 typeOfRecord;
        bytes body;
    }
    
    Record[] private _records;
    mapping (address => uint128[]) private _recordIdsForOwner;
    mapping (string => address) private _ownerOfName;
    mapping (address => string) private _namesOfOwner;
    
    modifier onlyOwnerOfName(string _name) {
        address owner = _ownerOfName[_name];
        require(owner == 0 || owner == msg.sender);
        _;
    }
    
    function isValidName(string _name) pure public returns(bool) {
        bytes memory nameInByteArray = bytes(_name);
        for(uint128 i=0; i<nameInByteArray.length; i++)
            if(nameInByteArray[i] == '.')
                return false;
        return true;
    }
    
    function isValidString(bytes _str) pure public returns(bool) {
        bytes memory strInByteArray = bytes(_str);
        for(uint128 i=0; i<strInByteArray.length; i++)
            if(strInByteArray[i] == 0)
                return false;
        return true;
    }
    
    function bytesToUint32LE(bytes _what) pure public returns(uint32) {
        require(_what.length >= 4);
        return uint32(_what[0]) | (uint32(_what[1])<<8) | (uint32(_what[2])<<16) | (uint32(_what[3])<<24);
    }
    
    function isValidFDNSRecord(uint8 _type, bytes _recorBody) pure public returns(bool) {
        if(_type != 0)
            return false;
        if(_recorBody.length < 4)
            return false;
        // if(_recorBody.length >= uint32(0)-1)
        //     return false;
        if(uint32(_recorBody.length - 4) != bytesToUint32LE(_recorBody))
            return false;
        return true;
    }
    
    function isValidIPv4Record(uint8 _type, bytes _recorBody) pure public returns(bool) {
        if(_type != 1)
            return false;
        if(_recorBody.length != 4)
            return false;
        return true;
    }
    
    function isValidIPv6Record(uint8 _type, bytes _recorBody) pure public returns(bool) {
        if(_type != 2)
            return false;
        if(_recorBody.length != 16)
            return false;
        return true;
    }
    
    function isValidDNSRecord(uint8 _type, bytes _recorBody) pure public returns(bool) {
        if(_type != 3)
            return false;
        if(!isValidString(_recorBody))
            return false;
        return true;
    }
    
    /**
     * If type of protocol not in range for custom or not unknow type, the  function the return false
     */
    function isValidRecord(uint8 _type, bytes _recorBody) pure public returns(bool) {
        if(_recorBody.length == 0)
            return false;
        if(_type >= 64 && _type <= 255)
            return true;
        if(_type == 0)
            return isValidFDNSRecord(_type, _recorBody);
        else if(_type == 1)
            return isValidIPv4Record(_type, _recorBody);
        else if(_type == 2)
            return isValidIPv6Record(_type, _recorBody);
        else if(_type == 3)
            return isValidDNSRecord(_type, _recorBody);
        return false;
    }
    
    function getOwnerForName(string _name) view public returns(address) {
        return _ownerOfName[_name];
    }
    

    function createRecord(
            string _name, 
            uint8 _type, 
            bytes _recorBody) 
            onlyOwnerOfName(_name)
            public {
        Record memory record = Record(_type, _recorBody);
        uint128 recordIndex = uint128(_records.push(record)-1);
        _recordIdsForOwner[msg.sender].push(recordIndex) ;
    }
    
    function removeRecordByIndex(uint128 _recordIndex) public {
        uint128[] storage recordIdsForOwner = _recordIdsForOwner[msg.sender];
        bool found=false;
        for(uint128 i=0;i<recordIdsForOwner.length;i++) {
            if(found)
                recordIdsForOwner[i-1] = recordIdsForOwner[i];
            else if(recordIdsForOwner[i] == _recordIndex){
                found = true;
            }
        }
        recordIdsForOwner.length--;
    }
    
    
    //--------------------------------------------------------------------
    function stringToHexHelper(string what) pure public returns(bytes) {
        return bytes(what);
    }
}
