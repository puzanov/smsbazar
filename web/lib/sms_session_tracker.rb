class SmsSessionTracker
  def get_node_id phone
    return SmsSession.first(:conditions => { :phone => phone })
  end
  def save_session phone, node_id
    session = SmsSession.new
    session.phone = phone
    session.node_id = node_id
    session.date_modified = 
    session.save
  end
end

class SmsSession
  filed :node_id, :type=>String
end

