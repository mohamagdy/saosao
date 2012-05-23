module ApplicationHelper
  # Helper that returns the menu item class
  # Params:
  #   item_controller_name: name of the item controller the menu item calls on following it
  #   item_action_name: name of the action the menu item calls on following it
  def menu_item_class(item_controller_name, item_action_name)
    item_controller_name == controller_name && action_name == item_action_name ? "active" : "not-active"
  end
end
