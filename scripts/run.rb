require 'orocos'

Orocos.initialize

Orocos.run "auv_simulation" do 
    mars = Orocos::TaskContext.get "simulation"
    thrusters = Orocos::TaskContext.get "thrusters"
    
    Orocos.conf.load_dir(File.join(ENV['AUTOPROJ_PROJECT_BASE'],"tutorials", "orogen", "auv_simulation", "configuration"))
    Orocos.conf.apply(mars,['default'])
    Orocos.conf.apply(thrusters,['default'])

    #Warning, Mars have to be started at first!
    mars.configure
    mars.start

    thrusters.configure
    thrusters.start

    loop do
        sleep 1
    end
end
