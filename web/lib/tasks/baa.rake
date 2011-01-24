desc "BAA"
task :baa => :environment do
  require "config/environment"
  Tree.delete_all
  
  Tree.new(:name => "root", :children => [
    Tree.new(:name => "Авто", :children => [
      Tree.new(:name => "Легковые", :tags => {"show_prices_after"=>true, "show_cities_after" => true}, :children => [
        Tree.new(:name => "BMW"),
        Tree.new(:name => "Audi"),
        Tree.new(:name => "Mers")
      ]),
      Tree.new(:name => "Грузовые"),
      Tree.new(:name => "Сельхоз"),
      Tree.new(:name => "Запчасти")
    ]),
    Tree.new(:name => "Сельхоз"),
    Tree.new(:name => "Недвижимость"),
    Tree.new(:name => "Услуги"),
    Tree.new(:name => "Животные")
  ]).save

  adv = Adv.new;
  adv.phone = "1"
  adv.content = "2"
  adv.node_id = "3"
  adv.save
end

