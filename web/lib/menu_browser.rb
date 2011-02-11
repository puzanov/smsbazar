class MenuBrowser
  attr_accessor :menu_manager, :io, :session_tracker
  def process_action phone, message, pdu
    if message == "0"
      @session_tracker.delete_session(phone)
    end
    
    session = @session_tracker.get_session phone.to_s
    
    if session == nil
      items = Array.new
      items << "1 - Купить"
      items << "2 - Продать"
      @io.send(phone, items, pdu)
      sms_session = SmsSession.new
      @session_tracker.save_session(phone, sms_session) # empty session
      return

    else
      if session.node_id.nil?
        menu_item = @menu_manager.get_root
        @io.send(phone, menu_item.menu_text_items, pdu)
        sms_session = SmsSession.new
        sms_session.browse_type = message
        sms_session.node_id = menu_item.node.id.to_s
        @session_tracker.save_session(phone, sms_session)
        return
      end

      node_id = session.node_id
      node = @menu_manager.get_node node_id
      menu_item = @menu_manager.get_menu_by_item_number node, message.to_i
      puts menu_item.node.inspect
      if menu_item.node.leaf?
        
        if session.browse_type == "1"
          advs = @menu_manager.get_advs menu_item.node
          advs.each do |adv|
            @io.send(phone, "#{adv.content}. Телефон #{adv.phone}", pdu)
          end
        else
          if session.put_adv
            puts "put adv"
            
            adv = Adv.new
            adv.phone = phone
            adv.content = message
            adv.node_id = session.node_id
            adv.save
            @io.send(phone, "Спасибо! Ваше объявление сохранено и доступно для поиска", pdu)
            @session_tracker.delete_session phone
          else
            @io.send(phone, "Отправьте ваше объявление! Укажите цену и город", pdu)
            session.put_adv = true
            session.node_id = menu_item.node.id.to_s
            @session_tracker.save_session(phone, session)
          end

          return
        end
      
      else
        @io.send(phone, menu_item.menu_text_items, pdu)
      end
    end
    session.node_id = menu_item.node.id.to_s
    @session_tracker.save_session(phone, session)
  end
end
