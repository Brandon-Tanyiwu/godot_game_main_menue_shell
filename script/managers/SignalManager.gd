extends Node
#通知背包增加物品
signal request_add_item(item:ItemData,amount:int,extra:Dictionary)
#通知物品丢弃
signal item_overflowed(item:ItemData,amount:int,extra:Dictionary)
