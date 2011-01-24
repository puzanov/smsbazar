desc "Generate tree"
task :tree => :environment do
  require "config/environment"
  Tree.delete_all

  t11 = Tree.new
  t11.name = "Авто"
  t11.save
    
    t211 = Tree.new
    t211.name = "Легковые"
    t211.parent = t11
    t211.save
      t2111 = Tree.new
      t2111.name = "BMW"
      t2111.parent = t211
      t2111.save
      
      t2112 = Tree.new
      t2112.name = "Mersedes"
      t2112.parent = t211
      t2112.save
    
    t212 = Tree.new
    t212.name = "Грузовые"
    t212.parent = t11
    t212.save

    t213 = Tree.new
    t213.name = "Сельхоз"
    t213.parent = t11
    t213.save

    t214 = Tree.new
    t214.name = "Запчасти"
    t214.parent = t11
    t214.save

  t12 = Tree.new
  t12.name = "Сельхоз"
  t12.save
  

end

