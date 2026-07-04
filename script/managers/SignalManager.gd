extends Node

#通知背包增加物品
signal request_add_item(target:String,item_id,amount:int,extra:Dictionary)
#通知物品丢弃
signal item_overflowed(item:ItemData,amount:int,extra:Dictionary)

signal refresh_inventory_ui(type)

signal map_generation_completed(world_cells:Dictionary)

signal hex_cell_clicked(path_data:Dictionary,terrain_layer:TileMapLayer)

signal request_reveal_fog(center_coord:Vector2i,radius:int)

signal player_info_change()

signal ui_item_clicked()

signal ui_skill_clicked()

signal ui_page_tab_clicked()

signal unit_selected()

signal unit_deselected()

signal tile_inspected()

signal move_completed(hex_coord:Vector2i,unit:Node)

signal npc_turn()
