require 'orocos'
require 'vizkit'

Orocos.initialize

widget = Vizkit.load "simulator.ui"

Orocos.run "auv_simulation" do 
    mars = Orocos::TaskContext.get "simulation"
    thrusters = Orocos::TaskContext.get "thrusters"
    imu = Orocos::TaskContext.get "imu"
    sonar_top = Orocos::TaskContext.get "sonar_top"
    sonar_bottom = Orocos::TaskContext.get "sonar_bottom"
    camera_front = Orocos::TaskContext.get "camera_front"
    camera_bottom = Orocos::TaskContext.get "camera_bottom"
    world_to_aligned = Orocos::TaskContext.get "ctrl_wta"
    aligned_position_controller = Orocos::TaskContext.get "ctrl_apc"
    aligned_velocity_controller = Orocos::TaskContext.get "ctrl_avc"
    aligned_to_body = Orocos::TaskContext.get "ctrl_atb"
    acceleration_controller = Orocos::TaskContext.get "ctrl_acc"
    world_cmd_producer = Orocos::TaskContext.get "ctrl_world_cmd_producer"
    velocity_cmd_producer = Orocos::TaskContext.get "ctrl_velocity_cmd_producer"

   

    Orocos.conf.load_dir(File.join(ENV['AUTOPROJ_PROJECT_BASE'],"tutorials", "orogen", "auv_simulation", "configuration"))
    Orocos.conf.apply(mars,['default'])
    Orocos.conf.apply(thrusters,['default'])
    Orocos.conf.apply(imu,['default'])
    Orocos.conf.apply(sonar_top,['default'])
    Orocos.conf.apply(camera_front,['front_cam'])
    Orocos.conf.apply(camera_bottom,['bottom_cam'])
    Orocos.conf.apply(world_to_aligned,['default'])
    Orocos.conf.apply(aligned_position_controller,['default_aligned_position_simulation'])
    Orocos.conf.apply(aligned_velocity_controller,['default_aligned_velocity_simulation'])
    Orocos.conf.apply(aligned_to_body,['default'])
    Orocos.conf.apply(acceleration_controller,['default_simulation'])

    #Warning, Mars have to be started at first!
    mars.configure
    mars.start

    #Configure and start the simulated System
    thrusters.configure
    thrusters.start

    imu.configure
    imu.start

    sonar_top.node_name = "sonar_top_sensor"
    sonar_top.configure
    sonar_top.start

    #sonar_bottom.configure
    #sonar_bottom.start

    camera_front.configure
    camera_front.start

    camera_bottom.configure
    camera_bottom.start

    #Configure auv_control
    
    world_to_aligned.configure
    aligned_position_controller.configure
    aligned_velocity_controller.configure
    aligned_to_body.configure
    acceleration_controller.configure

    cmd_world = world_cmd_producer.cmd
    cmd_world.linear[0] = NaN;
    cmd_world.linear[1] = NaN;
    cmd_world.linear[2] = 0;
    
    cmd_world.angular[0] = 0;
    cmd_world.angular[1] = 0;
    cmd_world.angular[2] = 0;
    world_cmd_producer.cmd = cmd_world
    world_cmd_producer.configure

    cmd_vel = velocity_cmd_producer.cmd
    cmd_vel.linear[0] = 0;
    cmd_vel.linear[1] = 0;
    cmd_vel.linear[2] = NaN;
    
    cmd_vel.angular[0] = NaN;
    cmd_vel.angular[1] = NaN;
    cmd_vel.angular[2] = NaN;
    velocity_cmd_producer.cmd = cmd_vel
    velocity_cmd_producer.configure
    
    #Connect ports of auv_control
    imu.pose_samples.connect_to world_to_aligned.pose_samples
    imu.pose_samples.connect_to aligned_position_controller.pose_samples
    imu.pose_samples.connect_to aligned_velocity_controller.pose_samples
    imu.pose_samples.connect_to aligned_to_body.orientation_samples

    world_cmd_producer.cmd_out.connect_to world_to_aligned.cmd_in
    world_to_aligned.cmd_out.connect_to aligned_position_controller.cmd_cascade
    velocity_cmd_producer.cmd_out.connect_to aligned_velocity_controller.cmd_in
    aligned_position_controller.cmd_out.connect_to aligned_velocity_controller.cmd_cascade
    aligned_velocity_controller.cmd_out.connect_to aligned_to_body.cmd_cascade
    aligned_to_body.cmd_out.connect_to acceleration_controller.cmd_cascade
    acceleration_controller.cmd_out.connect_to thrusters.command

    #Start auv_control
    world_cmd_producer.start
    velocity_cmd_producer.start
    world_to_aligned.start
    aligned_position_controller.start
    aligned_velocity_controller.start
    aligned_to_body.start
    acceleration_controller.start
   
    #read velocitys from joystick and write on velocity_cmd_producer
    widget.joystick.connect(SIGNAL('axisChanged(double,double)'))do |x,y|
        cmd_vel.linear[0] = x
        cmd_vel.linear[1] = -y
	velocity_cmd_producer.cmd = cmd_vel
    end
    
    #read world positions from ther sliders and write on world_cmd_producer
    widget.slider_depth.connect(SIGNAL('valueChanged(int)'))do |x|
        cmd_world.linear[2] = x/10.0
	world_cmd_producer.cmd = cmd_world
    end
    
    widget.slider_pitch.connect(SIGNAL('valueChanged(int)'))do |x|
        cmd_world.angular[1] = x/100.0
	world_cmd_producer.cmd = cmd_world
    end
    
    widget.slider_yaw.connect(SIGNAL('valueChanged(int)'))do |x|
        cmd_world.angular[2] = x/100.0
	world_cmd_producer.cmd = cmd_world
    end

    #show camra and orientation in control pannel
    Vizkit.display imu.pose_samples, :widget => widget.orientation
    Vizkit.display camera_front.frame, :widget => widget.camera_front
    Vizkit.display camera_bottom.frame, :widget => widget.camera_bottom
    widget.show 
    Vizkit.exec
    #loop do
    #    sleep 1
    #end
end
