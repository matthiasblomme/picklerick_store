-- S_ITEMSCANS
CREATE STREAM S_ITEMSCANS (CUSTOMERID STRING, ITEMID STRING, SCANTIMESTAMP STRING, STOREID STRING, VISITID STRING)
	WITH (KAFKA_TOPIC='item_scans', KEY_FORMAT='KAFKA', VALUE_FORMAT='JSON');

-- S_PROMOTIONS
CREATE OR REPLACE STREAM S_PROMOTIONS (ITEMID STRING, ITEMNAME STRING, ITEMCATEGORY STRING, PROMOTION STRING, VALIDFROM STRING, VALIDTO STRING)
	WITH (KAFKA_TOPIC='promotions', KEY_FORMAT='KAFKA', VALUE_FORMAT='JSON');

-- S_CUSTOMER_TRACKING
CREATE STREAM S_CUSTOMER_TRACKING (CUSTOMERID STRING, LOCATIONID STRING, STOREID STRING, TRACKINGTIMESTAMP STRING, VISITID STRING)
	WITH (KAFKA_TOPIC='customer_tracking', KEY_FORMAT='KAFKA', VALUE_FORMAT='JSON');

-- S_PURCHASES
CREATE STREAM S_PURCHASES (CUSTOMERID STRING, PURCHASETIMESTAMP STRING, STOREID STRING, VISITID STRING)
	WITH (KAFKA_TOPIC='purchases', KEY_FORMAT='KAFKA', VALUE_FORMAT='JSON');

-- S_PAIRINGS
CREATE STREAM S_PAIRINGS (ITEMID STRING, ITEMNAME STRING, ITEMCATEGORY STRING, PAIRINGID STRING, PAIRINGNAME STRING, PAIRINGCATEGORY STRING)
	WITH (KAFKA_TOPIC='pairings', KEY_FORMAT='KAFKA', VALUE_FORMAT='JSON');

-- S_PROMO_OFFER
CREATE OR REPLACE STREAM S_PROMO_OFFER WITH (KAFKA_TOPIC='st_promo_offer', PARTITIONS=1, REPLICAS=3, VALUE_FORMAT='JSON') AS SELECT *
	FROM S_CUSTOMER_TRACKING CT
	INNER JOIN S_PROMOTIONS P WITHIN 3 DAYS ON ((P.ITEMCATEGORY = CT.LOCATIONID))
	EMIT CHANGES;

-- S_SCAN_ITEM_DETAILS
CREATE STREAM S_SCAN_ITEM_DETAILS WITH (KAFKA_TOPIC='st_scan_item_details', PARTITIONS=1, REPLICAS=3, VALUE_FORMAT='JSON') AS SELECT IT.*
	FROM S_ITEMSCANS ISC
	INNER JOIN T_ITEMS IT ON ((ISC.ITEMID = IT.ITEMID))
	EMIT CHANGES;


-- S_BILL
CREATE OR REPLACE STREAM S_BILL WITH (KAFKA_TOPIC='st_bill', PARTITIONS=1, REPLICAS=3) AS SELECT
		P.CUSTOMERID P_CUSTOMERID,
		P.VISITID P_VISITID,
		P.STOREID P_STOREID,
		IT.ITEMID IT_ITEMID,
		IT.ITEMNAME ITEMNAME,
		IT.UNITPRICE UNITPRICE
	FROM S_PURCHASES P
	INNER JOIN S_ITEMSCANS ISC WITHIN 1 DAYS ON ((P.VISITID = ISC.VISITID))
	INNER JOIN T_ITEMS IT ON ((ISC.ITEMID = IT.ITEMID))
	EMIT CHANGES;


-- S_PAIRING_SUGGESTIONS
CREATE STREAM S_PAIRING_SUGGESTIONS WITH (KAFKA_TOPIC='st_pairing_suggestions', PARTITIONS=1, REPLICAS=3) AS SELECT *
	FROM S_ITEMSCANS ISC
	INNER JOIN S_PAIRINGS PA WITHIN 1 DAYS ON ((ISC.ITEMID = PA.ITEMID))
	EMIT CHANGES;

-- T_ITEMS
CREATE TABLE T_ITEMS (ITEMID STRING PRIMARY KEY, ITEMNAME STRING, ITEMCATEGORY STRING, UNITPRICE DOUBLE)
	WITH (KAFKA_TOPIC='items', KEY_FORMAT='JSON', VALUE_FORMAT='JSON');



- Schemas

--customer_tracking
{
  "$id": "CustomerTrackingV1.json",
  "$schema": "http://json-schema.org/customerTracking/v1/schema#",
  "additionalProperties": false,
  "description": "Schema for the item topic that desribes an item that can be purchased from the store.",
  "properties": {
    "customerId": {
      "description": "The id of the customer whose location is being tracked.",
      "type": "string"
    },
    "locationId": {
      "description": "Id of the location tracked as a string in ISO 8601 format.",
      "type": "string"
    },
    "storeId": {
      "description": "Id of the store where the customer location is being tracked.",
      "type": "string"
    },
    "trackingTimestamp": {
      "description": "Timestamp of the customer location tracking.",
      "type": "string"
    },
    "visitId": {
      "description": "Id of the customer visit to the store, in which the item has been scanned.",
      "type": "string"
    }
  },
  "title": "CustomerTracking",
  "type": "object"
}


-- item_scans
{
  "$id": "ItemScansV1.json",
  "$schema": "http://json-schema.org/itemScans/v1/schema#",
  "additionalProperties": false,
  "description": "Schema for the item_scans topic that desribes an item scan from a customer.",
  "properties": {
    "customerId": {
      "description": "The id of the customer who scans the item.",
      "type": "string"
    },
    "itemId": {
      "description": "Id of the scanned item.",
      "type": "string"
    },
    "scanTimestamp": {
      "description": "Timestamp of the scan event as a string in ISO 8601 format.",
      "type": "string"
    },
    "storeId": {
      "description": "Id of the store where the customer scanned the store.",
      "type": "string"
    },
    "visitId": {
      "description": "Id of the customer visit to the store, in which the item has been scanned.",
      "type": "string"
    }
  },
  "title": "ItemScans",
  "type": "object"
}

-- items
{
  "$id": "ItemsV1.json",
  "$schema": "http://json-schema.org/items/v1/schema#",
  "additionalProperties": false,
  "description": "Schema for the item topic that desribes an item that can be purchased from the store.",
  "properties": {
    "itemCategory": {
      "description": "Category of the item, like drinks, fruit, vegetables, frozen food...",
      "type": "string"
    },
    "itemId": {
      "description": "Id of the item.",
      "type": "string"
    },
    "itemName": {
      "description": "Short name of the item.",
      "type": "string"
    },
    "unitPrice": {
      "description": "Price of each unit of the item in €.",
      "type": "number"
    }
  },
  "title": "Items",
  "type": "object"
}


--purchases
{
  "$id": "PurchasesV1.json",
  "$schema": "http://json-schema.org/purchases/v1/schema#",
  "additionalProperties": false,
  "description": "Schema for the purchases topic that describes the purchase event.",
  "properties": {
    "customerId": {
      "description": "The id of the customer purchasing.",
      "type": "string"
    },
    "purchaseTimestamp": {
      "description": "Timestamp of the purchase event as a string in ISO 8601 format.",
      "type": "string"
    },
    "storeId": {
      "description": "Id of the store where the customer is buying.",
      "type": "string"
    },
    "visitId": {
      "description": "Id of the customer visit to the store, in which the item has been purchased.",
      "type": "string"
    }
  },
  "title": "Purchases",
  "type": "object"
}