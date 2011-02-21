class MenuBrowser
  attr_accessor :menu_manager, :io, :session_tracker
  
  def process_action(phone, message, pdu)
    self.delete_session_if_needed(phone, message)
    session = @session_tracker.get_session phone.to_s
    
    if session == nil
      self.show_first_menu(phone, message, pdu)
      return
    end
    
    if session.node_id.nil?
      self.show_first_catalogue_menu(phone, message, pdu)
      return
    end

    unless session.browse_adv == true # дергаем каталог только тогда когда, когда не получаем сами объявления
      node_id = session.node_id
      node = @menu_manager.get_node node_id
      menu_item = @menu_manager.get_menu_by_item_number(node, message.to_i)
    end
    
    unless menu_item.nil?
    unless menu_item.node.leaf? # если это не лист каталога то посылаем меню пользователю
      @io.send(phone, menu_item.menu_text_items, pdu)
      session.node_id = menu_item.node.id.to_s
      @session_tracker.save_session(phone, session)
      return
    end
    end
    
    unless session.browse_adv
      if session.browse_type == "1" && menu_item.node.leaf?
        session.browse_adv = true
      end
    end

    # купить
    if session.browse_adv == true
      session.adv_position = 0 if session.adv_position.nil?
      if session.adv_position == 0
        limit = 1
        node_id = menu_item.node.id.to_s
        session.node_id = node_id
      else
        limit = message.to_i
        node_id = session.node_id
      end
      advs = @menu_manager.get_one_adv(session.node_id, session.adv_position, limit)
      adv_exists = 0
      advs.each do |adv|
        adv_exists = 1
        @io.send(phone, "#{adv.content}. Телефон #{adv.phone}", pdu)
      end
      session.adv_position = session.adv_position + limit
      if adv_exists == 0
        @io.send(phone, "Объявлений нет. Пошлите 0 и вернетесь в начало", pdu)
      end
      @session_tracker.save_session(phone, session)
      return
    end        

    # продать
    if session.put_adv
      self.save_adv(phone, message, session.node_id)
      @io.send(phone, "Спасибо! Ваше объявление сохранено и доступно для поиска", pdu)
      @session_tracker.delete_session phone
    else
      @io.send(phone, "Отправьте ваше объявление! Укажите цену и город", pdu)
      session.put_adv = true
      session.node_id = menu_item.node.id.to_s
      @session_tracker.save_session(phone, session)
    end
  end

  def save_adv(phone, message, node_id)
    adv = Adv.new
    adv.phone = phone
    adv.content = message
    adv.node_id = session.node_id
    adv.ctime = Time.new.to_i
    adv.save
  end

  def delete_session_if_needed(phone, message)
    if message == "0"
      @session_tracker.delete_session(phone)
    end
  end

  def show_first_menu(phone, message, pdu)
    items = Array.new
    items << "1 - Купить"
    items << "2 - Продать"
    @io.send(phone, items, pdu)
    sms_session = SmsSession.new
    @session_tracker.save_session(phone, sms_session) # empty session
  end

  def show_first_catalogue_menu(phone, message, pdu)
    menu_item = @menu_manager.get_root
    @io.send(phone, menu_item.menu_text_items, pdu)
    sms_session = SmsSession.new
    sms_session.browse_type = message
    sms_session.node_id = menu_item.node.id.to_s
    @session_tracker.save_session(phone, sms_session)
  end
end
