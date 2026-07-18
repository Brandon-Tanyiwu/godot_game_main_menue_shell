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

signal unit_death()

signal npc_turn()

signal map_cal_completed()

signal cell_event_action()

signal npc_generation_completed(spawn_list:Array)

# ================== 新增信号 ==================
# 当在地图目标单位上释放/拖放道具时触发
signal use_item_on_unit(user: Node, target: Node, item_data: Dictionary)
# 当在地图目标单位上释放技能时触发
signal use_skill_on_unit(user: Node, target: Node, skill_data: Dictionary)
# 当玩家触发对特定单位的攻击时触发
signal player_attack_triggered(attacker: Node, target: Node)
