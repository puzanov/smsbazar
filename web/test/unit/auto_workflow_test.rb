require 'test/unit'
require 'yaml'
require 'rubygems'
require 'workflow'

class SmsWorkflow
  include Workflow
  def need_language
    puts "Choose language"
    puts "1 - kg"
    puts "2 - ru"
  end

  def sell_or_buy
    puts "Хотите купить или продать?"
    puts "1 - купить"    
    puts "2 - продать"
  end

  def buy
    puts "1 - Авто"
    puts "2 - Недвижимость"
    puts "3 - Сельхоз"
    puts "4 - Услуги"
  end

  workflow do
    state :init do
      event :need_language, :transition_to => :language_menu
    end
    
    state :language_menu do
      event :sell_or_buy, :transitions_to => :sell_or_buy_menu
    end

    state :sell_or_buy_menu do
      event :buy, :transition_to => :buy_menu
      event :sell, :transition_to => :sell_menu
    end
    
    state :buy_menu do
      event :auto, :transition_to => :auto_menu
    end

    state :auto_menu do
      event :cars, :transition_to => :cars_prices_menu
    end

    state :cars_prices_menu do
      event :cars_prices, :transition_to => :cars_cities_menu
    end

    state :cars_cities_menu do
      event :cars_cities, :transition_to => :cars_models_menu
    end

    state :cars_models_menu do
      event :show_cars_models, :transition_to => :cars_list
    end

    state :cars_list
    
    on_transition do |from, to, triggering_event, *event_args|
      puts "#{from} -> #{to}"
    end
  end
end

class AutoWorkflowTest < Test::Unit::TestCase 
  def test_workflow
    w = SmsWorkflow.new
    w.need_language!
    lang = gets.chomp
    
    w.sell_or_buy!
    sb = gets.chomp
    if sb != "1"
      return
    end

    w.buy!
    b = gets.chomp
    if b != "1"
      return
    end

    w.auto!
    w.cars!
    w.cars_prices!
    w.cars_cities!
    w.show_cars_models!
  end
end
