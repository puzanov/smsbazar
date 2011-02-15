module ApplicationHelper
  def format_phone_number phone_number
    regexp = /^996(\d{3})(\d{6})/is
    matches = regexp.match phone_number
    if matches
      return "0-#{matches[1]}-#{matches[2]}"
    end
  end

  def get_crumps node_id
    crumps = Array.new

    begin
      current_node = Tree.find node_id
    rescue
      return crumps
    end

    parents = current_node.parent_ids
    parents.each do |node_id|
      node = Tree.find node_id
      crumps << node  
    end
    crumps << current_node
    return crumps
  end
end
