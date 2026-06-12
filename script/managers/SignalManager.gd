extends Node
#通知背包增加物品
signal request_add_item(target:String,item_id,amount:int,extra:Dictionary)
#通知物品丢弃
signal item_overflowed(item:ItemData,amount:int,extra:Dictionary)

signal refresh_inventory_ui(type)

signal map_generation_completed(world_cells:Dictionary)

signal hex_cell_clicked(coord:Vector2,cell_data:Dictionary)
